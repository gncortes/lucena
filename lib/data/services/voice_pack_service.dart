import '../../domain/models/lesson_video.dart';

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

import 'lesson_content_service.dart';

/// Um arquivo de voz publicado: caminho no pacote, tamanho e SHA-256.
typedef VoiceFile = ({String path, int bytes, String sha256});

/// O áudio da fala é nomeado pela chave (`sha1(idioma \n voz \n texto)[:16]`,
/// spike §3): `audio/<idioma>/<voz>/<chave>.opus`. Nada fora disso é aceito.
bool isVoiceAudioPath(String path) =>
    RegExp(r'^audio/[a-z]{2}(_[A-Z]{2})?/[a-z0-9_-]+/[0-9a-f]{16}\.opus$')
        .hasMatch(path);

/// Falha de download da voz (o repositório traduz para o estado da tela).
class VoicePackException implements Exception {
  const VoicePackException(this.kind);

  /// `network`, `corrupt`, `storage` ou `unavailable`.
  final String kind;

  @override
  String toString() => 'VoicePackException($kind)';
}

/// Baixa e guarda o áudio dos capítulos. Mesma origem e mesma regra dos
/// pacotes de conteúdo publicados (`content/releases/<versão>/`, só
/// download; credenciais de envio nunca ficam no app). O índice da voz do
/// capítulo é `voice/<idioma>/<voz>/<capítulo>.json`:
/// `{"formato": 1, "arquivos": {"audio/...opus": {"bytes": n, "sha256": h}}}`.
/// Cada arquivo pode trazer os tempos da fala (`"ms"` e `"palavras"`, o
/// contrato de [VoiceClip] gerado pelo `gerar_licao.py`); sem eles, a fala
/// toca o áudio com os tempos estimados.
///
/// Cada arquivo vai para `<pasta>/voice/<versão>/<caminho>` pelo nome da
/// chave (texto igual, áudio igual: capítulos dividem arquivos), escrito em
/// `.part` e renomeado só depois de conferido. A marca do capítulo
/// (`chapters/...json`) só é gravada quando todos os arquivos conferem, então
/// um download interrompido recomeça do arquivo que faltou.
class VoicePackService {
  VoicePackService({
    required this.release,
    required this.download,
    required this.directory,
  }) {
    if (!RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(release)) {
      throw ArgumentError.value(release, 'release');
    }
  }

  final String release;
  final LessonObjectDownload download;
  final Future<Directory> Function() directory;

  static const maxFileBytes = 8 * 1024 * 1024;
  static final _id = RegExp(r'^[a-zA-Z0-9_.-]+$');

  String _indexObject(String language, String voice, String chapter) =>
      'content/releases/$release/voice/$language/$voice/$chapter.json';

  Future<Directory> _root() async =>
      Directory('${(await directory()).path}/voice/$release');

  Future<File> _marker(String language, String voice, String chapter) async =>
      File('${(await _root()).path}/chapters/$language.$voice.$chapter.json');

  void _checkIds(String language, String voice, String chapter) {
    for (final id in [language, voice, chapter]) {
      if (!_id.hasMatch(id) || id.startsWith('.')) {
        throw ArgumentError.value(id, 'id');
      }
    }
  }

  List<VoiceFile> _parse(Uint8List raw) {
    try {
      final json = jsonDecode(utf8.decode(raw));
      if (json is! Map ||
          json['formato'] != 1 ||
          json['arquivos'] is! Map ||
          (json['arquivos'] as Map).isEmpty) {
        throw const VoicePackException('corrupt');
      }
      final files = <VoiceFile>[];
      for (final entry in (json['arquivos'] as Map).entries) {
        final path = entry.key;
        final meta = entry.value;
        if (path is! String ||
            !isVoiceAudioPath(path) ||
            meta is! Map ||
            meta['bytes'] is! int ||
            (meta['bytes'] as int) <= 0 ||
            (meta['bytes'] as int) > maxFileBytes ||
            meta['sha256'] is! String ||
            !RegExp(r'^[0-9a-f]{64}$').hasMatch(meta['sha256'] as String)) {
          throw const VoicePackException('corrupt');
        }
        files.add((
          path: path,
          bytes: meta['bytes'] as int,
          sha256: meta['sha256'] as String,
        ));
      }
      return files;
    } on FormatException {
      throw const VoicePackException('corrupt');
    }
  }

  Future<Uint8List> _get(String object, int limit) async {
    final Uint8List? bytes;
    try {
      bytes = await download(object);
    } on SocketException {
      throw const VoicePackException('network');
    } on TimeoutException {
      throw const VoicePackException('network');
    } on LessonContentNetworkUnavailable {
      throw const VoicePackException('network');
    } on LessonContentNotFound {
      throw const VoicePackException('unavailable');
    } on Object {
      throw const VoicePackException('network');
    }
    if (bytes == null) throw const VoicePackException('unavailable');
    if (bytes.length > limit) throw const VoicePackException('corrupt');
    return bytes;
  }

  Future<bool> _verified(File file, VoiceFile meta) async {
    if (!await file.exists() || await file.length() != meta.bytes) {
      return false;
    }
    return sha256.convert(await file.readAsBytes()).toString() == meta.sha256;
  }

  /// O capítulo está completo no aparelho (marca gravada e cada arquivo com o
  /// tamanho publicado; o hash foi conferido ao baixar).
  Future<bool> installed(String language, String voice, String chapter) async {
    _checkIds(language, voice, chapter);
    final marker = await _marker(language, voice, chapter);
    if (!await marker.exists()) return false;
    try {
      final files = _parse(await marker.readAsBytes());
      final root = await _root();
      for (final f in files) {
        final file = File('${root.path}/${f.path}');
        if (!await file.exists() || await file.length() != f.bytes) {
          return false;
        }
      }
      return true;
    } on VoicePackException {
      return false;
    }
  }

  /// Baixa o que falta da voz do capítulo, conferindo cada arquivo pelo
  /// tamanho, pelo SHA-256 e pela chave no nome. [progress] recebe
  /// (prontos, total). Lança [VoicePackException].
  Future<void> install(
    String language,
    String voice,
    String chapter, {
    void Function(int done, int total)? progress,
  }) async {
    _checkIds(language, voice, chapter);
    final raw = await _get(_indexObject(language, voice, chapter), 1 << 20);
    final files = _parse(raw);
    final root = await _root();
    try {
      var done = 0;
      progress?.call(done, files.length);
      for (final meta in files) {
        final file = File('${root.path}/${meta.path}');
        if (!await _verified(file, meta)) {
          final bytes = await _get(
            'content/releases/$release/${meta.path}',
            maxFileBytes,
          );
          if (bytes.length != meta.bytes ||
              sha256.convert(bytes).toString() != meta.sha256) {
            throw const VoicePackException('corrupt');
          }
          await file.parent.create(recursive: true);
          final part = File('${file.path}.part');
          await part.writeAsBytes(bytes, flush: true);
          await part.rename(file.path);
        }
        progress?.call(++done, files.length);
      }
      final marker = await _marker(language, voice, chapter);
      await marker.parent.create(recursive: true);
      final next = File('${marker.path}.next');
      await next.writeAsBytes(raw, flush: true);
      await next.rename(marker.path);
    } on FileSystemException catch (error) {
      if ([28, 112].contains(error.osError?.errorCode)) {
        throw const VoicePackException('storage');
      }
      rethrow;
    }
  }

  /// Os tempos de cada fala do capítulo instalado, pela chave do áudio
  /// (o nome do arquivo); vazio sem o capítulo ou sem tempos no índice.
  Future<Map<String, VoiceClip>> clips(
    String language,
    String voice,
    String chapter,
  ) async {
    if (!await installed(language, voice, chapter)) return const {};
    final marker = await _marker(language, voice, chapter);
    try {
      final json = jsonDecode(utf8.decode(await marker.readAsBytes())) as Map;
      final out = <String, VoiceClip>{};
      for (final MapEntry(:key, :value) in (json['arquivos'] as Map).entries) {
        if (key is! String || value is! Map || value['ms'] is! num) continue;
        final name = key.substring(key.lastIndexOf('/') + 1);
        out[name.substring(0, name.length - '.opus'.length)] =
            VoiceClip.fromJson(value.cast<String, dynamic>());
      }
      return out;
    } on Object {
      return const {};
    }
  }

  /// O caminho no disco de um áudio do capítulo, ou nulo se não está lá.
  Future<String?> file(String path) async {
    if (!isVoiceAudioPath(path)) return null;
    final file = File('${(await _root()).path}/$path');
    return await file.exists() ? file.path : null;
  }
}

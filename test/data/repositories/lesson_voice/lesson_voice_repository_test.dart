import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/data/repositories/lesson_voice/lesson_voice_repository.dart';
import 'package:lucena/data/repositories/lesson_voice/lesson_voice_repository_downloaded.dart';
import 'package:lucena/data/services/lesson_content_service.dart';
import 'package:lucena/data/services/preferences_service.dart';
import 'package:lucena/data/services/voice_pack_service.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

const _a = 'audio/pt/viktor/0123456789abcdef.opus';
const _b = 'audio/pt/viktor/fedcba9876543210.opus';
const _index = 'content/releases/r1/voice/pt/viktor/c1.json';

/// O servidor publicado em memória: objetos por caminho, falhas sob pedido.
class _Server {
  final objects = <String, Uint8List>{};
  final failing = <String>{};
  final requests = <String>[];

  Future<Uint8List?> download(String object) async {
    requests.add(object);
    if (failing.contains(object)) {
      throw const SocketException('sem internet');
    }
    return objects[object];
  }

  void publish(Map<String, List<int>> files, {Map<String, String>? hashes}) {
    for (final e in files.entries) {
      objects['content/releases/r1/${e.key}'] = Uint8List.fromList(e.value);
    }
    objects[_index] = Uint8List.fromList(
      utf8.encode(
        jsonEncode({
          'formato': 1,
          'arquivos': {
            for (final e in files.entries)
              e.key: {
                'bytes': e.value.length,
                'sha256': hashes?[e.key] ?? sha256.convert(e.value).toString(),
              },
          },
        }),
      ),
    );
  }
}

void main() {
  late Directory dir;
  late _Server server;

  DownloadedLessonVoiceRepository repository({bool configured = true}) =>
      DownloadedLessonVoiceRepository(
        configured
            ? VoicePackService(
                release: 'r1',
                download: server.download,
                directory: () async => dir,
              )
            : null,
        PreferencesService(),
        language: () async => 'pt',
      );

  setUp(() async {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    dir = await Directory.systemTemp.createTemp('voz-');
    server = _Server()
      ..publish({
        _a: [1, 2, 3],
        _b: [4, 5, 6, 7],
      });
  });

  tearDown(() => dir.delete(recursive: true));

  test('Vídeo 10: capítulo sem a voz baixada fica "Sem áudio"', () async {
    final repo = repository();
    expect(await repo.state('c1'), const VoicePackMissing());
    expect(await repo.audioFile('c1', _a), isNull);
  });

  test('baixar a voz confere cada arquivo e deixa pronto', () async {
    final repo = repository();
    final states = <VoicePackState>[];
    final sub = repo.watch('c1').listen(states.add);
    await pumpEventQueue();
    expect(await repo.download('c1'), const VoicePackReady());
    await pumpEventQueue();
    await sub.cancel();
    expect(states, [
      const VoicePackMissing(),
      const VoicePackDownloading(0, 2),
      const VoicePackDownloading(1, 2),
      const VoicePackDownloading(2, 2),
      const VoicePackReady(),
    ]);
    final file = await repo.audioFile('c1', _a);
    expect(await File(file!).readAsBytes(), [1, 2, 3]);
    // Reabrir o app: o pacote continua lá, sem rede.
    server.failing.add(_index);
    expect(await repository().state('c1'), const VoicePackReady());
  });

  test('hash errado não grava o arquivo e falha como corrompido', () async {
    server.publish(
      {
        _a: [1, 2, 3],
      },
      hashes: {_a: 'f' * 64},
    );
    final repo = repository();
    expect(
      await repo.download('c1'),
      const VoicePackFailed(VoicePackFailure.corrupt),
    );
    expect(await repo.state('c1'), isNot(const VoicePackReady()));
    expect(File('${dir.path}/voice/r1/$_a').existsSync(), isFalse);
  });

  test('caminho fora da chave no índice é recusado', () async {
    server.objects[_index] = Uint8List.fromList(
      utf8.encode(
        jsonEncode({
          'formato': 1,
          'arquivos': {
            '../../segredo.opus': {'bytes': 1, 'sha256': '0' * 64},
          },
        }),
      ),
    );
    expect(
      await repository().download('c1'),
      const VoicePackFailed(VoicePackFailure.corrupt),
    );
  });

  test('Vídeo 11: sem internet falha com nova tentativa possível', () async {
    server.failing.add(_index);
    final repo = repository();
    expect(
      await repo.download('c1'),
      const VoicePackFailed(VoicePackFailure.network),
    );
    expect(
      await repo.state('c1'),
      const VoicePackFailed(VoicePackFailure.network),
    );
    server.failing.clear();
    expect(await repo.download('c1'), const VoicePackReady());
    expect(await repo.state('c1'), const VoicePackReady());
  });

  test('retomada: a nova tentativa baixa só o arquivo que faltou', () async {
    server.failing.add('content/releases/r1/$_b');
    final repo = repository();
    expect(
      await repo.download('c1'),
      const VoicePackFailed(VoicePackFailure.network),
    );
    expect(await repo.audioFile('c1', _a), isNull);
    server
      ..failing.clear()
      ..requests.clear();
    expect(await repo.download('c1'), const VoicePackReady());
    expect(server.requests, [_index, 'content/releases/r1/$_b']);
  });

  test('capítulo sem voz publicada falha como indisponível', () async {
    server.objects.remove(_index);
    expect(
      await repository().download('c1'),
      const VoicePackFailed(VoicePackFailure.unavailable),
    );
  });

  test('sem fonte configurada: "Sem áudio" e baixar falha', () async {
    final repo = repository(configured: false);
    expect(await repo.state('c1'), const VoicePackMissing());
    expect(
      await repo.download('c1'),
      const VoicePackFailed(VoicePackFailure.unavailable),
    );
  });

  test('dois toques em "Baixar a voz" fazem um download só', () async {
    final repo = repository();
    final both = await Future.wait([repo.download('c1'), repo.download('c1')]);
    expect(both, [const VoicePackReady(), const VoicePackReady()]);
    expect(server.requests.where((r) => r == _index), hasLength(1));
  });

  test('arquivo apagado do disco volta a "Sem áudio"', () async {
    final repo = repository();
    await repo.download('c1');
    await File('${dir.path}/voice/r1/$_b').delete();
    expect(await repo.state('c1'), const VoicePackMissing());
  });

  test('erro de rede do conteúdo publicado conta como sem internet', () async {
    final repo = DownloadedLessonVoiceRepository(
      VoicePackService(
        release: 'r1',
        download: (_) async => throw const LessonContentNetworkUnavailable(),
        directory: () async => dir,
      ),
      PreferencesService(),
      language: () async => 'pt',
    );
    expect(
      await repo.download('c1'),
      const VoicePackFailed(VoicePackFailure.network),
    );
  });

  group('preferência de voz', () {
    test('Vídeo 9: começa ligada', () async {
      expect(await repository().voiceOn(), isTrue);
    });

    test('desligada continua desligada ao reabrir', () async {
      await repository().setVoiceOn(on: false);
      expect(await repository().voiceOn(), isFalse);
      await repository().setVoiceOn(on: true);
      expect(await repository().voiceOn(), isTrue);
    });
  });
}

import '../../../domain/models/lesson_video.dart';

import 'dart:async';

import '../../services/preferences_service.dart';
import '../../services/voice_pack_service.dart';
import 'lesson_voice_repository.dart';

/// A voz baixada pelo [VoicePackService] (mesma origem dos pacotes de
/// conteúdo publicados) e a preferência nas preferências do aparelho. Sem
/// serviço (conteúdo só do APK ou sem versão publicada), todo capítulo fica
/// "Sem áudio" e baixar falha como indisponível.
class DownloadedLessonVoiceRepository implements LessonVoiceRepository {
  DownloadedLessonVoiceRepository(
    this._packs,
    this._preferences, {
    required this._language,
    this.voice = 'viktor',
  });

  final VoicePackService? _packs;
  final PreferencesService _preferences;
  final Future<String> Function() _language;

  /// A voz do professor (provisória, decisão 9: trocar a voz troca só os
  /// arquivos).
  final String voice;

  static const voiceKey = 'lessonVideo.voice';

  final _controllers = <String, StreamController<VoicePackState>>{};
  final _running = <String, Future<VoicePackState>>{};
  final _last = <String, VoicePackState>{};

  StreamController<VoicePackState> _controller(String chapterId) =>
      _controllers.putIfAbsent(chapterId, StreamController.broadcast);

  void _emit(String chapterId, VoicePackState state) {
    _last[chapterId] = state;
    _controller(chapterId).add(state);
  }

  @override
  Future<VoicePackState> state(String chapterId) async {
    if (_last[chapterId] case final VoicePackDownloading s) return s;
    final packs = _packs;
    if (packs != null &&
        await packs.installed(await _language(), voice, chapterId)) {
      return const VoicePackReady();
    }
    if (_last[chapterId] case final VoicePackFailed s) return s;
    return const VoicePackMissing();
  }

  @override
  Stream<VoicePackState> watch(String chapterId) {
    // Ouve as mudanças antes de ler o estado: nada se perde no meio.
    StreamSubscription<VoicePackState>? changes;
    late final StreamController<VoicePackState> out;
    VoicePackState? previous;
    void add(VoicePackState state) {
      if (state == previous) return;
      previous = state;
      out.add(state);
    }

    out = StreamController<VoicePackState>(
      onListen: () {
        final pending = <VoicePackState>[];
        var live = false;
        changes = _controller(chapterId).stream.listen((state) {
          live ? add(state) : pending.add(state);
        });
        unawaited(
          state(chapterId).then((current) {
            if (pending.isEmpty) add(current);
            pending.forEach(add);
            live = true;
          }),
        );
      },
      onCancel: () => changes?.cancel(),
    );
    return out.stream;
  }

  @override
  Future<VoicePackState> download(String chapterId) =>
      _running.putIfAbsent(chapterId, () async {
        try {
          return await _download(chapterId);
        } finally {
          unawaited(_running.remove(chapterId));
        }
      });

  Future<VoicePackState> _download(String chapterId) async {
    final packs = _packs;
    if (packs == null) {
      const failed = VoicePackFailed(VoicePackFailure.unavailable);
      _emit(chapterId, failed);
      return failed;
    }
    final language = await _language();
    try {
      await packs.install(
        language,
        voice,
        chapterId,
        progress: (done, total) =>
            _emit(chapterId, VoicePackDownloading(done, total)),
      );
      _emit(chapterId, const VoicePackReady());
      return const VoicePackReady();
    } on VoicePackException catch (error) {
      final failed = VoicePackFailed(switch (error.kind) {
        'network' => VoicePackFailure.network,
        'corrupt' => VoicePackFailure.corrupt,
        'storage' => VoicePackFailure.storage,
        _ => VoicePackFailure.unavailable,
      });
      _emit(chapterId, failed);
      return failed;
    } on Object {
      const failed = VoicePackFailed(VoicePackFailure.storage);
      _emit(chapterId, failed);
      return failed;
    }
  }

  @override
  Future<String?> audioFile(String chapterId, String audioPath) async {
    final packs = _packs;
    if (packs == null) return null;
    if (await state(chapterId) is! VoicePackReady) return null;
    return packs.file(audioPath);
  }

  @override
  Future<Map<String, VoiceClip>> clips(String chapterId) async {
    final packs = _packs;
    if (packs == null) return const {};
    return packs.clips(await _language(), voice, chapterId);
  }

  @override
  Future<bool> voiceOn() async => await _preferences.getBool(voiceKey) ?? true;

  @override
  Future<void> setVoiceOn({required bool on}) =>
      _preferences.setBool(voiceKey, value: on);
}

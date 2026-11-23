import 'dart:async';

import 'package:lucena/data/repositories/lesson_voice/lesson_voice_repository.dart';

/// A voz dos capítulos em memória: o teste diz o estado de cada capítulo e o
/// que o próximo download devolve.
class FakeLessonVoiceRepository implements LessonVoiceRepository {
  FakeLessonVoiceRepository({
    Map<String, VoicePackState>? states,
    this.on = true,
  }) : states = states ?? {};

  final Map<String, VoicePackState> states;

  /// O resultado do próximo download (padrão: pronto).
  VoicePackState nextDownload = const VoicePackReady();
  final downloads = <String>[];
  bool on;
  final _changes = StreamController<(String, VoicePackState)>.broadcast();

  @override
  Future<VoicePackState> state(String chapterId) async =>
      states[chapterId] ?? const VoicePackMissing();

  @override
  Stream<VoicePackState> watch(String chapterId) async* {
    yield await state(chapterId);
    yield* _changes.stream.where((c) => c.$1 == chapterId).map((c) => c.$2);
  }

  @override
  Future<VoicePackState> download(String chapterId) async {
    downloads.add(chapterId);
    states[chapterId] = nextDownload;
    _changes.add((chapterId, nextDownload));
    return nextDownload;
  }

  @override
  Future<String?> audioFile(String chapterId, String audioPath) async =>
      states[chapterId] is VoicePackReady ? '/fake/$audioPath' : null;

  @override
  Future<bool> voiceOn() async => on;

  @override
  Future<void> setVoiceOn({required bool on}) async => this.on = on;
}

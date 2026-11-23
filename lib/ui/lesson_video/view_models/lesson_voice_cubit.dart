import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/lesson_voice/lesson_voice_repository.dart';

/// A voz da aula em vídeo vista pela tela: preferência ligada/desligada e o
/// pacote de áudio do capítulo.
class LessonVoiceState {
  const LessonVoiceState({
    this.voiceOn = true,
    this.pack = const VoicePackMissing(),
    this.loaded = false,
  });

  /// A voz do Viktor ligada (folha "Som e voz").
  final bool voiceOn;

  /// O áudio do capítulo no aparelho.
  final VoicePackState pack;
  final bool loaded;

  /// Toca a voz gravada; senão, modo leitura (`VideoPace.reading`).
  bool get speaks => voiceOn && pack is VoicePackReady;

  /// O aviso "Sem áudio. Baixar a voz" (var 3): só quando a voz está ligada
  /// e falta o áudio; com a voz desligada, sem aviso (Vídeo 9).
  bool get showsNoAudio => loaded && voiceOn && pack is! VoicePackReady;

  LessonVoiceState copyWith({
    bool? voiceOn,
    VoicePackState? pack,
    bool? loaded,
  }) => LessonVoiceState(
    voiceOn: voiceOn ?? this.voiceOn,
    pack: pack ?? this.pack,
    loaded: loaded ?? this.loaded,
  );

  @override
  bool operator ==(Object other) =>
      other is LessonVoiceState &&
      other.voiceOn == voiceOn &&
      other.pack == pack &&
      other.loaded == loaded;

  @override
  int get hashCode => Object.hash(voiceOn, pack, loaded);
}

class LessonVoiceCubit extends Cubit<LessonVoiceState> {
  LessonVoiceCubit(this._repository, {required this.chapterId})
    : super(const LessonVoiceState());

  final LessonVoiceRepository _repository;
  final String chapterId;
  StreamSubscription<VoicePackState>? _pack;

  Future<void> load() async {
    final on = await _repository.voiceOn();
    if (isClosed) return;
    emit(state.copyWith(voiceOn: on));
    await _pack?.cancel();
    _pack = _repository.watch(chapterId).listen((pack) {
      if (!isClosed) emit(state.copyWith(pack: pack, loaded: true));
    });
  }

  Future<void> setVoiceOn({required bool on}) async {
    emit(state.copyWith(voiceOn: on));
    await _repository.setVoiceOn(on: on);
  }

  /// "Baixar a voz" e "Tentar de novo".
  Future<void> download() async {
    if (state.pack is VoicePackDownloading) return;
    final result = await _repository.download(chapterId);
    if (!isClosed) emit(state.copyWith(pack: result, loaded: true));
  }

  @override
  Future<void> close() async {
    await _pack?.cancel();
    return super.close();
  }
}

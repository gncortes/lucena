import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/lesson_ad/demo_ad_repository.dart';
import '../../../domain/use_cases/ad_policy.dart';
import '../../../domain/use_cases/now.dart';

enum LessonAdPhase { loading, ready, failed }

/// O estado da tela do anúncio: carregando, pronto (com a contagem) ou falha.
class LessonAdState {
  const LessonAdState({
    this.phase = LessonAdPhase.loading,
    this.secondsLeft = 3,
  });

  final LessonAdPhase phase;

  /// O número de "Fechar em N"; 0 libera o "Fechar".
  final int secondsLeft;

  bool get canClose => phase == LessonAdPhase.ready && secondsLeft == 0;

  @override
  bool operator ==(Object other) =>
      other is LessonAdState &&
      other.phase == phase &&
      other.secondsLeft == secondsLeft;

  @override
  int get hashCode => Object.hash(phase, secondsLeft);
}

/// Carrega o anúncio e conta os 3 segundos pelo [Now] injetado (H-LIC-10).
/// A contagem pausa em segundo plano ([pause]) e retoma de onde parou
/// ([resume]); o tempo parado não conta.
class LessonAdCubit extends Cubit<LessonAdState> {
  LessonAdCubit({
    required this.ads,
    required this.now,
    this.tick = const Duration(milliseconds: 100),
  }) : super(const LessonAdState());

  final DemoAdRepository ads;
  final Now now;
  final Duration tick;

  Timer? _timer;
  Duration _elapsed = Duration.zero;
  DateTime? _runningSince;

  /// Carrega o anúncio. Em [retry] (Tentar novamente) a tela de falha fica e
  /// o carregando aparece no botão, que espera este `Future`.
  Future<void> load({bool retry = false}) async {
    _stop();
    _elapsed = Duration.zero;
    if (!retry) emit(const LessonAdState());
    bool loaded;
    try {
      loaded = await ads.load();
    } on Object {
      loaded = false;
    }
    if (isClosed) return;
    if (!loaded) return emit(const LessonAdState(phase: LessonAdPhase.failed));
    emit(
      LessonAdState(
        phase: LessonAdPhase.ready,
        secondsLeft: DemoAdPolicy.secondsLeft(Duration.zero),
      ),
    );
    resume();
  }

  /// Segundo plano: guarda o tempo já contado e para.
  void pause() {
    final since = _runningSince;
    if (since == null) return;
    _elapsed += now().difference(since);
    _stop();
  }

  /// Volta do segundo plano (ou começa): conta a partir do que faltava.
  void resume() {
    if (isClosed || state.phase != LessonAdPhase.ready) return;
    if (_runningSince != null || state.secondsLeft == 0) return;
    _runningSince = now();
    _timer = Timer.periodic(tick, (_) => _update());
  }

  void _update() {
    final since = _runningSince;
    if (since == null) return;
    final left = DemoAdPolicy.secondsLeft(_elapsed + now().difference(since));
    if (left != state.secondsLeft) {
      emit(LessonAdState(phase: LessonAdPhase.ready, secondsLeft: left));
    }
    if (left == 0) _stop();
  }

  void _stop() {
    _timer?.cancel();
    _timer = null;
    _runningSince = null;
  }

  @override
  Future<void> close() {
    _stop();
    return super.close();
  }
}

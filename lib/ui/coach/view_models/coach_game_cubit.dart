import 'dart:async';
import 'dart:math' as math;

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/lesson_ad/course_grants_repository.dart';
import '../../../data/repositories/coach/coach_preferences.dart';
import '../../../data/repositories/coach/coach_repository.dart';
import '../../../data/services/firebase/coach_service.dart';
import '../../../domain/models/coach/coach.dart';
import '../../../domain/use_cases/now.dart';
import '../../../domain/use_cases/coach/coach_rules.dart';

/// O pedido de análise feito nesta tela.
enum AnalysisRequest {
  none,
  sending,

  /// O grátis passou das 3 análises da semana: a saída é o plano.
  quota,

  /// O assinante passou do teto do mês ou o Treinador está desligado.
  refused,
  failed,
}

/// Uma partida do Treinador: início, espera da análise, erro e resumo.
final class CoachGameState {
  const CoachGameState({
    this.loading = true,
    this.failed = false,
    this.game,
    this.grant = false,
    this.request = AnalysisRequest.none,
    this.analysisStart,
    this.expectedExercises,
    this.autoAnalysis = false,
  });

  final bool loading;
  final bool failed;

  /// Nula depois de carregar: a partida não existe (ou é de outra conta).
  final CoachGame? game;
  final bool grant;
  final AnalysisRequest request;

  /// Quando a análise começou neste aparelho (para a porcentagem da espera).
  final DateTime? analysisStart;

  /// Quantos exercícios a análise gera (`config.exerciciosPorPartida`); nulo
  /// até a config chegar.
  final int? expectedExercises;

  /// A10 G2: partida nova com plano pede a análise ao abrir; a tela já mostra
  /// a espera em vez do "Começar a análise".
  final bool autoAnalysis;

  bool get notFound => !loading && !failed && game == null;

  CoachGameState copyWith({
    bool? loading,
    bool? failed,
    CoachGame? Function()? game,
    bool? grant,
    AnalysisRequest? request,
    DateTime? Function()? analysisStart,
    int? expectedExercises,
    bool? autoAnalysis,
  }) => CoachGameState(
    loading: loading ?? this.loading,
    failed: failed ?? this.failed,
    game: game == null ? this.game : game(),
    grant: grant ?? this.grant,
    request: request ?? this.request,
    analysisStart: analysisStart == null ? this.analysisStart : analysisStart(),
    expectedExercises: expectedExercises ?? this.expectedExercises,
    autoAnalysis: autoAnalysis ?? this.autoAnalysis,
  );
}

final class CoachGameCubit extends Cubit<CoachGameState> {
  CoachGameCubit({
    required this.id,
    required this.repository,
    required this.grants,
    required this.preferences,
    required this.now,
  }) : super(const CoachGameState());

  final String id;
  final CoachRepository repository;
  final CourseGrantsRepository grants;
  final CoachPreferences preferences;
  final Now now;

  StreamSubscription<CoachGame?>? _game;
  StreamSubscription<Object?>? _grants;
  var _requestedAlone = false;

  Future<void> load() async {
    final start = await preferences.startOfAnalysis(id);
    if (isClosed) return;
    emit(
      state.copyWith(
        analysisStart: () => start,
        grant: CoachRules.hasAccess(grants.current, now()),
      ),
    );
    _grants ??= grants.changes.listen((g) {
      if (!isClosed) {
        emit(state.copyWith(grant: CoachRules.hasAccess(g, now())));
      }
    });
    _listen();
    unawaited(_readConfig());
  }

  /// Sem a config, a tela usa o padrão do modelo.
  Future<void> _readConfig() async {
    try {
      final config = await repository.config();
      if (!isClosed) {
        emit(state.copyWith(expectedExercises: config.exercisesPerGame));
      }
    } on Object {
      // O cartão "Como funciona" mostra o número padrão.
    }
  }

  void _listen() {
    _game?.cancel();
    _game = repository
        .game(id)
        .listen(
          (p) => unawaited(_arrived(p)),
          onError: (_) {
            if (!isClosed) {
              emit(state.copyWith(loading: false, failed: true));
            }
          },
        );
  }

  // Emite já e grava depois: se a partida mudar no meio da gravação, o
  // estado novo não é passado para trás pelo antigo.
  Future<void> _arrived(CoachGame? p) async {
    if (isClosed) return;
    var start = state.analysisStart;
    Future<void>? record;
    // Só a análise rodando conta tempo: na fila a barra não anda (a fila do
    // grátis pode durar horas) e a porcentagem não mente.
    if (p != null && p.status == GameStatus.analyzing && start == null) {
      start = now();
      record = preferences.markStart(id, start);
    } else if (p != null && p.status != GameStatus.analyzing && start != null) {
      start = null;
      record = preferences.forgetStart(id);
    }
    emit(
      state.copyWith(
        loading: false,
        failed: false,
        game: () => p,
        analysisStart: () => start,
      ),
    );
    if (p?.status == GameStatus.newGame && state.grant && !_requestedAlone) {
      _requestedAlone = true;
      emit(state.copyWith(autoAnalysis: true));
      unawaited(
        analyze().then((ok) {
          if (!ok && !isClosed) emit(state.copyWith(autoAnalysis: false));
        }),
      );
    }
    await record;
  }

  void retry() {
    emit(state.copyWith(loading: true, failed: false));
    _listen();
  }

  /// Pede a análise (partida nova, ou "Tentar de novo" de um erro).
  Future<bool> analyze() => _request(notify: false);

  /// "Me avise quando terminar": o servidor manda o aviso mesmo no limite de
  /// um por hora. Falha aqui não prende a pessoa na espera.
  Future<void> notifyMe() async {
    try {
      await repository.analyze(id, notify: true);
    } on Object {
      // A análise segue; sem o aviso, a partida aparece pronta na lista.
    }
  }

  Future<bool> _request({required bool notify}) async {
    if (state.request == AnalysisRequest.sending) return false;
    emit(state.copyWith(request: AnalysisRequest.sending));
    try {
      await repository.analyze(id, notify: notify);
      if (isClosed) return true;
      // A partida pode ter ficado pronta antes de o servidor responder.
      if (state.game?.ready ?? false) {
        emit(state.copyWith(request: AnalysisRequest.none));
        return true;
      }
      // O início da contagem vem do status `analisando` (ver `_chegou`).
      emit(state.copyWith(request: AnalysisRequest.none));
      return true;
    } on CoachCallException catch (e) {
      if (isClosed) return false;
      emit(
        state.copyWith(
          request: e.quota
              ? AnalysisRequest.quota
              : e.code == 'permission-denied'
              ? AnalysisRequest.refused
              : AnalysisRequest.failed,
        ),
      );
      return false;
    } on Object {
      if (!isClosed) emit(state.copyWith(request: AnalysisRequest.failed));
      return false;
    }
  }

  /// A recusa ou a falha já foi mostrada.
  void requestSeen() => emit(state.copyWith(request: AnalysisRequest.none));

  @override
  Future<void> close() async {
    await _game?.cancel();
    await _grants?.cancel();
    await super.close();
  }
}

/// A porcentagem da espera: anda depressa no começo e para perto de 95%
/// até a partida ficar pronta (a análise leva de 1 a 5 minutos).
abstract final class WaitPercentage {
  static const ceiling = 95;
  static const constant = Duration(seconds: 90);

  static int of(DateTime? start, DateTime currentTime) {
    if (start == null) return 0;
    final t = currentTime.difference(start).inMilliseconds;
    if (t <= 0) return 0;
    final fraction = 1 - math.exp(-t / constant.inMilliseconds);
    return (ceiling * fraction).floor().clamp(0, ceiling);
  }
}

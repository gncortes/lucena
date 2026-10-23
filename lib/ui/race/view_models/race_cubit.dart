import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/race/race_repository.dart';
import '../../../domain/models/race.dart';
import '../../../domain/use_cases/now.dart';
import '../../../domain/use_cases/race_rules.dart';

/// Em que ponto da Corrida a tela está.
enum RacePhase { loading, intro, playing, finished, reviewing }

/// O que o último lance foi: o ícone toma o lugar do contador.
enum RaceFeedback { correct, wrong }

class RaceState {
  const RaceState({
    this.phase = RacePhase.loading,
    this.problems = const [],
    this.record = const RaceRecord(),
    this.theme,
    this.run,
    this.problem,
    this.remaining = RaceRules.limit,
    this.feedback,
    this.feedbackCount = 0,
    this.outcome,
    this.reviewIndex = 0,
  });

  final RacePhase phase;
  final List<RaceProblem> problems;
  final RaceRecord record;

  /// O filtro escolhido na abertura. Nulo: todos os finais.
  final RaceTheme? theme;
  final RaceRun? run;

  /// O problema no tabuleiro.
  final RaceProblem? problem;
  final Duration remaining;
  final RaceFeedback? feedback;

  /// Quantos lances já deram retorno: muda a cada um, mesmo repetindo o
  /// mesmo [feedback], para o ícone animar de novo.
  final int feedbackCount;
  final RaceOutcome? outcome;

  /// Qual erro a revisão mostra (a partir de 0).
  final int reviewIndex;

  /// Os temas que o banco tem, na ordem do filtro.
  List<RaceTheme> get themes => [
    for (final theme in RaceTheme.values)
      if (problems.any((problem) => problem.theme == theme)) theme,
  ];

  /// Os erros da Corrida acabada, na ordem em que vieram.
  List<RaceAnswer> get mistakes => [
    for (final answer in outcome?.result.run.answers ?? const <RaceAnswer>[])
      if (!answer.correct) answer,
  ];

  RaceState copyWith({
    RacePhase? phase,
    List<RaceProblem>? problems,
    RaceRecord? record,
    RaceTheme? theme,
    bool clearTheme = false,
    RaceRun? run,
    RaceProblem? problem,
    bool clearProblem = false,
    Duration? remaining,
    RaceFeedback? feedback,
    bool clearFeedback = false,
    int? feedbackCount,
    RaceOutcome? outcome,
    int? reviewIndex,
  }) => RaceState(
    phase: phase ?? this.phase,
    problems: problems ?? this.problems,
    record: record ?? this.record,
    theme: clearTheme ? null : theme ?? this.theme,
    run: run ?? this.run,
    problem: clearProblem ? null : problem ?? this.problem,
    remaining: remaining ?? this.remaining,
    feedback: clearFeedback ? null : feedback ?? this.feedback,
    feedbackCount: feedbackCount ?? this.feedbackCount,
    outcome: outcome ?? this.outcome,
    reviewIndex: reviewIndex ?? this.reviewIndex,
  );
}

/// A Corrida de problemas: abertura, corrida, resultado e revisão dos erros.
class RaceCubit extends Cubit<RaceState> {
  RaceCubit(this._repository, this._now) : super(const RaceState());

  final RaceRepository _repository;
  final Now _now;

  // Entre o fim da Corrida e o resultado gravado, nada mais vale.
  bool _finishing = false;

  /// Lê o banco e o recorde. Com uma Corrida em andamento (o app foi fechado
  /// no meio), continua dela, se ainda há tempo, ou fecha o resultado.
  Future<void> load() async {
    final problems = await _repository.problems();
    final record = await _repository.record();
    final ongoing = await _repository.ongoing();
    final saved = await _repository.theme();
    emit(
      state.copyWith(
        problems: problems,
        record: record,
        // Um filtro que o banco não tem mais volta a "Todos os finais".
        theme: problems.any((problem) => problem.theme == saved) ? saved : null,
        phase: RacePhase.intro,
      ),
    );
    if (ongoing != null) await _resume(ongoing);
  }

  Future<void> _resume(RaceRun run) async {
    final end = RaceRules.endOf(run, _now());
    if (end != null) {
      await _finish(run, end);
      return;
    }
    emit(
      state.copyWith(
        phase: RacePhase.playing,
        theme: run.theme,
        clearTheme: run.theme == null,
        run: run,
        problem: RaceRules.next(state.problems, run),
        remaining: RaceRules.remaining(run, _now()),
        clearFeedback: true,
      ),
    );
  }

  /// Escolhe o filtro de finais e o guarda para a próxima vez.
  Future<void> selectTheme(RaceTheme? theme) {
    emit(state.copyWith(theme: theme, clearTheme: theme == null));
    return _repository.setTheme(theme);
  }

  /// Começa uma Corrida nova com o filtro escolhido.
  Future<void> start() async {
    final run = RaceRun(startedAt: _now(), theme: state.theme);
    final problem = RaceRules.next(state.problems, run);
    if (problem == null) return;
    _finishing = false;
    emit(
      state.copyWith(
        phase: RacePhase.playing,
        run: run,
        problem: problem,
        remaining: RaceRules.limit,
        clearFeedback: true,
        feedbackCount: 0,
      ),
    );
    await _repository.saveOngoing(run);
  }

  /// O jogador jogou [move] (UCI) no problema do tabuleiro.
  Future<void> answer(String move) async {
    final run = state.run;
    final problem = state.problem;
    if (state.phase != RacePhase.playing ||
        _finishing ||
        run == null ||
        problem == null) {
      return;
    }
    final now = _now();
    // O tempo acabou antes do lance: ele não vale.
    if (RaceRules.endOf(run, now) == RaceEnd.time) {
      await _finish(run, RaceEnd.time);
      return;
    }
    final answer = RaceRules.answer(problem, move);
    final updated = run.withAnswer(answer);
    final end = RaceRules.endOf(updated, now);
    final feedback = answer.correct ? RaceFeedback.correct : RaceFeedback.wrong;
    if (end != null) {
      await _finish(updated, end, feedback: feedback);
      return;
    }
    emit(
      state.copyWith(
        run: updated,
        problem: RaceRules.next(state.problems, updated),
        remaining: RaceRules.remaining(updated, now),
        feedback: feedback,
        feedbackCount: state.feedbackCount + 1,
      ),
    );
    await _repository.saveOngoing(updated);
  }

  /// Refaz o tempo que falta a partir do relógio; acabando, fecha a Corrida.
  Future<void> tick() async {
    final run = state.run;
    if (state.phase != RacePhase.playing || _finishing || run == null) return;
    final now = _now();
    final end = RaceRules.endOf(run, now);
    if (end != null) {
      await _finish(run, end);
      return;
    }
    emit(state.copyWith(remaining: RaceRules.remaining(run, now)));
  }

  /// A tela voltou do segundo plano: o tempo correu enquanto isso.
  Future<void> resumed() => tick();

  Future<void> _finish(
    RaceRun run,
    RaceEnd end, {
    RaceFeedback? feedback,
  }) async {
    _finishing = true;
    final outcome = await _repository.finish(run, end);
    emit(
      state.copyWith(
        phase: RacePhase.finished,
        run: run,
        remaining: end == RaceEnd.time ? Duration.zero : null,
        record: RaceRules.merge(outcome.previous, run),
        outcome: outcome,
        feedback: feedback,
        clearFeedback: feedback == null,
        reviewIndex: 0,
      ),
    );
  }

  /// O jogador saiu no meio: a Corrida é descartada, sem resultado e sem
  /// contar (nem recorde, nem histórico), e a tela volta à abertura.
  Future<void> quit() async {
    final run = state.run;
    if (state.phase != RacePhase.playing || _finishing || run == null) return;
    _finishing = true;
    await _repository.discardOngoing();
    emit(
      state.copyWith(
        phase: RacePhase.intro,
        clearProblem: true,
        clearFeedback: true,
      ),
    );
  }

  /// Do resultado para a abertura (jogar de novo escolhe o filtro de novo).
  void backToIntro() =>
      emit(state.copyWith(phase: RacePhase.intro, clearProblem: true));

  void review() {
    if (state.mistakes.isEmpty) return;
    emit(state.copyWith(phase: RacePhase.reviewing, reviewIndex: 0));
  }

  /// O próximo erro; depois do último, volta ao resultado.
  void nextMistake() {
    final next = state.reviewIndex + 1;
    if (next >= state.mistakes.length) {
      emit(state.copyWith(phase: RacePhase.finished, reviewIndex: 0));
      return;
    }
    emit(state.copyWith(reviewIndex: next));
  }

  void closeReview() =>
      emit(state.copyWith(phase: RacePhase.finished, reviewIndex: 0));
}

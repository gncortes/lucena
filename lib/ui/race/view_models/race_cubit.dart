import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/race/race_repository.dart';
import '../../../domain/models/race.dart';
import '../../../domain/use_cases/now.dart';
import '../../../domain/use_cases/race_diagnosis.dart';
import '../../../domain/use_cases/race_rules.dart';
import '../../../domain/use_cases/race_turn.dart';

/// Em que ponto da Corrida a tela está.
enum RacePhase { loading, intro, playing, finished, reviewing }

/// O que o último lance foi: o ícone toma o lugar do contador.
enum RaceFeedback { correct, wrong }

class RaceState {
  const RaceState({
    this.phase = RacePhase.loading,
    this.problems = const [],
    this.record = const RaceRecord(),
    this.duration = RaceDuration.threeMinutes,
    this.filter = const RaceFilter(),
    this.run,
    this.turn,
    this.boardFen,
    this.replying = false,
    this.recent = const {},
    this.remaining = RaceRules.limit,
    this.feedback,
    this.feedbackCount = 0,
    this.outcome,
    this.reviewIndex = 0,
    this.diagnosis = const RaceDiagnosis(runs: 0),
  });

  final RacePhase phase;
  final List<RaceProblem> problems;
  final RaceRecord record;

  /// A duração escolhida (o recorde acima é o dela).
  final RaceDuration duration;

  /// O filtro escolhido na abertura: objetivo e tipos de final.
  final RaceFilter filter;
  final RaceRun? run;

  /// A vez do jogador no problema do tabuleiro (a posição e os lances ótimos).
  final RaceTurn? turn;

  /// A posição que o tabuleiro mostra: a da vez do jogador, ou a de depois do
  /// lance dele enquanto a defesa ainda não respondeu.
  final String? boardFen;

  /// A defesa está respondendo: o tabuleiro não aceita lance.
  final bool replying;

  /// Os problemas das últimas Corridas, que o sorteio evita repetir.
  final Set<String> recent;

  /// O problema no tabuleiro.
  RaceProblem? get problem => turn?.problem;
  final Duration remaining;
  final RaceFeedback? feedback;

  /// Quantos lances já deram retorno: muda a cada um, mesmo repetindo o
  /// mesmo [feedback], para o ícone animar de novo.
  final int feedbackCount;
  final RaceOutcome? outcome;

  /// Qual erro a revisão mostra (a partir de 0).
  final int reviewIndex;

  /// Em que finais o jogador mais erra, pelas últimas Corridas.
  final RaceDiagnosis diagnosis;

  /// Os erros da Corrida acabada, na ordem em que vieram.
  List<RaceAnswer> get mistakes => [
    for (final answer in outcome?.result.run.answers ?? const <RaceAnswer>[])
      if (!answer.correct) answer,
  ];

  RaceState copyWith({
    RacePhase? phase,
    List<RaceProblem>? problems,
    RaceRecord? record,
    RaceDuration? duration,
    RaceFilter? filter,
    RaceRun? run,
    RaceTurn? turn,
    bool clearTurn = false,
    String? boardFen,
    bool? replying,
    Set<String>? recent,
    Duration? remaining,
    RaceFeedback? feedback,
    bool clearFeedback = false,
    int? feedbackCount,
    RaceOutcome? outcome,
    int? reviewIndex,
    RaceDiagnosis? diagnosis,
  }) => RaceState(
    phase: phase ?? this.phase,
    problems: problems ?? this.problems,
    record: record ?? this.record,
    duration: duration ?? this.duration,
    filter: filter ?? this.filter,
    run: run ?? this.run,
    turn: clearTurn ? null : turn ?? this.turn,
    boardFen: clearTurn ? null : boardFen ?? this.boardFen,
    replying: replying ?? this.replying,
    recent: recent ?? this.recent,
    remaining: remaining ?? this.remaining,
    feedback: clearFeedback ? null : feedback ?? this.feedback,
    feedbackCount: feedbackCount ?? this.feedbackCount,
    outcome: outcome ?? this.outcome,
    reviewIndex: reviewIndex ?? this.reviewIndex,
    diagnosis: diagnosis ?? this.diagnosis,
  );
}

/// A Corrida de problemas: abertura, corrida, resultado e revisão dos erros.
class RaceCubit extends Cubit<RaceState> {
  RaceCubit(
    this._repository,
    this._now, {
    this.replyDelay = const Duration(milliseconds: 450),
    this.onlySubcategory,
    this.onlyCategory,
  }) : super(const RaceState());

  /// A Corrida só de um tipo de final ou de uma família (vinda da aula ou do
  /// diagnóstico): o filtro vale nesta tela, sem trocar o guardado.
  final String? onlySubcategory;
  final String? onlyCategory;

  /// O tempo entre o lance do jogador e a resposta da defesa.
  final Duration replyDelay;

  final RaceRepository _repository;
  final Now _now;

  // Entre o fim da Corrida e o resultado gravado, nada mais vale.
  bool _finishing = false;

  /// Lê o banco e o recorde. Com uma Corrida em andamento (o app foi fechado
  /// no meio), continua dela, se ainda há tempo, ou fecha o resultado.
  Future<void> load() async {
    final problems = await _repository.problems();
    final duration = await _repository.duration();
    final record = await _repository.record(duration: duration);
    final ongoing = await _repository.ongoing();
    final saved = await _repository.filter();
    final history = await _repository.history();
    final recent = RaceRules.recentIds(history);
    final only = onlySubcategory != null || onlyCategory != null
        ? RaceRules.only(
            problems,
            subcategory: onlySubcategory,
            category: onlyCategory,
          )
        : null;
    emit(
      state.copyWith(
        problems: problems,
        record: record,
        duration: duration,
        remaining: duration.limit,
        recent: recent,
        diagnosis: RaceDiagnosis.of(history, problems),
        // Um filtro sem problema no banco de hoje volta ao padrão.
        filter: only != null && RaceRules.count(problems, only) > 0
            ? only
            : RaceRules.count(problems, saved) > 0
            ? saved
            : const RaceFilter(),
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
        filter: run.filter,
        run: run,
        turn: _first(run),
        boardFen: _first(run)?.fen,
        replying: false,
        remaining: RaceRules.remaining(run, _now()),
        clearFeedback: true,
      ),
    );
  }

  /// A primeira vez do problema que vem na Corrida [run].
  RaceTurn? _first(RaceRun run) {
    final problem = RaceRules.next(state.problems, run, recent: state.recent);
    return problem == null ? null : RaceTurn.start(problem);
  }

  /// Aplica o filtro (objetivo e tipos de final) e o guarda para a próxima
  /// vez.
  Future<void> applyFilter(RaceFilter filter) {
    emit(state.copyWith(filter: filter));
    return _repository.setFilter(filter);
  }

  /// Escolhe a duração (3 ou 5 minutos), a guarda e mostra o recorde dela.
  Future<void> selectDuration(RaceDuration duration) async {
    if (duration == state.duration) return;
    await _repository.setDuration(duration);
    final record = await _repository.record(duration: duration);
    emit(
      state.copyWith(
        duration: duration,
        record: record,
        remaining: duration.limit,
      ),
    );
  }

  /// Começa uma Corrida nova com o filtro e a duração escolhidos.
  Future<void> start() async {
    final run = RaceRun(
      startedAt: _now(),
      filter: state.filter,
      duration: state.duration,
    );
    final turn = _first(run);
    if (turn == null) return;
    _finishing = false;
    emit(
      state.copyWith(
        phase: RacePhase.playing,
        run: run,
        turn: turn,
        boardFen: turn.fen,
        replying: false,
        remaining: run.duration.limit,
        clearFeedback: true,
        feedbackCount: 0,
      ),
    );
    await _repository.saveOngoing(run);
  }

  /// O jogador jogou [move] (UCI) na vez dele. Lance ótimo no meio da
  /// sequência: a defesa responde sozinha e o problema segue. O último lance
  /// ótimo fecha o problema (acerto); qualquer outro é erro (inclusive o que
  /// ainda ganha, mas mais devagar).
  Future<void> answer(String move) async {
    final run = state.run;
    final turn = state.turn;
    if (state.phase != RacePhase.playing ||
        _finishing ||
        state.replying ||
        run == null ||
        turn == null) {
      return;
    }
    final now = _now();
    // O tempo acabou antes do lance: ele não vale.
    if (RaceRules.endOf(run, now) == RaceEnd.time) {
      await _finish(run, RaceEnd.time);
      return;
    }
    if (turn.judge(move) == RaceMoveKind.optimal && !turn.ends(move)) {
      emit(state.copyWith(boardFen: turn.fenAfter(move), replying: true));
      if (replyDelay > Duration.zero) await Future<void>.delayed(replyDelay);
      // Acabou a Corrida (ou saiu) enquanto a defesa respondia.
      if (state.turn != turn || state.phase != RacePhase.playing) return;
      final next = turn.after(move)!;
      emit(state.copyWith(turn: next, boardFen: next.fen, replying: false));
      return;
    }
    final correct = turn.judge(move) == RaceMoveKind.optimal;
    final answer = correct ? turn.solved(move) : turn.mistake(move);
    final updated = run.withAnswer(answer);
    final end = RaceRules.endOf(updated, now);
    final feedback = correct ? RaceFeedback.correct : RaceFeedback.wrong;
    if (end != null) {
      await _finish(updated, end, feedback: feedback);
      return;
    }
    final nextTurn = _first(updated);
    emit(
      state.copyWith(
        run: updated,
        turn: nextTurn,
        boardFen: nextTurn?.fen,
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
    final history = await _repository.history();
    // "Jogar de novo" sorteia sem passar pelo load: a Corrida que acabou já
    // entra nos recentes.
    final recent = RaceRules.recentIds(history);
    emit(
      state.copyWith(
        phase: RacePhase.finished,
        run: run,
        remaining: end == RaceEnd.time ? Duration.zero : null,
        record: RaceRules.merge(outcome.previous, run),
        outcome: outcome,
        recent: recent,
        feedback: feedback,
        clearFeedback: feedback == null,
        reviewIndex: 0,
        diagnosis: RaceDiagnosis.of(history, state.problems),
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
        clearTurn: true,
        clearFeedback: true,
      ),
    );
  }

  /// Do resultado para a abertura (jogar de novo escolhe o filtro de novo).
  void backToIntro() =>
      emit(state.copyWith(phase: RacePhase.intro, clearTurn: true));

  /// Do resultado para a abertura de uma Corrida só de uma família de finais
  /// (o ponto fraco do diagnóstico), sem trocar o filtro guardado.
  void focus({required String category}) {
    final filter = RaceRules.only(state.problems, category: category);
    if (RaceRules.count(state.problems, filter) == 0) return;
    emit(
      state.copyWith(phase: RacePhase.intro, filter: filter, clearTurn: true),
    );
  }

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

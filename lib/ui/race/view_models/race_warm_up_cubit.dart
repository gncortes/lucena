import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/race/race_repository.dart';
import '../../../domain/models/race.dart';
import '../../../domain/use_cases/race_rules.dart';
import '../../../domain/use_cases/race_turn.dart';
import 'race_cubit.dart';

class RaceWarmUpState {
  const RaceWarmUpState({
    this.problems = const [],
    this.results = const [],
    this.feedback,
    this.feedbackCount = 0,
    this.turn,
    this.boardFen,
    this.replying = false,
  });

  final List<RaceProblem> problems;

  /// Acerto (`true`) ou erro de cada problema já jogado.
  final List<bool> results;
  final RaceFeedback? feedback;
  final int feedbackCount;

  /// A vez do jogador no problema do tabuleiro.
  final RaceTurn? turn;
  final String? boardFen;
  final bool replying;

  bool get loaded => problems.isNotEmpty;
  bool get done => loaded && results.length >= problems.length;
  int get corrects => results.where((ok) => ok).length;

  /// O problema no tabuleiro. Nulo ao terminar.
  RaceProblem? get problem => done || !loaded ? null : problems[results.length];
}

/// O aquecimento: poucos problemas fáceis, sem relógio e sem contar rating.
/// Não guarda nada: sair no meio não deixa rastro.
class RaceWarmUpCubit extends Cubit<RaceWarmUpState> {
  RaceWarmUpCubit(
    this._repository, {
    this.replyDelay = const Duration(milliseconds: 450),
  }) : super(const RaceWarmUpState());

  final RaceRepository _repository;

  /// O tempo entre o lance do jogador e a resposta da defesa.
  final Duration replyDelay;

  /// Os problemas do final do desafio ([theme]); faltando, completa com os
  /// mais fáceis do banco.
  Future<void> load({RaceTheme? theme}) async {
    final bank = await _repository.problems();
    emit(RaceWarmUpState(problems: RaceRules.warmUp(bank, theme: theme)));
  }

  Future<void> answer(String move) async {
    final problem = state.problem;
    if (problem == null || state.replying) return;
    final turn = state.turn ?? RaceTurn.start(problem);
    final kind = turn.judge(move);
    if (kind == RaceMoveKind.optimal && !turn.ends(move)) {
      emit(_with(turn: turn, boardFen: turn.fenAfter(move), replying: true));
      if (replyDelay > Duration.zero) await Future<void>.delayed(replyDelay);
      if (isClosed || state.turn != turn) return;
      final next = turn.after(move)!;
      emit(_with(turn: next, boardFen: next.fen));
      return;
    }
    final correct = kind == RaceMoveKind.optimal;
    emit(
      RaceWarmUpState(
        problems: state.problems,
        results: [...state.results, correct],
        feedback: correct ? RaceFeedback.correct : RaceFeedback.wrong,
        feedbackCount: state.feedbackCount + 1,
      ),
    );
  }

  RaceWarmUpState _with({
    required RaceTurn turn,
    required String boardFen,
    bool replying = false,
  }) => RaceWarmUpState(
    problems: state.problems,
    results: state.results,
    feedback: state.feedback,
    feedbackCount: state.feedbackCount,
    turn: turn,
    boardFen: boardFen,
    replying: replying,
  );
}

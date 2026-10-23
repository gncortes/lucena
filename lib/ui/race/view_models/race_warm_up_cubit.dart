import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/race/race_repository.dart';
import '../../../domain/models/race.dart';
import '../../../domain/use_cases/race_rules.dart';
import 'race_cubit.dart';

class RaceWarmUpState {
  const RaceWarmUpState({
    this.problems = const [],
    this.results = const [],
    this.feedback,
    this.feedbackCount = 0,
  });

  final List<RaceProblem> problems;

  /// Acerto (`true`) ou erro de cada problema já jogado.
  final List<bool> results;
  final RaceFeedback? feedback;
  final int feedbackCount;

  bool get loaded => problems.isNotEmpty;
  bool get done => loaded && results.length >= problems.length;
  int get corrects => results.where((ok) => ok).length;

  /// O problema no tabuleiro. Nulo ao terminar.
  RaceProblem? get problem => done || !loaded ? null : problems[results.length];
}

/// O aquecimento: poucos problemas fáceis, sem relógio e sem contar rating.
/// Não guarda nada: sair no meio não deixa rastro.
class RaceWarmUpCubit extends Cubit<RaceWarmUpState> {
  RaceWarmUpCubit(this._repository) : super(const RaceWarmUpState());

  final RaceRepository _repository;

  /// Os problemas do final do desafio ([theme]); faltando, completa com os
  /// mais fáceis do banco.
  Future<void> load({RaceTheme? theme}) async {
    final bank = await _repository.problems();
    emit(RaceWarmUpState(problems: RaceRules.warmUp(bank, theme: theme)));
  }

  void answer(String move) {
    final problem = state.problem;
    if (problem == null) return;
    final correct = RaceRules.isSolution(problem, move);
    emit(
      RaceWarmUpState(
        problems: state.problems,
        results: [...state.results, correct],
        feedback: correct ? RaceFeedback.correct : RaceFeedback.wrong,
        feedbackCount: state.feedbackCount + 1,
      ),
    );
  }
}

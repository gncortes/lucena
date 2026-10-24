import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/race/race_repository.dart';
import '../../../domain/use_cases/race_diagnosis.dart';

/// O que a tela "Seu desempenho" mostra: o desempenho por final e a aula
/// liberada de cada final a melhorar.
class RacePerformanceState {
  const RacePerformanceState({
    this.ready = false,
    this.diagnosis = const RaceDiagnosis(runs: 0),
    this.lessons = const [],
  });

  final bool ready;
  final RaceDiagnosis diagnosis;

  /// As aulas dos finais a melhorar, do pior para o melhor.
  final List<RaceFinalLesson> lessons;
}

/// "Seu desempenho" (canvas V2 · Ligações, L6b): lê o histórico de Corridas
/// e monta o desempenho por final.
class RacePerformanceCubit extends Cubit<RacePerformanceState> {
  RacePerformanceCubit(this._repository) : super(const RacePerformanceState());

  final RaceRepository _repository;

  Future<void> load() async {
    final problems = await _repository.problems();
    final history = await _repository.history();
    if (isClosed) return;
    final diagnosis = RaceDiagnosis.of(history, problems);
    emit(
      RacePerformanceState(
        ready: true,
        diagnosis: diagnosis,
        lessons: RaceFinalLesson.forScores(diagnosis.toImprove),
      ),
    );
  }
}

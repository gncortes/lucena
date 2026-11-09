import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/coach/trivia_repository.dart';
import '../../../domain/models/coach/trivia.dart';
import '../../../domain/use_cases/now.dart';

/// A curiosidade da espera da análise: começa por uma diferente a cada dia
/// e "Outra curiosidade" passa para a seguinte.
final class TriviaState {
  const TriviaState({this.all = const [], this.index = 0});

  final List<Trivia> all;
  final int index;

  Trivia? get current => all.isEmpty ? null : all[index % all.length];
}

final class TriviaCubit extends Cubit<TriviaState> {
  TriviaCubit({required this.repository, required this.now})
    : super(const TriviaState());

  final TriviaRepository repository;
  final Now now;

  Future<void> load() async {
    try {
      final all = await repository.all();
      if (isClosed || all.isEmpty) return;
      final currentTime = now();
      final start =
          (currentTime.millisecondsSinceEpoch ~/ Duration.millisecondsPerDay) %
          all.length;
      emit(TriviaState(all: all, index: start));
    } on Object {
      // Sem curiosidade, a espera mostra só a porcentagem.
    }
  }

  void another() {
    if (state.all.length < 2) return;
    emit(TriviaState(all: state.all, index: state.index + 1));
  }
}

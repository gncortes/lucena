import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/endgame_lesson.dart';
import 'package:lucena/ui/core/keys/endgames_keys.dart';
import 'package:lucena/ui/endgames/view_models/endgame_lesson_cubit.dart';
import 'package:lucena/ui/endgames/widgets/exercises_done_screen.dart';

import '../../../testing/fakes/fake_character_repository.dart';
import '../../../testing/fakes/fake_endgame_repositories.dart';
import '../../../testing/fakes/fake_journey_repository.dart';
import '../../../testing/test_app.dart';

/// O resultado dos exercícios: a nota e a escada das faixas, com a do aluno
/// em destaque. A aula dos fakes tem 6 estrelas e mínimo 4.
void main() {
  Future<void> pump(WidgetTester tester, Map<String, int> stars) async {
    final cubit = EndgameLessonCubit(
      lessons: FakeEndgameLessonRepository(),
      progress: FakeEndgameProgressRepository(
        EndgameProgress(
          lessons: {'rook.lucena': EndgameLessonProgress(stars: stars)},
        ),
      ),
      journey: FakeJourneyRepository(),
      characters: FakeCharacterRepository(),
    );
    addTearDown(cubit.close);
    await cubit.load('rook.lucena', 'en');
    await tester.pumpWidget(
      TestApp(
        child: BlocProvider.value(
          value: cubit,
          child: const ExercisesDoneScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('mostra a nota e destaca a faixa do aluno', (tester) async {
    await pump(tester, {'e01': 2, 'e02': 2, 'e03': 1});
    expect(find.text('Exercises complete'), findsOneWidget);
    expect(
      tester.widget<Text>(find.byKey(ExercisesDoneKeys.score)).data,
      '5 of 6 stars',
    );
    expect(find.byKey(ExercisesDoneKeys.needMore), findsNothing);
    // A faixa "Bom" é a do aluno: destacada, com "Você".
    final current = find.byKey(ExercisesDoneKeys.current);
    expect(
      find.descendant(of: current, matching: find.text('Good')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: current, matching: find.text('You')),
      findsOneWidget,
    );
    expect(find.text('Passed'), findsOneWidget);
    expect(find.text('Perfect'), findsOneWidget);
  });

  testWidgets('abaixo do mínimo: avisa quantas estrelas faltam', (
    tester,
  ) async {
    await pump(tester, {'e01': 1, 'e02': 1, 'e03': 1});
    expect(find.text('Not enough stars'), findsOneWidget);
    expect(find.byKey(ExercisesDoneKeys.needMore), findsOneWidget);
    expect(find.byKey(ExercisesDoneKeys.current), findsNothing);
  });
}

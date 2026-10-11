import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/endgame_lesson.dart';
import 'package:lucena/ui/core/keys/endgames_keys.dart';
import 'package:lucena/ui/endgames/view_models/endgame_lesson_cubit.dart';
import 'package:lucena/ui/endgames/widgets/exercises_done_screen.dart';
import 'package:lucena/ui/endgames/widgets/grade_widgets.dart';

import '../../../testing/fakes/fake_character_repository.dart';
import '../../../testing/fakes/fake_endgame_repositories.dart';
import '../../../testing/fakes/fake_journey_repository.dart';
import '../../../testing/test_app.dart';

/// O resultado dos exercícios: a nota e a escada das faixas, com a do aluno
/// em destaque. A aula dos fakes tem 6 estrelas e mínimo 4.
void main() {
  Future<void> pump(
    WidgetTester tester,
    Map<String, int> stars, {
    bool lessonDone = false,
  }) async {
    final cubit = EndgameLessonCubit(
      lessons: FakeEndgameLessonRepository(),
      progress: FakeEndgameProgressRepository(
        EndgameProgress(
          lessons: {
            'rook.lucena': EndgameLessonProgress(
              stars: stars,
              lessonDone: lessonDone,
            ),
          },
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
    // Sem título: a medalha já é a conclusão.
    expect(find.text('Exercises complete'), findsNothing);
    expect(find.byKey(ExercisesDoneKeys.practice), findsOneWidget);
    expect(
      tester.widget<Text>(find.byKey(ExercisesDoneKeys.score)).data,
      '5 of 6 possible points',
    );
    expect(find.byKey(ExercisesDoneKeys.needMore), findsNothing);
    // Só a faixa do aluno, com a medalha; as outras ficam na introdução.
    expect(
      tester.widget<Text>(find.byKey(ExercisesDoneKeys.current)).data,
      'Great',
    );
    expect(find.byType(GradeMedal), findsOneWidget);
    expect(find.text('Fair'), findsNothing);
    expect(find.text('Perfect'), findsNothing);
    // Nota mínima alcançada: o diploma, mesmo sem a lição feita.
    expect(
      find.byKey(ExercisesDoneKeys.diploma, skipOffstage: false),
      findsOneWidget,
    );
  });

  testWidgets('aula aprovada: o diploma com o aluno, a aula e o resumo, e o '
      'compartilhar', (tester) async {
    await pump(tester, {'e01': 1, 'e02': 2, 'e03': 3}, lessonDone: true);
    await tester.scrollUntilVisible(find.byKey(ExercisesDoneKeys.diploma), 200);
    expect(find.text('Diploma'), findsOneWidget);
    expect(find.byKey(ExercisesDoneKeys.diplomaName), findsOneWidget);
    expect(
      find.text(
        'for completing the lesson “The Lucena position” with an '
        'exceptional performance.',
      ),
      findsOneWidget,
    );
    expect(find.text('The bridge.'), findsOneWidget);
    // Sem números no diploma: a frase já resume o desempenho.
    expect(
      find.descendant(
        of: find.byKey(ExercisesDoneKeys.diploma),
        matching: find.textContaining('6 of 6'),
      ),
      findsNothing,
    );
    expect(find.byKey(ExercisesDoneKeys.share), findsOneWidget);
  });

  testWidgets('abaixo do mínimo: avisa quantas estrelas faltam', (
    tester,
  ) async {
    await pump(tester, {'e01': 1, 'e02': 1, 'e03': 1});
    expect(find.byKey(ExercisesDoneKeys.practice), findsNothing);
    expect(find.byKey(ExercisesDoneKeys.redo), findsOneWidget);
    expect(find.byKey(ExercisesDoneKeys.reviewLesson), findsOneWidget);
    expect(
      find.byKey(ExercisesDoneKeys.retrySpeech, skipOffstage: false),
      findsOneWidget,
    );
    expect(find.text('Minimum score not reached'), findsOneWidget);
    expect(find.byKey(ExercisesDoneKeys.needMore), findsOneWidget);
    expect(find.byKey(ExercisesDoneKeys.current), findsNothing);
    expect(
      find.byKey(ExercisesDoneKeys.diploma, skipOffstage: false),
      findsNothing,
    );
  });
}

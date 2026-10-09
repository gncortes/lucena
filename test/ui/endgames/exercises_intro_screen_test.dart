import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/endgame_lesson.dart';
import 'package:lucena/ui/core/keys/endgames_keys.dart';
import 'package:lucena/ui/endgames/view_models/endgame_lesson_cubit.dart';
import 'package:lucena/ui/endgames/widgets/exercises_intro_screen.dart';

import '../../../testing/fakes/fake_character_repository.dart';
import '../../../testing/fakes/fake_endgame_repositories.dart';
import '../../../testing/fakes/fake_journey_repository.dart';
import '../../../testing/test_app.dart';

/// A introdução aos exercícios: a fala do Viktor, os chips (quantos, a nota
/// mínima, o tempo de pensar) e o botão que abre o próximo por resolver. A
/// aula dos fakes tem 3 exercícios, 6 estrelas e mínimo 4.
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
          child: const ExercisesIntroScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('nada resolvido: a fala, os chips e "começar"', (tester) async {
    await pump(tester, {});
    expect(find.byKey(ExercisesIntroKeys.screen), findsOneWidget);
    expect(
      find.textContaining('Your first try is what counts'),
      findsOneWidget,
    );
    expect(find.text('3 exercises'), findsOneWidget);
    expect(find.text('At least 4 points'), findsOneWidget);
    expect(
      find.text('Out of 6 possible points, to pass the lesson.'),
      findsOneWidget,
    );
    expect(find.text('No time limit'), findsOneWidget);
    // A legenda das estrelas.
    expect(find.text('3 points', skipOffstage: false), findsOneWidget);
    expect(find.text('1 point', skipOffstage: false), findsOneWidget);
    expect(
      find.byKey(ExercisesIntroKeys.legend, skipOffstage: false),
      findsOneWidget,
    );
    expect(
      find.byKey(ExercisesIntroKeys.after, skipOffstage: false),
      findsOneWidget,
    );
    // As faixas: o mínimo da aula (4), bom (5) e perfeito (6); "excelente"
    // pediria 6 também, e some.
    expect(find.text('Fair', skipOffstage: false), findsOneWidget);
    expect(
      find.text('4 of 6 possible points', skipOffstage: false),
      findsOneWidget,
    );
    expect(find.text('Perfect', skipOffstage: false), findsOneWidget);
    expect(
      find.text('6 of 6 possible points', skipOffstage: false),
      findsOneWidget,
    );
    expect(find.text('Excellent', skipOffstage: false), findsNothing);
    final start = find.byKey(ExercisesIntroKeys.start);
    expect(
      find.descendant(of: start, matching: find.text('Start the exercises')),
      findsOneWidget,
    );
    expect(tester.widget<FilledButton>(start).enabled, isTrue);
  });

  testWidgets('com um resolvido: "continuar"', (tester) async {
    await pump(tester, {'e01': 1});
    expect(find.text('Continue the exercises'), findsOneWidget);
  });
}

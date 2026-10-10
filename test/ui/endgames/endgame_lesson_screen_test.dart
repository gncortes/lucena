import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/app_language.dart';
import 'package:lucena/domain/models/app_settings.dart';
import 'package:lucena/domain/models/endgame_lesson.dart';
import 'package:lucena/ui/core/keys/endgames_keys.dart';
import 'package:lucena/ui/endgames/view_models/endgame_lesson_cubit.dart';
import 'package:lucena/ui/endgames/widgets/endgame_lesson_screen.dart';
import 'package:lucena/ui/settings/view_models/settings_cubit.dart';

import '../../../testing/fakes/fake_character_repository.dart';
import '../../../testing/fakes/fake_endgame_repositories.dart';
import '../../../testing/fakes/fake_journey_repository.dart';
import '../../../testing/fakes/fake_settings_repository.dart';
import '../../../testing/test_app.dart';

void main() {
  Future<EndgameLessonCubit> pump(
    WidgetTester tester, {
    String id = 'rook.lucena',
    EndgameProgress progress = const EndgameProgress(),
    EndgameTrail? trail,
  }) async {
    final cubit = EndgameLessonCubit(
      lessons: FakeEndgameLessonRepository(trail: trail),
      progress: FakeEndgameProgressRepository(progress),
      journey: FakeJourneyRepository(),
      characters: FakeCharacterRepository(),
    );
    addTearDown(cubit.close);
    await cubit.load(id, 'en');
    final settings = SettingsCubit(
      FakeSettingsRepository(const AppSettings()),
      languages: AppLanguage.selectable,
    );
    addTearDown(settings.close);
    await settings.load();
    await tester.pumpWidget(
      TestApp(
        settingsCubit: settings,
        child: BlocProvider.value(
          value: cubit,
          child: const EndgameLessonScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return cubit;
  }

  const passed = EndgameProgress(
    lessons: {
      'rook.lucena': EndgameLessonProgress(
        lessonDone: true,
        stars: {'e01': 1, 'e02': 2, 'e03': 1},
      ),
    },
  );

  testWidgets(
    'nada feito: começar a lição, o teste recolhido e o desafio aberto',
    (tester) async {
      await pump(tester);
      expect(find.text('The Lucena position'), findsOneWidget);
      expect(find.textContaining('1 of 2'), findsOneWidget);
      expect(find.text('Start'), findsOneWidget);
      // O teste final: sem nada resolvido, só o resumo (sem os zeros), a
      // dica e o botão de começar; a lista dos exercícios não aparece (nem
      // ao tocar).
      expect(find.text('3 exercises'), findsOneWidget);
      expect(find.text('0/6'), findsNothing);
      await tester.ensureVisible(
        find.byKey(EndgameLessonKeys.finalTestSummary),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(EndgameLessonKeys.finalTestSummary));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byKey(EndgameLessonKeys.startExercises),
        100,
      );
      expect(find.byKey(EndgameLessonKeys.testAdvice), findsOneWidget);
      expect(find.byKey(EndgameLessonKeys.exercise('e01')), findsNothing);
      expect(find.byKey(EndgameLessonKeys.exercise('e03')), findsNothing);
      expect(find.text('0 of 6 points'), findsNothing);
      expect(find.byKey(EndgameLessonKeys.score), findsNothing);
      expect(find.text('Start the exercises'), findsOneWidget);
      expect(find.byKey(EndgameLessonKeys.redoButton), findsNothing);
      // O desafio no final fica aberto desde o começo (T51).
      await tester.scrollUntilVisible(
        find.byKey(EndgameLessonKeys.trainButton),
        200,
      );
      expect(find.byKey(EndgameLessonKeys.finalStep), findsOneWidget);
    },
  );

  testWidgets('aprovado: a nota, o speedrun com os ritmos e o treino', (
    tester,
  ) async {
    await pump(tester, progress: passed);
    // Com todos resolvidos, a lista dos exercícios aparece.
    expect(find.byKey(EndgameLessonKeys.exercise('e01')), findsOneWidget);
    expect(find.byKey(EndgameLessonKeys.startExercises), findsNothing);
    expect(find.text('Passed.'), findsOneWidget);
    expect(find.byKey(EndgameLessonKeys.lessonDone), findsOneWidget);
    expect(find.text('Review the lesson'), findsOneWidget);
    expect(find.byKey(EndgameLessonKeys.passed), findsOneWidget);
    expect(find.text('4 of 6 points'), findsOneWidget);
    expect(find.byKey(EndgameLessonKeys.redoButton), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(EndgameLessonKeys.speedrunButton),
      200,
    );
    expect(find.byKey(EndgameLessonKeys.finalStep), findsOneWidget);
    expect(find.byKey(EndgameLessonKeys.pace('180+2')), findsOneWidget);
    expect(find.byKey(EndgameLessonKeys.trainButton), findsOneWidget);
    expect(find.byKey(EndgameLessonKeys.nextLessonButton), findsOneWidget);
  });

  testWidgets('reprovado: faltaram estrelas e refazer zera', (tester) async {
    final cubit = await pump(
      tester,
      progress: const EndgameProgress(
        lessons: {
          'rook.lucena': EndgameLessonProgress(
            lessonDone: true,
            stars: {'e01': 0, 'e02': 1, 'e03': 1},
          ),
        },
      ),
    );
    expect(find.byKey(EndgameLessonKeys.failed), findsOneWidget);
    expect(find.text('Not this time.'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(EndgameLessonKeys.redoButton),
      200,
    );
    expect(find.byKey(EndgameLessonKeys.redoButton), findsOneWidget);
    await cubit.redoExercises();
    await tester.pumpAndSettle();
    expect(cubit.state.score, 0);
    // Zerado: volta ao estado inicial, só com o botão de começar.
    expect(find.byKey(EndgameLessonKeys.score), findsNothing);
    // A lista encurtou e o card ficou fora da janela: conta o que está
    // montado.
    expect(
      find.byKey(EndgameLessonKeys.startExercises, skipOffstage: false),
      findsOneWidget,
    );
    expect(find.byKey(EndgameLessonKeys.failed), findsNothing);
  });

  testWidgets('final sem speedrun: só o treino', (tester) async {
    await pump(
      tester,
      id: 'rook.philidor',
      progress: const EndgameProgress(
        lessons: {
          'rook.philidor': EndgameLessonProgress(
            lessonDone: true,
            stars: {'e01': 1},
          ),
        },
      ),
    );
    await tester.scrollUntilVisible(
      find.byKey(EndgameLessonKeys.trainButton),
      200,
    );
    expect(find.byKey(EndgameLessonKeys.speedrunButton), findsNothing);
    expect(find.byKey(EndgameLessonKeys.nextLessonButton), findsNothing);
  });

  testWidgets('aula que não existe', (tester) async {
    await pump(tester, id: 'nothing');
    expect(find.byKey(EndgameLessonKeys.missing), findsOneWidget);
  });

  testWidgets('nota alcançada sem as etapas: pede para concluir a lição', (
    tester,
  ) async {
    await pump(
      tester,
      progress: const EndgameProgress(
        lessons: {
          'rook.lucena': EndgameLessonProgress(
            stars: {'e01': 1, 'e02': 2, 'e03': 3},
          ),
        },
      ),
    );
    expect(
      find.text('Score reached: finish the lesson', skipOffstage: false),
      findsOneWidget,
    );
    expect(find.text('Almost there: redo them to make it stick'), findsNothing);
  });

  testWidgets('aula em revisão: o aviso aparece só nela', (tester) async {
    await pump(tester);
    expect(find.byKey(EndgameLessonKeys.inReview), findsNothing);

    final sample = FakeEndgameLessonRepository.sample.lessons.first;
    final review = EndgameLesson(
      id: sample.id,
      module: sample.module,
      lesson: sample.lesson,
      exercises: sample.exercises,
      passScore: sample.passScore,
      keyPositions: sample.keyPositions,
      practice: sample.practice,
      references: sample.references,
      inReview: true,
    );
    await pump(
      tester,
      trail: EndgameTrail(
        modules: [
          EndgameModule(id: review.module, lessons: [review]),
        ],
      ),
    );
    expect(find.byKey(EndgameLessonKeys.inReview), findsOneWidget);
    expect(find.textContaining('under review'), findsOneWidget);
  });
}

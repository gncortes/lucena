import 'package:flutter/material.dart';
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
  }) async {
    final cubit = EndgameLessonCubit(
      lessons: FakeEndgameLessonRepository(),
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

  testWidgets('nada feito: começar a lição, exercícios e o final trancado', (
    tester,
  ) async {
    await pump(tester);
    expect(find.text('The Lucena position'), findsOneWidget);
    expect(find.text('Lesson 1 of 2'), findsOneWidget);
    expect(find.text('Start the lesson'), findsOneWidget);
    expect(find.byKey(EndgameLessonKeys.exercise('e01')), findsOneWidget);
    expect(find.byKey(EndgameLessonKeys.exercise('e03')), findsOneWidget);
    expect(find.text('0 of 6 stars'), findsOneWidget);
    expect(find.text('Start the exercises'), findsOneWidget);
    expect(find.byKey(EndgameLessonKeys.redoButton), findsNothing);
    expect(find.byKey(EndgameLessonKeys.finalLocked), findsOneWidget);
    expect(find.byKey(EndgameLessonKeys.speedrunButton), findsNothing);
  });

  testWidgets('aprovado: a nota, o speedrun com os ritmos e o treino', (
    tester,
  ) async {
    await pump(tester, progress: passed);
    expect(find.byKey(EndgameLessonKeys.lessonDone), findsOneWidget);
    expect(find.text('Review the lesson'), findsOneWidget);
    expect(find.byKey(EndgameLessonKeys.passed), findsOneWidget);
    expect(find.text('4 of 6 stars'), findsOneWidget);
    expect(find.byKey(EndgameLessonKeys.redoButton), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(EndgameLessonKeys.speedrunButton),
      200,
    );
    expect(find.byKey(EndgameLessonKeys.finalStep), findsOneWidget);
    expect(find.byKey(EndgameLessonKeys.pace('180+2')), findsOneWidget);
    expect(find.byKey(EndgameLessonKeys.trainButton), findsOneWidget);
    expect(find.byKey(EndgameLessonKeys.nextLessonButton), findsOneWidget);
    expect(find.text('Passed.'), findsOneWidget);
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
    expect(find.byKey(EndgameLessonKeys.finalLocked), findsOneWidget);
    await tester.tap(find.byKey(EndgameLessonKeys.redoButton));
    await tester.pumpAndSettle();
    expect(cubit.state.score, 0);
    expect(find.text('0 of 6 stars'), findsOneWidget);
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
}

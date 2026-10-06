import 'package:chessground/chessground.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/app_language.dart';
import 'package:lucena/domain/models/app_settings.dart';
import 'package:lucena/ui/core/keys/endgames_keys.dart';
import 'package:lucena/ui/endgames/view_models/exercise_cubit.dart';
import 'package:lucena/ui/endgames/widgets/exercise_screen.dart';
import 'package:lucena/ui/settings/view_models/settings_cubit.dart';

import '../../../testing/board_gestures.dart';
import '../../../testing/fakes/fake_character_repository.dart';
import '../../../testing/fakes/fake_endgame_repositories.dart';
import '../../../testing/fakes/fake_settings_repository.dart';
import '../../../testing/test_app.dart';

void main() {
  Future<ExerciseCubit> pump(WidgetTester tester, String exercise) async {
    final cubit = ExerciseCubit(
      lessons: FakeEndgameLessonRepository(),
      progress: FakeEndgameProgressRepository(),
      characters: FakeCharacterRepository(),
      replyDelay: Duration.zero,
    );
    addTearDown(cubit.close);
    await cubit.load('rook.lucena', exercise, 'en');
    final settings = SettingsCubit(
      FakeSettingsRepository(const AppSettings()),
      languages: AppLanguage.selectable,
    );
    addTearDown(settings.close);
    await settings.load();
    await tester.pumpWidget(
      TestApp(
        settingsCubit: settings,
        child: BlocProvider.value(value: cubit, child: const ExerciseScreen()),
      ),
    );
    await tester.pumpAndSettle();
    return cubit;
  }

  Future<void> move(WidgetTester tester, String from, String to) async {
    final board = tester.getRect(find.byKey(ExerciseKeys.board));
    await tester.tapAt(squareCenter(board, from));
    await tester.pump();
    await tester.tapAt(squareCenter(board, to));
    await tester.pumpAndSettle();
  }

  String speech(WidgetTester tester) =>
      tester.widget<Text>(find.byKey(ExerciseKeys.speech).last).data!;

  testWidgets('o enunciado, as estrelas e a dica com a seta', (tester) async {
    await pump(tester, 'e03');
    expect(find.text('Exercise 3 of 3'), findsOneWidget);
    expect(speech(tester), 'The hard one.');
    expect(find.byKey(ExerciseKeys.stars), findsOneWidget);

    await tester.tap(find.byKey(ExerciseKeys.hintButton));
    await tester.pumpAndSettle();
    expect(speech(tester), 'Same idea.');
    final board = tester.widget<Chessboard>(find.byKey(ExerciseKeys.board));
    expect(
      board.shapes.whereType<Arrow>().any(
        (arrow) => arrow.orig.name == 'c1' && arrow.dest.name == 'c4',
      ),
      isTrue,
    );
  });

  testWidgets('lance errado volta; o certo resolve e mostra a nota', (
    tester,
  ) async {
    final cubit = await pump(tester, 'e03');
    await move(tester, 'c1', 'c2');
    expect(cubit.state.mistakes, 1);
    expect(cubit.state.fen, FakeEndgameLessonRepository.lucenaFen);

    await move(tester, 'c1', 'c4');
    expect(find.byKey(ExerciseKeys.solved), findsOneWidget);
    expect(find.text('Solved!'), findsOneWidget);
    expect(find.text('2 of 3 stars'), findsOneWidget);
    expect(speech(tester), 'Same bridge.');
    // Os outros dois ainda estão por resolver.
    expect(find.byKey(ExerciseKeys.nextButton), findsOneWidget);
    expect(find.byKey(ExerciseKeys.hintButton), findsNothing);
  });

  testWidgets('exercício que não existe', (tester) async {
    await pump(tester, 'e99');
    expect(find.byKey(ExerciseKeys.missing), findsOneWidget);
  });
}

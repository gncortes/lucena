import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/app_language.dart';
import 'package:lucena/domain/models/app_settings.dart';
import 'package:lucena/domain/models/goal_preference.dart';
import 'package:lucena/ui/core/keys/course_guide_keys.dart';
import 'package:lucena/ui/core/keys/training_keys.dart';
import 'package:lucena/ui/core/widgets/course/course_item_tile.dart';
import 'package:lucena/ui/core/widgets/course/training_badge.dart';
import 'package:lucena/ui/core/widgets/exercise_actions.dart';
import 'package:lucena/ui/core/widgets/position_board.dart';
import 'package:lucena/ui/endgames/widgets/stars_row.dart';
import 'package:lucena/ui/home/view_models/home_cubit.dart';
import 'package:lucena/ui/home/widgets/hero_card.dart';
import 'package:lucena/ui/settings/view_models/settings_cubit.dart';

import '../../../testing/fakes/fake_settings_repository.dart';
import '../../../testing/test_app.dart';

void main() {
  testWidgets('footer keeps the timer visible without result actions', (
    tester,
  ) async {
    await tester.pumpWidget(
      TestApp(
        child: Scaffold(
          body: const SizedBox.expand(),
          bottomNavigationBar: ExerciseActions(
            hint: ExerciseHintButton(label: 'Dica', onPressed: () {}),
            leading: const Text('0:18'),
          ),
        ),
      ),
    );
    expect(find.text('0:18'), findsOneWidget);
    expect(
      tester.getRect(find.text('0:18')).center.dx,
      greaterThan(tester.getRect(find.byType(Scaffold)).center.dx),
    );
    expect(tester.getSize(find.byType(ExerciseActions)).height, lessThan(100));
    expect(tester.takeException(), isNull);
  });

  testWidgets('footer with result actions leaves room for the board', (
    tester,
  ) async {
    await tester.pumpWidget(
      TestApp(
        child: Scaffold(
          body: const SizedBox.expand(key: Key('board-area')),
          bottomNavigationBar: ExerciseActions(
            actions: [
              ExerciseAction(
                label: 'Solution',
                onPressed: () {},
                key: const Key('solution'),
              ),
              ExerciseAction(
                label: 'Next',
                onPressed: () {},
                key: const Key('next'),
                primary: true,
              ),
            ],
          ),
        ),
      ),
    );
    expect(
      tester.getSize(find.byKey(const Key('board-area'))).height,
      greaterThan(400),
    );
    expect(tester.getSize(find.byType(ExerciseActions)).height, lessThan(100));
    expect(tester.takeException(), isNull);
  });

  Future<void> pump(WidgetTester tester, Widget child) => tester.pumpWidget(
    TestApp(
      locale: const Locale('pt'),
      child: Scaffold(body: child),
    ),
  );

  for (final difficulty in <int?>[null, 1, 2, 3]) {
    testWidgets('tile preserva resumo e metal: $difficulty', (tester) async {
      await pump(
        tester,
        CourseItemTile(
          key: TrainingKeys.goalTile('exercise', 'test'),
          state: CourseItemState.open,
          title: 'Garfo',
          summary: '1 exercício',
          difficulty: difficulty,
        ),
      );
      expect(find.text('1 exercício'), findsOneWidget);
      final star = find.byKey(CourseGuideKeys.difficultyStar('Garfo'));
      expect(star, difficulty == null ? findsNothing : findsOneWidget);
      if (difficulty != null) {
        final icon = tester.widget<Icon>(
          find.descendant(of: star, matching: find.byType(Icon)),
        );
        expect(icon.color, StarsRow.colorFor(difficulty));
        expect(
          find.bySemanticsLabel(
            RegExp(['Fácil', 'Médio', 'Difícil'][difficulty - 1]),
          ),
          findsOneWidget,
        );
      }
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('selo usa rótulo e estrela; com dica usa lâmpada', (
    tester,
  ) async {
    for (var level = 1; level <= 3; level++) {
      await pump(
        tester,
        Builder(builder: (context) => TrainingBadge.difficulty(context, level)),
      );
      expect(find.byKey(TrainingKeys.difficultyBadge), findsOneWidget);
      expect(find.byType(ValueStar), findsOneWidget);
      expect(
        find.bySemanticsLabel(['Fácil', 'Médio', 'Difícil'][level - 1]),
        findsOneWidget,
      );
    }
    await pump(tester, Builder(builder: TrainingBadge.withHint));
    expect(find.byKey(TrainingKeys.hintBadge), findsOneWidget);
    expect(find.bySemanticsLabel('Com dica'), findsOneWidget);
    expect(find.byIcon(Icons.lightbulb_outline), findsOneWidget);
    expect(find.byType(ValueStar), findsNothing);
  });

  for (final navigation in <ExerciseNavigation?>[
    null,
    ...ExerciseNavigation.values,
  ]) {
    testWidgets('rodapé: $navigation, callbacks e altura fixa', (tester) async {
      var previous = 0;
      var next = 0;
      await pump(
        tester,
        SizedBox(
          height: 96,
          child: ExerciseActions(
            key: TrainingKeys.secondary,
            navigation: navigation,
            onPreviousMove: () => previous++,
            onNextMove: () => next++,
            padding: const EdgeInsets.symmetric(horizontal: 16),
          ),
        ),
      );
      final prevFinder = find.byKey(TrainingKeys.prevMove);
      final nextFinder = find.byKey(TrainingKeys.nextMove);
      if (navigation == null) {
        expect(prevFinder, findsNothing);
        expect(nextFinder, findsNothing);
      } else {
        final canPrevious = navigation != ExerciseNavigation.start;
        final canNext = navigation != ExerciseNavigation.end;
        expect(
          tester.widget<IconButton>(prevFinder).onPressed != null,
          canPrevious,
        );
        expect(
          tester.widget<IconButton>(nextFinder).onPressed != null,
          canNext,
        );
        expect(find.byTooltip('Lance anterior'), findsOneWidget);
        expect(find.byTooltip('Próximo lance'), findsOneWidget);
        await tester.tap(prevFinder);
        await tester.tap(nextFinder);
        expect(previous, canPrevious ? 1 : 0);
        expect(next, canNext ? 1 : 0);
      }
      expect(tester.getSize(find.byKey(TrainingKeys.secondary)).height, 96);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Hero: orientação padrão branca e opção preta', (tester) async {
    final settings = SettingsCubit(
      FakeSettingsRepository(const AppSettings()),
      languages: AppLanguage.selectable,
    );
    addTearDown(settings.close);
    await settings.load();
    for (final side in [Side.white, Side.black]) {
      await tester.pumpWidget(
        TestApp(
          settingsCubit: settings,
          locale: const Locale('pt'),
          child: Scaffold(
            body: side == Side.white
                ? const HeroCard(
                    state: HomeState(ready: true, goal: GoalPreference.learn),
                  )
                : const HeroCard(
                    state: HomeState(ready: true, goal: GoalPreference.learn),
                    orientation: Side.black,
                  ),
          ),
        ),
      );
      expect(
        tester.widget<PositionBoard>(find.byType(PositionBoard)).orientation,
        side,
      );
      expect(tester.takeException(), isNull);
    }
  });
}

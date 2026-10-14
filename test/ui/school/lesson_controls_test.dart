import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/data/repositories/school/lesson_source.dart';
import 'package:lucena/domain/models/endgame_lesson.dart';
import 'package:lucena/domain/models/lesson.dart';
import 'package:lucena/ui/core/keys/school_keys.dart';
import 'package:lucena/ui/school/view_models/lesson_cubit.dart';
import 'package:lucena/ui/school/widgets/lesson_part_widgets.dart';

import '../../../testing/fakes/fake_character_repository.dart';
import '../../../testing/fakes/fake_endgame_repositories.dart';
import '../../../testing/fakes/fake_now.dart';
import '../../../testing/fakes/fake_opponent_repository.dart';
import '../../../testing/test_app.dart';

/// T65 F4: o rodapé de controles (demonstração e variante) e o anel do ⏭.
void main() {
  Future<LessonCubit> cubit() async {
    final cubit = LessonCubit(
      source: EndgameLessonSource(
        FakeEndgameLessonRepository(
          trail: const EndgameTrail(modules: []),
          texts: LessonTexts.fromJson(const {}),
        ),
        FakeEndgameProgressRepository(),
      ),
      characters: FakeCharacterRepository(),
      opponent: FakeOpponentRepository(),
      now: FakeNow(DateTime.utc(2026, 10, 12, 20)),
      replyDelay: Duration.zero,
    );
    addTearDown(cubit.close);
    return cubit;
  }

  Future<LessonCubit> pumpDemo(WidgetTester tester, {Locale? locale}) async {
    tester.view
      ..devicePixelRatio = 1
      ..physicalSize = const Size(412, 917);
    addTearDown(tester.view.reset);
    final lesson = await cubit();
    await tester.pumpWidget(
      TestApp(
        locale: locale ?? const Locale('en'),
        child: BlocProvider.value(
          value: lesson,
          child: Scaffold(
            body: Align(
              alignment: Alignment.bottomCenter,
              child: DemoControls(
                state: lesson.state,
                height: 96,
                ring: ValueNotifier<double?>(0.5),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    return lesson;
  }

  Future<void> pumpVariation(WidgetTester tester, {Locale? locale}) async {
    tester.view
      ..devicePixelRatio = 1
      ..physicalSize = const Size(412, 917);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      TestApp(
        locale: locale ?? const Locale('en'),
        child: Scaffold(
          body: Align(
            alignment: Alignment.bottomCenter,
            child: VariationControls(
              canPrevious: true,
              canNext: true,
              onExit: () {},
              onBack: () {},
              onForward: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  Rect rect(WidgetTester tester, Key key) => tester.getRect(find.byKey(key));

  testWidgets(
    'rodapé: altura 96 e botões redondos de 48 dp (demo e variante)',
    (tester) async {
      await pumpDemo(tester);
      // A casa do rodapé reserva 96 dp (_actionsHeight); o componente mede 88
      // (48 + 8 de respiro + 16 de fundo + 16 do degradê) e cabe nela.
      expect(
        tester.getSize(find.byType(DemoControls)).height,
        lessThanOrEqualTo(96),
      );
      for (final key in [
        LessonKeys.backButton,
        LessonKeys.demoReplay,
        LessonKeys.demoBack,
        LessonKeys.demoPause,
        LessonKeys.demoForward,
      ]) {
        expect(tester.getSize(find.byKey(key)), const Size.square(48));
        final style = tester.widget<IconButton>(find.byKey(key)).style!;
        expect(style.shape!.resolve({}), isA<CircleBorder>());
      }
      await pumpVariation(tester);
      expect(
        tester.getSize(find.byType(VariationControls)).height,
        lessThanOrEqualTo(96),
      );
      for (final key in [
        LessonKeys.variationExit,
        LessonKeys.variationBack,
        LessonKeys.variationForward,
      ]) {
        expect(tester.getSize(find.byKey(key)), const Size.square(48));
      }
    },
  );

  testWidgets('rodapé: ordem da demo e da variante, nas mesmas casas', (
    tester,
  ) async {
    await pumpDemo(tester);
    final demo = [
      for (final key in [
        LessonKeys.backButton,
        LessonKeys.demoReplay,
        LessonKeys.demoBack,
        LessonKeys.demoPause,
        LessonKeys.demoForward,
      ])
        rect(tester, key),
    ];
    for (var i = 1; i < demo.length; i++) {
      expect(demo[i].left, greaterThan(demo[i - 1].right - 1));
    }
    await pumpVariation(tester);
    final exit = rect(tester, LessonKeys.variationExit);
    final back = rect(tester, LessonKeys.variationBack);
    final next = rect(tester, LessonKeys.variationForward);
    // [X][vazio][⏮][vazio][⏭]: o X onde o ← da demo, o ⏮ no meio, o ⏭ no canto.
    expect(exit.left, demo[0].left);
    expect(back.left, closeTo(demo[2].left, 1));
    expect(next.left, demo[4].left);
    // As casas vazias entre eles têm 48 dp de largura, no mínimo.
    expect(back.left - exit.right, greaterThanOrEqualTo(48));
    expect(next.left - back.right, greaterThanOrEqualTo(48));
  });

  testWidgets('rodapé: a linha não espelha em árabe', (tester) async {
    await pumpDemo(tester, locale: const Locale('ar'));
    final first = rect(tester, LessonKeys.backButton);
    final last = rect(tester, LessonKeys.demoForward);
    expect(first.left, lessThan(last.left));
    await pumpVariation(tester, locale: const Locale('ar'));
    expect(
      rect(tester, LessonKeys.variationExit).left,
      lessThan(rect(tester, LessonKeys.variationForward).left),
    );
  });

  group('anel do ⏭', () {
    Future<ValueNotifier<double?>> pumpRing(
      WidgetTester tester, {
      bool reduced = false,
    }) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          FakeAccessibilityFeatures(disableAnimations: reduced);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      final progress = ValueNotifier<double?>(0);
      addTearDown(progress.dispose);
      await tester.pumpWidget(
        TestApp(
          child: Center(child: DemoRing(progress: progress)),
        ),
      );
      return progress;
    }

    double arc(WidgetTester tester) =>
        (tester.widget<CustomPaint>(find.byKey(LessonKeys.demoRing)).painter!
                    as dynamic)
                .progress
            as double;

    testWidgets('60 dp de diâmetro e traço 3', (tester) async {
      await pumpRing(tester);
      expect(
        tester.getSize(find.byKey(LessonKeys.demoRing)),
        const Size(60, 60),
      );
      expect(DemoRing.diameter, 60);
      expect(DemoRing.stroke, 3);
      expect(DemoRing.outside, 6);
    });

    testWidgets('reduzir movimento: o arco anda em degraus de 25 %', (
      tester,
    ) async {
      final progress = await pumpRing(tester, reduced: true);
      for (final (value, step) in [
        (0.1, 0.0),
        (0.3, 0.25),
        (0.6, 0.5),
        (0.8, 0.75),
        (0.99, 0.75),
        (1.0, 1.0),
      ]) {
        progress.value = value;
        await tester.pump();
        expect(arc(tester), step, reason: '$value');
        expect(tester.hasRunningAnimations, isFalse);
      }
    });

    testWidgets('com movimento, o arco anda contínuo entre os tiques', (
      tester,
    ) async {
      final progress = await pumpRing(tester);
      progress.value = 0.5;
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 125));
      expect(arc(tester), inExclusiveRange(0, 0.5));
    });
  });
}

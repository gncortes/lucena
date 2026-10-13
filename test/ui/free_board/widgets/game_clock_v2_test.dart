import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/ui/core/keys/free_board_keys.dart';
import 'package:lucena/ui/core/widgets/game_clock.dart';
import 'package:lucena/ui/core/widgets/time_display.dart';

import '../../../../testing/test_app.dart';

void main() {
  testWidgets('relógio parado fica a 55% de opacidade (CompTempo parado)', (
    tester,
  ) async {
    Future<double> opacity(bool running) async {
      await tester.pumpWidget(
        TestApp(
          child: Scaffold(
            body: Center(
              child: GameClock(
                key: FreeBoardKeys.clock(Side.black),
                side: Side.black,
                time: const Duration(minutes: 3),
                running: running,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      return tester
          .widget<Opacity>(
            find.descendant(
              of: find.byKey(FreeBoardKeys.clock(Side.black)),
              matching: find.byType(Opacity),
            ),
          )
          .opacity;
    }

    expect(await opacity(false), 0.55);
    expect(await opacity(true), 1);
  });

  for (final side in Side.values) {
    testWidgets('$side: cor e tamanho fixos; só borda e ícone indicam a vez', (
      tester,
    ) async {
      Future<void> pump(bool running, Duration time) async {
        await tester.pumpWidget(
          TestApp(
            child: Scaffold(
              body: Center(
                child: GameClock(
                  key: FreeBoardKeys.clock(side),
                  side: side,
                  time: time,
                  running: running,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
      }

      BoxDecoration decoration() =>
          tester
                  .widget<Container>(
                    find.descendant(
                      of: find.byKey(FreeBoardKeys.clock(side)),
                      matching: find.byType(Container),
                    ),
                  )
                  .decoration!
              as BoxDecoration;

      await pump(false, const Duration(minutes: 3));
      final stopped = decoration();
      final stoppedRect = tester.getRect(find.byKey(FreeBoardKeys.clock(side)));
      await pump(true, const Duration(minutes: 3));
      final running = decoration();
      expect(running.color, stopped.color);
      expect((running.border! as Border).top.width, 2);
      expect(
        (running.border! as Border).top.color,
        Theme.of(tester.element(find.byType(TimeDisplay)))
            .colorScheme
            .onSurface,
      );
      expect((stopped.border! as Border).top.width, 2);
      expect(running.border, isNot(stopped.border));
      expect(
        tester.getRect(find.byKey(FreeBoardKeys.clock(side))),
        stoppedRect,
      );
      await pump(true, const Duration(seconds: 2));
      expect(decoration().color, stopped.color);
      expect(find.byType(TimeDisplay), findsOneWidget);
      expect(
        tester
            .widget<Opacity>(
              find.descendant(
                of: find.byType(TimeDisplay),
                matching: find.byType(Opacity),
              ),
            )
            .opacity,
        1,
      );
      expect(tester.takeException(), isNull);
    });
  }

  for (final width in [96.0, 124.0]) {
    for (final scale in [1.0, 2.0]) {
      for (final side in Side.values) {
        testWidgets('D7 $width / fonte $scale / $side: décimos, keys e LTR', (
          tester,
        ) async {
          await tester.pumpWidget(
            TestApp(
              locale: const Locale('ar'),
              themeMode: ThemeMode.dark,
              child: Scaffold(
                body: MediaQuery(
                  data: MediaQueryData(textScaler: TextScaler.linear(scale)),
                  child: Center(
                    child: GameClock(
                      key: FreeBoardKeys.clock(side),
                      timeKey: FreeBoardKeys.clockTime(side),
                      side: side,
                      time: const Duration(milliseconds: 9400),
                      running: true,
                      width: width,
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(
            tester.getSize(find.byKey(FreeBoardKeys.clock(side))),
            Size(width, 44),
          );
          final display = tester.widget<TimeDisplay>(find.byType(TimeDisplay));
          expect(display.type, TimeDisplayType.clock);
          expect(display.state, TimeDisplayState.active);
          expect(display.side, side);
          expect(display.value, '0:09.4');
          expect(display.semanticsLabel, '0:09.4');
          final clock = tester.widget<ClockText>(
            find.byKey(FreeBoardKeys.clockTime(side)),
          );
          expect(clock.text, '0:09.4');
          expect(
            Directionality.of(tester.element(find.byType(ClockText))),
            TextDirection.ltr,
          );
          final text = tester.widget<Text>(
            find.descendant(
              of: find.byType(ClockText),
              matching: find.byType(Text),
            ),
          );
          final spans = (text.textSpan! as TextSpan).children!;
          expect(
            (spans.last as TextSpan).style!.fontSize,
            clock.style!.fontSize! * .7,
          );
          final numbers = tester.getRect(find.byType(FittedBox));
          final box = tester.getRect(find.byKey(FreeBoardKeys.clock(side)));
          expect(numbers.left, greaterThanOrEqualTo(box.left));
          expect(numbers.right, lessThanOrEqualTo(box.right));
          expect(numbers.height, greaterThan(0));
          expect(tester.takeException(), isNull);
        });
      }
    }
  }
}

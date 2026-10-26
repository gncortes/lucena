import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/board_settings.dart';
import 'package:lucena/ui/core/keys/free_board_keys.dart';
import 'package:lucena/ui/core/widgets/game_clock.dart';
import 'package:lucena/ui/core/widgets/time_display.dart';

import '../../../../testing/test_app.dart';

void main() {
  for (final both in [false, true]) {
    testWidgets('CompJogador ${both ? 'duplo' : 'simples'}: conteúdo opcional '
        'preserva relógio e acesso por toque', (tester) async {
      var tapped = false;
      Future<void> row({bool speaking = false}) async {
        await tester.pumpWidget(
          TestApp(
            child: Scaffold(
              body: Center(
                child: SizedBox(
                  width: 360,
                  child: PlayersRow(
                    board: const BoardSettings(),
                    detailed: true,
                    players: [
                      PlayerEntry(
                        side: Side.black,
                        name: 'Coco',
                        detail: '1000',
                        portrait: const SizedBox(width: 44, height: 44),
                        clockKey: FreeBoardKeys.clock(Side.black),
                        time: const Duration(minutes: 3),
                        nameContent: speaking
                            ? GestureDetector(
                                key: FreeBoardKeys.speechBubble,
                                behavior: HitTestBehavior.opaque,
                                onTap: () => tapped = true,
                                child: const Text('…'),
                              )
                            : null,
                      ),
                      if (both)
                        PlayerEntry(
                          side: Side.white,
                          name: 'Jogador',
                          time: const Duration(minutes: 3),
                          clockKey: FreeBoardKeys.clock(Side.white),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
      }

      await row();
      expect(find.text('Coco'), findsOneWidget);
      expect(find.text('1000'), findsOneWidget);
      final clocks = {
        for (final side in both ? Side.values : [Side.black])
          side: tester.getRect(find.byKey(FreeBoardKeys.clock(side))),
      };
      await row(speaking: true);
      expect(find.text('Coco'), findsNothing);
      expect(find.text('1000'), findsNothing);
      final speech = find.byKey(FreeBoardKeys.speechBubble);
      for (final side in clocks.keys) {
        final clock = tester.getRect(find.byKey(FreeBoardKeys.clock(side)));
        expect(clock, clocks[side]);
        expect(tester.getRect(speech).overlaps(clock), isFalse);
      }
      await tester.tap(speech);
      expect(tapped, isTrue);
      await row();
      expect(find.text('Coco'), findsOneWidget);
      expect(find.text('1000'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  Future<void> pump(
    WidgetTester tester,
    Side side, {
    required bool running,
    required Duration time,
  }) async {
    await tester.pumpWidget(
      TestApp(
        child: Scaffold(
          body: Center(
            child: GameClock(
              key: FreeBoardKeys.clock(side),
              timeKey: FreeBoardKeys.clockTime(side),
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

  BoxDecoration decoration(WidgetTester tester, Side side) =>
      tester
              .widget<Container>(
                find.descendant(
                  of: find.byKey(FreeBoardKeys.clock(side)),
                  matching: find.byType(Container),
                ),
              )
              .decoration!
          as BoxDecoration;

  Color numberColor(WidgetTester tester, Side side) => tester
      .widget<ClockText>(find.byKey(FreeBoardKeys.clockTime(side)))
      .style!
      .color!;

  for (final side in Side.values) {
    testWidgets('$side: parado sem opacidade, sem ícone, borda suave', (
      tester,
    ) async {
      await pump(
        tester,
        side,
        running: false,
        time: const Duration(minutes: 3),
      );
      expect(find.byType(Opacity), findsNothing);
      expect(find.byIcon(Icons.av_timer_outlined), findsNothing);
      final scheme = Theme.of(tester.element(find.byType(TimeDisplay)))
          .colorScheme;
      final border = decoration(tester, side).border! as Border;
      expect(border.top.width, 2);
      expect(border.top.color, scheme.outlineVariant);
    });

    testWidgets('$side: correndo, borda onSurface e av_timer; mesmo tamanho', (
      tester,
    ) async {
      await pump(
        tester,
        side,
        running: false,
        time: const Duration(minutes: 3),
      );
      final stoppedRect = tester.getRect(find.byKey(FreeBoardKeys.clock(side)));
      final stopped = decoration(tester, side);
      await pump(tester, side, running: true, time: const Duration(minutes: 3));
      final scheme = Theme.of(tester.element(find.byType(TimeDisplay)))
          .colorScheme;
      final running = decoration(tester, side);
      expect(running.color, stopped.color);
      expect((running.border! as Border).top.color, scheme.onSurface);
      expect(find.byIcon(Icons.av_timer_outlined), findsOneWidget);
      expect(
        tester.getRect(find.byKey(FreeBoardKeys.clock(side))),
        stoppedRect,
      );
    });

    testWidgets('$side: abaixo de 10 s correndo, o alerta é igual nos dois '
        'lados', (tester) async {
      await pump(tester, side, running: true, time: const Duration(seconds: 9));
      final scheme = Theme.of(tester.element(find.byType(TimeDisplay)))
          .colorScheme;
      final low = decoration(tester, side);
      expect(low.color, scheme.errorContainer);
      expect((low.border! as Border).top.color, scheme.error);
      expect((low.border! as Border).top.width, 2);
      expect(numberColor(tester, side), scheme.onErrorContainer);
      expect(find.byIcon(Icons.av_timer_outlined), findsOneWidget);
      // Sem a bolinha vermelha de antes.
      expect(
        find.byWidgetPredicate(
          (w) =>
              w is DecoratedBox &&
              (w.decoration as BoxDecoration).shape == BoxShape.circle,
        ),
        findsNothing,
      );
    });

    testWidgets('$side: parado com menos de 10 s vale o parado', (
      tester,
    ) async {
      await pump(
        tester,
        side,
        running: false,
        time: const Duration(seconds: 5),
      );
      final scheme = Theme.of(tester.element(find.byType(TimeDisplay)))
          .colorScheme;
      expect(decoration(tester, side).color, isNot(scheme.errorContainer));
      expect(
        (decoration(tester, side).border! as Border).top.color,
        scheme.outlineVariant,
      );
    });

    testWidgets('$side: número do relógio parado tem contraste >= 4,5:1', (
      tester,
    ) async {
      await pump(
        tester,
        side,
        running: false,
        time: const Duration(minutes: 3),
      );
      final box = decoration(tester, side).color!;
      final number = Color.alphaBlend(numberColor(tester, side), box);
      double luminance(Color c) => c.computeLuminance();
      final hi = luminance(number) > luminance(box) ? number : box;
      final lo = hi == number ? box : number;
      final ratio = (luminance(hi) + 0.05) / (luminance(lo) + 0.05);
      expect(ratio, greaterThanOrEqualTo(4.5));
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
          expect(display.state, TimeDisplayState.low);
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

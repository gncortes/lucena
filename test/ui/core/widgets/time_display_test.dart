import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/ui/core/widgets/time_display.dart';
import 'package:lucena/ui/core/widgets/game_clock.dart';

void main() {
  const textKey = ValueKey('time value');
  final scheme = ColorScheme.fromSeed(seedColor: Colors.blue);

  Widget app(
    TimeDisplay display, {
    TextDirection direction = TextDirection.ltr,
    double scale = 1,
    double width = 320,
    Brightness brightness = Brightness.light,
  }) => MaterialApp(
    theme: ThemeData(colorScheme: scheme),
    darkTheme: ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.blue,
        brightness: Brightness.dark,
      ),
    ),
    themeMode: brightness == Brightness.dark ? ThemeMode.dark : ThemeMode.light,
    home: Scaffold(
      body: Directionality(
        textDirection: direction,
        child: MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(scale)),
          child: SingleChildScrollView(
            child: Center(
              child: SizedBox(width: width, child: display),
            ),
          ),
        ),
      ),
    ),
  );

  BoxDecoration decoration(WidgetTester tester) =>
      tester
              .widget<Container>(
                find.descendant(
                  of: find.byType(TimeDisplay),
                  matching: find.byType(Container),
                ),
              )
              .decoration!
          as BoxDecoration;

  testWidgets('compact clocks keep 96/124 widths and caller tenths', (
    tester,
  ) async {
    for (final width in [96.0, 124.0]) {
      for (final state in [TimeDisplayState.normal, TimeDisplayState.active]) {
        await tester.pumpWidget(
          app(
            TimeDisplay(
              value: '0:09.4',
              semanticsLabel: 'Clock nine seconds',
              type: TimeDisplayType.clock,
              width: width,
              state: state,
              textKey: textKey,
              valueWidget: const ClockText(
                '0:09.4',
                style: TextStyle(fontSize: 20),
              ),
            ),
            width: width,
          ),
        );
        expect(tester.takeException(), isNull);
        final box = find.descendant(
          of: find.byType(TimeDisplay),
          matching: find.byType(Container),
        );
        expect(tester.getSize(box), Size(width, 44));
        expect(
          find.descendant(
            of: find.byType(TimeDisplay),
            matching: find.byType(Wrap),
          ),
          findsNothing,
        );
        expect(tester.widget<Opacity>(find.byType(Opacity)).opacity, 1);
        final number = tester.widget<Text>(
          find.descendant(of: find.byKey(textKey), matching: find.byType(Text)),
        );
        final spans = (number.textSpan! as TextSpan).children!;
        expect((spans.last as TextSpan).style!.fontSize, 14);
        expect(
          Directionality.of(tester.element(find.byType(ClockText))),
          TextDirection.ltr,
        );
      }
    }
  });

  testWidgets('compact long label stays constrained with low clock and RTL', (
    tester,
  ) async {
    for (final scale in [1.0, 2.0]) {
      await tester.pumpWidget(
        app(
          const TimeDisplay(
            value: '0:09.4',
            semanticsLabel: 'Clock nine seconds remaining',
            type: TimeDisplayType.clock,
            state: TimeDisplayState.low,
            width: 96,
            label: 'Tempo restante da partida',
            textKey: textKey,
            valueWidget: ClockText('0:09.4', style: TextStyle(fontSize: 20)),
          ),
          width: 96,
          scale: scale,
          direction: TextDirection.rtl,
        ),
      );
      expect(tester.takeException(), isNull);
      final label = tester.widget<Text>(find.text('Tempo restante da partida'));
      expect(label.maxLines, 1);
      expect(label.overflow, TextOverflow.ellipsis);
      expect(tester.getSize(find.byType(TimeDisplay)).width, 96);
      expect(
        tester.getSize(find.byType(TimeDisplay)).height,
        greaterThanOrEqualTo(44),
      );
      expect(
        Directionality.of(tester.element(find.byType(ClockText))),
        TextDirection.ltr,
      );
      expect(
        MediaQuery.textScalerOf(tester.element(find.byType(ClockText)))
            .scale(14),
        14 * scale,
      );
    }
  });

  testWidgets('compact fallback remains one line and respects text scale', (
    tester,
  ) async {
    await tester.pumpWidget(
      app(
        const TimeDisplay(
          value: '12:34:56.7',
          semanticsLabel: 'Clock',
          type: TimeDisplayType.clock,
          width: 96,
          textKey: textKey,
        ),
        width: 96,
        scale: 2,
      ),
    );
    expect(tester.takeException(), isNull);
    final text = tester.widget<Text>(find.byKey(textKey));
    expect(text.maxLines, 1);
    expect(text.overflow, TextOverflow.ellipsis);
    expect(
      MediaQuery.textScalerOf(tester.element(find.byKey(textKey))).scale(14),
      28,
    );
  });

  testWidgets('all types preserve caller value and use the intended icon', (
    tester,
  ) async {
    final icons = <TimeDisplayType, IconData?>{
      TimeDisplayType.clock: null,
      TimeDisplayType.stopwatch: Icons.timer_outlined,
      TimeDisplayType.countdown: Icons.hourglass_top_rounded,
      TimeDisplayType.record: Icons.emoji_events_outlined,
      TimeDisplayType.duration: Icons.schedule_outlined,
      TimeDisplayType.pace: Icons.bolt_rounded,
    };
    for (final entry in icons.entries) {
      await tester.pumpWidget(
        app(
          TimeDisplay(
            value: '1:42.3',
            semanticsLabel: 'Localized time',
            type: entry.key,
            textKey: textKey,
          ),
        ),
      );
      expect(tester.widget<Text>(find.byKey(textKey)).data, '1:42.3');
      if (entry.value == null) {
        expect(find.byType(Icon), findsNothing);
      } else {
        expect(find.byIcon(entry.value!), findsOneWidget);
      }
    }
  });

  testWidgets('states use theme colors and low time has a visible cue', (
    tester,
  ) async {
    final expected = <TimeDisplayState, Color>{
      TimeDisplayState.normal: scheme.surfaceContainerHighest,
      TimeDisplayState.active: scheme.surface,
      TimeDisplayState.low: scheme.errorContainer,
      TimeDisplayState.paused: scheme.surfaceContainerHighest,
      TimeDisplayState.highlight: scheme.tertiaryContainer,
    };
    for (final entry in expected.entries) {
      await tester.pumpWidget(
        app(
          TimeDisplay(
            value: '0:05',
            semanticsLabel: 'Localized state',
            state: entry.key,
          ),
        ),
      );
      expect(decoration(tester).color, entry.value);
      if (entry.key == TimeDisplayState.low) {
        final cue = tester
            .widgetList<DecoratedBox>(find.byType(DecoratedBox))
            .where(
              (widget) =>
                  widget.decoration is BoxDecoration &&
                  (widget.decoration as BoxDecoration).shape == BoxShape.circle,
            );
        expect(cue, hasLength(1));
      }
    }
  });

  testWidgets('clock side colors and border width survive all states/themes', (
    tester,
  ) async {
    for (final brightness in Brightness.values) {
      for (final side in Side.values) {
        for (final state in TimeDisplayState.values) {
          await tester.pumpWidget(
            app(
              TimeDisplay(
                value: '5:00',
                semanticsLabel: 'Localized clock',
                type: TimeDisplayType.clock,
                side: side,
                state: state,
                textKey: textKey,
              ),
              brightness: brightness,
            ),
          );
          await tester.pumpAndSettle();
          final box = decoration(tester);
          expect(
            box.color,
            side == Side.white
                ? const Color(0xFFFFFFFF)
                : const Color(0xFF262421),
          );
          expect((box.border! as Border).top.width, 2);
          expect(
            tester.widget<Opacity>(find.byType(Opacity)).opacity,
            state == TimeDisplayState.paused ? 0.55 : 1,
          );
          expect(
            tester.widget<Text>(find.byKey(textKey)).style!.color,
            side == Side.white
                ? const Color(0xFF262421)
                : const Color(0xFFFFFFFF),
          );
          expect(
            find.byIcon(Icons.av_timer_outlined),
            state == TimeDisplayState.active || state == TimeDisplayState.low
                ? findsOneWidget
                : findsNothing,
          );
        }
      }
    }
  });

  testWidgets(
    'localized semantics replace decorative and numeric descendants',
    (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        app(
          const TimeDisplay(
            value: '1:42.3',
            label: 'Tiempo',
            semanticsLabel: 'Tiempo: un minuto',
          ),
        ),
      );
      expect(find.bySemanticsLabel('Tiempo: un minuto'), findsOneWidget);
      expect(find.bySemanticsLabel('1:42.3'), findsNothing);
      expect(find.bySemanticsLabel('Tiempo'), findsNothing);
      handle.dispose();
    },
  );

  testWidgets('RTL labels and LTR tabular numbers tolerate scale and width', (
    tester,
  ) async {
    // Let wrapped text grow vertically, as it would in a scrollable host.
    tester.view.physicalSize = const Size(400, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    for (final type in TimeDisplayType.values) {
      for (final size in TimeDisplaySize.values) {
        await tester.pumpWidget(
          app(
            TimeDisplay(
              value: '12:34:56.7',
              type: type,
              state: TimeDisplayState.low,
              progress: type == TimeDisplayType.countdown ? 0.25 : null,
              label: 'الوقت المتبقي',
              semanticsLabel: 'الوقت',
              size: size,
              textKey: textKey,
            ),
            direction: TextDirection.rtl,
            scale: 2,
            width: 80,
          ),
        );
        expect(tester.takeException(), isNull);
        final text = tester.widget<Text>(find.byKey(textKey));
        expect(text.textDirection, TextDirection.ltr);
        expect(
          text.style!.fontFeatures,
          contains(const FontFeature.tabularFigures()),
        );
        expect(
          Directionality.of(tester.element(find.text('الوقت المتبقي'))),
          TextDirection.rtl,
        );
        expect(
          MediaQuery.textScalerOf(tester.element(find.byKey(textKey)))
              .scale(14),
          28,
        );
      }
    }
  });

  testWidgets('only countdown blocks render the supplied remaining fraction', (
    tester,
  ) async {
    for (final fraction in [0.0, 0.25, 1.0]) {
      await tester.pumpWidget(
        app(
          TimeDisplay(
            value: '0:05',
            semanticsLabel: 'Remaining',
            type: TimeDisplayType.countdown,
            size: TimeDisplaySize.block,
            progress: fraction,
          ),
        ),
      );
      expect(
        tester
            .widget<FractionallySizedBox>(find.byType(FractionallySizedBox))
            .widthFactor,
        fraction,
      );
    }
    for (final display in [
      const TimeDisplay(value: '5', semanticsLabel: 'Time', progress: 0.5),
      const TimeDisplay(
        value: '5',
        semanticsLabel: 'Time',
        type: TimeDisplayType.countdown,
        size: TimeDisplaySize.block,
      ),
    ]) {
      await tester.pumpWidget(app(display));
      expect(find.byType(FractionallySizedBox), findsNothing);
    }
  });

  test('invalid remaining fractions are rejected', () {
    for (final fraction in [-0.1, 1.1, double.nan]) {
      expect(
        () =>
            TimeDisplay(value: '5', semanticsLabel: 'Time', progress: fraction),
        throwsAssertionError,
      );
    }
  });
}

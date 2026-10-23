import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/ui/core/widgets/time_display.dart';
import 'package:lucena/ui/core/widgets/game_clock.dart';
import 'package:lucena_ui/lucena_ui.dart';

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

  testWidgets('plain countdown fits a 40 dp band and preserves RTL semantics', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    for (final direction in TextDirection.values) {
      for (final scale in [1.0, 2.0]) {
        for (final state in TimeDisplayState.values) {
          await tester.pumpWidget(
            app(
              TimeDisplay(
                value: '0:05',
                semanticsLabel: 'Tempo restante: 0:05, ${state.name}',
                type: TimeDisplayType.countdown,
                size: TimeDisplaySize.inline,
                presentation: TimeDisplayPresentation.plain,
                state: state,
                textKey: textKey,
              ),
              scale: scale,
              direction: direction,
            ),
          );
          expect(tester.takeException(), isNull);
          expect(find.byType(Icon), findsNothing);
          expect(find.byType(Container), findsNothing);
          expect(tester.getSize(find.byType(TimeDisplay)).height, 24 * scale);
          if (scale == 1) {
            expect(tester.getSize(find.byType(TimeDisplay)).height + 16, 40);
          }
          final text = tester.widget<Text>(find.byKey(textKey));
          expect(text.textDirection, TextDirection.ltr);
          expect(
            text.style!.color,
            state == TimeDisplayState.low ? scheme.error : scheme.onSurface,
          );
          expect(
            find.bySemanticsLabel('Tempo restante: 0:05, ${state.name}'),
            findsOneWidget,
          );
        }
      }
    }
    handle.dispose();
  });

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
        expect(find.byType(Opacity), findsNothing);
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
      TimeDisplayState.highlight: const Color(0xFF2E7D32),
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
        // A cor, a borda e o ícone bastam: sem a bolinha vermelha.
        expect(cue, isEmpty);
      }
    }
  });

  testWidgets('clock side colors and border width follow the state', (
    tester,
  ) async {
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
          ),
        );
        await tester.pumpAndSettle();
        final colors = Theme.of(tester.element(find.byType(TimeDisplay)))
            .colorScheme;
        final white = side == Side.white;
        final box = decoration(tester);
        final text = tester.widget<Text>(find.byKey(textKey)).style!.color;
        expect(find.byType(Opacity), findsNothing);
        expect((box.border! as Border).top.width, 2);
        switch (state) {
          case TimeDisplayState.low:
            expect(box.color, colors.errorContainer);
            expect((box.border! as Border).top.color, colors.error);
            expect(text, colors.onErrorContainer);
          case TimeDisplayState.paused:
            expect(box.color, white ? AppColors.white : AppColors.ink);
            expect((box.border! as Border).top.color, colors.outlineVariant);
            expect(
              text,
              white
                  ? colors.onSurfaceVariant
                  : AppColors.white.withValues(alpha: 0.72),
            );
          default:
            expect(box.color, white ? AppColors.white : AppColors.ink);
            expect((box.border! as Border).top.color, colors.onSurface);
            expect(text, white ? AppColors.ink : AppColors.white);
        }
        expect(
          find.byIcon(Icons.av_timer_outlined),
          state == TimeDisplayState.active || state == TimeDisplayState.low
              ? findsOneWidget
              : findsNothing,
        );
      }
    }
  });

  testWidgets('icon replaces the icon of the type', (tester) async {
    await tester.pumpWidget(
      app(
        const TimeDisplay(
          value: '1:00',
          semanticsLabel: 'Time',
          type: TimeDisplayType.countdown,
          icon: Icons.schedule,
        ),
      ),
    );
    expect(find.byIcon(Icons.schedule), findsOneWidget);
    expect(find.byIcon(Icons.hourglass_top_rounded), findsNothing);
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

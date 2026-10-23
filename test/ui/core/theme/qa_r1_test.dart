import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/ui/core/widgets/game_clock.dart';
import 'package:lucena_ui/lucena_ui.dart';

// Os ajustes da 1ª rodada de QA da E1.08: cor, altura e peso medidos.
Widget _app(Widget child) => MaterialApp(
  theme: AppTheme.light,
  home: Scaffold(body: Center(child: child)),
);

void main() {
  final theme = AppTheme.light;

  test('superfícies do claro iguais às do canvas (painel branco)', () {
    expect(theme.colorScheme.surfaceContainerLow, const Color(0xFFFFFFFF));
    expect(theme.colorScheme.surface, theme.scaffoldBackgroundColor);
  });

  testWidgets('segmento não selecionado em onSurface', (tester) async {
    await tester.pumpWidget(
      _app(
        SegmentedButton<int>(
          showSelectedIcon: false,
          segments: const [
            ButtonSegment(value: 1, label: Text('Um')),
            ButtonSegment(value: 2, label: Text('Dois')),
          ],
          selected: const {1},
          onSelectionChanged: (_) {},
        ),
      ),
    );
    final text = tester.widget<DefaultTextStyle>(
      find
          .ancestor(
            of: find.text('Dois'),
            matching: find.byType(DefaultTextStyle),
          )
          .first,
    );
    expect(text.style.color, theme.colorScheme.onSurface);
  });

  testWidgets('chips: 32 de altura e 8 entre linhas', (tester) async {
    await tester.pumpWidget(
      _app(
        SizedBox(
          width: 60,
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final k in ['a', 'b'])
                ChoiceChip(
                  key: Key(k),
                  materialTapTargetSize: AppChip.tapTarget,
                  visualDensity: AppChip.density,
                  label: const Text('x'),
                  selected: false,
                  onSelected: (_) {},
                ),
            ],
          ),
        ),
      ),
    );
    final a = tester.getRect(find.byKey(const Key('a')));
    final b = tester.getRect(find.byKey(const Key('b')));
    expect(a.height, 32);
    expect(b.top - a.bottom, 8);
  });

  testWidgets('botão do rodapé com letra 16/24', (tester) async {
    await tester.pumpWidget(
      _app(
        ActionsFooter(
          children: [FilledButton(onPressed: () {}, child: const Text('Ok'))],
        ),
      ),
    );
    final style = tester.widget<DefaultTextStyle>(
      find
          .descendant(
            of: find.byType(FilledButton),
            matching: find.byType(DefaultTextStyle),
          )
          .first,
    );
    expect(style.style.fontSize, 16);
    expect(style.style.height, 24 / 16);
  });

  testWidgets('relógio em peso 700', (tester) async {
    await tester.pumpWidget(
      _app(
        const GameClock(
          timeKey: Key('t'),
          side: Side.white,
          time: Duration(minutes: 5),
          running: true,
        ),
      ),
    );
    final style = tester
        .widget<Text>(
          find
              .descendant(
                of: find.byKey(const Key('t')),
                matching: find.byType(Text),
              )
              .first,
        )
        .style;
    expect(
      style?.fontWeight ??
          tester
              .widget<ClockText>(find.byKey(const Key('t')))
              .style
              ?.fontWeight,
      FontWeight.w700,
    );
  });

  testWidgets('InfoChip contornado: sem fundo e borda outline-variant', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(const InfoChip(label: 'Nível', outlined: true)),
    );
    final box = tester.widget<Container>(find.byKey(CoreKeys.infoChip));
    final decoration = box.decoration! as BoxDecoration;
    expect(decoration.color, isNull);
    expect(
      (decoration.border! as Border).top.color,
      theme.colorScheme.outlineVariant,
    );
    expect(tester.getSize(find.byKey(CoreKeys.infoChip)).height, 32);
  });

  testWidgets('títulos de tela e de cartão em 700', (tester) async {
    late BuildContext context;
    await tester.pumpWidget(
      _app(
        Builder(
          builder: (c) =>
              (context = c) is Element ? const SizedBox() : const SizedBox(),
        ),
      ),
    );
    expect(context.screenTitle?.fontWeight, FontWeight.w700);
    expect(context.cardTitle?.fontWeight, FontWeight.w700);
  });
}

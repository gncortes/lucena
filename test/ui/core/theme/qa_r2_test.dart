import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/ui/core/board/centered_board_layout.dart';
import 'package:lucena_ui/lucena_ui.dart';

// Os ajustes da 2ª rodada de QA da E1.08: fundo do chip, altura e pesos.
Widget _app(Widget child) => MaterialApp(
  theme: AppTheme.light,
  home: Scaffold(body: Center(child: child)),
);

void main() {
  final theme = AppTheme.light;

  test('chip não escolhido é transparente nos dois temas (CompChip)', () {
    expect(theme.chipTheme.backgroundColor, Colors.transparent);
    expect(AppTheme.dark.chipTheme.backgroundColor, Colors.transparent);
  });

  testWidgets('FilterChip da folha de filtros: 32 de altura', (tester) async {
    await tester.pumpWidget(
      _app(
        FilterChip(
          key: const Key('f'),
          materialTapTargetSize: AppChip.tapTarget,
          visualDensity: AppChip.density,
          label: const Text('x'),
          selected: false,
          onSelected: (_) {},
        ),
      ),
    );
    expect(tester.getRect(find.byKey(const Key('f'))).height, 32);
  });

  testWidgets('ficha do relógio sem marca e sem folga de rótulo', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        ChoiceChip(
          key: const Key('t'),
          materialTapTargetSize: AppChip.tapTarget,
          visualDensity: AppChip.density,
          showCheckmark: false,
          labelPadding: EdgeInsets.zero,
          label: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 24),
            child: const Text('1', textAlign: TextAlign.center),
          ),
          selected: true,
          onSelected: (_) {},
        ),
      ),
    );
    final size = tester.getSize(find.byKey(const Key('t')));
    expect(size.height, 32);
    expect(size.width, lessThan(46));
    expect(find.byIcon(Icons.check), findsNothing);
  });

  testWidgets('sectionTitle em onSurfaceVariant; título de cartão em 700', (
    tester,
  ) async {
    late BuildContext ctx;
    await tester.pumpWidget(
      _app(
        Builder(
          builder: (c) {
            ctx = c;
            return const SizedBox();
          },
        ),
      ),
    );
    expect(ctx.sectionTitle?.color, theme.colorScheme.onSurfaceVariant);
    expect(AppWeight.strong, FontWeight.w700);
    expect(ctx.cardTitle?.fontWeight, FontWeight.w700);
  });

  testWidgets('folha da Lucena: o chip pinta por baixo o branco da folha', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        LucenaSheetFrame(
          onClose: () {},
          child: ChoiceChip(
            key: const Key('c'),
            label: const Text('x'),
            selected: false,
            onSelected: (_) {},
          ),
        ),
      ),
    );
    final chip = tester.element(find.byKey(const Key('c')));
    expect(Theme.of(chip).canvasColor, theme.colorScheme.surfaceContainerLow);
    expect(theme.colorScheme.surfaceContainerLow, isNot(theme.canvasColor));
  });

  testWidgets('painel da Nova partida: o chip pinta por baixo o branco', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        BoardOptionsPanel(
          child: ChoiceChip(
            key: const Key('p'),
            label: const Text('x'),
            selected: false,
            onSelected: (_) {},
          ),
        ),
      ),
    );
    final chip = tester.element(find.byKey(const Key('p')));
    expect(Theme.of(chip).canvasColor, theme.colorScheme.surfaceContainerLow);
  });
}

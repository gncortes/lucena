import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/ui/core/keys/school_keys.dart';
import 'package:lucena/ui/core/l10n/l10n.dart';
import 'package:lucena/ui/core/widgets/actions_footer.dart';

import '../../../../testing/goldens/golden_harness.dart';
import '../../../../testing/test_app.dart';

const _primary = LessonKeys.nextPartButton;
const _secondary = LessonKeys.reviewPartButton;

// Prints com sombra real: --dart-define=PRINT=<pasta> --update-goldens.
const _print = String.fromEnvironment('PRINT');

Future<void> _snap(WidgetTester tester, String name) async {
  if (_print.isEmpty) return;
  debugDisableShadows = false;
  await tester.pumpAndSettle();
  await expectLater(
    find.byType(ActionsFooter),
    matchesGoldenFile('$_print/$name.png'),
  );
  debugDisableShadows = true;
}

/// O rodapé do fim de capítulo em PT-BR, com a letra do app (Roboto): a
/// medida de reserva depende da largura real do rótulo.
Future<void> _pump(
  WidgetTester tester,
  double width, {
  required bool last,
}) async {
  await Goldens.loadFonts();
  tester.view
    ..devicePixelRatio = 1
    ..physicalSize = Size(width, 400);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    TestApp(
      locale: const Locale('pt'),
      child: Builder(
        builder: (context) => Scaffold(
          bottomNavigationBar: ActionsFooter(
            secondaryKey: _secondary,
            secondaryIcon: Icons.replay,
            secondaryLabel: context.l10n.lessonReviewPart,
            onSecondary: () {},
            primaryKey: _primary,
            primaryIcon: last ? null : Icons.arrow_forward_rounded,
            primaryLabel: last
                ? context.l10n.lessonToFinalTest
                : context.l10n.lessonPartNext,
            onPrimary: () {},
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  for (final width in [360.0, 412.0]) {
    testWidgets('$width: "Revisar | Próximo" lado a lado, metade cada, 52', (
      tester,
    ) async {
      await _pump(tester, width, last: false);
      final primary = tester.getRect(find.byKey(_primary));
      final secondary = tester.getRect(find.byKey(_secondary));
      final half = (width - 32 - 8) / 2;
      // O contornado no começo, o cheio no fim, na mesma linha.
      expect(secondary.left, 16);
      expect(secondary.width, closeTo(half, 0.5));
      expect(primary.left - secondary.right, closeTo(8, 0.5));
      expect(primary.right, closeTo(width - 16, 0.5));
      expect(primary.top, secondary.top);
      expect(primary.height, 52);
      expect(secondary.height, 52);
      // Padding 8 em cima e 12 embaixo.
      final footer = tester.getRect(find.byType(ActionsFooter));
      expect(primary.top - footer.top, 8);
      expect(footer.bottom - primary.bottom, 12);
      expect(
        find.descendant(
          of: find.byKey(_primary),
          matching: find.byIcon(Icons.arrow_forward_rounded),
        ),
        findsOneWidget,
      );
      await _snap(tester, 'lado_a_lado_${width.toInt()}');
    });

    testWidgets('$width: "Fazer o teste final" (3 palavras) empilha, o cheio '
        'em cima, sem ícone', (tester) async {
      await _pump(tester, width, last: true);
      final primary = tester.getRect(find.byKey(_primary));
      final secondary = tester.getRect(find.byKey(_secondary));
      expect(primary.left, 16);
      expect(primary.width, width - 32);
      expect(secondary.width, width - 32);
      expect(secondary.top - primary.bottom, 8);
      expect(primary.height, 52);
      expect(secondary.height, 52);
      expect(
        find.descendant(of: find.byKey(_primary), matching: find.byType(Icon)),
        findsNothing,
      );
      final footer = tester.getRect(find.byType(ActionsFooter));
      expect(footer.bottom - secondary.bottom, 12);
      await _snap(tester, 'empilhado_${width.toInt()}');
    });
  }

  testWidgets('reserva: rótulo de duas palavras que não cabe na metade '
      'empilha', (tester) async {
    await Goldens.loadFonts();
    tester.view
      ..devicePixelRatio = 1
      ..physicalSize = const Size(360, 400);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      TestApp(
        locale: const Locale('pt'),
        child: Scaffold(
          bottomNavigationBar: ActionsFooter(
            secondaryKey: _secondary,
            secondaryLabel: 'Revisar',
            onSecondary: () {},
            primaryKey: _primary,
            primaryIcon: Icons.arrow_forward_rounded,
            primaryLabel: 'Inconstitucionalíssimamente adiante',
            onPrimary: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final primary = tester.getRect(find.byKey(_primary));
    final secondary = tester.getRect(find.byKey(_secondary));
    expect(secondary.top, greaterThan(primary.bottom));
    expect(primary.width, 360 - 32);
  });
}

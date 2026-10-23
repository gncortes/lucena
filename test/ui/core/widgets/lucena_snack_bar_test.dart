import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/ui/core/widgets/lucena_snack_bar.dart';
import 'package:lucena_ui/lucena_ui.dart';

import '../../../../testing/test_app.dart';

void main() {
  Future<void> pump(WidgetTester tester, void Function(BuildContext) onTap) =>
      tester.pumpWidget(
        TestApp(
          child: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => onTap(context),
                child: const Text('abrir'),
              ),
            ),
          ),
        ),
      );

  testWidgets('aviso com ícone de 20, texto e ação', (tester) async {
    var undone = false;
    await pump(
      tester,
      (context) => showLucenaSnackBar(
        context,
        'Feito',
        icon: Icons.check,
        action: SnackBarAction(
          label: 'Desfazer',
          onPressed: () => undone = true,
        ),
      ),
    );
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
    expect(find.byKey(CoreKeys.snackBar), findsOneWidget);
    expect(find.text('Feito'), findsOneWidget);
    expect(tester.getSize(find.byIcon(Icons.check)).width, 20);
    expect(
      tester.getSize(find.byKey(CoreKeys.snackBar)).height,
      greaterThanOrEqualTo(48),
    );
    await tester.tap(find.text('Desfazer'));
    expect(undone, isTrue);
  });

  testWidgets('um aviso novo troca o que estava aberto', (tester) async {
    var n = 0;
    await pump(
      tester,
      (context) => showLucenaSnackBar(context, 'Aviso ${++n}'),
    );
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
    expect(find.text('Aviso 1'), findsNothing);
    expect(find.text('Aviso 2'), findsOneWidget);
  });

  testWidgets('some sozinho depois de 4 s', (tester) async {
    await pump(tester, (context) => showLucenaSnackBar(context, 'Some'));
    await tester.tap(find.text('abrir'));
    await tester.pump();
    // O prazo só começa a contar depois da animação de entrada.
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    expect(find.text('Some'), findsNothing);
  });

  testWidgets('top: o aviso fica no alto da tela', (tester) async {
    await pump(
      tester,
      (context) => showLucenaSnackBar(context, 'Alto', top: true),
    );
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
    final bar = tester.getRect(find.byKey(CoreKeys.snackBar));
    expect(bar.top, lessThan(tester.view.physicalSize.height / 2));
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/ui/core/keys/opponent_error_keys.dart';
import 'package:lucena/ui/core/keys/sheet_keys.dart';
import 'package:lucena/ui/core/widgets/opponent_error_sheet.dart';

import '../../../../testing/test_app.dart';

/// H-PAR-18: a folha do adversário que não responde não tem ✕, não fecha pelo
/// toque fora nem pelo voltar; só os dois botões saem dela.
void main() {
  late bool? result;

  Future<void> open(WidgetTester tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    result = null;
    await tester.pumpWidget(
      TestApp(
        locale: const Locale('pt'),
        child: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async =>
                  result = await showOpponentErrorSheet(context),
              child: const Text('abrir'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
  }

  testWidgets('mostra o texto do quadro e não tem ✕', (tester) async {
    await open(tester);
    expect(find.byKey(OpponentErrorKeys.sheet), findsOneWidget);
    expect(find.text('Ocorreu um erro inesperado'), findsOneWidget);
    expect(
      find.text(
        'Seu relógio está parado. Se sair, a partida continua de onde parou.',
      ),
      findsOneWidget,
    );
    expect(find.byKey(SheetKeys.close), findsNothing);
    expect(find.text('Tentar novamente'), findsOneWidget);
    expect(find.text('Sair'), findsOneWidget);
  });

  testWidgets('toque fora e voltar do sistema não fecham', (tester) async {
    await open(tester);
    await tester.tapAt(const Offset(200, 20));
    await tester.pumpAndSettle();
    expect(find.byKey(OpponentErrorKeys.sheet), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byKey(OpponentErrorKeys.sheet), findsOneWidget);
    expect(result, isNull);
  });

  testWidgets('Tentar novamente devolve verdadeiro', (tester) async {
    await open(tester);
    await tester.tap(find.byKey(OpponentErrorKeys.retry));
    await tester.pumpAndSettle();
    expect(result, isTrue);
    expect(find.byKey(OpponentErrorKeys.sheet), findsNothing);
  });

  testWidgets('Sair devolve falso', (tester) async {
    await open(tester);
    await tester.tap(find.byKey(OpponentErrorKeys.leave));
    await tester.pumpAndSettle();
    expect(result, isFalse);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/ui/core/widgets/lucena_dialog.dart';
import 'package:lucena/ui/core/widgets/section_title.dart';

void main() {
  Widget host(
    Future<bool?>? Function(BuildContext) open,
    ValueSetter<bool?> r,
  ) => MaterialApp(
    home: Builder(
      builder: (context) => TextButton(
        onPressed: () async => r(await open(context)),
        child: const Text('abrir'),
      ),
    ),
  );

  testWidgets('showLucenaConfirm devolve true ao confirmar e mantém a key', (
    tester,
  ) async {
    bool? result;
    var called = false;
    await tester.pumpWidget(
      host(
        (c) => showLucenaConfirm(
          c,
          title: 'Título',
          content: const Text('Corpo'),
          cancelLabel: 'Não',
          confirmLabel: 'Sim',
          confirmKey: const Key('ok'),
        ),
        (v) {
          called = true;
          result = v;
        },
      ),
    );
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
    expect(find.text('Título'), findsOneWidget);
    expect(find.text('Corpo'), findsOneWidget);
    final dialog = tester.widget<AlertDialog>(find.byType(AlertDialog));
    expect(dialog.actionsPadding, const EdgeInsets.fromLTRB(24, 14, 24, 18));
    await tester.tap(find.byKey(const Key('ok')));
    await tester.pumpAndSettle();
    expect(called, isTrue);
    expect(result, isTrue);
  });

  testWidgets('showLucenaConfirm devolve false ao cancelar', (tester) async {
    bool? result;
    await tester.pumpWidget(
      host(
        (c) => showLucenaConfirm(
          c,
          title: 'T',
          content: const Text('C'),
          cancelLabel: 'Não',
          confirmLabel: 'Sim',
        ),
        (v) => result = v,
      ),
    );
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Não'));
    await tester.pumpAndSettle();
    expect(result, isFalse);
  });

  testWidgets('SectionTitle com inset 0 não tem margem lateral', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: SectionTitle('Seção', inset: 0))),
    );
    expect(tester.getTopLeft(find.text('Seção')).dx, 0);
  });
}

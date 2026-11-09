import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/ui/core/widgets/filter_sheet.dart';
import 'package:lucena/ui/core/widgets/status_circle_icon.dart';

void main() {
  testWidgets('FilterSheetScaffold mostra título, opções, Limpar e botão', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FilterSheetScaffold(
            key: const Key('sheet'),
            title: 'Filtros',
            clearButton: TextButton(
              key: const Key('clear'),
              onPressed: () {},
              child: const Text('Limpar'),
            ),
            filterId: 'teste',
            items: const [
              FilterSheetHeading('Tipo'),
              FilterSheetOptions(children: [Chip(label: Text('Torre'))]),
            ],
            applyButton: FilledButton(
              key: const Key('apply'),
              onPressed: () {},
              child: const Text('Ver 3'),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('sheet')), findsOneWidget);
    expect(find.text('Filtros'), findsOneWidget);
    expect(find.byKey(const Key('clear')), findsOneWidget);
    expect(find.text('Tipo'), findsOneWidget);
    expect(find.text('Torre'), findsOneWidget);
    expect(find.byKey(const Key('apply')), findsOneWidget);
  });

  testWidgets('FilterSheetScaffold sem Limpar não mostra o botão', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FilterSheetScaffold(
            title: 'Filtros',
            filterId: 'teste',
            items: const [FilterSheetHeading('Tipo')],
            applyButton: FilledButton(
              onPressed: () {},
              child: const Text('Fechar'),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Limpar'), findsNothing);
    expect(find.text('Fechar'), findsOneWidget);
  });

  testWidgets('StatusCircleIcon: círculo de 48 com o ícone', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: StatusCircleIcon(icon: Icons.remove)),
      ),
    );
    expect(tester.getSize(find.byType(StatusCircleIcon)), const Size(48, 48));
    expect(find.byIcon(Icons.remove), findsOneWidget);
  });
}

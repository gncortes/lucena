import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/ui/core/widgets/lucena_app_bar.dart';

void main() {
  Future<double> titleCenterX(WidgetTester tester, LucenaAppBar bar) async {
    await tester.pumpWidget(MaterialApp(home: Scaffold(appBar: bar)));
    final screenCenter = tester.getSize(find.byType(Scaffold)).width / 2;
    return tester.getCenter(find.text('Título')).dx - screenCenter;
  }

  testWidgets('sem ação, o título fica centralizado', (tester) async {
    final offset = await titleCenterX(
      tester,
      LucenaAppBar(title: const Text('Título')),
    );
    expect(offset.abs(), lessThan(1));
  });

  testWidgets('com a lista de ações vazia, o título fica centralizado', (
    tester,
  ) async {
    final offset = await titleCenterX(
      tester,
      LucenaAppBar(title: const Text('Título'), actions: const []),
    );
    expect(offset.abs(), lessThan(1));
  });

  testWidgets('com ação, o título fica à esquerda', (tester) async {
    final offset = await titleCenterX(
      tester,
      LucenaAppBar(
        title: const Text('Título'),
        actions: const [Icon(Icons.star)],
      ),
    );
    expect(offset, lessThan(-50));
  });
}

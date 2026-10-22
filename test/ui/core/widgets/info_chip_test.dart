import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/ui/core/keys/core_keys.dart';
import 'package:lucena/ui/core/theme/app_shape.dart';
import 'package:lucena/ui/core/widgets/info_chip.dart';

import '../../../../testing/test_app.dart';

void main() {
  Future<void> pump(WidgetTester tester, InfoChip chip) => tester.pumpWidget(
    TestApp(
      child: Scaffold(body: Center(child: chip)),
    ),
  );

  testWidgets('chip: 32 de altura, raio 8, sem borda, surfaceContainer', (
    tester,
  ) async {
    await pump(tester, const InfoChip(icon: Icons.timer, label: '5+3'));
    expect(tester.getSize(find.byKey(CoreKeys.infoChip)).height, 32);
    final box =
        tester.widget<Container>(find.byKey(CoreKeys.infoChip)).decoration
            as BoxDecoration;
    final scheme = Theme.of(tester.element(find.byType(Scaffold))).colorScheme;
    expect(box.color, scheme.surfaceContainer);
    expect(box.border, isNull);
    expect(box.borderRadius, BorderRadius.circular(AppShape.small));
  });

  testWidgets('compacto tem 28', (tester) async {
    await pump(tester, const InfoChip(label: 'Nível 1200', compact: true));
    expect(tester.getSize(find.byKey(CoreKeys.infoChip)).height, 28);
  });

  testWidgets('selo colorido usa a mesma caixa', (tester) async {
    await pump(tester, const InfoChip(label: 'Novo', background: Colors.green));
    final box =
        tester.widget<Container>(find.byKey(CoreKeys.infoChip)).decoration
            as BoxDecoration;
    expect(box.color, Colors.green);
    expect(tester.getSize(find.byKey(CoreKeys.infoChip)).height, 32);
  });
}

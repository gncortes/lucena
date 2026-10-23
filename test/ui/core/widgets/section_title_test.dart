import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/ui/core/widgets/section_title.dart';
import 'package:lucena_ui/lucena_ui.dart';

import '../../../../testing/test_app.dart';

void main() {
  testWidgets('título de seção: 40 de altura, cinza, valor e ação', (
    tester,
  ) async {
    var tapped = false;
    await tester.pumpWidget(
      TestApp(
        child: Scaffold(
          body: SectionTitle(
            'Adversários',
            value: '8 de 12',
            action: SectionAction(
              label: 'Ver tudo',
              icon: Icons.chevron_right,
              onPressed: () => tapped = true,
            ),
          ),
        ),
      ),
    );
    expect(
      tester.getSize(find.byKey(CoreKeys.sectionTitle)).height,
      greaterThanOrEqualTo(SectionTitle.minHeight - 16 - 8),
    );
    final scheme = Theme.of(tester.element(find.byKey(CoreKeys.sectionTitle)))
        .colorScheme;
    final style = tester.widget<Text>(find.text('Adversários')).style!;
    expect(style.color, scheme.onSurfaceVariant);
    expect(find.text('8 de 12'), findsOneWidget);
    await tester.tap(find.text('Ver tudo'));
    expect(tapped, isTrue);
  });

  testWidgets('sem valor nem ação, só o texto', (tester) async {
    await tester.pumpWidget(
      const TestApp(child: Scaffold(body: SectionTitle('Sozinho'))),
    );
    expect(find.byType(TextButton), findsNothing);
    expect(find.text('Sozinho'), findsOneWidget);
  });
}

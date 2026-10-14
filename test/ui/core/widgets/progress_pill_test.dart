import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/ui/core/widgets/progress_pill.dart';

import '../../../../testing/test_app.dart';

/// T73 (7.1): a barra de progresso em cartão é uma pílula de 8.
void main() {
  testWidgets('a barra em cartão tem 8 dp e ponta em pílula', (tester) async {
    await tester.pumpWidget(
      const TestApp(
        child: Scaffold(body: Center(child: ProgressPill(value: 0.4))),
      ),
    );
    expect(tester.getSize(find.byType(ProgressPill)).height, 8);
    final clip = tester.widget<ClipRRect>(find.byType(ClipRRect).first);
    expect(clip.borderRadius, isNot(BorderRadius.zero));
  });
}

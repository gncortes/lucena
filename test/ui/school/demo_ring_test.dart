import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/ui/core/keys/school_keys.dart';
import 'package:lucena/ui/school/widgets/lesson_part_widgets.dart';

import '../../../testing/test_app.dart';

/// T65 (F4, item 3): quando o lance sai, o anel zera na hora, sem animar de
/// volta.
void main() {
  testWidgets('o valor cai: o arco recomeça em 0 sem desenrolar', (
    tester,
  ) async {
    final progress = ValueNotifier<double?>(0.2);
    addTearDown(progress.dispose);
    await tester.pumpWidget(
      TestApp(
        child: Center(child: DemoRing(progress: progress)),
      ),
    );
    progress.value = 1;
    await tester.pumpAndSettle();
    progress.value = 0;
    await tester.pump();
    // No primeiro quadro depois da queda o arco já está em 0: o painter
    // novo não guarda valor intermediário (nada de TweenAnimationBuilder
    // andando para trás).
    final paint = tester.widget<CustomPaint>(find.byKey(LessonKeys.demoRing));
    expect(paint.painter.toString(), contains('_RingPainter'));
    expect(tester.hasRunningAnimations, isFalse);
  });
}

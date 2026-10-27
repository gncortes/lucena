import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/ui/core/widgets/sheet_close_button.dart';

import '../../../../testing/test_app.dart';

void main() {
  testWidgets('X visual de 44 e alvo de 48, inclusive nas bordas', (
    tester,
  ) async {
    var closes = 0;
    const closeKey = ValueKey('sheetClose.test');
    await tester.pumpWidget(
      TestApp(
        child: Scaffold(
          body: Center(
            child: SheetCloseButton(key: closeKey, onPressed: () => closes++),
          ),
        ),
      ),
    );
    final target = tester.getRect(find.byKey(closeKey));
    final visual = tester.getRect(
      find
          .descendant(of: find.byKey(closeKey), matching: find.byType(Material))
          .first,
    );
    expect(visual.size, const Size.square(44));
    expect(target.width, greaterThanOrEqualTo(48));
    expect(target.height, greaterThanOrEqualTo(48));
    expect(find.byTooltip('Close'), findsOneWidget);
    for (final point in [
      target.center,
      target.topLeft + const Offset(1, 1),
      target.bottomRight - const Offset(1, 1),
    ]) {
      await tester.tapAt(point);
      await tester.pump();
    }
    expect(closes, 3);
    expect(tester.takeException(), isNull);
  });
}

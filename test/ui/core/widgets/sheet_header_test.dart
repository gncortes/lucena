import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/ui/core/widgets/sheet_header.dart';
import 'package:lucena_ui/lucena_ui.dart';

import '../../../../testing/test_app.dart';

void main() {
  testWidgets('título com margem 24 e dica abaixo', (tester) async {
    await tester.pumpWidget(
      const TestApp(
        child: Scaffold(
          body: SheetHeader(title: 'Título', hint: 'Dica'),
        ),
      ),
    );
    final header = tester.getRect(find.byKey(SheetKeys.header));
    final title = tester.getRect(find.byKey(SheetKeys.title));
    final hint = tester.getRect(find.byKey(SheetKeys.hint));
    expect(title.left - header.left, 24);
    expect(hint.top, greaterThan(title.bottom - 1));
    final style = tester.widget<Text>(find.byKey(SheetKeys.title)).style;
    final theme = Theme.of(tester.element(find.byKey(SheetKeys.header)));
    expect(style?.fontSize ?? theme.textTheme.titleLarge!.fontSize, 22);
  });

  testWidgets('sem dica, sem o espaço dela', (tester) async {
    await tester.pumpWidget(
      const TestApp(
        child: Scaffold(body: SheetHeader(title: 'Título')),
      ),
    );
    expect(find.byKey(SheetKeys.hint), findsNothing);
  });

  testWidgets('a alça tem 32 por 4', (tester) async {
    await tester.pumpWidget(
      const TestApp(
        child: Scaffold(body: Center(child: SheetHandle())),
      ),
    );
    expect(tester.getSize(find.byType(SheetHandle)), const Size(32, 4));
  });
}

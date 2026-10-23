import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/ui/core/widgets/actions_footer.dart';
import 'package:lucena_ui/lucena_ui.dart';

import '../../../../testing/test_app.dart';

void main() {
  Future<void> pump(WidgetTester tester, ActionsFooter footer) =>
      tester.pumpWidget(
        TestApp(
          child: Scaffold(body: Column(children: [const Spacer(), footer])),
        ),
      );

  testWidgets('botões de 52 com margem 16 e 8, lado a lado', (tester) async {
    await pump(
      tester,
      ActionsFooter(
        children: [
          OutlinedButton(onPressed: () {}, child: const Text('A')),
          FilledButton(onPressed: () {}, child: const Text('B')),
        ],
      ),
    );
    final footer = tester.getRect(find.byKey(CoreKeys.actionsFooter));
    final a = tester.getRect(find.byType(OutlinedButton));
    final b = tester.getRect(find.byType(FilledButton));
    expect(a.height, kButtonHeight);
    expect(a.left - footer.left, 16);
    expect(footer.right - b.right, 16);
    expect(b.left - a.right, 8);
    expect(a.width, b.width);
    expect(footer.height, kButtonHeight + 16);
  });

  testWidgets('sem degradê por padrão; fade pinta o degradê', (tester) async {
    await pump(
      tester,
      ActionsFooter(
        children: [FilledButton(onPressed: () {}, child: const Text('B'))],
      ),
    );
    BoxDecoration? decoration() =>
        tester
                .widget<DecoratedBox>(find.byKey(CoreKeys.actionsFooter))
                .decoration
            as BoxDecoration?;
    expect(decoration()?.gradient, isNull);
    expect(decoration()?.boxShadow, isNull);
    await pump(
      tester,
      ActionsFooter(
        fade: true,
        children: [FilledButton(onPressed: () {}, child: const Text('B'))],
      ),
    );
    expect(decoration()?.gradient, isNotNull);
  });

  testWidgets('stacked põe um botão sobre o outro', (tester) async {
    await pump(
      tester,
      ActionsFooter(
        stacked: true,
        children: [
          FilledButton(onPressed: () {}, child: const Text('B')),
          TextButton(onPressed: () {}, child: const Text('C')),
        ],
      ),
    );
    final top = tester.getRect(find.byType(FilledButton));
    final bottom = tester.getRect(find.byType(TextButton));
    expect(bottom.top, greaterThan(top.bottom - 1));
    expect(top.left, bottom.left);
  });
}

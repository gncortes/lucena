import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/ui/core/widgets/animated_progress.dart';
import 'package:lucena/ui/core/widgets/celebration.dart';

void main() {
  double shown(WidgetTester tester) => tester
      .widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator))
      .value!;

  Widget app(Widget child, {bool reduced = false}) => MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(disableAnimations: reduced),
      child: Scaffold(body: child),
    ),
  );

  testWidgets('a barra aparece no valor e, quando ele muda, enche aos '
      'poucos', (tester) async {
    await tester.pumpWidget(app(const AnimatedProgress(value: 0.2)));
    expect(shown(tester), 0.2);
    await tester.pumpWidget(app(const AnimatedProgress(value: 0.6)));
    await tester.pump(const Duration(milliseconds: 200));
    expect(shown(tester), inExclusiveRange(0.2, 0.6));
    await tester.pumpAndSettle();
    expect(shown(tester), 0.6);
  });

  testWidgets('com "remover animações", a barra vai direto', (tester) async {
    await tester.pumpWidget(
      app(const AnimatedProgress(value: 0.2), reduced: true),
    );
    await tester.pumpWidget(
      app(const AnimatedProgress(value: 0.6), reduced: true),
    );
    await tester.pump();
    expect(shown(tester), 0.6);
  });

  testWidgets('o confete cai uma vez e some', (tester) async {
    await tester.pumpWidget(app(const Celebration()));
    await tester.pump(const Duration(milliseconds: 400));
    expect(
      find.descendant(
        of: find.byType(Celebration),
        matching: find.byType(CustomPaint),
      ),
      findsOneWidget,
    );
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byType(Celebration),
        matching: find.byType(CustomPaint),
      ),
      findsNothing,
    );
  });

  testWidgets('com "remover animações", sem confete', (tester) async {
    await tester.pumpWidget(app(const Celebration(), reduced: true));
    await tester.pump();
    expect(
      find.descendant(
        of: find.byType(Celebration),
        matching: find.byType(CustomPaint),
      ),
      findsNothing,
    );
  });
}

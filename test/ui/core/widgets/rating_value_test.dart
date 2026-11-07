import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/ui/core/widgets/rating_value.dart';

void main() {
  const valueKey = ValueKey('rating counter');
  Widget app(int value, {bool reduced = false, bool animate = true}) =>
      MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: reduced),
          child: RatingValue(
            rating: value,
            valueKey: valueKey,
            animateOnce: animate,
          ),
        ),
      );
  int shown(WidgetTester tester) =>
      int.parse(tester.widget<Text>(find.byKey(valueKey)).data!);

  testWidgets('opt-in counts once; reload/updated rating does not restart', (
    tester,
  ) async {
    await tester.pumpWidget(app(1200));
    expect(shown(tester), 0);
    await tester.pump(const Duration(milliseconds: 100));
    expect(shown(tester), inExclusiveRange(0, 1200));
    await tester.pumpAndSettle();
    expect(shown(tester), 1200);
    await tester.pumpWidget(app(1215));
    expect(shown(tester), 1215);
    await tester.pumpAndSettle();
    expect(shown(tester), 1215);
  });

  testWidgets('H-ANI-19: a variação conta junto, com a seta certa desde o '
      'início', (tester) async {
    const changeKey = ValueKey('rating change');
    Widget com(int change) => MaterialApp(
      home: RatingValue(
        rating: 1267,
        change: change,
        valueKey: valueKey,
        changeKey: changeKey,
        animateOnce: true,
      ),
    );
    String variacao() => tester
        .widgetList<Text>(
          find.descendant(
            of: find.byKey(changeKey),
            matching: find.byType(Text),
          ),
        )
        .map((t) => t.data)
        .join();

    await tester.pumpWidget(com(267));
    await tester.pump(const Duration(milliseconds: 100));
    expect(variacao(), isNot('+267'));
    expect(find.byIcon(Icons.arrow_drop_up), findsOneWidget);
    await tester.pumpAndSettle();
    expect(variacao(), '+267');

    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(com(-30));
    await tester.pump();
    expect(find.byIcon(Icons.arrow_drop_down), findsOneWidget);
    await tester.pumpAndSettle();
    expect(variacao(), signedChange(-30));
  });

  testWidgets(
    'reduced motion and callers without opt-in show final value immediately',
    (tester) async {
      await tester.pumpWidget(app(1200, reduced: true));
      expect(shown(tester), 1200);
      expect(tester.binding.transientCallbackCount, 0);
      await tester.pumpWidget(app(1300, animate: false));
      expect(shown(tester), 1300);
      expect(tester.takeException(), isNull);
    },
  );
}

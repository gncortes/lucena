import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/ui/core/widgets/exercise_actions.dart';

void main() {
  Future<void> pump(WidgetTester tester, double width) async {
    tester.view
      ..physicalSize = Size(width, 640)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: ExerciseActions(
            hug: true,
            hint: const SizedBox(width: 56, height: 56),
            actions: [
              ExerciseAction(
                label: 'Ver linha principal',
                onPressed: () {},
                key: const Key('a'),
              ),
              ExerciseAction(
                label: 'Continuar',
                onPressed: () {},
                key: const Key('b'),
                primary: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  testWidgets('hug: o rótulo longo fica numa linha quando cabe', (
    tester,
  ) async {
    await pump(tester, 700);
    final line = tester.getSize(find.text('Continuar')).height;
    expect(tester.getSize(find.text('Ver linha principal')).height, line);
    expect(
      tester.getSize(find.byKey(const Key('b'))).width,
      greaterThanOrEqualTo(ExerciseActions.actionWidth),
    );
  });

  testWidgets('hug: numa tela estreita, quebra sem estourar', (tester) async {
    await pump(tester, 300);
    expect(tester.takeException(), isNull);
  });

  testWidgets('hug: o principal sozinho, mais largo que a tela, quebra', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(220, 640)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: ExerciseActions(
            hug: true,
            leading: const SizedBox(width: 48, height: 48),
            actions: [
              ExerciseAction(
                label: 'Ver linha principal',
                onPressed: () {},
                key: const Key('b'),
                primary: true,
              ),
            ],
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
  });
}

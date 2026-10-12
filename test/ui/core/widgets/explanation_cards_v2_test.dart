import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/explanation.dart';
import 'package:lucena/ui/core/keys/explanation_keys.dart';
import 'package:lucena/ui/core/widgets/explanation_cards.dart';

import '../../../../testing/test_app.dart';

void main() {
  const fen = '6k1/8/8/8/8/8/3P4/7K w - - 0 1';
  ExplanationVariation root() => ExplanationVariation(
    id: 'A',
    label: 'A',
    outcome: VariationOutcome.accepted,
    texts: ['Root explanation.'],
    originFen: fen,
    movesUci: ['d2d4'],
    movesSan: ['1.d4'],
    validated: true,
  );
  ExplanationPayload payload(List<ExplanationVariation> variations) =>
      ExplanationPayload(
        positionId: 'tree',
        state: ExplanationState.review,
        explanations: [
          ExplanationBlock(
            id: 'solution',
            kind: ExplanationKind.mainSolution,
            variations: variations,
          ),
        ],
      );
  Widget app(
    ExplanationPayload data, {
    bool lessonV2 = true,
    VariationCursor? active,
    ValueChanged<VariationCursor?>? onVariation,
  }) => TestApp(
    child: Scaffold(
      body: SingleChildScrollView(
        child: ExplanationCards(
          payload: data,
          lessonV2: lessonV2,
          activeCursor: active,
          paragraph: (text) => Text(text),
          onVariation: onVariation ?? (_) {},
        ),
      ),
    ),
  );

  testWidgets(
    'V2 leaf explanation is visible before selection; legacy retains cards',
    (tester) async {
      final data = payload([root()]);
      await tester.pumpWidget(app(data, lessonV2: false));
      expect(find.byType(Card), findsOneWidget);
      await tester.pumpWidget(app(data));
      expect(find.byType(Card), findsNothing);
      expect(find.text('Root explanation.'), findsOneWidget);
      expect(find.byIcon(Icons.expand_more), findsNothing);
      expect(find.byKey(ExplanationKeys.restore), findsNothing);
      await tester.tap(find.byKey(ExplanationKeys.variation('A')));
      await tester.pumpAndSettle();
      expect(find.text('Root explanation.'), findsOneWidget);
      expect(find.byKey(ExplanationKeys.restore), findsNothing);
      expect(find.byKey(ExplanationKeys.first), findsNothing);
      expect(find.byKey(ExplanationKeys.last), findsNothing);
    },
  );

  testWidgets(
    'only the principal expands; descendants stay visible and keep their verified cursor',
    (tester) async {
      final main = root();
      final semantics = tester.ensureSemantics();
      final child = ExplanationVariation(
        id: 'A.1',
        label: 'A.1',
        parentId: 'A',
        parentPly: 1,
        outcome: VariationOutcome.accepted,
        texts: ['Child explanation.'],
        originFen: main.open()!.fen,
        movesUci: ['g8f7'],
        movesSan: ['1...Kf7'],
        validated: true,
      );
      final grandchild = ExplanationVariation(
        id: 'A.1.1',
        label: 'A.1.1',
        parentId: 'A.1',
        parentPly: 1,
        outcome: VariationOutcome.accepted,
        texts: ['Reply explanation.'],
        originFen: child.open()!.fen,
        movesUci: ['h1h2'],
        movesSan: ['2.Kh2'],
        validated: true,
      );
      final data = payload([main, child, grandchild]);
      VariationCursor? selected;
      await tester.pumpWidget(
        app(data, onVariation: (value) => selected = value),
      );
      expect(find.text('Root explanation.'), findsNothing);
      expect(find.text('Child explanation.'), findsNothing);
      expect(
        tester.getSemantics(find.byKey(ExplanationKeys.variation('A'))),
        isSemantics(hasExpandedState: true, isExpanded: false),
      );
      await tester.tap(find.byKey(ExplanationKeys.variation('A')));
      await tester.pumpAndSettle();
      expect(find.text('Root explanation.'), findsOneWidget);
      expect(
        tester.getSemantics(find.byKey(ExplanationKeys.variation('A'))),
        isSemantics(hasExpandedState: true, isExpanded: true),
      );
      expect(find.text('Child explanation.'), findsOneWidget);
      expect(find.text('Reply explanation.'), findsOneWidget);
      expect(find.byIcon(Icons.circle), findsNothing);
      expect(find.text('1...Kf7'), findsOneWidget);
      expect(find.byIcon(Icons.expand_less), findsOneWidget);
      expect(find.byIcon(Icons.expand_more), findsNothing);
      await tester.tap(find.byKey(ExplanationKeys.variation('A.1.1')));
      await tester.pumpAndSettle();
      expect(selected!.variation.id, 'A.1.1');
      expect(
        tester
            .getSemantics(find.byKey(ExplanationKeys.variation('A.1.1')))
            .label,
        contains('A.1.1'),
      );
      expect(selected!.fen, data.openVariation(grandchild)!.fen);
      expect(find.byKey(ExplanationKeys.restore), findsNothing);
      expect(find.byKey(ExplanationKeys.last), findsNothing);
      expect(find.text('Reply explanation.'), findsOneWidget);
      await tester.tap(find.byKey(ExplanationKeys.variation('A')));
      await tester.pumpAndSettle();
      expect(find.text('Child explanation.'), findsNothing);
      expect(
        tester.getSemantics(find.byKey(ExplanationKeys.variation('A'))),
        isSemantics(hasExpandedState: true, isExpanded: false),
      );
      expect(tester.takeException(), isNull);
      semantics.dispose();
    },
  );

  testWidgets('parent return and previous ply have distinct accessible names', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final main = root();
    final child = ExplanationVariation(
      id: 'A.1',
      label: 'A.1',
      parentId: 'A',
      parentPly: 1,
      outcome: VariationOutcome.accepted,
      texts: ['Child explanation.'],
      originFen: main.open()!.fen,
      movesUci: ['g8f7', 'h1h2'],
      movesSan: ['1...Kf7', '2.Kh2'],
      validated: true,
    );
    final data = payload([main, child]);
    VariationCursor? selected;
    await tester.pumpWidget(
      app(data, onVariation: (value) => selected = value),
    );
    await tester.tap(find.byKey(ExplanationKeys.variation('A')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(ExplanationKeys.variation('A.1')));
    await tester.pumpAndSettle();
    expect(
      tester.getSemantics(find.byKey(ExplanationKeys.parent)).label,
      contains('Return to parent variation'),
    );
    expect(
      tester
          .getSemantics(find.byKey(ExplanationKeys.previous))
          .getSemanticsData()
          .tooltip,
      contains('Previous move'),
    );
    await tester.tap(find.byKey(ExplanationKeys.next));
    await tester.pumpAndSettle();
    expect(selected!.fen, data.openVariation(child)!.at(2).fen);
    await tester.tap(find.byKey(ExplanationKeys.parent));
    await tester.pumpAndSettle();
    expect(selected!.fen, data.parentCursor(child)!.fen);
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });

  testWidgets(
    'V2 replay reaches every verified ply even when authored text has no SAN',
    (tester) async {
      final line = ExplanationVariation(
        id: 'A',
        label: 'A',
        outcome: VariationOutcome.accepted,
        texts: ['Advance the pawn, then bring the king.'],
        originFen: fen,
        movesUci: ['d2d4', 'g8f7', 'h1h2'],
        movesSan: ['1.d4', '1...Kf7', '2.Kh2'],
        validated: true,
      );
      VariationCursor? selected;
      await tester.pumpWidget(
        app(payload([line]), onVariation: (value) => selected = value),
      );
      await tester.tap(find.byKey(ExplanationKeys.variation('A')));
      await tester.pumpAndSettle();
      final verified = line.open()!;
      expect(selected!.fen, verified.at(1).fen);
      await tester.tap(find.byKey(ExplanationKeys.next));
      await tester.pumpAndSettle();
      expect(selected!.fen, verified.at(2).fen);
      await tester.tap(find.byKey(ExplanationKeys.last));
      await tester.pumpAndSettle();
      expect(selected!.fen, verified.at(3).fen);
      expect(
        tester.widget<IconButton>(find.byKey(ExplanationKeys.next)).onPressed,
        isNull,
      );
      await tester.tap(find.byKey(ExplanationKeys.previous));
      await tester.pumpAndSettle();
      expect(selected!.fen, verified.at(2).fen);
      await tester.tap(find.byKey(ExplanationKeys.first));
      await tester.pumpAndSettle();
      expect(selected!.fen, verified.at(0).fen);
      expect(
        tester
            .widget<IconButton>(find.byKey(ExplanationKeys.previous))
            .onPressed,
        isNull,
      );
    },
  );

  testWidgets(
    'external verified child reveals its principal; orphan remains hidden',
    (tester) async {
      final main = root();
      final child = ExplanationVariation(
        id: 'A.1',
        label: 'A.1',
        parentId: 'A',
        parentPly: 1,
        outcome: VariationOutcome.accepted,
        texts: ['Child explanation.'],
        originFen: main.open()!.fen,
        movesUci: ['g8f7'],
        movesSan: ['1...Kf7'],
        validated: true,
      );
      final orphan = ExplanationVariation(
        id: 'orphan',
        label: 'B.1',
        parentId: 'missing',
        parentPly: 0,
        outcome: VariationOutcome.accepted,
        texts: ['Orphan explanation.'],
        originFen: fen,
        movesUci: ['d2d4'],
        movesSan: ['1.d4'],
        validated: true,
      );
      final data = payload([main, child, orphan]);
      await tester.pumpWidget(app(data, active: data.openVariation(child)));
      expect(find.text('Child explanation.'), findsOneWidget);
      expect(find.text('Orphan explanation.'), findsNothing);
      expect(find.byKey(ExplanationKeys.variation('orphan')), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}

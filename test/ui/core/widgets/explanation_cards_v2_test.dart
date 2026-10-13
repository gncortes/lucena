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

  testWidgets('V2 has no parent button nor move bar under the line', (
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
    // Contrato 3.5: sem "Voltar à variante pai" nem barra de lances na V2;
    // a volta é o "Voltar" do rodapé da tela.
    expect(find.byKey(ExplanationKeys.parent), findsNothing);
    expect(find.byKey(ExplanationKeys.previous), findsNothing);
    expect(find.byKey(ExplanationKeys.next), findsNothing);
    expect(selected!.fen, data.openVariation(child)!.at(1).fen);
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });

  testWidgets('V2 opens the line at ply 1 without the move bar', (
    tester,
  ) async {
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
    for (final key in [
      ExplanationKeys.first,
      ExplanationKeys.previous,
      ExplanationKeys.next,
      ExplanationKeys.last,
    ]) {
      expect(find.byKey(key), findsNothing);
    }
  });

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

  testWidgets('V2 orders POSITION, CORRECT MOVE, THESE DO NOT WORK EITHER and '
      'colours the line by quality with the result label', (tester) async {
    ExplanationVariation line(
      String id,
      String label,
      String san,
      String uci,
      VariationOutcome outcome, {
      String? outcomeText,
    }) => ExplanationVariation(
      id: id,
      label: label,
      outcome: outcome,
      outcomeText: outcomeText,
      texts: ['Text $id.'],
      originFen: fen,
      movesUci: [uci],
      movesSan: [san],
      validated: true,
    );
    final data = ExplanationPayload(
      positionId: 'order',
      state: ExplanationState.review,
      explanations: [
        ExplanationBlock(
          id: 'f',
          kind: ExplanationKind.failedAlternatives,
          title: 'Tentativas que falham',
          variations: [
            line(
              'B',
              'B',
              '1.Kh2?',
              'h1h2',
              VariationOutcome.doesNotMeetGoal,
              outcomeText: 'Draws',
            ),
          ],
        ),
        ExplanationBlock(
          id: 'm',
          kind: ExplanationKind.mainSolution,
          variations: [
            line('A', 'A', '1.d4', 'd2d4', VariationOutcome.accepted),
          ],
        ),
        ExplanationBlock(
          id: 'c',
          kind: ExplanationKind.context,
          title: 'The position and the goal',
          texts: ['Goal text.'],
        ),
      ],
    );
    await tester.pumpWidget(app(data));
    await tester.pumpAndSettle();
    double top(String text) => tester.getTopLeft(find.text(text)).dy;
    expect(top('THE POSITION AND THE GOAL'), lessThan(top('CORRECT MOVE')));
    expect(top('CORRECT MOVE'), lessThan(top('THESE DO NOT WORK EITHER')));
    expect(find.text('TENTATIVAS QUE FALHAM'), findsNothing);
    // The failing line: quality colour (mistake, not primary) and result.
    final theme = Theme.of(tester.element(find.byType(ExplanationCards)));
    final wrong = tester.widget<Text>(find.text('1.Kh2?'));
    expect(wrong.style?.color, isNot(theme.colorScheme.primary));
    expect(wrong.style?.fontWeight, FontWeight.w700);
    expect(find.text('DRAWS'), findsOneWidget);
    // The correct line has no result label (accepted, as the section).
    final right = tester.widget<Text>(find.text('1.d4'));
    expect(right.style?.color, theme.colorScheme.primary);
    expect(find.text('ACCEPTED'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

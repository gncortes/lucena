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
        tester.getSemantics(find.byKey(ExplanationKeys.expand('A'))),
        isSemantics(hasExpandedState: true, isExpanded: false),
      );
      await tester.tap(find.byKey(ExplanationKeys.expand('A')));
      await tester.pumpAndSettle();
      expect(find.text('Root explanation.'), findsOneWidget);
      expect(
        tester.getSemantics(find.byKey(ExplanationKeys.expand('A'))),
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
      await tester.tap(find.byKey(ExplanationKeys.expand('A')));
      await tester.pumpAndSettle();
      expect(find.text('Child explanation.'), findsNothing);
      expect(
        tester.getSemantics(find.byKey(ExplanationKeys.expand('A'))),
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
    await tester.tap(find.byKey(ExplanationKeys.expand('A')));
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

  testWidgets(
    'V2 orders CORRECT MOVE, quote, THESE DO NOT WORK EITHER; no result label',
    (tester) async {
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
            texts: ['Goal text. {{Euwe|max-euwe}}'],
          ),
        ],
      );
      await tester.pumpWidget(app(data));
      await tester.pumpAndSettle();
      double top(String text) =>
          tester.getTopLeft(find.textContaining(text)).dy;
      // Contexto sem rótulo: a citação vem depois do certo e antes de "Também
      // não funcionam"; o título "A posição e o objetivo" não aparece.
      expect(find.text('THE POSITION AND THE GOAL'), findsNothing);
      expect(find.byKey(ExplanationKeys.quote('c')), findsOneWidget);
      expect(top('CORRECT MOVE'), lessThan(top('Goal text.')));
      expect(top('Goal text.'), lessThan(top('THESE DO NOT WORK EITHER')));
      expect(find.text('TENTATIVAS QUE FALHAM'), findsNothing);
      // Linha que falha: lance primary peso 500, sem selo de resultado.
      final theme = Theme.of(tester.element(find.byType(ExplanationCards)));
      final wrong = tester.widget<Text>(find.text('1.Kh2?'));
      expect(wrong.style?.color, theme.colorScheme.primary);
      expect(wrong.style?.fontWeight, FontWeight.w500);
      expect(find.text('DRAWS'), findsNothing);
      // Variante única: nem "A)" nem "B)".
      expect(find.textContaining(') '), findsNothing);
      final right = tester.widget<Text>(find.text('1.d4'));
      expect(right.style?.color, theme.colorScheme.primary);
      expect(find.text('ACCEPTED'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  ExplanationVariation line(
    String id,
    String san,
    String uci, {
    String? parent,
    int parentPly = 0,
    String? origin,
  }) => ExplanationVariation(
    id: id,
    label: id,
    parentId: parent,
    parentPly: parentPly,
    outcome: VariationOutcome.accepted,
    texts: ['Text $id.'],
    originFen: origin ?? fen,
    movesUci: [uci],
    movesSan: [san],
    validated: true,
  );

  testWidgets('wrong move: error, correct, quote, then the failures', (
    tester,
  ) async {
    final data = ExplanationPayload(
      positionId: 'wrong',
      state: ExplanationState.incorrect,
      explanations: [
        ExplanationBlock(
          id: 'f',
          kind: ExplanationKind.failedAlternatives,
          variations: [line('B', '1.Kh2?', 'h1h2')],
        ),
        ExplanationBlock(
          id: 'c',
          kind: ExplanationKind.context,
          title: 'History',
          texts: ['Story text. {{Euwe|max-euwe}}'],
        ),
        ExplanationBlock(
          id: 'm',
          kind: ExplanationKind.mainSolution,
          texts: ['Right text.'],
          variations: [line('A', '1.d4', 'd2d4')],
        ),
        ExplanationBlock(
          id: 'e',
          kind: ExplanationKind.playedIncorrect,
          texts: ['Wrong text.'],
        ),
      ],
    );
    await tester.pumpWidget(app(data));
    await tester.pumpAndSettle();
    double top(String text) => tester.getTopLeft(find.textContaining(text)).dy;
    expect(top('Wrong text.'), lessThan(top('Right text.')));
    expect(top('Right text.'), lessThan(top('Story text.')));
    expect(top('Story text.'), lessThan(top('THESE DO NOT WORK EITHER')));
    expect(find.text('HISTORY'), findsNothing);
    expect(find.textContaining('A)'), findsNothing);
    expect(find.byType(Divider), findsNWidgets(3));
  });

  testWidgets('solution seen: payload order is kept and the quote goes last', (
    tester,
  ) async {
    final data = ExplanationPayload(
      positionId: 'seen',
      state: ExplanationState.incorrect,
      explanations: [
        ExplanationBlock(
          id: 'm',
          kind: ExplanationKind.mainSolution,
          texts: ['Right text.'],
          variations: [line('A', '1.d4', 'd2d4')],
        ),
        ExplanationBlock(
          id: 'e',
          kind: ExplanationKind.playedIncorrect,
          texts: ['Wrong text.'],
        ),
        ExplanationBlock(
          id: 'f',
          kind: ExplanationKind.failedAlternatives,
          variations: [line('B', '1.Kh2?', 'h1h2')],
        ),
        ExplanationBlock(
          id: 'c',
          kind: ExplanationKind.context,
          title: 'History',
          texts: ['Story text. {{Euwe|max-euwe}}'],
        ),
      ],
    );
    await tester.pumpWidget(app(data));
    await tester.pumpAndSettle();
    double top(String text) => tester.getTopLeft(find.textContaining(text)).dy;
    expect(top('Right text.'), lessThan(top('Wrong text.')));
    expect(top('Wrong text.'), lessThan(top('THESE DO NOT WORK EITHER')));
    expect(top('THESE DO NOT WORK EITHER'), lessThan(top('Story text.')));
  });

  testWidgets('no loose move line when the move is already a link; the '
      'chevron sits in the paragraph and the label stays silent', (
    tester,
  ) async {
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
    final data = ExplanationPayload(
      positionId: 'inline',
      state: ExplanationState.review,
      explanations: [
        ExplanationBlock(
          id: 'solution',
          kind: ExplanationKind.mainSolution,
          texts: ['1.d4 wins.'],
          variations: [main, child],
        ),
      ],
    );
    await tester.pumpWidget(
      TestApp(
        child: Scaffold(
          body: SingleChildScrollView(
            child: ExplanationCards(
              payload: data,
              lessonV2: true,
              paragraph: (text) => Text(text),
              hasInlineNavigation: (_, _, _) => true,
              onVariation: (_) {},
            ),
          ),
        ),
      ),
    );
    expect(find.byKey(ExplanationKeys.variation('A')), findsNothing);
    final paragraph = tester.getRect(
      find.byKey(ExplanationKeys.paragraph('solution', 0)),
    );
    final chevron = tester.getRect(find.byKey(ExplanationKeys.expand('A')));
    expect(chevron.size, const Size(48, 48));
    expect(chevron.top, closeTo(paragraph.top, 1));
    expect(chevron.right, closeTo(paragraph.right, 1));
  });

  testWidgets('quote: 3 dp start bar, 12 dp padding, 14/20 muted text', (
    tester,
  ) async {
    final data = ExplanationPayload(
      positionId: 'q',
      state: ExplanationState.review,
      explanations: [
        ExplanationBlock(
          id: 'c',
          kind: ExplanationKind.context,
          title: 'History',
          texts: ['Story text. {{Euwe|max-euwe}}'],
        ),
      ],
    );
    await tester.pumpWidget(app(data));
    final theme = Theme.of(tester.element(find.byType(ExplanationCards)));
    final box = tester.widget<Container>(
      find.byKey(ExplanationKeys.quote('c')),
    );
    final decoration = box.decoration! as BoxDecoration;
    final border = decoration.border! as BorderDirectional;
    expect(border.start.width, 3);
    expect(border.start.color, theme.colorScheme.outlineVariant);
    expect(border.end, BorderSide.none);
    expect(
      tester.getTopLeft(find.textContaining('Story text.')).dx -
          tester.getTopLeft(find.byKey(ExplanationKeys.quote('c'))).dx,
      closeTo(15, 1), // 3 dp bar + 12 dp padding
    );
    final style = tester
        .widget<Text>(find.textContaining('Story text.'))
        .style!;
    expect(style.fontSize, 14);
    expect(style.height! * style.fontSize!, closeTo(20, .1));
    expect(style.color, theme.colorScheme.onSurfaceVariant);
  });

  testWidgets('the chevron only expands; the blue move calls onVariation', (
    tester,
  ) async {
    final main = root();
    final child = line(
      'A.1',
      '1...Kf7',
      'g8f7',
      parent: 'A',
      parentPly: 1,
      origin: main.open()!.fen,
    );
    final calls = <VariationCursor?>[];
    await tester.pumpWidget(
      app(payload([main, child]), onVariation: calls.add),
    );
    final chevron = tester.getRect(find.byKey(ExplanationKeys.expand('A')));
    expect(chevron.width, greaterThanOrEqualTo(48));
    expect(chevron.height, greaterThanOrEqualTo(48));
    await tester.tap(find.byKey(ExplanationKeys.expand('A')));
    await tester.pumpAndSettle();
    expect(calls, isEmpty);
    expect(find.text('Child explanation.'), findsNothing);
    expect(find.text('Text A.1.'), findsOneWidget);
    await tester.tap(find.byKey(ExplanationKeys.variation('A')));
    await tester.pumpAndSettle();
    expect(calls, hasLength(1));
    // Tocar no lance não recolhe.
    expect(find.text('Text A.1.'), findsOneWidget);
    await tester.tap(find.byKey(ExplanationKeys.expand('A')));
    await tester.pumpAndSettle();
    expect(find.text('Text A.1.'), findsNothing);
  });

  testWidgets('the letter shows only with two or more choices', (tester) async {
    await tester.pumpWidget(app(payload([root()])));
    expect(find.textContaining('A) '), findsNothing);
    final b = line('B', '1.Kh2', 'h1h2');
    await tester.pumpWidget(app(payload([root(), b])));
    await tester.pumpAndSettle();
    expect(find.text('A) '), findsOneWidget);
    expect(find.text('B) '), findsOneWidget);
  });

  testWidgets('expanding a card keeps the scroll offset', (tester) async {
    final main = root();
    final child = line(
      'A.1',
      '1...Kf7',
      'g8f7',
      parent: 'A',
      parentPly: 1,
      origin: main.open()!.fen,
    );
    final controller = ScrollController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      TestApp(
        child: Scaffold(
          body: SingleChildScrollView(
            controller: controller,
            child: Column(
              children: [
                const SizedBox(height: 40),
                ExplanationCards(
                  payload: payload([main, child]),
                  lessonV2: true,
                  paragraph: (text) => Text(text),
                  onVariation: (_) {},
                ),
                const SizedBox(height: 2000),
              ],
            ),
          ),
        ),
      ),
    );
    controller.jumpTo(30);
    await tester.pump();
    await tester.tap(find.byKey(ExplanationKeys.expand('A')));
    await tester.pumpAndSettle();
    expect(controller.offset, 30);
  });

  testWidgets('citação: só a história; objetivo e ensino ficam fora dela, '
      'sem rótulo "A ideia principal"', (tester) async {
    ExplanationPayload data(ExplanationState state) => ExplanationPayload(
      positionId: 'q',
      state: state,
      explanations: [
        ExplanationBlock(
          id: 'c',
          kind: ExplanationKind.context,
          title: 'A posição e o objetivo',
          texts: [
            'Goal text.',
            'In 1928, {{Max Euwe|max-euwe}} played.',
            'Teaching text.',
          ],
        ),
        ExplanationBlock(
          id: 'm',
          kind: ExplanationKind.mainSolution,
          title: 'A ideia principal',
          texts: ['Right text.'],
          variations: [line('A', '1.d4', 'd2d4')],
        ),
      ],
    );
    await tester.pumpWidget(app(data(ExplanationState.review)));
    await tester.pumpAndSettle();
    final quote = find.byKey(ExplanationKeys.quote('c'));
    expect(quote, findsOneWidget);
    expect(
      find.descendant(of: quote, matching: find.textContaining('1928')),
      findsOneWidget,
    );
    for (final out in ['Goal text.', 'Teaching text.']) {
      expect(find.textContaining(out), findsOneWidget);
      expect(
        find.descendant(of: quote, matching: find.textContaining(out)),
        findsNothing,
      );
    }
    expect(find.text('A IDEIA PRINCIPAL'), findsNothing);
    // Depois do lance do aluno, só a história aparece (o objetivo não repete).
    await tester.pumpWidget(app(data(ExplanationState.correct)));
    await tester.pumpAndSettle();
    expect(find.textContaining('Goal text.'), findsNothing);
    expect(find.textContaining('Teaching text.'), findsNothing);
    expect(find.textContaining('1928'), findsOneWidget);
  });
}

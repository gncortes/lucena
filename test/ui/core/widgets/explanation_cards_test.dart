import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/explanation.dart';
import 'package:lucena/ui/core/keys/explanation_keys.dart';
import 'package:lucena/ui/core/widgets/explanation_cards.dart';

import '../../../../testing/test_app.dart';

void main() {
  const fen = '6k1/8/8/8/8/8/3P4/7K w - - 0 1';
  testWidgets(
    'B is above one joined body and navigation adds no duplicate bubble',
    (tester) async {
      final variation = ExplanationVariation(
        id: 'B',
        label: 'B',
        outcome: VariationOutcome.accepted,
        texts: ['First paragraph.', 'Second paragraph.'],
        originFen: fen,
        movesUci: ['d2d4', 'g8f7'],
        movesSan: ['1.d4', '1...Kf7'],
        explanationByPly: const {
          2: ['Specific reply.'],
        },
        validated: true,
      );
      await tester.pumpWidget(
        TestApp(
          child: Scaffold(
            body: SingleChildScrollView(
              child: ExplanationCards(
                payload: ExplanationPayload(
                  positionId: 'p',
                  state: ExplanationState.review,
                  explanations: [
                    ExplanationBlock(
                      id: 'b',
                      kind: ExplanationKind.otherSolutions,
                      texts: ['First paragraph.', 'Second paragraph.'],
                      variations: [variation],
                    ),
                  ],
                ),
                paragraph: (text) => Text(text),
                onVariation: (_) {},
              ),
            ),
          ),
        ),
      );
      final body = find.byKey(ExplanationKeys.paragraph('b', 0));
      expect(
        tester.getBottomLeft(find.byKey(ExplanationKeys.variation('B'))).dy,
        lessThanOrEqualTo(tester.getTopLeft(body).dy),
      );
      expect(
        find.text('First paragraph.\n\nSecond paragraph.'),
        findsOneWidget,
      );
      await tester.tap(find.byKey(ExplanationKeys.variation('B')));
      await tester.pumpAndSettle();
      expect(
        find.text('First paragraph.\n\nSecond paragraph.'),
        findsOneWidget,
      );
      await tester.tap(find.byKey(ExplanationKeys.next));
      await tester.pumpAndSettle();
      expect(body, findsOneWidget);
      expect(
        find.text('First paragraph.\n\nSecond paragraph.\n\nSpecific reply.'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );
  ExplanationVariation line(
    String id,
    List<String> moves, {
    bool validated = true,
  }) => ExplanationVariation(
    id: id,
    label: '1.d4 1...Kf7 $id',
    outcome: VariationOutcome.accepted,
    texts: ['$id explanation.'],
    originFen: fen,
    movesUci: moves,
    movesSan: moves,
    validated: validated,
  );
  testWidgets('external cursor cannot bypass an orphan ancestry', (
    tester,
  ) async {
    final orphan = ExplanationVariation(
      id: 'orphan',
      label: 'A.1',
      parentId: 'missing',
      parentPly: 0,
      outcome: VariationOutcome.accepted,
      texts: ['Hidden branch.'],
      originFen: fen,
      movesUci: ['d2d4'],
      movesSan: ['1.d4'],
      validated: true,
    );
    await tester.pumpWidget(
      TestApp(
        child: Scaffold(
          body: ExplanationCards(
            payload: ExplanationPayload(
              positionId: 'p',
              state: ExplanationState.review,
              explanations: [
                ExplanationBlock(
                  id: 'tree',
                  kind: ExplanationKind.mainSolution,
                  variations: [orphan],
                ),
              ],
            ),
            activeCursor: orphan.open(),
            paragraph: (text) => Text(text),
            onVariation: (_) {},
          ),
        ),
      ),
    );
    expect(find.text('Hidden branch.'), findsNothing);
    expect(find.byKey(ExplanationKeys.restore), findsNothing);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'selective children return to parent divergence and original board',
    (tester) async {
      final root = line('A', ['d2d4', 'g8f7']);
      final child = ExplanationVariation(
        id: 'A.1',
        label: 'A.1',
        parentId: 'A',
        parentPly: 1,
        outcome: VariationOutcome.accepted,
        texts: ['Child.'],
        originFen: root.open()!.fen,
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
        texts: ['Grandchild.'],
        originFen: child.open()!.fen,
        movesUci: ['h1h2'],
        movesSan: ['2.Kh2'],
        validated: true,
      );
      VariationCursor? cursor;
      final events = <VariationCursor?>[];
      await tester.pumpWidget(
        TestApp(
          child: Scaffold(
            body: SingleChildScrollView(
              child: ExplanationCards(
                payload: ExplanationPayload(
                  positionId: 'p',
                  state: ExplanationState.review,
                  explanations: [
                    ExplanationBlock(
                      id: 'tree',
                      kind: ExplanationKind.mainSolution,
                      variations: [root, child, grandchild],
                    ),
                  ],
                ),
                paragraph: (text) => Text(text),
                onVariation: (value) {
                  cursor = value;
                  events.add(value);
                },
              ),
            ),
          ),
        ),
      );
      expect(find.byKey(ExplanationKeys.variation('A.1')), findsNothing);
      await tester.tap(find.byKey(ExplanationKeys.variation('A')));
      await tester.pumpAndSettle();
      expect(find.byKey(ExplanationKeys.variation('A.1.1')), findsNothing);
      await tester.tap(find.byKey(ExplanationKeys.variation('A.1')));
      await tester.pumpAndSettle();
      expect(cursor!.variation.id, 'A.1');
      await tester.tap(find.byKey(ExplanationKeys.variation('A.1.1')));
      await tester.pumpAndSettle();
      expect(cursor!.variation.id, 'A.1.1');
      await tester.tap(find.byKey(ExplanationKeys.parent));
      await tester.pumpAndSettle();
      expect(cursor!.variation.id, 'A.1');
      expect(cursor!.fen, grandchild.originFen);
      await tester.tap(find.byKey(ExplanationKeys.parent));
      await tester.pumpAndSettle();
      expect(cursor!.variation.id, 'A');
      expect(cursor!.fen, child.originFen);
      // T73 (D1): "Voltar à posição" com o ícone de desfazer.
      expect(
        find.descendant(
          of: find.byKey(ExplanationKeys.restore),
          matching: find.byIcon(Icons.undo),
        ),
        findsOneWidget,
      );
      await tester.tap(find.byKey(ExplanationKeys.restore));
      await tester.pumpAndSettle();
      expect(cursor, isNull);
      expect(events.length, 6);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'authored prior-attempt consequence replaces outcome in badge and semantics',
    (tester) async {
      final semantics = tester.ensureSemantics();
      const consequence =
          'Refutation of the previous attempt: Black loses against correct play.';
      final variation = ExplanationVariation.fromJson({
        'id': 'reply',
        'label': '1.d4',
        'outcome': 'losing',
        'outcomeText': consequence,
        'texts': ['The reply keeps the win.'],
        'originFen': fen,
        'movesUci': ['d2d4'],
        'movesSan': ['1.d4'],
        'validated': true,
      });
      await tester.pumpWidget(
        TestApp(
          child: Scaffold(
            body: ExplanationCards(
              payload: ExplanationPayload(
                positionId: 'refutation',
                state: ExplanationState.review,
                explanations: [
                  ExplanationBlock(
                    id: 'refutation',
                    kind: ExplanationKind.mainSolution,
                    title: 'Why the previous attempt fails',
                    variations: [variation],
                  ),
                ],
              ),
              paragraph: (text) => Text(text),
              onVariation: (_) {},
            ),
          ),
        ),
      );
      expect(
        find.bySemanticsLabel(
          RegExp('1.d4, Refutation of the previous attempt:'),
        ),
        findsOneWidget,
      );
      await tester.tap(find.byKey(ExplanationKeys.variation('reply')));
      await tester.pumpAndSettle();
      expect(find.text(consequence), findsOneWidget);
      expect(find.text('Why the previous attempt fails'), findsOneWidget);
      expect(find.text('Loses'), findsNothing);
      semantics.dispose();
    },
  );

  testWidgets(
    'narrow enlarged paragraphs, wrap, accessible controls and unavailable line',
    (tester) async {
      tester.view.physicalSize = const Size(320, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      VariationCursor? cursor;
      final payload = ExplanationPayload(
        positionId: 'p',
        state: ExplanationState.review,
        explanations: [
          ExplanationBlock(
            id: 'context',
            kind: ExplanationKind.context,
            texts: ['First paragraph.', 'Second paragraph.'],
            variations: [
              line('main', ['d2d4', 'g8f7']),
              line('branch', ['d2d3']),
              line('invalid', ['d2d4', 'g8g6']),
            ],
          ),
        ],
      );
      await tester.pumpWidget(
        TestApp(
          child: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(1.8)),
            child: Scaffold(
              body: SingleChildScrollView(
                child: ExplanationCards(
                  payload: payload,
                  paragraph: (text) => Text(text),
                  onVariation: (value) => cursor = value,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.text('First paragraph.\n\nSecond paragraph.'),
        findsOneWidget,
      );
      final button = find.byKey(ExplanationKeys.variation('main'));
      expect(tester.getSize(button).height, greaterThanOrEqualTo(44));
      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(cursor!.ply, 1);
      await tester.ensureVisible(find.byKey(ExplanationKeys.last));
      await tester.tap(find.byKey(ExplanationKeys.last));
      await tester.pumpAndSettle();
      expect(cursor!.canNext, isFalse);
      expect(
        tester.widget<IconButton>(find.byKey(ExplanationKeys.next)).onPressed,
        isNull,
      );
      await tester.ensureVisible(find.byKey(ExplanationKeys.first));
      await tester.tap(find.byKey(ExplanationKeys.first));
      await tester.pumpAndSettle();
      expect(cursor!.fen, fen);
      expect(
        tester
            .widget<IconButton>(find.byKey(ExplanationKeys.previous))
            .onPressed,
        isNull,
      );
      await tester.ensureVisible(
        find.byKey(ExplanationKeys.variation('branch')),
      );
      await tester.tap(find.byKey(ExplanationKeys.variation('branch')));
      await tester.pumpAndSettle();
      expect(cursor!.ply, 1);
      expect(cursor!.fens.first, fen);
      expect(find.byKey(ExplanationKeys.next), findsNothing);
      final branchFen = cursor!.fen;
      await tester.tap(find.byKey(ExplanationKeys.variation('invalid')));
      await tester.pumpAndSettle();
      expect(find.byKey(ExplanationKeys.unavailable), findsOneWidget);
      expect(cursor!.fen, branchFen);
      await tester.ensureVisible(find.byKey(ExplanationKeys.restore));
      await tester.tap(find.byKey(ExplanationKeys.restore));
      await tester.pumpAndSettle();
      expect(cursor, isNull);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'parent rebuild keeps selected branch and navigation, return clears it',
    (tester) async {
      VariationCursor? cursor;
      late StateSetter rebuild;
      await tester.pumpWidget(
        TestApp(
          child: StatefulBuilder(
            builder: (context, setState) {
              rebuild = setState;
              return Scaffold(
                body: SingleChildScrollView(
                  child: ExplanationCards(
                    payload: ExplanationPayload(
                      positionId: 'p',
                      state: ExplanationState.review,
                      explanations: [
                        ExplanationBlock(
                          id: 'main',
                          kind: ExplanationKind.mainSolution,
                          variations: [
                            line('main', ['d2d4', 'g8f7']),
                          ],
                        ),
                      ],
                    ),
                    activeCursor: cursor,
                    paragraph: (text) => Text(text),
                    onVariation: (value) => setState(() => cursor = value),
                  ),
                ),
              );
            },
          ),
        ),
      );
      await tester.tap(find.byKey(ExplanationKeys.variation('main')));
      await tester.pumpAndSettle();
      expect(cursor!.ply, 1);
      expect(find.byKey(ExplanationKeys.next), findsOneWidget);
      rebuild(() {});
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(ExplanationKeys.next));
      await tester.pumpAndSettle();
      expect(cursor!.ply, 2);
      await tester.tap(find.byKey(ExplanationKeys.restore));
      await tester.pumpAndSettle();
      expect(cursor, isNull);
      expect(find.byKey(ExplanationKeys.next), findsNothing);
    },
  );
}

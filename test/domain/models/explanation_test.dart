import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/explanation.dart';

void main() {
  test('optional review target survives JSON and every presentation state', () {
    final payload = ExplanationPayload.fromJson({
      'positionId': 'move/test.2',
      'reviewStepId': 'intro',
      'explanations': [],
    });
    for (final state in ExplanationState.values) {
      expect(payload.forState(state).reviewStepId, 'intro');
    }
    expect(ExplanationPayload.context(['legacy']).reviewStepId, isNull);
  });
  const fen = '6k1/8/8/8/8/8/3P4/7K w - - 0 1';
  ExplanationVariation variation(
    String id,
    List<String> moves, {
    bool validated = true,
    VariationOutcome outcome = VariationOutcome.accepted,
    String origin = fen,
    String? parentId,
    int? parentPly,
    String? contextId,
  }) => ExplanationVariation(
    id: id,
    label: id,
    outcome: outcome,
    texts: ['$id paragraph one', '$id paragraph two'],
    originFen: origin,
    parentId: parentId,
    parentPly: parentPly,
    contextId: contextId,
    movesUci: moves,
    movesSan: [for (final move in moves) move],
    validated: validated,
    explanationByPly: {
      2: ['Second ply.'],
    },
  );

  test(
    'tree preserves sibling replies and selected branches in both states',
    () {
      final root = variation('A', ['d2d4', 'g8f7']);
      final childFen = root.open()!.at(1).fen;
      final nodes = [
        root,
        variation(
          'A.1',
          ['g8f7'],
          origin: childFen,
          parentId: 'A',
          parentPly: 1,
        ),
        variation(
          'A.2',
          ['g8f7', 'h1h2'],
          origin: childFen,
          parentId: 'A',
          parentPly: 1,
        ),
      ];
      ExplanationPayload tree(ExplanationKind kind) => ExplanationPayload(
        positionId: 'p',
        state: ExplanationState.review,
        explanations: [
          ExplanationBlock(id: 'tree', kind: kind, variations: nodes),
        ],
      );
      final source = tree(ExplanationKind.mainSolution);
      expect(source.childrenOf(root).map((v) => v.id), ['A.1', 'A.2']);
      expect(source.openVariation(nodes.last), isNotNull);
      expect(source.parentCursor(nodes.last)!.fen, childFen);
      for (final state in [ExplanationState.review, ExplanationState.correct]) {
        final selected = source.forState(state, playedUci: 'd2d4');
        expect(selected.variations.map((v) => v.id), ['A', 'A.1', 'A.2']);
        expect(selected.openVariation(selected.variations.last), isNotNull);
      }
      final rejected = tree(ExplanationKind.failedAlternatives)
          .forState(ExplanationState.incorrect, playedUci: 'd2d4');
      expect(rejected.variations.map((v) => v.id), ['A', 'A.1', 'A.2']);
      expect(source.forState(ExplanationState.intro).variations, isEmpty);
    },
  );

  test('ancestry rejects orphan, cycles, wrong full FEN, context and illegal parent', () {
    final root = variation('A', ['d2d4']);
    final childFen = root.open()!.fen;
    ExplanationPayload tree(List<ExplanationVariation> nodes) =>
        ExplanationPayload(
          positionId: 'p',
          state: ExplanationState.review,
          explanations: [
            ExplanationBlock(
              id: 'tree',
              kind: ExplanationKind.mainSolution,
              variations: nodes,
            ),
          ],
        );
    for (final child in [
      variation(
        'c',
        ['g8f7'],
        origin: childFen,
        parentId: 'missing',
        parentPly: 1,
      ),
      variation('c', ['g8f7'], origin: childFen, parentId: 'A', parentPly: 2),
      variation(
        'c',
        ['g8f7'],
        origin: childFen.replaceFirst('0 1', '1 1'),
        parentId: 'A',
        parentPly: 1,
      ),
      variation(
        'c',
        ['g8f7'],
        origin: childFen,
        parentId: 'A',
        parentPly: 1,
        contextId: 'other',
      ),
    ]) {
      final payload = tree([root, child]);
      expect(payload.openVariation(child), isNull);
      expect(payload.cursorForNotation('g8f7', preferred: child), isNull);
    }
    final a = variation('a', ['d2d4'], parentId: 'b', parentPly: 0);
    final b = variation('b', ['d2d4'], parentId: 'a', parentPly: 0);
    expect(tree([a, b]).openVariation(a), isNull);
    final illegal = variation('A', ['d2d4', 'g8g6']);
    final child = variation(
      'c',
      ['g8f7'],
      origin: childFen,
      parentId: 'A',
      parentPly: 1,
    );
    expect(tree([illegal, child]).openVariation(child), isNull);
    expect(tree([root, root, child]).openVariation(child), isNull);
    expect(
      tree([root, root, child]).forState(ExplanationState.review).variations,
      isEmpty,
    );
  });

  test('equal transposed origins retain distinct identities without inferred edges', () {
    final a = variation('A', ['h1g1', 'g8f8', 'g1h1', 'f8g8'], contextId: 'p');
    final b = variation('B', ['h1h2', 'g8h8', 'h2h1', 'h8g8'], contextId: 'p');
    final payload = ExplanationPayload(
      positionId: 'p',
      state: ExplanationState.review,
      explanations: [
        ExplanationBlock(
          id: 'b',
          kind: ExplanationKind.otherSolutions,
          variations: [a, b],
        ),
      ],
    );
    final review = payload.forState(ExplanationState.review);
    expect(review.variations.map((v) => v.id), ['A', 'B']);
    expect(
      review.openVariation(a)!.at(4).fen,
      review.openVariation(b)!.at(4).fen,
    );
    expect(review.parentCursor(b), isNull);
  });

  test('whole replay precedes first move; unverified, illegal tail, SAN mismatch fail', () {
    expect(variation('unverified', ['d2d4'], validated: false).open(), isNull);
    expect(variation('illegal-tail', ['d2d4', 'g8g6']).open(), isNull);
    expect(variation('bad-origin', ['d2d4'], origin: 'invalid').open(), isNull);
    final incomplete = ExplanationVariation(
      id: 'missing-san',
      label: 'missing',
      outcome: VariationOutcome.accepted,
      texts: const [],
      originFen: fen,
      movesUci: const ['d2d4'],
      movesSan: const [],
      validated: true,
    );
    expect(incomplete.open(), isNull);
  });
  test('numbered notation uses verified authored origin and selected ply', () {
    final line = ExplanationVariation(
      id: 'main',
      label: '1.d4',
      outcome: VariationOutcome.accepted,
      texts: ['Explanation.'],
      originFen: fen,
      movesUci: ['d2d4', 'g8f7'],
      movesSan: ['1.d4', '1...Kf7'],
      validated: true,
    );
    final payload = ExplanationPayload(
      positionId: 'p',
      state: ExplanationState.review,
      explanations: [
        ExplanationBlock(
          id: 'main',
          kind: ExplanationKind.mainSolution,
          variations: [line],
        ),
      ],
    );
    expect(payload.cursorForNotation('1...Kf7!')!.ply, 2);
    expect(payload.cursorForNotation('Kf7')!.fen, line.open()!.at(2).fen);
    expect(payload.cursorForNotation('2...Kf7'), isNull);
    expect(payload.cursorForNotation('1.d3'), isNull);
  });

  test('first tap, limits, first/last, explanation per ply and switch start at own origin', () {
    final first = variation('main', ['d2d4', 'g8f7']).open()!;
    expect(first.ply, 1);
    expect(first.fen, contains('3P4/8/8/7K b'));
    expect(first.at(0).fen, fen);
    expect(first.at(-100).canPrevious, isFalse);
    expect(first.at(100).canNext, isFalse);
    expect(first.next().texts, ['Second ply.']);
    expect(first.previous().texts, [
      'main paragraph one',
      'main paragraph two',
    ]);
    final branch = variation('alternative', ['d2d3']).open()!;
    expect(branch.ply, 1);
    expect(branch.fens.first, fen);
    expect(branch.fen, isNot(first.next().fen));
    expect(first.fens.first, fen);
  });

  ExplanationPayload payload() => ExplanationPayload(
    positionId: 'lesson/position',
    state: ExplanationState.review,
    explanations: [
      ExplanationBlock(
        id: 'context',
        kind: ExplanationKind.context,
        texts: ['Context.', 'Goal.'],
      ),
      ExplanationBlock(
        id: 'main',
        kind: ExplanationKind.mainSolution,
        variations: [
          variation('main', ['d2d4']),
        ],
      ),
      ExplanationBlock(
        id: 'other',
        kind: ExplanationKind.otherSolutions,
        variations: [
          variation('duplicate-main', ['d2d4']),
          variation('alternative', ['d2d3']),
        ],
      ),
      ExplanationBlock(
        id: 'failed',
        kind: ExplanationKind.failedAlternatives,
        variations: [
          variation('failed', [
            'h1h2',
          ], outcome: VariationOutcome.doesNotMeetGoal),
        ],
      ),
      ExplanationBlock(id: 'empty', kind: ExplanationKind.context),
    ],
  );

  test(
    'arrays stay arrays; intro conceals solutions; empty blocks omitted',
    () {
      final intro = payload().forState(ExplanationState.intro);
      expect(intro.explanations.map((b) => b.id), ['context']);
      expect(intro.explanations.single.texts, ['Context.', 'Goal.']);
      expect(
        () => intro.explanations.single.texts.add('mutate'),
        throwsUnsupportedError,
      );
    },
  );

  test('incorrect played move first, specific reason, objective retained and dedup', () {
    final incorrect = payload().forState(
      ExplanationState.incorrect,
      playedUci: 'h1h2',
    );
    expect(incorrect.explanations.first.kind, ExplanationKind.playedIncorrect);
    expect(incorrect.explanations.first.texts, [
      'failed paragraph one',
      'failed paragraph two',
    ]);
    expect(
      incorrect.explanations.first.variations.single.outcome,
      VariationOutcome.doesNotMeetGoal,
    );
    final other = incorrect.explanations.singleWhere(
      (b) => b.kind == ExplanationKind.otherSolutions,
    );
    expect(other.variations.map((v) => v.firstUci), ['d2d3']);
    expect(
      incorrect.explanations.where(
        (b) => b.kind == ExplanationKind.failedAlternatives,
      ),
      isEmpty,
    );
  });

  test(
    'accepted alternative selected first, never invent alternative explanation',
    () {
      final correct = payload().forState(
        ExplanationState.correct,
        playedUci: 'd2d3',
      );
      expect(correct.explanations.first.kind, ExplanationKind.playedCorrect);
      expect(correct.explanations.first.texts, [
        'alternative paragraph one',
        'alternative paragraph two',
      ]);
      expect(
        correct.explanations
            .expand((b) => b.variations)
            .where((v) => v.firstUci == 'd2d3'),
        hasLength(1),
      );
      expect(
        payload()
            .forState(ExplanationState.correct, playedUci: 'd2d4')
            .explanations
            .first
            .variations
            .map((v) => v.id),
        ['main'],
      );
      final unauthored = payload().forState(
        ExplanationState.correct,
        playedUci: 'h1g2',
      );
      expect(
        unauthored.explanations.where(
          (b) => b.kind == ExplanationKind.playedCorrect,
        ),
        isEmpty,
      );
    },
  );

  test('parser preserves texts and per-ply arrays and requires explicit validation', () {
    final parsed = ExplanationPayload.fromJson({
      'positionId': 'p',
      'state': 'review',
      'explanations': [
        {
          'id': 'main',
          'kind': 'main_solution',
          'texts': ['A.', 'B.'],
          'variations': [
            {
              'id': 'v',
              'label': '1.d4',
              'outcome': 'accepted',
              'texts': ['C.', 'D.'],
              'originFen': fen,
              'movesUci': ['d2d4'],
              'movesSan': ['d4'],
              'explanationByPly': {
                '1': ['E.', 'F.'],
              },
            },
          ],
        },
      ],
    });
    final block = parsed.explanations.single;
    expect(block.texts, ['A.', 'B.']);
    expect(block.variations.single.explanationByPly[1], ['E.', 'F.']);
    expect(block.variations.single.open(), isNull);
  });
}

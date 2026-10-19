import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/assessment_attempt.dart';
import 'package:lucena/domain/use_cases/assessment_relations.dart';

// Abstract geometry, deliberately unrelated to the private U1 answer corpus.
AssessmentFacts facts({bool completeHistory = true, bool opportunity = true}) =>
    AssessmentFacts(
      initialSnapshotRef: 'initial',
      snapshots: {
        'initial': AssessmentSnapshotFacts(
          ref: 'initial',
          visited: true,
          complete: true,
          studentKingSquare: 'c3',
          controls: {
            AssessmentPiece.king: {'a2'},
            AssessmentPiece.bishop: {'a2'},
            AssessmentPiece.knight: {'a2'},
          },
          controlsAfterRelocation: {
            AssessmentPiece.king: {'a2'},
            AssessmentPiece.bishop: {'a2'},
            AssessmentPiece.knight: {'a2'},
          },
          protections: {},
        ),
        'later': AssessmentSnapshotFacts(
          ref: 'later',
          visited: true,
          complete: true,
          studentKingSquare: 'c3',
          controls: {
            AssessmentPiece.king: {'b2'},
          },
          controlsAfterRelocation: {},
          protections: {
            AssessmentPiece.king: {'b2'},
          },
        ),
      },
      bishopCompatibleCorners: {'a1': true, 'h8': true, 'h1': false},
      supportedCorners: {'a1'},
      knownEscapeSquares: {'a1', 'a2'},
      availableEscapes: {'a1'},
      blockedEscapes: {'a2'},
      visitedHistoryFactsComplete: completeHistory,
      protectionOpportunity: opportunity,
    );

AssessmentRelation edge({
  String id = 'edge',
  AssessmentPiece piece = AssessmentPiece.king,
  String snapshot = 'initial',
  AssessmentMoment moment = AssessmentMoment.initial,
  AssessmentRelationKind kind = AssessmentRelationKind.control,
  Set<String> squares = const {'a2'},
  Set<AssessmentComponent> links = const {
    AssessmentComponent.target,
    AssessmentComponent.pieces,
  },
}) => AssessmentRelation(
  id: id,
  snapshotRef: snapshot,
  piece: piece,
  kind: kind,
  targetSquares: squares,
  useFor: links,
  moment: moment,
);

AssessmentDraft initial([List<AssessmentRelation> extra = const []]) =>
    AssessmentDraft(
      target: AssessmentTarget(
        corner: 'a1',
        colorPiece: AssessmentPiece.bishop,
        sameColor: true,
        accessSquares: {'a1'},
      ),
      relations: [
        for (final piece in AssessmentPiece.values)
          edge(id: piece.name, piece: piece),
        ...extra,
      ],
    );

AssessmentConceptResult evaluate({
  AssessmentDraft? answer,
  AssessmentDraft? protection,
  AssessmentFacts? evidence,
  bool submitted = true,
}) => const AssessmentRelations().evaluate(
  initial: answer ?? initial(),
  protection: protection ?? AssessmentDraft(),
  facts: evidence ?? facts(),
  initialSubmitted: submitted,
  protectionSubmitted: submitted,
  executionComplete: true,
);

void main() {
  test('B1 linked contradiction wins with complete or grouped coverage', () {
    for (final squares in [
      {'a1'},
      {'a2', 'a1'},
    ]) {
      final result = evaluate(
        answer: initial([edge(id: 'false', squares: squares)]),
      );
      expect(
        result.components[AssessmentComponent.target],
        AssessmentVerdict.incorrect,
      );
      expect(result.pieces[AssessmentPiece.king], AssessmentVerdict.incorrect);
      expect(result.pairs.any((p) => p.contributes), isTrue);
      expect(
        result.pairs.any((p) => p.verdict == AssessmentVerdict.incorrect),
        isTrue,
      );
    }
  });

  test(
    'unlinked contradiction has no effect; sufficient proof retains extras',
    () {
      final result = evaluate(
        answer: initial([
          edge(id: 'unlinked', squares: {'a1'}, links: {}),
          edge(id: 'planned', moment: AssessmentMoment.plannedOrUnrepresented),
        ]),
      );
      expect(
        result.components[AssessmentComponent.target],
        AssessmentVerdict.supported,
      );
      expect(
        result.components[AssessmentComponent.pieces],
        AssessmentVerdict.supported,
      );
      expect(result.pairs.any((p) => p.relationId == 'unlinked'), isFalse);
      expect(
        result.pairs.any((p) => p.verdict == AssessmentVerdict.unsupported),
        isTrue,
      );
    },
  );

  test(
    'missing coverage is incomplete; necessary planned evidence unsupported',
    () {
      final omitted = evaluate(answer: AssessmentDraft());
      expect(
        omitted.components[AssessmentComponent.pieces],
        AssessmentVerdict.incomplete,
      );
      final planned = evaluate(
        answer: AssessmentDraft(
          relations: [edge(moment: AssessmentMoment.plannedOrUnrepresented)],
        ),
      );
      expect(
        planned.pieces[AssessmentPiece.king],
        AssessmentVerdict.unsupported,
      );
      expect(
        planned.pieces[AssessmentPiece.bishop],
        AssessmentVerdict.incomplete,
      );
      expect(
        planned.components[AssessmentComponent.pieces],
        AssessmentVerdict.unsupported,
      );
      expect(
        evaluate(
          answer: AssessmentDraft(),
          submitted: false,
        ).pieces[AssessmentPiece.king],
        AssessmentVerdict.unanswered,
      );
    },
  );

  test('B2 protection requires kind, explicit link and visited moment', () {
    AssessmentDraft response(
      AssessmentRelationKind kind,
      Set<AssessmentComponent> links, {
      AssessmentMoment moment = AssessmentMoment.visited,
    }) => AssessmentDraft(
      relations: [
        edge(
          snapshot: 'later',
          moment: moment,
          kind: kind,
          squares: {'b2'},
          links: links,
        ),
      ],
    );
    final link = {AssessmentComponent.protection};
    expect(
      evaluate(protection: response(AssessmentRelationKind.protection, link))
          .components[AssessmentComponent.protection],
      AssessmentVerdict.supported,
    );
    expect(
      evaluate(protection: response(AssessmentRelationKind.control, link))
          .components[AssessmentComponent.protection],
      AssessmentVerdict.incomplete,
    );
    expect(
      evaluate(protection: response(AssessmentRelationKind.protection, {}))
          .components[AssessmentComponent.protection],
      AssessmentVerdict.incomplete,
    );
    expect(
      evaluate(
        protection: response(
          AssessmentRelationKind.protection,
          link,
          moment: AssessmentMoment.plannedOrUnrepresented,
        ),
      ).components[AssessmentComponent.protection],
      AssessmentVerdict.unsupported,
    );
  });

  test('visited-history guards affect only protection; retrospective answers cannot backfill', () {
    for (final evidence in [
      facts(completeHistory: false),
      facts(opportunity: false),
    ]) {
      final result = evaluate(evidence: evidence);
      expect(
        result.components[AssessmentComponent.target],
        AssessmentVerdict.supported,
      );
      expect(
        result.components[AssessmentComponent.pieces],
        AssessmentVerdict.supported,
      );
      expect(
        result.components[AssessmentComponent.execution],
        AssessmentVerdict.supported,
      );
      expect(
        result.components[AssessmentComponent.protection],
        AssessmentVerdict.unsupported,
      );
      expect(result.integral(timeAndHistoryIntact: true), isFalse);
    }
    final result = evaluate(answer: AssessmentDraft(), protection: initial());
    expect(
      result.components[AssessmentComponent.pieces],
      AssessmentVerdict.incomplete,
    );
  });

  test('a compatible but unproven target remains unsupported', () {
    final result = evaluate(
      answer: AssessmentDraft(
        target: AssessmentTarget(
          corner: 'h8',
          colorPiece: AssessmentPiece.bishop,
          sameColor: true,
          accessSquares: {},
        ),
        relations: initial().relations,
      ),
    );
    expect(result.targetPredicates['color'], AssessmentVerdict.supported);
    expect(
      result.components[AssessmentComponent.target],
      AssessmentVerdict.unsupported,
    );
  });
}

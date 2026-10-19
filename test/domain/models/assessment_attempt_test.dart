import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/assessment_attempt.dart';

void main() {
  test(
    'response collections are defensive and nested snapshots round-trip',
    () {
      final squares = <String>{'synthetic-square'};
      final links = <AssessmentComponent>{AssessmentComponent.pieces};
      final relation = AssessmentRelation(
        id: 'relation',
        snapshotRef: 'initial',
        piece: AssessmentPiece.king,
        kind: AssessmentRelationKind.control,
        targetSquares: squares,
        useFor: links,
      );
      final rows = [relation];
      final draft = AssessmentDraft(relations: rows);
      squares.clear();
      links.clear();
      rows.clear();
      expect(draft.relations.single.targetSquares, {'synthetic-square'});
      expect(draft.relations.single.useFor, {AssessmentComponent.pieces});
      expect(() => relation.targetSquares.clear(), throwsUnsupportedError);
      expect(() => draft.relations.clear(), throwsUnsupportedError);

      final at = DateTime.utc(2026, 1, 1);
      final identity = {'item': 'opaque-hash'};
      final attempt = AssessmentAttempt(
        attemptId: 'a',
        lessonId: 'lesson',
        exerciseId: 'exercise',
        contentIdentity: identity,
        startedAtUtc: at,
        lastObservedUtc: at,
        execution: AssessmentExecution(
          gameFen: 'synthetic-board',
          played: [],
          visitedSnapshots: {'initial': 'synthetic-board'},
          historyIdentity: 'replay-hash',
          historyVerified: true,
          studentMate: false,
          terminal: false,
          studentTurn: true,
        ),
        draft: draft,
        submissions: [
          AssessmentSubmission(
            phase: AssessmentPhase.initial,
            atUtc: at,
            response: draft,
          ),
        ],
      );
      identity.clear();
      final restored = AssessmentAttempt.fromJson(
        (jsonDecode(jsonEncode(attempt.toJson())) as Map)
            .cast<String, Object?>(),
      );
      expect(restored.toJson(), attempt.toJson());
      expect(restored.deadlineUtc.difference(at), const Duration(seconds: 600));
      expect(() => restored.contentIdentity.clear(), throwsUnsupportedError);
      expect(() => restored.submissions.clear(), throwsUnsupportedError);
      expect(() => restored.execution.played.clear(), throwsUnsupportedError);
      expect(
        () => restored.execution.visitedSnapshots.clear(),
        throwsUnsupportedError,
      );
    },
  );

  test('duplicate relation ids and empty selections are rejected', () {
    AssessmentRelation relation(Iterable<String> targets) => AssessmentRelation(
      id: 'same',
      snapshotRef: null,
      piece: AssessmentPiece.knight,
      kind: AssessmentRelationKind.control,
      targetSquares: targets,
      useFor: [],
    );
    expect(() => relation([]), throwsArgumentError);
    expect(
      () => AssessmentDraft(
        relations: [
          relation(['x']),
          relation(['y']),
        ],
      ),
      throwsArgumentError,
    );
  });

  test('empty editing has no selected answers or implied relations', () {
    final draft = AssessmentDraft();
    final editing = draft.editing;
    expect(editing.corner, isNull);
    expect(editing.colorPiece, isNull);
    expect(editing.sameColor, isNull);
    expect(editing.accessSquares, isEmpty);
    expect(editing.relationId, isNull);
    expect(editing.relationPiece, isNull);
    expect(editing.relationKind, isNull);
    expect(editing.relationMoment, isNull);
    expect(editing.relationSnapshotRef, isNull);
    expect(editing.relationTargets, isEmpty);
    expect(editing.relationUseFor, isEmpty);
    expect(draft.target, isNull);
    expect(draft.relations, isEmpty);
  });

  test('partial editing round-trips without confirmed target or relation', () {
    final draft = AssessmentDraft(
      editing: AssessmentEditingState(
        corner: 'learner-choice',
        colorPiece: AssessmentPiece.bishop,
        accessSquares: {'selected-access'},
        relationId: 'unfinished-relation',
        relationPiece: AssessmentPiece.king,
        relationKind: AssessmentRelationKind.protection,
        relationMoment: AssessmentMoment.visited,
        relationSnapshotRef: 'visited-reference',
        relationTargets: {'selected-target'},
        relationUseFor: {AssessmentComponent.protection},
      ),
    );
    final restored = AssessmentDraft.fromJson(
      (jsonDecode(jsonEncode(draft.toJson())) as Map).cast<String, Object?>(),
    );
    expect(restored.toJson(), draft.toJson());
    expect(restored.editing.sameColor, isNull);
    expect(restored.editing.relationPiece, AssessmentPiece.king);
    expect(restored.target, isNull);
    expect(restored.relations, isEmpty);
  });

  test(
    'editing distinguishes an explicit false from a missing color choice',
    () {
      final explicit = AssessmentEditingState.fromJson(
        AssessmentEditingState(sameColor: false).toJson(),
      );
      final missing = AssessmentEditingState.fromJson({});
      expect(explicit.sameColor, isFalse);
      expect(explicit.toJson()['sameColor'], isFalse);
      expect(missing.sameColor, isNull);
      expect(missing.toJson()['sameColor'], isNull);
      expect(missing.accessSquares, isEmpty);
    },
  );

  test('editing defensively copies all sets and exposes them as immutable', () {
    final access = <String>{'selected-access'};
    final targets = <String>{'selected-target'};
    final useFor = <AssessmentComponent>{AssessmentComponent.target};
    final editing = AssessmentEditingState(
      accessSquares: access,
      relationTargets: targets,
      relationUseFor: useFor,
    );
    access.clear();
    targets.clear();
    useFor.clear();
    expect(editing.accessSquares, {'selected-access'});
    expect(editing.relationTargets, {'selected-target'});
    expect(editing.relationUseFor, {AssessmentComponent.target});
    expect(() => editing.accessSquares.clear(), throwsUnsupportedError);
    expect(() => editing.relationTargets.clear(), throwsUnsupportedError);
    expect(() => editing.relationUseFor.clear(), throwsUnsupportedError);
  });

  test('legacy drafts without editing restore an empty collector', () {
    final legacy = AssessmentDraft.fromJson({'target': null, 'relations': []});
    final explicitlyNull = AssessmentDraft.fromJson({
      'target': null,
      'relations': [],
      'editing': null,
    });
    expect(legacy.editing.toJson(), AssessmentEditingState().toJson());
    expect(explicitlyNull.editing.toJson(), legacy.editing.toJson());
    expect(legacy.target, isNull);
    expect(legacy.relations, isEmpty);
    expect(legacy.toJson().containsKey('editing'), isTrue);
  });

  test(
    'frozen response keeps partial diagnosis after collector replacement',
    () {
      final targets = <String>{'first-choice'};
      final collected = AssessmentDraft(
        editing: AssessmentEditingState(
          relationId: 'unfinished',
          relationTargets: targets,
          sameColor: false,
        ),
      );
      final frozen = AssessmentSubmission(
        phase: AssessmentPhase.initial,
        atUtc: DateTime.utc(2026, 1, 1),
        response: collected,
      );
      final serialized = jsonEncode(frozen.toJson());
      targets.clear();
      targets.add('later-choice');
      final replacement = AssessmentDraft(
        editing: AssessmentEditingState(
          relationTargets: targets,
          sameColor: true,
        ),
      );
      final restored = AssessmentSubmission.fromJson(
        (jsonDecode(serialized) as Map).cast<String, Object?>(),
      );
      expect(frozen.response.editing.relationTargets, {'first-choice'});
      expect(frozen.response.editing.sameColor, isFalse);
      expect(restored.toJson(), frozen.toJson());
      expect(restored.response.editing.relationId, 'unfinished');
      expect(restored.response.target, isNull);
      expect(restored.response.relations, isEmpty);
      expect(replacement.editing.relationTargets, {'later-choice'});
      expect(replacement.editing.sameColor, isTrue);
    },
  );
}

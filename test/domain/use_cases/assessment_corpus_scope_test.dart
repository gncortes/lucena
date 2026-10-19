import 'dart:convert';
import 'dart:io' as io;

import 'package:crypto/crypto.dart';
import 'package:dartchess/dartchess.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/assessment_attempt.dart';
import 'package:lucena/domain/use_cases/assessment_execution_adapter.dart';
import 'package:lucena/domain/use_cases/assessment_facts_provider.dart';
import 'package:lucena/domain/use_cases/assessment_relations.dart';
import 'package:lucena/domain/use_cases/assessment_session.dart';
import 'package:lucena/domain/use_cases/now.dart';
import 'package:lucena/domain/use_cases/exercise_judge.dart';

// Private inputs stay on disk; no geometry or answer map is supplied as facts.
const _directory = 'docs/tasks/aulas/bispo-cavalo/piloto-u1';
const _corpusName = 'avaliacao-conceitual.corpus-materializado.json';
const _descriptorName = 'avaliacao-conceitual.descritor-confiavel.json';

Map<String, dynamic> _read(String name) =>
    jsonDecode(io.File('$_directory/$name').readAsStringSync())
        as Map<String, dynamic>;

Map<String, dynamic> _map(Object? value) =>
    (value as Map).cast<String, dynamic>();

AssessmentFactsDescriptor _descriptor(Map<String, dynamic> json) =>
    AssessmentFactsDescriptor(
      descriptorId: json['descriptorId'] as String,
      factualVersion: json['factualVersion'] as String,
      assessmentVersion: json['assessmentVersion'] as String,
      lessonId: json['lessonId'] as String,
      exerciseId: json['exerciseId'] as String,
      initialFen: json['initialFen'] as String,
      student: Side.values.byName(json['student'] as String),
      orientation: Side.values.byName(json['orientation'] as String),
      supportedCorner: json['supportedCorner'] as String,
      contentIdentity: (json['contentIdentity'] as Map).cast<String, String>(),
      sourceHashes: (json['sourceHashes'] as Map).cast<String, String>(),
    );

String _snapshot(String legacy) {
  if (!RegExp(r'^s\d+$').hasMatch(legacy)) {
    throw const FormatException('Unsupported legacy snapshot reference');
  }
  return 'ply:${int.parse(legacy.substring(1))}';
}

AssessmentComponent _component(String legacy) => switch (legacy) {
  'functions.pieces' => AssessmentComponent.pieces,
  'target.support' => AssessmentComponent.target,
  'functions.protection' => AssessmentComponent.protection,
  _ => throw const FormatException('Unsupported legacy component'),
};

AssessmentRelation _relation(Map<String, dynamic> json) => AssessmentRelation(
  id: json['id'] as String,
  snapshotRef: _snapshot(json['snapshotId'] as String),
  moment: AssessmentMoment.values.byName(json['momentIntent'] as String),
  piece: AssessmentPiece.values.byName(json['pieceId'] as String),
  kind: AssessmentRelationKind.values.byName(json['kind'] as String),
  targetSquares: (json['targetSquareRefs'] as List).cast<String>(),
  useFor: (json['useFor'] as List).cast<String>().map(_component),
);

AssessmentDraft _draft(Map<String, dynamic> input) {
  final target = input['target'] == null ? null : _map(input['target']);
  return AssessmentDraft(
    target: target == null
        ? null
        : AssessmentTarget(
            corner: target['cornerRef'] as String,
            colorPiece: AssessmentPiece.values.byName(
              target['colorPieceId'] as String,
            ),
            sameColor: switch (target['colorRelation']) {
              'sameColor' => true,
              'differentColor' => false,
              _ => throw const FormatException('Unsupported color relation'),
            },
            accessSquares: (target['accessSquareRefs'] as List).cast<String>(),
          ),
    relations: [
      for (final row in (input['relations'] as List? ?? const []))
        _relation(_map(row)),
      if (input['relation'] != null) _relation(_map(input['relation'])),
    ],
  );
}

final class _FixedNow implements Now {
  @override
  DateTime call() => DateTime.utc(2026, 1, 1);
}

Role _role(AssessmentPiece piece) => switch (piece) {
  AssessmentPiece.king => Role.king,
  AssessmentPiece.bishop => Role.bishop,
  AssessmentPiece.knight => Role.knight,
};

Object? _pointer(Object? value, String pointer) {
  for (final part in pointer.split('/').skip(1)) {
    final key = part.replaceAll('~1', '/').replaceAll('~0', '~');
    value = value is List ? value[int.parse(key)] : (value as Map)[key];
  }
  return value;
}

void main() {
  final corpus = _read(_corpusName);
  final all = (corpus['cases'] as List).map(_map).toList();
  const families = ['integrity', 'eligibility', 'twoPhase', 'exposure'];
  final cases = all.where((row) => families.contains(row['family'])).toList();
  late AssessmentFactsDescriptor trusted;
  late Map<String, dynamic> spec;
  late List<String> history;
  late List<Map<String, dynamic>> frames;

  String hash(String path) =>
      sha256.convert(io.File(path).readAsBytesSync()).toString();

  AssessmentExecution replay(int ply) =>
      const AssessmentExecutionAdapter().replay(
        initialFen: trusted.initialFen,
        student: trusted.student,
        played: history.take(ply).toList(),
      );

  AssessmentAttempt attempt(String id, int ply) => AssessmentAttempt(
    attemptId: 'corpus-scope:$id',
    lessonId: trusted.lessonId,
    exerciseId: trusted.exerciseId,
    contentIdentity: trusted.contentIdentity,
    startedAtUtc: _FixedNow()(),
    lastObservedUtc: _FixedNow()(),
    execution: replay(ply),
    draft: AssessmentDraft(),
    phase: AssessmentPhase.execution,
    submissions: [
      AssessmentSubmission(
        phase: AssessmentPhase.initial,
        atUtc: _FixedNow()(),
        response: AssessmentDraft(),
      ),
    ],
  );

  setUpAll(() {
    expect(
      hash('$_directory/$_corpusName'),
      '478e19ecde0dd92fd2b1a84325e32da7e0126ae6c36e5aff472fa2990502ff6d',
    );
    expect(
      hash('$_directory/$_descriptorName'),
      '45f235f05e4f6439c50242891f23b3abff2c6fa4987ff460947d3b61689af038',
    );
    trusted = _descriptor(_read(_descriptorName));
    for (final entry in _map(corpus['sourceSha256']).entries) {
      expect(hash('$_directory/${entry.key}'), entry.value);
    }
    const inventoryName = 'avaliacao-conceitual.inventario-privado.json';
    expect(
      hash('$_directory/$inventoryName'),
      trusted.sourceHashes['inventory'],
    );
    final inventory = _read(inventoryName);
    history = (inventory['history'] as List).cast<String>();
    frames = (inventory['frames'] as List).map(_map).toList();
    spec = _read('avaliacao-conceitual.spec.json');
    final teaching = _map(_map(spec['sources'])['teaching']);
    expect(hash(teaching['path'] as String), trusted.sourceHashes['teaching']);
    expect(hash(teaching['path'] as String), teaching['sha256']);
  });

  test('scope selects eight unique cases with explicit family counts', () {
    expect(all.length, 52);
    expect(all.map((row) => row['id']).toSet().length, 52);
    expect(cases.length, 8);
    expect(cases.map((row) => row['id']).toSet().length, 8);
    expect(
      {
        for (final family in families)
          family: cases.where((row) => row['family'] == family).length,
      },
      {'integrity': 1, 'eligibility': 5, 'twoPhase': 1, 'exposure': 1},
    );
  });

  for (final row in cases) {
    final id = row['id'] as String;
    test('scope corpus $id real assertions and explicit consumer gaps', () async {
      final input = _map(row['input']);
      final expected = _map(row['expectedRelativeToProposedSpec']);
      final provider = AssessmentRuntimeFactsProvider(trusted);
      switch (row['family']) {
        case 'integrity':
          {
            expect(
              input['historyRef'],
              history,
              reason: '$id reserved history',
            );
            final facts = provider(attempt(id, history.length));
            final refs = (input['snapshots'] as List).cast<String>().map(
              _snapshot,
            );
            expect(facts.snapshots.keys.toSet(), refs.toSet(), reason: id);
            final frameMatches = <bool>[];
            final pairMatches = <bool>[];
            for (final frame in frames) {
              final ply = frame['ply'] as int;
              final ref = 'ply:$ply';
              frameMatches.add(
                facts.provenance!.snapshots[ref]!.fen == frame['fen'],
              );
              final position = ExerciseJudge.exactPosition(
                frame['fen'] as String,
              )!;
              final origins = {
                for (final piece in AssessmentPiece.values)
                  piece: position.board
                      .bySide(trusted.student)
                      .squares
                      .singleWhere(
                        (square) =>
                            position.board.roleAt(square) == _role(piece),
                      )
                      .name,
              };
              final actualPairs = {
                for (final entry in facts.snapshots[ref]!.protections.entries)
                  for (final target in entry.value)
                    '${origins[entry.key]}>$target',
              };
              final reservedPairs = (frame['protectionFacts'] as List)
                  .map((pair) => '${pair['defender']}>${pair['target']}')
                  .toSet();
              pairMatches.add(
                actualPairs.length == reservedPairs.length &&
                    actualPairs.containsAll(reservedPairs),
              );
            }
            expect(
              frameMatches.length == 6 && frameMatches.every((v) => v),
              expected['sixFramesMatchReserved'],
              reason: '$id frames',
            );
            expect(
              pairMatches.every((v) => v),
              expected['protectionPairsMatchReserved'],
              reason: '$id protectionPairs',
            );
            fail(
              '$id generatedGeometry: documentary source-process assertion; '
              'no runtime consumer (runtime facts are derived geometry).',
            );
          }
        case 'eligibility':
          {
            if (input['historySupplied'] == false) {
              expect(
                input.containsKey('sourceWinningAlternative'),
                isTrue,
                reason: id,
              );
              fail(
                '$id protection/reason/studentError: no supplied route history; '
                'cannot derive an execution or invent a verdict/student-error field.',
              );
            }
            expect(
              input['routeId'],
              _map(spec['coverage'])['frozenComparisonRouteId'],
              reason: '$id supported route',
            );
            final through = input['frozenThroughPly'] as int;
            expect(through, inInclusiveRange(0, history.length), reason: id);
            final facts = provider(attempt(id, through));
            expect(
              facts.protectionOpportunity ? 'available' : 'unsupported',
              expected['opportunity'],
              reason: '$id opportunity',
            );
            final eligible = facts.snapshots.values
                .where(
                  (snapshot) =>
                      snapshot.visited &&
                      snapshot.complete &&
                      snapshot.protections.values.any(
                        (targets) => targets.isNotEmpty,
                      ),
                )
                .map((snapshot) => snapshot.ref)
                .toSet();
            expect(
              eligible,
              (expected['eligibleSnapshotIds'] as List)
                  .cast<String>()
                  .map(_snapshot)
                  .toSet(),
              reason: '$id eligible snapshots',
            );
            expect(
              facts.snapshots.length,
              through + 1,
              reason: '$id visited only',
            );
            break;
          }
        case 'twoPhase':
          {
            expect(
              input['routeId'],
              _map(spec['coverage'])['frozenComparisonRouteId'],
            );
            final through = input['frozenThroughPly'] as int;
            expect(through, inInclusiveRange(0, history.length));
            final session = await AssessmentSession.start(
              attemptId: 'corpus-scope:$id',
              lessonId: trusted.lessonId,
              exerciseId: trusted.exerciseId,
              contentIdentity: trusted.contentIdentity,
              initialExecution: replay(0),
              now: _FixedNow(),
              save: (_) async {},
            );
            await session.replaceDraft(_draft(_map(input['frozenInitial'])));
            await session.submitInitial();
            final frozen = jsonEncode(
              session.attempt.submissions.single.toJson(),
            );
            await session.updateExecution(
              token: session.callbackToken,
              contentIdentity: trusted.contentIdentity,
              execution: replay(through),
            );
            await session.finishExecution(voluntaryConfirmed: true);
            final late = _relation(_map(input['relation']));
            await session.replaceDraft(AssessmentDraft(relations: [late]));
            await session.submitProtection();
            final a = session.attempt;
            expect(
              jsonEncode(a.submissions.first.toJson()) == frozen,
              expected['initialSubmissionUnchanged'],
              reason: '$id immutable initial',
            );
            final result = const AssessmentRelations().evaluate(
              initial: a.submissions.first.response,
              protection: a.submissions.last.response,
              facts: provider(a),
              initialSubmitted: true,
              protectionSubmitted: true,
              executionComplete: true,
            );
            expect(
              result.pieces[AssessmentPiece.knight]?.name,
              expected['initialKnight'],
              reason: '$id initialKnight',
            );
            expect(
              result.components[AssessmentComponent.protection]?.name,
              expected['protection'],
              reason: '$id protection',
            );
            expect(
              result.pairs.where(
                (pair) =>
                    pair.relationId == late.id &&
                    pair.component == AssessmentComponent.pieces,
              ),
              isEmpty,
              reason: '$id no late backfill',
            );
            fail(
              '$id latePieceLink: evaluator emits no pieces pair for late links; '
              'absence is not the expected unsupported verdict.',
            );
          }
        case 'exposure':
          {
            final facts = provider(attempt(id, history.length));
            final ref = _snapshot(input['snapshotId'] as String);
            final fen = facts.provenance!.snapshots[ref]!.fen;
            final teachingSource = _map(_map(spec['sources'])['teaching']);
            final teaching = jsonDecode(
              io.File(teachingSource['path'] as String).readAsStringSync(),
            );
            final crosswalk =
                (_map(spec['coverage'])['exposureCrosswalk'] as List)
                    .map(_map)
                    .singleWhere(
                      (row) => row['snapshotId'] == input['snapshotId'],
                    );
            final matches = (crosswalk['samePosition'] as List)
                .map(_map)
                .toList();
            expect(
              matches.isNotEmpty &&
                  matches.every(
                    (match) =>
                        _pointer(teaching, match['ref'] as String) == fen,
                  ),
              expected['literalTeachingOverlap'],
              reason: '$id literalTeachingOverlap',
            );
            fail(
              '$id transferNovelty/anticipation: documentary claims without '
              'runtime consumers; literal teaching overlap does not establish them.',
            );
          }
        default:
          fail('$id unsupported family');
      }
    });
  }
}

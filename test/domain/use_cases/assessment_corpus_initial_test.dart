import 'dart:convert';
import 'dart:io' as io;

import 'package:crypto/crypto.dart';
import 'package:dartchess/dartchess.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/assessment_attempt.dart';
import 'package:lucena/domain/use_cases/assessment_execution_adapter.dart';
import 'package:lucena/domain/use_cases/assessment_facts_provider.dart';
import 'package:lucena/domain/use_cases/assessment_relations.dart';

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

void main() {
  final corpus = _read(_corpusName);
  final all = (corpus['cases'] as List).map(_map).toList();
  final cases = all.where((row) => row['family'] == 'initial').toList();
  late AssessmentFactsDescriptor trusted;

  setUpAll(() {
    for (final entry in {
      _corpusName:
          '478e19ecde0dd92fd2b1a84325e32da7e0126ae6c36e5aff472fa2990502ff6d',
      _descriptorName:
          '45f235f05e4f6439c50242891f23b3abff2c6fa4987ff460947d3b61689af038',
    }.entries) {
      expect(
        sha256
            .convert(io.File('$_directory/${entry.key}').readAsBytesSync())
            .toString(),
        entry.value,
        reason: 'Input identity: ${entry.key}',
      );
    }
    trusted = _descriptor(_read(_descriptorName));
    // These identify the original v2 sources, not a rewritten v3 oracle.
    final sources = _map(corpus['sourceSha256']);
    expect(
      sources['avaliacao-conceitual.spec.json'],
      trusted.sourceHashes['spec'],
    );
    expect(
      sources['avaliacao-conceitual.fixtures.json'],
      sha256
          .convert(
            io.File('$_directory/avaliacao-conceitual.fixtures.json')
                .readAsBytesSync(),
          )
          .toString(),
    );
  });

  test('private corpus has exactly 52 unique cases and 16 initial cases', () {
    expect(all.length, 52);
    expect(all.map((row) => row['id']).toSet().length, all.length);
    expect(cases.length, 16);
    expect(cases.map((row) => row['id']).toSet().length, cases.length);
    expect(cases.every((row) => (row['id'] as String).isNotEmpty), isTrue);
  });

  for (final row in cases) {
    final id = row['id'] as String;
    test('initial corpus $id against real provider and evaluator', () {
      final input = _map(row['input']);
      expect(input['phase'], 'initial', reason: id);
      expect(input['submitted'], isTrue, reason: id);
      if (input['snapshotId'] != null) {
        expect(_snapshot(input['snapshotId'] as String), 'ply:0', reason: id);
      }
      final initial = _draft(input);
      final at = DateTime.utc(2026, 1, 1);
      final execution = const AssessmentExecutionAdapter().replay(
        initialFen: trusted.initialFen,
        student: trusted.student,
        played: const [],
      );
      final attempt = AssessmentAttempt(
        attemptId: 'corpus-initial:$id',
        lessonId: trusted.lessonId,
        exerciseId: trusted.exerciseId,
        contentIdentity: trusted.contentIdentity,
        startedAtUtc: at,
        lastObservedUtc: at,
        phase: AssessmentPhase.execution,
        revision: 1,
        execution: execution,
        draft: AssessmentDraft(),
        submissions: [
          AssessmentSubmission(
            phase: AssessmentPhase.initial,
            atUtc: at,
            response: initial,
          ),
        ],
      );
      final facts = AssessmentRuntimeFactsProvider(trusted)(attempt);
      expect(facts.snapshots.keys.toSet(), {'ply:0'}, reason: id);
      expect(facts.provenance!.historyIdentity, execution.historyIdentity);
      final result = const AssessmentRelations().evaluate(
        initial: attempt.submissions.single.response,
        protection: AssessmentDraft(),
        facts: facts,
        initialSubmitted: true,
        protectionSubmitted: false,
        executionComplete: false,
      );
      final expected = _map(row['expectedRelativeToProposedSpec']);
      expect(
        expected.keys.every(
          (key) =>
              const ['target', 'pieces', 'relation', 'reason'].contains(key),
        ),
        isTrue,
        reason: '$id unsupported expectation field',
      );
      if (expected.containsKey('target')) {
        expect(
          result.components[AssessmentComponent.target]?.name,
          expected['target'],
          reason: '$id target',
        );
      }
      if (expected.containsKey('pieces')) {
        for (final entry in _map(expected['pieces']).entries) {
          expect(
            result.pieces[AssessmentPiece.values.byName(entry.key)]?.name,
            entry.value,
            reason: '$id pieces.${entry.key}',
          );
        }
      }
      if (expected.containsKey('relation')) {
        expect(initial.relations.length, 1, reason: '$id relation cardinality');
        final relation = initial.relations.single;
        final pairs = result.pairs.where((p) => p.relationId == relation.id);
        expect(
          pairs.length,
          relation.targetSquares.length * relation.useFor.length,
          reason: '$id linked pair cardinality',
        );
        expect(pairs, isNotEmpty, reason: '$id no linked relation verdict');
        for (final pair in pairs) {
          expect(
            pair.verdict.name,
            expected['relation'],
            reason: '$id relation',
          );
        }
      }
      // Spec reason is explanatory metadata, not a runtime reason-code oracle.
      // Normalize comparison to the asserted target/piece/pair verdict above;
      // neither equate prose to runtime codes nor replace its expected verdict.
      if (expected.containsKey('reason')) {
        expect(expected['reason'], isA<String>(), reason: '$id spec reason');
        expect((expected['reason'] as String).isNotEmpty, isTrue, reason: id);
      }
    });
  }
}

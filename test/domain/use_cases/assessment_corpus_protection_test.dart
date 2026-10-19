import 'dart:convert';
import 'dart:io' as io;

import 'package:crypto/crypto.dart';
import 'package:dartchess/dartchess.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/assessment_attempt.dart';
import 'package:lucena/domain/use_cases/assessment_execution_adapter.dart';
import 'package:lucena/domain/use_cases/assessment_facts_provider.dart';
import 'package:lucena/domain/use_cases/assessment_relations.dart';

const _directory = 'docs/tasks/aulas/bispo-cavalo/piloto-u1';
const _corpusName = 'avaliacao-conceitual.corpus-materializado.json';
const _descriptorName = 'avaliacao-conceitual.descritor-confiavel.json';
const _inventoryName = 'avaliacao-conceitual.inventario-privado.json';
const _specName = 'avaliacao-conceitual.spec.json';

Map<String, dynamic> _map(Object? value) =>
    (value as Map).cast<String, dynamic>();
Map<String, dynamic> _read(String name) =>
    _map(jsonDecode(io.File('$_directory/$name').readAsStringSync()));
String _hash(String name) =>
    sha256.convert(io.File('$_directory/$name').readAsBytesSync()).toString();

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

void main() {
  final corpus = _read(_corpusName);
  final all = (corpus['cases'] as List).map(_map).toList();
  final cases = all.where((row) => row['family'] == 'protection').toList();
  late AssessmentFactsDescriptor trusted;
  late List<String> history;
  late String routeId;

  setUpAll(() {
    expect(
      _hash(_corpusName),
      '478e19ecde0dd92fd2b1a84325e32da7e0126ae6c36e5aff472fa2990502ff6d',
      reason: 'Corpus identity',
    );
    expect(
      _hash(_descriptorName),
      '45f235f05e4f6439c50242891f23b3abff2c6fa4987ff460947d3b61689af038',
      reason: 'Descriptor identity',
    );
    trusted = _descriptor(_read(_descriptorName));
    final sources = _map(corpus['sourceSha256']);
    expect(_hash(_specName), sources[_specName], reason: 'Spec identity');
    expect(sources[_specName], trusted.sourceHashes['spec']);
    expect(
      _hash('avaliacao-conceitual.fixtures.json'),
      sources['avaliacao-conceitual.fixtures.json'],
      reason: 'Fixtures identity',
    );
    expect(_hash(_inventoryName), trusted.sourceHashes['inventory']);
    final inventory = _read(_inventoryName);
    final spec = _read(_specName);
    final coverage = _map(spec['coverage']);
    // Resolve only the existing reserved history; never invent another route.
    final ref = _map(coverage['historyRef'])[r'$ref'] as String;
    final alias = _map(_map(spec['aliases'])[ref]);
    expect(alias['source'], 'inventory');
    expect(alias['pointer'], '/history');
    history = (inventory['history'] as List).cast<String>();
    routeId = coverage['frozenComparisonRouteId'] as String;
  });

  test(
    'private corpus has 52 unique cases and exactly 12 protection cases',
    () {
      expect(all.length, 52);
      expect(all.map((row) => row['id']).toSet().length, all.length);
      expect(cases.length, 12);
      expect(cases.map((row) => row['id']).toSet().length, cases.length);
      expect(cases.every((row) => (row['id'] as String).isNotEmpty), isTrue);
    },
  );

  for (final row in cases) {
    final id = row['id'] as String;
    test('protection corpus $id against real replay provider and evaluator', () {
      final input = _map(row['input']);
      expect(input['phase'], 'protection', reason: id);
      expect(input['routeId'], routeId, reason: '$id supported route');
      final through = input['frozenThroughPly'] as int;
      expect(
        through,
        inInclusiveRange(0, history.length),
        reason: '$id prefix',
      );
      if (input.containsKey('throughPly')) {
        expect(input['throughPly'], through, reason: '$id prefix agreement');
      }
      // Legacy protection cases omit submitted for completed response collection.
      // Both explicit true and omitted mean submitted; false is not accepted.
      expect(input['submitted'] ?? true, isTrue, reason: '$id submitted');
      final protection = AssessmentDraft(
        relations: [
          for (final json in (input['relations'] as List? ?? const []))
            _relation(_map(json)),
          if (input['relation'] != null) _relation(_map(input['relation'])),
        ],
      );
      final initial = AssessmentDraft();
      final at = DateTime.utc(2026, 1, 1);
      final execution = const AssessmentExecutionAdapter().replay(
        initialFen: trusted.initialFen,
        student: trusted.student,
        played: history.take(through).toList(),
      );
      final attempt = AssessmentAttempt(
        attemptId: 'corpus-protection:$id',
        lessonId: trusted.lessonId,
        exerciseId: trusted.exerciseId,
        contentIdentity: trusted.contentIdentity,
        startedAtUtc: at,
        lastObservedUtc: at,
        phase: AssessmentPhase.closed,
        revision: through + 2,
        execution: execution,
        executionFinishedAtUtc: at,
        closedAtUtc: at,
        closeReason: AssessmentCloseReason.submitted,
        draft: AssessmentDraft(),
        submissions: [
          AssessmentSubmission(
            phase: AssessmentPhase.initial,
            atUtc: at,
            response: initial,
          ),
          AssessmentSubmission(
            phase: AssessmentPhase.protection,
            atUtc: at,
            response: protection,
          ),
        ],
      );
      final facts = AssessmentRuntimeFactsProvider(trusted)(attempt);
      expect(facts.snapshots.keys.toSet(), {
        for (var ply = 0; ply <= through; ply++) 'ply:$ply',
      }, reason: '$id visited prefix only');
      expect(facts.provenance!.historyIdentity, execution.historyIdentity);
      final result = const AssessmentRelations().evaluate(
        initial: attempt.submissions.first.response,
        protection: attempt.submissions.last.response,
        facts: facts,
        initialSubmitted: true,
        protectionSubmitted: true,
        executionComplete: true,
      );
      final expected = _map(row['expectedRelativeToProposedSpec']);
      expect(
        expected.keys.every(
          (key) => const ['protection', 'reason'].contains(key),
        ),
        isTrue,
        reason: '$id unsupported expectation field',
      );
      expect(expected.containsKey('protection'), isTrue, reason: id);
      expect(
        result.components[AssessmentComponent.protection]?.name,
        expected['protection'],
        reason: '$id protection',
      );
      // Pairs must preserve exactly the learner's explicit component links.
      expect(
        result.pairs.length,
        protection.relations
            .where((r) => r.useFor.contains(AssessmentComponent.protection))
            .fold<int>(0, (sum, r) => sum + r.targetSquares.length),
        reason: '$id linked pair cardinality',
      );
      for (final relation in protection.relations) {
        final pairs = result.pairs.where((p) => p.relationId == relation.id);
        if (!relation.useFor.contains(AssessmentComponent.protection)) {
          expect(pairs, isEmpty, reason: '$id no inferred link');
          continue;
        }
        expect(
          pairs.map((p) => p.square).toSet(),
          relation.targetSquares,
          reason: '$id pair targets',
        );
        for (final pair in pairs) {
          expect(pair.component, AssessmentComponent.protection, reason: id);
          expect(pair.piece, relation.piece, reason: '$id pair piece');
          // A true control can have a supported pair without contributing to
          // protection. Do not infer a protection assertion from its geometry.
          if (relation.kind != AssessmentRelationKind.protection) {
            expect(pair.contributes, isFalse, reason: '$id kind contribution');
          } else {
            expect(
              pair.verdict.name,
              expected['protection'],
              reason: '$id protection pair',
            );
          }
          if (relation.moment == AssessmentMoment.plannedOrUnrepresented ||
              !facts.snapshots.containsKey(relation.snapshotRef)) {
            expect(pair.verdict, AssessmentVerdict.unsupported, reason: id);
          }
        }
      }
      // Spec prose reason is metadata, normalized to the checked verdict above;
      // no textual equivalence with runtime reason codes is asserted.
      if (expected.containsKey('reason')) {
        expect(expected['reason'], isA<String>(), reason: '$id spec reason');
        expect((expected['reason'] as String).isNotEmpty, isTrue, reason: id);
      }
    });
  }
}

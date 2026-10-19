import 'dart:convert';
import 'dart:io' as io;

import 'package:crypto/crypto.dart';
import 'package:dartchess/dartchess.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/data/repositories/endgames/assessment_attempt_repository.dart';
import 'package:lucena/data/services/preferences_service.dart';
import 'package:lucena/domain/models/assessment_attempt.dart';
import 'package:lucena/domain/use_cases/assessment_execution_adapter.dart';
import 'package:lucena/domain/use_cases/assessment_facts_provider.dart';
import 'package:lucena/domain/use_cases/assessment_relations.dart';
import 'package:lucena/domain/use_cases/exercise_judge.dart';
import 'package:lucena/domain/use_cases/now.dart';
import 'package:lucena/ui/endgames/view_models/assessment_cubit.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

// Restricted test inputs are read locally, never copied into production assets.
const _directory = 'docs/tasks/aulas/bispo-cavalo/piloto-u1';
Map<String, dynamic> read(String name) =>
    jsonDecode(io.File('$_directory/$name').readAsStringSync())
        as Map<String, dynamic>;

AssessmentFactsDescriptor descriptor(Map<String, dynamic> json) =>
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

final class FixedNow implements Now {
  @override
  DateTime call() => DateTime.utc(2026, 1, 1);
}

Role role(AssessmentPiece id) => switch (id) {
  AssessmentPiece.king => Role.king,
  AssessmentPiece.bishop => Role.bishop,
  AssessmentPiece.knight => Role.knight,
};

void main() {
  late Map<String, dynamic> descriptorJson;
  late Map<String, dynamic> inventory;
  late AssessmentFactsDescriptor trusted;
  late AssessmentRuntimeFactsProvider provider;
  late List<String> history;
  late List<Map<String, dynamic>> frames;

  AssessmentAttempt attempt(int ply) => AssessmentAttempt(
    attemptId: 'private-test-attempt',
    lessonId: trusted.lessonId,
    exerciseId: trusted.exerciseId,
    contentIdentity: trusted.contentIdentity,
    startedAtUtc: FixedNow()(),
    lastObservedUtc: FixedNow()(),
    phase: ply == 0 ? AssessmentPhase.initial : AssessmentPhase.execution,
    revision: ply,
    execution: const AssessmentExecutionAdapter().replay(
      initialFen: trusted.initialFen,
      student: trusted.student,
      played: history.take(ply).toList(),
    ),
    draft: AssessmentDraft(),
    submissions: ply == 0
        ? []
        : [
            AssessmentSubmission(
              phase: AssessmentPhase.initial,
              atUtc: FixedNow()(),
              response: AssessmentDraft(),
            ),
          ],
  );

  AssessmentAttempt change(AssessmentAttempt a, Map<String, Object?> changes) =>
      AssessmentAttempt.fromJson({...a.toJson(), ...changes});

  setUpAll(() {
    final descriptorFile = io.File(
      '$_directory/avaliacao-conceitual.descritor-confiavel.json',
    );
    expect(
      sha256.convert(descriptorFile.readAsBytesSync()).toString(),
      '45f235f05e4f6439c50242891f23b3abff2c6fa4987ff460947d3b61689af038',
    );
    descriptorJson = read('avaliacao-conceitual.descritor-confiavel.json');
    trusted = descriptor(descriptorJson);
    provider = AssessmentRuntimeFactsProvider(trusted);
    final inventoryFile = io.File(
      '$_directory/avaliacao-conceitual.inventario-privado.json',
    );
    expect(
      sha256.convert(inventoryFile.readAsBytesSync()).toString(),
      trusted.sourceHashes['inventory'],
    );
    inventory = read('avaliacao-conceitual.inventario-privado.json');
    history = (inventory['history'] as List).cast<String>();
    frames = (inventory['frames'] as List).cast<Map<String, dynamic>>();
    expect(frames.length, 6);
  });

  test('production current geometry matches all six inventoried frames and prefixes', () {
    for (var ply = 0; ply < frames.length; ply++) {
      final facts = provider(attempt(ply));
      final frame = frames[ply];
      final snapshot = facts.snapshots['ply:$ply']!;
      final position = ExerciseJudge.exactPosition(frame['fen'] as String)!;
      final origins = {
        for (final id in AssessmentPiece.values)
          id: position.board
              .bySide(trusted.student)
              .squares
              .singleWhere((s) => position.board.roleAt(s) == role(id)),
      };
      expect(facts.snapshots.length, ply + 1);
      expect(facts.snapshots.containsKey('ply:${ply + 1}'), isFalse);
      expect(facts.visitedHistoryFactsComplete, isTrue);
      expect(facts.provenance!.snapshots['ply:$ply']!.fen, frame['fen']);
      expect(snapshot.checks.values.any((s) => s.isNotEmpty), frame['isCheck']);
      expect(attempt(ply).execution.studentMate, frame['isCheckmate']);
      for (final row
          in (frame['escapeGeometry'] as List).cast<Map<String, dynamic>>()) {
        final square = row['square'] as String;
        expect({
          for (final id in AssessmentPiece.values)
            if (snapshot.controls[id]!.contains(square)) origins[id]!.name,
        }, (row['currentAttackers'] as List).cast<String>().toSet());
      }
      final actualPairs = <String>{
        for (final id in AssessmentPiece.values)
          for (final square in snapshot.protections[id]!)
            '${origins[id]!.name}>$square',
      };
      final expectedPairs = (frame['protectionFacts'] as List)
          .map((row) => '${row['defender']}>${row['target']}')
          .toSet();
      expect(actualPairs, expectedPairs);
      expect(
        facts.protectionOpportunity,
        frames
            .take(ply + 1)
            .any((f) => (f['protectionFacts'] as List).isNotEmpty),
      );
    }
  });

  test(
    'root escape legality and relocated witnesses match private root inventory',
    () {
      final facts = provider(attempt(0));
      final geometry = (frames.first['escapeGeometry'] as List)
          .cast<Map<String, dynamic>>();
      final root = ExerciseJudge.exactPosition(trusted.initialFen)!;
      final origins = {
        for (final id in AssessmentPiece.values)
          id: root.board
              .bySide(trusted.student)
              .squares
              .singleWhere((s) => root.board.roleAt(s) == role(id)),
      };
      expect(
        facts.knownEscapeSquares,
        geometry.map((row) => row['square']).toSet(),
      );
      expect(
        facts.availableEscapes,
        geometry
            .where((row) => row['wouldBeLegalKingMove'] == true)
            .map((row) => row['square'])
            .toSet(),
      );
      expect(
        facts.blockedEscapes,
        facts.knownEscapeSquares.difference(facts.availableEscapes),
      );
      expect(facts.blockedEscapes, isNotEmpty);
      for (final row in geometry) {
        expect(
          {
            for (final id in AssessmentPiece.values)
              if (facts.snapshots['ply:0']!.controlsAfterRelocation[id]!
                  .contains(row['square']))
                origins[id]!.name,
          },
          (row['attackersAfterKingRelocation'] as List).cast<String>().toSet(),
        );
      }
      expect(facts.supportedCorners, {trusted.supportedCorner});
      expect(
        facts.bishopCompatibleCorners.entries
            .where((e) => e.value)
            .map((e) => e.key)
            .toSet(),
        (descriptorJson['bishopCompatibleCorners'] as List)
            .cast<String>()
            .toSet(),
      );
      expect(facts.protectionOpportunity, isFalse);
    },
  );

  test('complete current domains include all IDs and preserve occupancy invariants', () {
    final facts = provider(attempt(history.length));
    for (final snapshot in facts.snapshots.values) {
      final position = ExerciseJudge.exactPosition(
        facts.provenance!.snapshots[snapshot.ref]!.fen,
      )!;
      expect(snapshot.complete, isTrue);
      expect(
        snapshot.studentKingSquare,
        position.board.kingOf(trusted.student)!.name,
      );
      expect(snapshot.controls.keys.toSet(), AssessmentPiece.values.toSet());
      expect(snapshot.protections.keys.toSet(), AssessmentPiece.values.toSet());
      expect(snapshot.checks.keys.toSet(), AssessmentPiece.values.toSet());
      for (final id in AssessmentPiece.values) {
        final origin = position.board
            .bySide(trusted.student)
            .squares
            .singleWhere((s) => position.board.roleAt(s) == role(id));
        for (final file in 'abcdefgh'.split('')) {
          for (var rank = 1; rank <= 8; rank++) {
            final square = Square.parse('$file$rank')!;
            expect(
              snapshot.controls[id]!.contains(square.name),
              position.board.attacksTo(square, trusted.student).has(origin),
            );
          }
        }
        for (final targetName in snapshot.protections[id]!) {
          final target = Square.parse(targetName)!;
          expect(snapshot.controls[id], contains(targetName));
          expect(position.board.bySide(trusted.student).has(target), isTrue);
          expect(
            position.board.roleAt(target),
            isIn([Role.bishop, Role.knight]),
          );
          expect(target, isNot(origin));
        }
        expect(
          snapshot.checks[id]!.every(snapshot.controls[id]!.contains),
          isTrue,
        );
      }
      if (snapshot.ref != 'ply:0') {
        expect(snapshot.controlsAfterRelocation, isEmpty);
      }
    }
  });

  test('view and response permutations do not change facts; prefixes remain stable', () {
    final base = attempt(history.length);
    final full = provider(base);
    final changed = provider(
      change(base, {
        'viewSnapshotRef': 'ply:0',
        'draft': AssessmentDraft(
          editing: AssessmentEditingState(
            corner: 'learner-unconfirmed-choice',
            relationTargets: {'x', 'y'},
          ),
          relations: [
            for (final id in ['second', 'first'])
              AssessmentRelation(
                id: id,
                snapshotRef: 'learner-unconfirmed-ref',
                piece: AssessmentPiece.king,
                kind: AssessmentRelationKind.control,
                targetSquares: {id},
                useFor: {},
              ),
          ],
        ).toJson(),
      }),
    );
    for (var ply = 0; ply < frames.length; ply++) {
      final prefix = provider(attempt(ply));
      for (var previous = 0; previous <= ply; previous++) {
        final ref = 'ply:$previous';
        expect(prefix.snapshots[ref]!.controls, full.snapshots[ref]!.controls);
        expect(
          prefix.snapshots[ref]!.protections,
          full.snapshots[ref]!.protections,
        );
        expect(prefix.snapshots[ref]!.checks, full.snapshots[ref]!.checks);
        expect(changed.snapshots[ref]!.controls, full.snapshots[ref]!.controls);
      }
      if (prefix.protectionOpportunity) {
        expect(full.protectionOpportunity, isTrue);
      }
    }
  });

  test(
    'all checkpoint fields and visited references are verified independently',
    () {
      final base = attempt(history.length);
      final execution = base.execution.toJson();
      final forgedCounters = base.execution.gameFen.split(' ');
      forgedCounters[4] = '99';
      for (final delta in <Map<String, Object?>>[
        {'historyIdentity': 'forged'},
        {'historyVerified': false},
        {'studentTurn': !base.execution.studentTurn},
        {'studentMate': false},
        {'terminal': false},
        {'pending': true},
        {'gameFen': trusted.initialFen},
        {'gameFen': forgedCounters.join(' ')},
        {'played': history.take(history.length - 1).toList()},
        {
          'played': [...history, history.first],
        },
        {
          'visitedSnapshots': {
            ...base.execution.visitedSnapshots,
            'future': trusted.initialFen,
          },
        },
        {
          'visitedSnapshots': {
            ...base.execution.visitedSnapshots,
            'ply:0': base.execution.gameFen,
          },
        },
      ]) {
        expect(
          () => provider(
            change(base, {
              'execution': {...execution, ...delta},
            }),
          ),
          throwsA(isA<AssessmentFactsProviderException>()),
        );
      }
      expect(
        () => provider(change(base, {'viewSnapshotRef': 'future'})),
        throwsA(isA<AssessmentFactsProviderException>()),
      );
      expect(
        () => provider(
          change(base, {
            'contentIdentity': {'item': 'unrecognized'},
          }),
        ),
        throwsA(isA<AssessmentFactsProviderException>()),
      );
    },
  );

  test('descriptor root, material, versions, side and hash identities cannot drift', () {
    for (final delta in <Map<String, dynamic>>[
      {'student': 'black'},
      {'orientation': 'black'},
      {'assessmentVersion': 'old'},
      {'factualVersion': 'frozenInventory'},
      {'exerciseId': 'other'},
      {'initialFen': '${trusted.initialFen} '},
      {'initialFen': (frames[1]['fen'] as String)},
      {
        'sourceHashes': {
          ...trusted.sourceHashes,
          'contract': List.filled(64, '0').join(),
        },
      },
      {
        'initialFen':
            'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1',
      },
    ]) {
      expect(
        () => AssessmentRuntimeFactsProvider(
          descriptor({...descriptorJson, ...delta}),
        )(attempt(0)),
        throwsA(isA<AssessmentFactsProviderException>()),
      );
    }
  });

  test('private provenance is immutable, scoped and reproducible without claiming authentication', () {
    final a = attempt(history.length);
    final facts = provider(a);
    final meta = facts.provenance!;
    expect(meta.providerVersion, 'u1-runtime-geometry-v1');
    expect(meta.method, 'runtimeGeometry');
    expect(meta.descriptorId, trusted.descriptorId);
    expect(meta.descriptorVersion, trusted.assessmentVersion);
    expect(meta.sourceHashes, trusted.sourceHashes);
    expect(meta.contentIdentity, a.contentIdentity);
    expect(meta.attemptId, a.attemptId);
    expect(meta.revision, a.revision);
    expect(meta.historyIdentity, a.execution.historyIdentity);
    expect(meta.initialFen, trusted.initialFen);
    expect(meta.gameFen, a.execution.gameFen);
    expect(meta.student, trusted.student.name);
    expect(meta.snapshots.length, frames.length);
    expect(
      meta.domains['controlsAfterRelocation'],
      contains('rootEscapesOnly'),
    );
    expect(
      meta.factRef(
        'ply:0',
        AssessmentRelationKind.control,
        AssessmentPiece.king,
        'x',
      ),
      'ply:0/control/king/x',
    );
    expect(() => meta.sourceHashes.clear(), throwsUnsupportedError);
    expect(() => meta.contentIdentity.clear(), throwsUnsupportedError);
    expect(() => meta.snapshots.clear(), throwsUnsupportedError);
    expect(() => meta.domains.clear(), throwsUnsupportedError);
    expect(
      () => facts.snapshots['ply:0']!.controls[AssessmentPiece.king]!.clear(),
      throwsUnsupportedError,
    );
  });

  test('king protection is unsupported after temporal eligibility; B1/B2 still apply', () {
    final facts = provider(attempt(history.length));
    final frame = facts.snapshots.values.firstWhere(
      (s) => s.protections.values.any((v) => v.isNotEmpty),
    );
    final protector = AssessmentPiece.values.firstWhere(
      (id) => frame.protections[id]!.isNotEmpty,
    );
    final target = frame.protections[protector]!.first;
    AssessmentRelation relation(
      String id,
      Set<String> targets, {
      AssessmentRelationKind kind = AssessmentRelationKind.protection,
      AssessmentMoment moment = AssessmentMoment.visited,
      Set<AssessmentComponent> links = const {AssessmentComponent.protection},
    }) => AssessmentRelation(
      id: id,
      snapshotRef: frame.ref,
      piece: protector,
      kind: kind,
      targetSquares: targets,
      useFor: links,
      moment: moment,
    );
    AssessmentConceptResult evaluate(List<AssessmentRelation> relations) =>
        const AssessmentRelations().evaluate(
          initial: AssessmentDraft(),
          protection: AssessmentDraft(relations: relations),
          facts: facts,
          initialSubmitted: true,
          protectionSubmitted: true,
          executionComplete: true,
        );
    final king = evaluate([
      relation('king', {frame.studentKingSquare}),
    ]);
    expect(
      king.components[AssessmentComponent.protection],
      AssessmentVerdict.unsupported,
    );
    expect(king.pairs.single.reason, 'kingProtectionOutsideSupport');
    expect(
      evaluate([
        relation('future', {
          frame.studentKingSquare,
        }, moment: AssessmentMoment.plannedOrUnrepresented),
      ]).pairs.single.reason,
      'momentOutsideSupport',
    );
    expect(
      evaluate([
        relation('true', {target}),
        relation('king', {frame.studentKingSquare}),
      ]).components[AssessmentComponent.protection],
      AssessmentVerdict.supported,
    );
    expect(
      evaluate([
        relation('control', {target}, kind: AssessmentRelationKind.control),
      ]).components[AssessmentComponent.protection],
      AssessmentVerdict.incomplete,
    );
    expect(
      evaluate([
        relation('unlinked', {target}, links: {}),
      ]).components[AssessmentComponent.protection],
      AssessmentVerdict.incomplete,
    );
    final falseTarget = facts.knownEscapeSquares.firstWhere(
      (s) =>
          s != frame.studentKingSquare &&
          !frame.protections[protector]!.contains(s),
    );
    expect(
      evaluate([
        relation('grouped', {target, falseTarget}),
      ]).components[AssessmentComponent.protection],
      AssessmentVerdict.incorrect,
    );
  });

  test(
    'off-board relation targets remain unsupported rather than factual errors',
    () {
      final facts = provider(attempt(history.length));
      final frame = facts.snapshots.values.firstWhere(
        (s) => s.protections.values.any((v) => v.isNotEmpty),
      );
      final protector = AssessmentPiece.values.firstWhere(
        (id) => frame.protections[id]!.isNotEmpty,
      );
    for (final invalid in ['i9', 'A1', 'a0', 'a9', '', 'a1 ', 'a1\n']) {
        final result = const AssessmentRelations().evaluate(
          initial: AssessmentDraft(),
          protection: AssessmentDraft(
            relations: [
              AssessmentRelation(
                id: 'outside-domain',
                snapshotRef: frame.ref,
                piece: protector,
                kind: AssessmentRelationKind.protection,
                targetSquares: {invalid},
                useFor: {AssessmentComponent.protection},
                moment: AssessmentMoment.visited,
              ),
            ],
          ),
          facts: facts,
          initialSubmitted: true,
          protectionSubmitted: true,
          executionComplete: true,
        );
        expect(
          result.components[AssessmentComponent.protection],
          AssessmentVerdict.unsupported,
        );
        expect(result.pairs.single.reason, 'geometryOutsideSupport');
      }
    },
  );

  for (final finalPosition in [false, true]) {
    test(
      'real callback integrates closed ${finalPosition ? 'final' : 'root'} prefix without early exposure',
      () async {
        SharedPreferencesAsyncPlatform.instance =
            InMemorySharedPreferencesAsync.empty();
        final repository = LocalAssessmentAttemptRepository(
          PreferencesService(),
        );
        var factsCalls = 0;
        var replies = 1;
        final cubit = AssessmentCubit(
          config: AssessmentConfig(
            lessonId: trusted.lessonId,
            exerciseId: trusted.exerciseId,
            initialFen: trusted.initialFen,
            student: trusted.student,
            contentIdentity: trusted.contentIdentity,
            createAttemptId: () => 'private-integration',
            now: FixedNow(),
          ),
          repository: repository,
          pickOpponent: (position, visited) async {
            final move = Move.parse(history[replies]);
            replies += 2;
            return move;
          },
          facts: (a) async {
            factsCalls++;
            return provider(a);
          },
        );
        await cubit.load();
        await cubit.submitInitial();
        if (finalPosition) {
          for (var ply = 0; ply < history.length; ply += 2) {
            await cubit.play(Move.parse(history[ply])!);
            if (cubit.state.snapshot!.execution.pending) {
              await cubit.stream.firstWhere(
                (s) => !s.busy && !s.snapshot!.execution.pending,
              );
            }
          }
        } else {
          await cubit.finishExecution(voluntaryConfirmed: true);
        }
        expect(cubit.state.snapshot!.phase, AssessmentPhase.protection);
        expect(factsCalls, 0);
        expect(cubit.state.conceptualResult, isNull);
        await cubit.submitProtection();
        if (cubit.state.conceptualResult == null) {
          await cubit.stream.firstWhere(
            (s) => s.conceptualResult != null || s.technicalFailure != null,
          );
        }
        expect(factsCalls, 1);
        expect(cubit.state.technicalFailure, isNull);
        expect(cubit.state.snapshot!.phase, AssessmentPhase.closed);
        expect(
          cubit.state.conceptualResult!.components[AssessmentComponent
              .protection],
          finalPosition
              ? AssessmentVerdict.incomplete
              : AssessmentVerdict.unsupported,
        );
        await cubit.close();
      },
    );
  }
}

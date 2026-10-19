import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/data/repositories/endgames/assessment_attempt_repository.dart';
import 'package:lucena/data/services/preferences_service.dart';
import 'package:lucena/domain/models/assessment_attempt.dart';
import 'package:lucena/domain/use_cases/assessment_session.dart';
import 'package:lucena/domain/use_cases/now.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

final class RecordingPreferences extends PreferencesService {
  int writes = 0;
  final failingWrites = <int>{};
  final keys = <String>[];
  final values = <String>[];
  Completer<void>? gate;
  void Function(int)? afterWrite;

  @override
  Future<void> setString(String key, String value) async {
    writes++;
    keys.add(key);
    values.add(value);
    if (failingWrites.contains(writes)) {
      throw StateError('synthetic write failure');
    }
    if (gate != null) await gate!.future;
    await super.setString(key, value);
    afterWrite?.call(writes);
  }
}

final _at = DateTime.utc(2026, 1, 1);

final class _Now implements Now {
  DateTime value = _at;
  @override
  DateTime call() => value;
}

AssessmentAttempt sample({
  String id = 'one',
  String? parent,
  bool closed = false,
  int revision = 0,
}) => AssessmentAttempt(
  attemptId: id,
  parentAttemptId: parent,
  lessonId: 'mates.bishopKnight.deletang',
  exerciseId: 'finalNetAssessment01',
  contentIdentity: {
    'version': 'u1-relations-v2',
    'item': 'synthetic-content-hash',
  },
  startedAtUtc: _at,
  lastObservedUtc: _at,
  phase: closed ? AssessmentPhase.closed : AssessmentPhase.initial,
  revision: revision,
  exposed: parent != null,
  execution: AssessmentExecution(
    gameFen: 'synthetic-board',
    played: [],
    visitedSnapshots: {'initial': 'synthetic-board'},
    historyIdentity: 'synthetic-replay-hash',
    historyVerified: true,
    studentMate: false,
    terminal: false,
    studentTurn: true,
  ),
  draft: AssessmentDraft(),
  closedAtUtc: closed ? _at : null,
  closeReason: closed ? AssessmentCloseReason.cancelled : null,
);

AssessmentAttempt change(AssessmentAttempt a, Map<String, Object?> changes) =>
    AssessmentAttempt.fromJson({...a.toJson(), ...changes});

AssessmentAttempt collected() {
  final response = AssessmentDraft(
    target: AssessmentTarget(
      corner: 'learner-selection',
      colorPiece: AssessmentPiece.bishop,
      sameColor: true,
      accessSquares: {'selected-square'},
    ),
    relations: [
      AssessmentRelation(
        id: 'relation',
        snapshotRef: 'initial',
        piece: AssessmentPiece.king,
        kind: AssessmentRelationKind.control,
        targetSquares: {'selected-square'},
        useFor: {AssessmentComponent.pieces},
      ),
    ],
  );
  return change(sample(closed: true, revision: 3), {
    'submissions': [
      AssessmentSubmission(
        phase: AssessmentPhase.initial,
        atUtc: _at,
        response: response,
      ).toJson(),
    ],
    'help': [
      AssessmentHelp(
        atUtc: _at,
        source: 'requested',
        received: false,
        components: {AssessmentComponent.execution},
      ).toJson(),
    ],
    'draft': response.toJson(),
    'executionFinishedAtUtc': _at.toIso8601String(),
    'execution': AssessmentExecution(
      gameFen: 'synthetic-endpoint',
      played: ['synthetic-move'],
      visitedSnapshots: {
        'initial': 'synthetic-board',
        'visited': 'synthetic-endpoint',
      },
      historyIdentity: 'synthetic-endpoint-hash',
      historyVerified: true,
      studentMate: false,
      terminal: false,
      studentTurn: true,
    ).toJson(),
    'viewSnapshotRef': 'initial',
  });
}

void main() {
  late RecordingPreferences preferences;
  late LocalAssessmentAttemptRepository repository;

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    preferences = RecordingPreferences();
    repository = LocalAssessmentAttemptRepository(preferences);
  });

  test('only an absent dedicated key is empty', () async {
    expect(await repository.loadCurrent(), isNull);
    expect(await repository.loadById('missing'), isNull);
    expect(preferences.writes, 0);
  });

  test(
    'resume persists technical integrity closure without revising answers',
    () async {
      final original = sample();
      await repository.save(original);
      final restored = await AssessmentSession.resume(
        snapshot: original,
        contentIdentity: {'item': 'changed-content'},
        verifiedReplay: original.execution,
        now: _Now(),
        save: repository.save,
      );
      final saved = (await repository.loadCurrent())!;
      expect(saved.closeReason, AssessmentCloseReason.identityIntegrity);
      expect(saved.toJson(), restored.attempt.toJson());
      expect(saved.contentIdentity, original.contentIdentity);
      expect(saved.revision, original.revision);
      expect(saved.draft.toJson(), original.draft.toJson());
      await expectLater(
        repository.save(
          change(saved, {
            'callbackEpoch': saved.callbackEpoch + 1,
            'closeReason': 'historyIntegrity',
          }),
        ),
        throwsStateError,
      );
    },
  );

  test(
    'one envelope write round-trips answers, help and actual execution',
    () async {
      await PreferencesService().setString(
        'endgames.progress',
        'legacy-sentinel',
      );
      final attempt = collected();
      await repository.save(attempt);
      expect(preferences.writes, 1);
      expect(preferences.keys, [LocalAssessmentAttemptRepository.key]);
      final envelope = jsonDecode(preferences.values.single) as Map;
      expect(envelope.keys.toSet(), {
        'schemaVersion',
        'currentAttemptId',
        'attempts',
      });
      expect(envelope['currentAttemptId'], attempt.attemptId);
      expect((await repository.loadCurrent())!.toJson(), attempt.toJson());
      expect(
        (await repository.loadById('one'))!.execution.gameFen,
        'synthetic-endpoint',
      );
      expect((await repository.loadById('one'))!.viewSnapshotRef, 'initial');
      expect(
        await PreferencesService().getString('endgames.progress'),
        'legacy-sentinel',
      );
    },
  );

  test(
    'retry preserves earlier responses and current pointer after reopening',
    () async {
      final original = collected();
      await repository.save(original);
      final retry = sample(id: 'two', parent: 'one');
      await repository.save(retry);
      final reopened = LocalAssessmentAttemptRepository(PreferencesService());
      expect((await reopened.loadCurrent())!.attemptId, 'two');
      expect((await reopened.loadById('one'))!.toJson(), original.toJson());
      expect((await reopened.loadById('two'))!.parentAttemptId, 'one');
      expect((await reopened.loadById('two'))!.exposed, isTrue);
    },
  );

  test('new roots, unknown parents, open parents and archived rewrites are rejected', () async {
    await expectLater(
      repository.save(sample(parent: 'missing')),
      throwsStateError,
    );
    await repository.save(sample());
    await expectLater(
      repository.save(sample(id: 'two', parent: 'one')),
      throwsStateError,
    );
    await repository.save(
      change(sample(), {
        'revision': 1,
        'phase': 'closed',
        'closedAtUtc': _at.toIso8601String(),
        'closeReason': 'cancelled',
      }),
    );
    await expectLater(repository.save(sample(id: 'two')), throwsStateError);
    await expectLater(
      repository.save(sample(id: 'two', parent: 'missing')),
      throwsStateError,
    );
    await repository.save(sample(id: 'two', parent: 'one'));
    await expectLater(
      repository.save(sample(closed: true, revision: 2)),
      throwsStateError,
    );
    expect((await repository.loadCurrent())!.attemptId, 'two');
  });

  test(
    'a failed second write remains visible to its caller and queue recovers',
    () async {
      await repository.save(sample());
      preferences.failingWrites.add(2);
      final failing = repository.save(sample(revision: 1));
      final recovered = repository.save(sample(revision: 2));
      await expectLater(failing, throwsStateError);
      await recovered;
      expect((await repository.loadCurrent())!.revision, 2);
      expect(preferences.writes, 3);
    },
  );

  test(
    'load waits for queued writes and concurrent saves preserve revisions',
    () async {
      preferences.gate = Completer<void>();
      final first = repository.save(sample());
      final second = repository.save(sample(revision: 1));
      bool loaded = false;
      final load = repository.loadCurrent().then((a) {
        loaded = true;
        return a;
      });
      await Future<void>.delayed(Duration.zero);
      expect(loaded, isFalse);
      expect(preferences.writes, 1);
      preferences.gate!.complete();
      await Future.wait([first, second]);
      expect((await load)!.revision, 1);
      expect(preferences.writes, 2);
    },
  );

  test(
    'corrupt or unknown envelope data is neither empty nor overwritten',
    () async {
      for (final text in [
        '',
        'null',
        '{broken',
        '{}',
        '{"schemaVersion":99,"currentAttemptId":"one","attempts":{}}',
        '{"schemaVersion":1,"currentAttemptId":"missing","attempts":{}}',
        jsonEncode({
          'schemaVersion': 1,
          'currentAttemptId': 'one',
          'attempts': {
            'one': {...sample().toJson(), 'schemaVersion': 99},
          },
        }),
      ]) {
        await PreferencesService().setString(
          LocalAssessmentAttemptRepository.key,
          text,
        );
        await expectLater(
          repository.loadCurrent(),
          throwsA(isA<AssessmentAttemptStorageException>()),
        );
        await expectLater(
          repository.loadById('missing'),
          throwsA(isA<AssessmentAttemptStorageException>()),
        );
        await expectLater(
          repository.save(sample()),
          throwsA(isA<AssessmentAttemptStorageException>()),
        );
        expect(
          await PreferencesService().getString(
            LocalAssessmentAttemptRepository.key,
          ),
          text,
        );
      }
      expect(preferences.writes, 0);
    },
  );

  test('malformed lineage is a reproducible technical failure', () async {
    for (final rows in [
      {'one': sample(parent: 'missing').toJson()},
      {'one': sample().toJson(), 'other': sample(id: 'other').toJson()},
      {'one': sample(parent: 'one', closed: true).toJson()},
    ]) {
      await PreferencesService().setString(
        LocalAssessmentAttemptRepository.key,
        jsonEncode({
          'schemaVersion': 1,
          'currentAttemptId': 'one',
          'attempts': rows,
        }),
      );
      await expectLater(
        repository.loadCurrent(),
        throwsA(isA<AssessmentAttemptStorageException>()),
      );
    }
  });

  test(
    'old revisions, identity changes and frozen record edits never write',
    () async {
      final original = collected();
      await repository.save(original);
      for (final delta in <Map<String, Object?>>[
        {'revision': 2},
        {
          'contentIdentity': {'version': 'another', 'item': 'changed'},
        },
        {'startedAtUtc': _at.add(const Duration(seconds: 1)).toIso8601String()},
        {'parentAttemptId': 'another'},
        {'submissions': []},
        {
          'submissions': [
            {
              ...original.submissions.single.toJson(),
              'atUtc': _at.add(const Duration(seconds: 1)).toIso8601String(),
            },
          ],
        },
        {'help': []},
        {
          'help': [
            {...original.help.single.toJson(), 'received': true},
          ],
        },
        {'execution': sample().execution.toJson()},
        {'draft': AssessmentDraft().toJson()},
        {'phase': 'initial'},
      ]) {
        await expectLater(
          repository.save(change(original, delta)),
          throwsStateError,
        );
      }
      expect(preferences.writes, 1);
      expect((await repository.loadCurrent())!.toJson(), original.toJson());
      await expectLater(
        repository.save(
          change(sample(id: 'two', parent: 'one'), {
            'contentIdentity': {'item': 'other-version'},
          }),
        ),
        throwsStateError,
      );
    },
  );

  test(
    'append preserves records and same-revision closure diagnosis may change',
    () async {
      final original = change(collected(), {
        'phase': 'protection',
        'closedAtUtc': null,
        'closeReason': null,
      });
      await repository.save(original);
      final appended = change(original, {
        'revision': 4,
        'help': [
          ...original.help.map((h) => h.toJson()),
          AssessmentHelp(
            atUtc: _at,
            source: 'receipt',
            received: true,
            components: {AssessmentComponent.execution},
          ).toJson(),
        ],
      });
      await repository.save(appended);
      final reclassified = change(appended, {
        'phase': 'closed',
        'closeReason': 'timeLimit',
        'closedAtUtc': _at.add(const Duration(seconds: 600)).toIso8601String(),
        'callbackEpoch': 1,
      });
      await repository.save(reclassified);
      final loaded = (await repository.loadCurrent())!;
      expect(loaded.closeReason, AssessmentCloseReason.timeLimit);
      expect(loaded.revision, 4);
      expect(
        loaded.submissions.single.toJson(),
        original.submissions.single.toJson(),
      );
      expect(loaded.help.length, 2);
    },
  );

  test(
    'same revision rejects conflicting draft but accepts exact replay',
    () async {
      final original = sample();
      await repository.save(original);
      await repository.save(original);
      final before = preferences.writes;
      await expectLater(
        repository.save(
          change(original, {
            'draft': AssessmentDraft(
              target: AssessmentTarget(
                corner: 'learner-choice',
                colorPiece: AssessmentPiece.king,
                sameColor: false,
                accessSquares: {},
              ),
            ).toJson(),
          }),
        ),
        throwsStateError,
      );
      expect(preferences.writes, before);
      expect((await repository.loadCurrent())!.toJson(), original.toJson());
    },
  );

  test(
    'closed cancellation cannot become submitted or acquire records',
    () async {
      final original = sample(closed: true);
      await repository.save(original);
      for (final delta in <Map<String, Object?>>[
        {'closeReason': 'submitted'},
        {'revision': 1, 'closeReason': 'submitted'},
        {
          'revision': 1,
          'help': [
            AssessmentHelp(
              atUtc: _at,
              source: 'late',
              received: false,
              components: {},
            ).toJson(),
          ],
        },
        {'closeReason': 'timeLimit', 'callbackEpoch': 1},
      ]) {
        await expectLater(
          repository.save(change(original, delta)),
          throwsStateError,
        );
      }
      expect((await repository.loadCurrent())!.toJson(), original.toJson());
    },
  );

  test(
    'real session and repository recover the exact failed clock closure',
    () async {
      final now = _Now();
      preferences.failingWrites.add(3);
      preferences.afterWrite = (count) {
        if (count == 2) now.value = _at.add(const Duration(seconds: 600));
      };
      final session = await AssessmentSession.start(
        attemptId: 'one',
        lessonId: sample().lessonId,
        exerciseId: sample().exerciseId,
        contentIdentity: sample().contentIdentity,
        initialExecution: sample().execution,
        now: now,
        save: repository.save,
      );
      now.value = _at.add(const Duration(seconds: 599));
      await expectLater(session.submitInitial(), throwsStateError);
      expect((await repository.loadCurrent())!.submissions, hasLength(1));
      now.value = _at.add(const Duration(seconds: 599));
      await session.observeTime();
      final saved = (await repository.loadCurrent())!;
      expect(saved.closeReason, AssessmentCloseReason.timeLimit);
      expect(saved.submissions, hasLength(1));
      expect(saved.toJson(), session.attempt.toJson());
    },
  );
}

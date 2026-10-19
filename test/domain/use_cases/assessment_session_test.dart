import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/assessment_attempt.dart';
import 'package:lucena/domain/use_cases/assessment_session.dart';
import 'package:lucena/domain/use_cases/now.dart';

final class TestNow implements Now {
  DateTime value = DateTime.utc(2026, 1, 1);
  @override
  DateTime call() => value;
  void seconds(int seconds) => value = value.add(Duration(seconds: seconds));
}

AssessmentExecution replay({
  bool terminal = false,
  bool mate = false,
  bool pending = false,
  bool studentTurn = true,
  bool verified = true,
  List<String> played = const [],
}) => AssessmentExecution(
  gameFen: played.isEmpty ? 'initial-board' : 'endpoint-board',
  played: played,
  visitedSnapshots: {
    'initial': 'initial-board',
    if (played.isNotEmpty) 'endpoint': 'endpoint-board',
  },
  historyIdentity: played.isEmpty ? 'root-hash' : 'endpoint-hash',
  historyVerified: verified,
  studentMate: mate,
  terminal: terminal,
  studentTurn: studentTurn,
  pending: pending,
);

Future<AssessmentSession> start(TestNow now, {SaveAssessmentAttempt? save}) =>
    AssessmentSession.start(
      attemptId: 'one',
      lessonId: 'mates.bishopKnight.deletang',
      exerciseId: 'finalNetAssessment01',
      contentIdentity: {'item': 'hash'},
      initialExecution: replay(),
      now: now,
      save: save ?? (_) async {},
    );

Future<void> update(AssessmentSession session, AssessmentExecution value) =>
    session.updateExecution(
      token: session.callbackToken,
      contentIdentity: {'item': 'hash'},
      execution: value,
    );

void main() {
  test(
    'start and retry reject a terminal initial replay before saving',
    () async {
      final now = TestNow();
      var writes = 0;
      Future<void> save(AssessmentAttempt _) async {
        writes++;
      }

      final session = await start(now, save: save);
      await session.cancel();
      final before = writes;
      for (final initial in [
        replay(terminal: true),
        replay(terminal: true, mate: true),
      ]) {
        await expectLater(
          AssessmentSession.start(
            attemptId: 'new',
            lessonId: session.attempt.lessonId,
            exerciseId: session.attempt.exerciseId,
            contentIdentity: {'item': 'hash'},
            initialExecution: initial,
            now: now,
            save: save,
          ),
          throwsStateError,
        );
        await expectLater(
          session.retry(attemptId: 'new', initialExecution: initial),
          throwsStateError,
        );
      }
      expect(writes, before);
    },
  );

  test(
    'second save failure blocks stale state and recovers durable response',
    () async {
      final now = TestNow();
      AssessmentAttempt? durable;
      var writes = 0;
      final session = await start(
        now,
        save: (value) async {
          writes++;
          if (writes == 3) throw StateError('closure write failed');
          durable = value;
          if (writes == 2) now.seconds(1);
        },
      );
      now.seconds(599);
      await expectLater(session.submitInitial(), throwsStateError);
      expect(durable!.phase, AssessmentPhase.execution);
      expect(durable!.submissions, hasLength(1));
      expect(() => session.attempt, throwsStateError);
      expect(() => session.callbackToken, throwsStateError);
      await expectLater(
        session.replaceDraft(AssessmentDraft()),
        throwsStateError,
      );
      // Expiry already observed cannot be undone during recovery.
      now.seconds(-1);
      await session.observeTime();
      expect(session.attempt.phase, AssessmentPhase.closed);
      expect(session.attempt.closeReason, AssessmentCloseReason.timeLimit);
      expect(session.attempt.submissions, hasLength(1));
      expect(durable!.toJson(), session.attempt.toJson());
    },
  );

  test(
    'resume rejects advanced initial history and incompatible close markers',
    () async {
      final now = TestNow();
      final original = await start(now);
      for (final change in <Map<String, Object?>>[
        {
          'execution': replay(played: ['synthetic-move']).toJson(),
        },
        {'closeReason': AssessmentCloseReason.submitted.name},
      ]) {
        final invalid = AssessmentAttempt.fromJson({
          ...original.attempt.toJson(),
          ...change,
        });
        final resumed = await AssessmentSession.resume(
          snapshot: invalid,
          contentIdentity: {'item': 'hash'},
          verifiedReplay: invalid.execution,
          now: now,
          save: (_) async {},
        );
        expect(
          resumed.attempt.closeReason,
          AssessmentCloseReason.historyIntegrity,
        );
        await expectLater(resumed.submitInitial(), throwsStateError);
      }
    },
  );

  test('retry rejects empty id before saving', () async {
    final now = TestNow();
    var writes = 0;
    final session = await start(
      now,
      save: (_) async {
        writes++;
      },
    );
    await session.cancel();
    final before = writes;
    await expectLater(
      session.retry(attemptId: '', initialExecution: replay()),
      throwsStateError,
    );
    expect(writes, before);
  });

  test(
    '599 seconds accepts; 600 closes across phases without extending deadline',
    () async {
      final now = TestNow();
      final session = await start(now);
      final deadline = session.attempt.deadlineUtc;
      now.seconds(599);
      await session.submitInitial();
      await session.finishExecution(voluntaryConfirmed: true);
      expect(session.attempt.phase, AssessmentPhase.protection);
      expect(session.attempt.feedbackVisible, isFalse);
      expect(session.attempt.deadlineUtc, deadline);
      now.seconds(1);
      await session.submitProtection();
      expect(session.attempt.closeReason, AssessmentCloseReason.timeLimit);
      expect(session.attempt.submissions.length, 1);
    },
  );

  test(
    'finish freezes replay, rejects stale play and keeps view separate',
    () async {
      final now = TestNow();
      final session = await start(now);
      await session.submitInitial();
      final token = session.callbackToken;
      await update(
        session,
        replay(played: ['synthetic-move'], terminal: true, mate: true),
      );
      await session.finishExecution(voluntaryConfirmed: false);
      expect(session.attempt.execution.studentMate, isTrue);
      await session.selectVisitedSnapshot('initial');
      expect(session.attempt.viewSnapshotRef, 'initial');
      expect(session.attempt.execution.gameFen, 'endpoint-board');
      await expectLater(
        session.selectVisitedSnapshot('future'),
        throwsStateError,
      );
      await expectLater(
        session.updateExecution(
          token: token,
          contentIdentity: {'item': 'hash'},
          execution: replay(),
        ),
        throwsStateError,
      );
      await session.submitProtection();
      expect(session.attempt.phase, AssessmentPhase.closed);
      expect(session.attempt.feedbackVisible, isTrue);
      expect(session.attempt.submissions.map((s) => s.phase), [
        AssessmentPhase.initial,
        AssessmentPhase.protection,
      ]);
    },
  );

  test('voluntary exit requires confirmation and stable execution', () async {
    final session = await start(TestNow());
    await session.submitInitial();
    await expectLater(
      session.finishExecution(voluntaryConfirmed: false),
      throwsStateError,
    );
    expect(session.attempt.phase, AssessmentPhase.execution);
    await update(session, replay(pending: true));
    await expectLater(
      session.finishExecution(voluntaryConfirmed: true),
      throwsStateError,
    );
    await update(session, replay(studentTurn: false));
    await expectLater(
      session.finishExecution(voluntaryConfirmed: true),
      throwsStateError,
    );
  });

  test(
    'save failure preserves published phase; expiry during await closes',
    () async {
      final now = TestNow();
      bool fail = false;
      Completer<void>? gate;
      final session = await start(
        now,
        save: (_) async {
          if (fail) throw StateError('disk');
          if (gate != null) await gate.future;
        },
      );
      fail = true;
      await expectLater(session.submitInitial(), throwsStateError);
      expect(session.attempt.phase, AssessmentPhase.initial);
      fail = false;
      gate = Completer<void>();
      final submit = session.submitInitial();
      expect(session.attempt.phase, AssessmentPhase.initial);
      now.seconds(600);
      gate.complete();
      await submit;
      expect(session.attempt.phase, AssessmentPhase.closed);
      expect(session.attempt.closeReason, AssessmentCloseReason.timeLimit);
    },
  );

  test(
    'resume catches rollback, expired background, identity and changed history',
    () async {
      for (final scenario in ['rollback', 'expired', 'identity', 'history']) {
        final now = TestNow();
        final session = await start(now);
        now.seconds(10);
        await session.observeTime();
        final snapshot = AssessmentAttempt.fromJson(session.attempt.toJson());
        if (scenario == 'rollback') now.seconds(-1);
        if (scenario == 'expired') now.seconds(600);
        final restored = await AssessmentSession.resume(
          snapshot: snapshot,
          contentIdentity: {
            'item': scenario == 'identity' ? 'changed' : 'hash',
          },
          verifiedReplay: replay(verified: scenario != 'history'),
          now: now,
          save: (_) async {},
        );
        expect(restored.attempt.phase, AssessmentPhase.closed);
        expect(restored.attempt.closeReason, switch (scenario) {
          'rollback' => AssessmentCloseReason.clockIntegrity,
          'expired' => AssessmentCloseReason.timeLimit,
          'identity' => AssessmentCloseReason.identityIntegrity,
          _ => AssessmentCloseReason.historyIntegrity,
        });
      }
    },
  );

  test('help request differs from receipt; retry preserves prior snapshot and exposure', () async {
    final session = await start(TestNow());
    await session.replaceDraft(
      AssessmentDraft(
        target: AssessmentTarget(
          corner: 'learner-choice',
          colorPiece: AssessmentPiece.bishop,
          sameColor: true,
          accessSquares: {},
        ),
      ),
    );
    await session.submitInitial();
    await session.requestHelp(
      source: 'learner',
      components: {AssessmentComponent.execution},
    );
    expect(session.attempt.phase, AssessmentPhase.execution);
    expect(session.attempt.help.single.received, isFalse);
    await session.receiveHelp(
      source: 'hint',
      components: {AssessmentComponent.execution},
    );
    expect(session.attempt.closeReason, AssessmentCloseReason.assistance);
    final previous = session.attempt.toJson();
    final retry = await session.retry(
      attemptId: 'two',
      initialExecution: replay(),
      assistedContinuation: true,
    );
    expect(retry.attempt.parentAttemptId, 'one');
    expect(retry.attempt.assisted, isTrue);
    expect(retry.attempt.exposed, isTrue);
    expect(session.attempt.toJson(), previous);
    expect(
      session.attempt.submissions.single.response.target!.corner,
      'learner-choice',
    );
  });
}

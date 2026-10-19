import '../models/assessment_attempt.dart';
import 'now.dart';

typedef SaveAssessmentAttempt = Future<void> Function(
  AssessmentAttempt attempt,
);

/// An adapter may deliver an asynchronous replay only to its original attempt.
final class AssessmentCallbackToken {
  const AssessmentCallbackToken(this.attemptId, this.epoch);
  final String attemptId;
  final int epoch;
}

/// Collection only: callers must not reveal content before [start] completes.
/// Save must atomically persist the complete attempt and execution checkpoint.
final class AssessmentSession {
  AssessmentSession._(this._attempt, this._now, this._save);

  AssessmentAttempt _attempt;
  final Now _now;
  final SaveAssessmentAttempt _save;
  bool _busy = false;
  bool _requiresRecovery = false;
  AssessmentAttempt? _requiredClosure;

  AssessmentAttempt get attempt {
    _checkRecovery();
    return _attempt;
  }

  AssessmentCallbackToken get callbackToken {
    _checkRecovery();
    return AssessmentCallbackToken(_attempt.attemptId, _attempt.callbackEpoch);
  }

  void _checkRecovery() {
    if (_requiresRecovery) {
      throw StateError(
        'Observe time or restore the last durable attempt first',
      );
    }
  }

  static Future<AssessmentSession> start({
    required String attemptId,
    required String lessonId,
    required String exerciseId,
    required Map<String, String> contentIdentity,
    required AssessmentExecution initialExecution,
    required Now now,
    required SaveAssessmentAttempt save,
  }) async {
    if (lessonId != 'mates.bishopKnight.deletang' ||
        exerciseId != 'finalNetAssessment01' ||
        attemptId.isEmpty ||
        contentIdentity.isEmpty) {
      throw ArgumentError('Only the identified U1 consumer is supported');
    }
    if (!initialExecution.historyVerified ||
        initialExecution.terminal ||
        initialExecution.studentMate ||
        initialExecution.pending ||
        initialExecution.played.isNotEmpty) {
      throw StateError('A verified initial replay is required');
    }
    final at = now().toUtc();
    final session = AssessmentSession._(
      AssessmentAttempt(
        attemptId: attemptId,
        lessonId: lessonId,
        exerciseId: exerciseId,
        contentIdentity: contentIdentity,
        startedAtUtc: at,
        lastObservedUtc: at,
        execution: initialExecution,
        draft: AssessmentDraft(),
      ),
      now,
      save,
    );
    await session._commit(session.attempt);
    return session;
  }

  /// Restoring always revalidates identity and full replay through the adapter.
  static Future<AssessmentSession> resume({
    required AssessmentAttempt snapshot,
    required Map<String, String> contentIdentity,
    required AssessmentExecution verifiedReplay,
    required Now now,
    required SaveAssessmentAttempt save,
  }) async {
    final session = AssessmentSession._(snapshot, now, save);
    AssessmentCloseReason? failure;
    if (snapshot.lessonId != 'mates.bishopKnight.deletang' ||
        snapshot.exerciseId != 'finalNetAssessment01' ||
        snapshot.attemptId.isEmpty ||
        snapshot.contentIdentity.isEmpty ||
        !_sameMap(snapshot.contentIdentity, contentIdentity)) {
      failure = AssessmentCloseReason.identityIntegrity;
    } else if (!_structurallyValid(snapshot) ||
        !verifiedReplay.historyVerified ||
        !_sameHistory(snapshot.execution, verifiedReplay)) {
      failure = AssessmentCloseReason.historyIntegrity;
    }
    if (snapshot.phase == AssessmentPhase.closed) {
      if (failure != null) {
        throw StateError('Closed snapshot integrity failure');
      }
      return session;
    }
    if (failure != null) {
      await session._commit(session._closed(snapshot, failure, now().toUtc()));
    } else {
      await session._run(
        (a, at) => session._copy(a, {'callbackEpoch': a.callbackEpoch + 1}),
      );
    }
    return session;
  }

  Future<void> observeTime() async {
    if (_requiresRecovery) {
      if (_busy) throw StateError('A persistence operation is in progress');
      _busy = true;
      try {
        // Retry the exact closing write, rather than creating a new revision
        // or changing the already observed clock failure.
        await _commit(_requiredClosure!);
      } finally {
        _busy = false;
      }
    } else if (_attempt.phase != AssessmentPhase.closed) {
      await _run((a, at) => a);
    }
  }

  Future<void> replaceDraft(AssessmentDraft draft) => _run((a, at) {
    if (a.phase != AssessmentPhase.initial &&
        a.phase != AssessmentPhase.protection) {
      throw StateError('Collection is not open');
    }
    return _copy(a, {'draft': draft.toJson()});
  });

  Future<void> submitInitial() => _run((a, at) {
    _phase(a, AssessmentPhase.initial);
    return _copy(a, {
      'phase': AssessmentPhase.execution.name,
      'draft': AssessmentDraft().toJson(),
      'submissions': [
        ...a.submissions.map((s) => s.toJson()),
        AssessmentSubmission(
          phase: AssessmentPhase.initial,
          atUtc: at,
          response: a.draft,
        ).toJson(),
      ],
    });
  });

  Future<void> updateExecution({
    required AssessmentCallbackToken token,
    required Map<String, String> contentIdentity,
    required AssessmentExecution execution,
  }) => _run((a, at) {
    _phase(a, AssessmentPhase.execution);
    if (token.attemptId != a.attemptId || token.epoch != a.callbackEpoch) {
      throw StateError('Stale execution callback');
    }
    if (!_sameMap(a.contentIdentity, contentIdentity)) {
      return _closed(a, AssessmentCloseReason.identityIntegrity, at);
    }
    if (!execution.historyVerified || !_extends(a.execution, execution)) {
      return _closed(a, AssessmentCloseReason.historyIntegrity, at);
    }
    return _copy(a, {'execution': execution.toJson()});
  });

  /// Call after neutral confirmation for voluntary exit. Cancellation requires
  /// no command: execution and its original deadline remain untouched.
  Future<void> finishExecution({required bool voluntaryConfirmed}) => _run((
    a,
    at,
  ) {
    _phase(a, AssessmentPhase.execution);
    final execution = a.execution;
    if (!execution.historyVerified) {
      return _closed(a, AssessmentCloseReason.historyIntegrity, at);
    }
    if (execution.pending || (!execution.terminal && !execution.studentTurn)) {
      throw StateError('Execution has an unsettled operation');
    }
    if (!execution.terminal && !voluntaryConfirmed) {
      throw StateError('Voluntary finish needs confirmation');
    }
    return _copy(a, {
      'phase': AssessmentPhase.protection.name,
      'executionFinishedAtUtc': at.toIso8601String(),
      'callbackEpoch': a.callbackEpoch + 1,
      'draft': AssessmentDraft().toJson(),
    });
  });

  Future<void> selectVisitedSnapshot(String ref) => _run((a, at) {
    _phase(a, AssessmentPhase.protection);
    if (!a.execution.visitedSnapshots.containsKey(ref)) {
      throw StateError('Snapshot was not visited');
    }
    return _copy(a, {'viewSnapshotRef': ref});
  });

  Future<void> submitProtection() => _run((a, at) {
    _phase(a, AssessmentPhase.protection);
    final submitted = _copy(a, {
      'submissions': [
        ...a.submissions.map((s) => s.toJson()),
        AssessmentSubmission(
          phase: AssessmentPhase.protection,
          atUtc: at,
          response: a.draft,
        ).toJson(),
      ],
    });
    return _closed(submitted, AssessmentCloseReason.submitted, at);
  });

  Future<void> cancel() =>
      _run((a, at) => _closed(a, AssessmentCloseReason.cancelled, at));

  Future<void> requestHelp({
    required String source,
    required Set<AssessmentComponent> components,
  }) => _recordHelp(source, components, false);

  /// Must complete durably BEFORE an adapter supplies correction or a solution.
  /// The independent attempt closes; assisted continuation uses a new linked id.
  Future<void> receiveHelp({
    required String source,
    required Set<AssessmentComponent> components,
  }) => _recordHelp(source, components, true);

  Future<void> _recordHelp(
    String source,
    Set<AssessmentComponent> components,
    bool received,
  ) => _run((a, at) {
    final next = _copy(a, {
      'help': [
        ...a.help.map((h) => h.toJson()),
        AssessmentHelp(
          atUtc: at,
          source: source,
          received: received,
          components: components,
        ).toJson(),
      ],
      'exposed': a.exposed || received,
    });
    return received
        ? _closed(next, AssessmentCloseReason.assistance, at)
        : next;
  });

  Future<AssessmentSession> retry({
    required String attemptId,
    required AssessmentExecution initialExecution,
    bool assistedContinuation = false,
  }) async {
    _checkRecovery();
    if (_busy || _attempt.phase != AssessmentPhase.closed) {
      throw StateError('Retry requires a closed durable attempt');
    }
    if (attemptId.isEmpty ||
        attemptId == _attempt.attemptId ||
        !initialExecution.historyVerified ||
        initialExecution.terminal ||
        initialExecution.studentMate ||
        initialExecution.pending ||
        initialExecution.played.isNotEmpty) {
      throw StateError(
        'Retry needs a new identity and verified initial replay',
      );
    }
    final at = _now().toUtc();
    final next = AssessmentSession._(
      AssessmentAttempt(
        attemptId: attemptId,
        parentAttemptId: _attempt.attemptId,
        lessonId: _attempt.lessonId,
        exerciseId: _attempt.exerciseId,
        contentIdentity: _attempt.contentIdentity,
        startedAtUtc: at,
        lastObservedUtc: at,
        execution: initialExecution,
        draft: AssessmentDraft(),
        assisted: assistedContinuation,
        exposed: true,
      ),
      _now,
      _save,
    );
    await next._commit(next.attempt);
    return next;
  }

  Future<void> _run(
    AssessmentAttempt Function(AssessmentAttempt, DateTime) transition,
  ) async {
    _checkRecovery();
    if (_busy) throw StateError('A persistence operation is in progress');
    if (_attempt.phase == AssessmentPhase.closed && !_requiresRecovery) {
      throw StateError('The assessment attempt is closed');
    }
    _busy = true;
    try {
      final at = _now().toUtc();
      final invalid = _clockFailure(_attempt, at);
      final next = invalid == null
          ? transition(_attempt, at)
          : _closed(_attempt, invalid, at);
      await _commit(
        _copy(next, {
          'revision': _attempt.revision + 1,
          'lastObservedUtc':
              (at.isBefore(next.lastObservedUtc) ? next.lastObservedUtc : at)
                  .toIso8601String(),
        }),
      );
    } finally {
      _busy = false;
    }
  }

  Future<void> _commit(AssessmentAttempt next) async {
    await _save(next);
    // This version is durable even if the clock-triggered second write fails.
    _attempt = next;
    final at = _now().toUtc();
    final failure =
        _requiredClosure != null && next.phase == AssessmentPhase.closed
        ? null
        : _clockFailure(next, at);
    if (failure != null) {
      next = _closed(next, failure, at);
      _requiresRecovery = true;
      _requiredClosure = next;
      await _save(next);
    }
    _attempt = next;
    _requiresRecovery = false;
    _requiredClosure = null;
  }

  AssessmentCloseReason? _clockFailure(AssessmentAttempt a, DateTime at) {
    if (at.isBefore(a.lastObservedUtc)) {
      return AssessmentCloseReason.clockIntegrity;
    }
    if (!at.isBefore(a.deadlineUtc)) return AssessmentCloseReason.timeLimit;
    return null;
  }

  AssessmentAttempt _closed(
    AssessmentAttempt a,
    AssessmentCloseReason reason,
    DateTime at,
  ) => _copy(a, {
    'phase': AssessmentPhase.closed.name,
    'closeReason': reason.name,
    'closedAtUtc': at.toIso8601String(),
    'callbackEpoch': a.callbackEpoch + 1,
  });

  AssessmentAttempt _copy(AssessmentAttempt a, Map<String, Object?> changes) =>
      AssessmentAttempt.fromJson({...a.toJson(), ...changes});
}

void _phase(AssessmentAttempt a, AssessmentPhase expected) {
  if (a.phase != expected) throw StateError('Wrong assessment phase');
}

bool _sameMap(Map<String, String> a, Map<String, String> b) =>
    a.length == b.length && a.entries.every((e) => b[e.key] == e.value);

bool _sameHistory(AssessmentExecution a, AssessmentExecution b) =>
    a.gameFen == b.gameFen &&
    a.historyIdentity == b.historyIdentity &&
    a.studentMate == b.studentMate &&
    a.terminal == b.terminal &&
    a.studentTurn == b.studentTurn &&
    a.played.length == b.played.length &&
    _extends(a, b) &&
    _sameMap(a.visitedSnapshots, b.visitedSnapshots);

bool _extends(AssessmentExecution old, AssessmentExecution next) =>
    (!next.studentMate || next.terminal) &&
    (!old.terminal ||
        (next.terminal && next.played.length == old.played.length)) &&
    (next.played.length != old.played.length ||
        (next.gameFen == old.gameFen &&
            next.historyIdentity == old.historyIdentity)) &&
    next.played.length >= old.played.length &&
    old.played.asMap().entries.every((e) => next.played[e.key] == e.value) &&
    old.visitedSnapshots.entries.every(
      (e) => next.visitedSnapshots[e.key] == e.value,
    );

bool _structurallyValid(AssessmentAttempt a) {
  if (a.lastObservedUtc.isBefore(a.startedAtUtc) ||
      a.revision < 0 ||
      a.callbackEpoch < 0 ||
      (a.viewSnapshotRef != null &&
          !a.execution.visitedSnapshots.containsKey(a.viewSnapshotRef))) {
    return false;
  }
  if (a.phase != AssessmentPhase.closed &&
      (a.closedAtUtc != null || a.closeReason != null)) {
    return false;
  }
  final finished = a.executionFinishedAtUtc;
  if (finished != null &&
      (finished.isBefore(a.startedAtUtc) ||
          !finished.isBefore(a.deadlineUtc) ||
          finished.isAfter(a.lastObservedUtc) ||
          a.execution.pending ||
          (!a.execution.terminal && !a.execution.studentTurn))) {
    return false;
  }
  final initial = a.submissions
      .where((s) => s.phase == AssessmentPhase.initial)
      .length;
  final protection = a.submissions
      .where((s) => s.phase == AssessmentPhase.protection)
      .length;
  if (initial > 1 ||
      protection > 1 ||
      initial + protection != a.submissions.length ||
      a.submissions.any(
        (s) =>
            s.atUtc.isBefore(a.startedAtUtc) ||
            !s.atUtc.isBefore(a.deadlineUtc),
      )) {
    return false;
  }
  return switch (a.phase) {
    AssessmentPhase.initial =>
      initial == 0 &&
          protection == 0 &&
          a.executionFinishedAtUtc == null &&
          a.execution.played.isEmpty &&
          !a.execution.terminal &&
          !a.execution.studentMate &&
          !a.execution.pending,
    AssessmentPhase.execution =>
      initial == 1 && protection == 0 && a.executionFinishedAtUtc == null,
    AssessmentPhase.protection =>
      initial == 1 && protection == 0 && a.executionFinishedAtUtc != null,
    AssessmentPhase.closed =>
      a.closedAtUtc != null &&
          a.closeReason != null &&
          (a.closeReason != AssessmentCloseReason.submitted ||
              (initial == 1 && protection == 1 && finished != null)) &&
          (protection == 0 ||
              (initial == 1 && a.executionFinishedAtUtc != null)),
  };
}

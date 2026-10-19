import 'dart:async';

import 'package:dartchess/dartchess.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/endgames/assessment_attempt_repository.dart';
import '../../../domain/models/assessment_attempt.dart';
import '../../../domain/use_cases/assessment_execution_adapter.dart';
import '../../../domain/use_cases/assessment_relations.dart';
import '../../../domain/use_cases/assessment_session.dart';
import '../../../domain/use_cases/exercise_judge.dart';
import '../../../domain/use_cases/now.dart';
import 'assessment_state.dart';

export 'assessment_state.dart';

typedef AssessmentOpponentPicker = Future<Move?> Function(
  Position position,
  List<Position> history,
);
typedef AssessmentFactsProvider = Future<AssessmentFacts?> Function(
  AssessmentAttempt attempt,
);

final class AssessmentConfig {
  AssessmentConfig({
    required this.lessonId,
    required this.exerciseId,
    required this.initialFen,
    required this.student,
    required Map<String, String> contentIdentity,
    required this.createAttemptId,
    required this.now,
  }) : contentIdentity = Map.unmodifiable(contentIdentity);

  final String lessonId;
  final String exerciseId;
  final String initialFen;
  final Side student;
  final Map<String, String> contentIdentity;
  final String Function() createAttemptId;
  final Now now;
}

/// Independent U1 collector. Production opponent/facts adapters are injected;
/// there is no legacy completion, score, solution or strength policy here.
final class AssessmentCubit extends Cubit<AssessmentState> {
  AssessmentCubit({
    required this.config,
    required this._repository,
    required this._pickOpponent,
    required this._facts,
  }) : super(AssessmentState());

  final AssessmentConfig config;
  final AssessmentAttemptRepository _repository;
  final AssessmentOpponentPicker _pickOpponent;
  final AssessmentFactsProvider _facts;
  static const _adapter = AssessmentExecutionAdapter();
  AssessmentSession? _session;
  Future<void>? _writes;
  Future<void>? _closeFuture;
  int _generation = 0;
  int _loadRequest = 0;
  int _pendingLoads = 0;
  bool _closeRequested = false;
  bool _closing = false;
  Object? _replyOwner;
  Object? _factsOwner;
  String? _evaluatingAttemptId;

  bool _current(int generation) =>
      !_closing && !isClosed && generation == _generation;

  bool _remoteCurrent(int generation) =>
      !_closeRequested && _pendingLoads == 0 && _current(generation);

  /// Does not replace malformed stored data with a new attempt.
  Future<void> load() {
    if (_closeRequested || isClosed) {
      return Future<void>.error(StateError('Assessment close was requested'));
    }
    final request = ++_loadRequest;
    _pendingLoads++;
    _replyOwner = null;
    _factsOwner = null;
    _evaluatingAttemptId = null;
    return _command(
      (g) async {
        final stored = await _repository.loadCurrent();
        if (!_current(g) || request != _loadRequest) {
          return;
        }
        final AssessmentSession session;
        if (stored == null) {
          session = await AssessmentSession.start(
            attemptId: config.createAttemptId(),
            lessonId: config.lessonId,
            exerciseId: config.exerciseId,
            contentIdentity: config.contentIdentity,
            initialExecution: _replay(const []),
            now: config.now,
            save: _save(g),
          );
        } else {
          if (stored.lessonId != config.lessonId ||
              stored.exerciseId != config.exerciseId) {
            throw const _Failure(AssessmentTechnicalFailure.replay);
          }
          final replay = _replay(
            stored.execution.played,
            expectedFen: stored.execution.gameFen,
            pending: stored.execution.pending,
          );
          session = await AssessmentSession.resume(
            snapshot: stored,
            contentIdentity: config.contentIdentity,
            verifiedReplay: replay,
            now: config.now,
            save: _save(g),
          );
        }
        if (!_current(g) || request != _loadRequest) {
          return;
        }
        _session = session;
        await _advance(g, session);
      },
      loadRequest: request,
      clearSnapshot: true,
    );
  }

  /// Foreground/reopen replays the durable history; no elapsed time is waived.
  Future<void> resume() => load();

  Future<void> replaceDraft(AssessmentDraft draft) =>
      _withSession((g, s) => s.replaceDraft(draft));

  Future<void> submitInitial() => _withSession((g, s) async {
    await s.submitInitial();
    if (_current(g)) {
      await _advance(g, s);
    }
  });

  Future<void> play(Move move) => _withSession((g, s) async {
    await s.observeTime();
    if (!_current(g) || s.attempt.phase == AssessmentPhase.closed) {
      return;
    }
    final attempt = s.attempt;
    if (attempt.phase != AssessmentPhase.execution ||
        attempt.execution.pending ||
        !attempt.execution.studentTurn) {
      throw const _Failure(AssessmentTechnicalFailure.invalidCommand);
    }
    final AssessmentExecution next;
    try {
      next = _replay([...attempt.execution.played, move.uci]);
    } on AssessmentExecutionAdapterException {
      throw const _Failure(AssessmentTechnicalFailure.invalidMove);
    }
    final pending = !next.terminal && !next.studentTurn;
    await s.updateExecution(
      token: s.callbackToken,
      contentIdentity: config.contentIdentity,
      execution: pending ? _replay(next.played, pending: true) : next,
    );
    if (_current(g)) {
      await _advance(g, s);
    }
  });

  Future<void> finishExecution({required bool voluntaryConfirmed}) =>
      _withSession(
        (g, s) => s.finishExecution(voluntaryConfirmed: voluntaryConfirmed),
      );

  Future<void> selectVisitedSnapshot(String ref) =>
      _withSession((g, s) => s.selectVisitedSnapshot(ref));

  Future<void> submitProtection() =>
      _withSession((g, s) => s.submitProtection());

  Future<void> observeTime() => _withSession((g, s) async {
    await s.observeTime();
    if (_current(g)) {
      await _advance(g, s);
    }
  }, showBusy: false);

  Future<void> cancel() {
    _replyOwner = null;
    return _withSession((g, s) => s.cancel());
  }

  Future<void> requestHelp({
    required String source,
    required Set<AssessmentComponent> components,
  }) => _withSession(
    (g, s) => s.requestHelp(source: source, components: components),
  );

  /// Only a true result authorizes a caller to reveal the requested help.
  Future<bool> receiveHelp({
    required String source,
    required Set<AssessmentComponent> components,
  }) {
    _replyOwner = null;
    return _withSession(
      (g, s) => s.receiveHelp(source: source, components: components),
    ).then(
      (_) =>
          !_closeRequested &&
          !_closing &&
          !isClosed &&
          state.snapshot?.phase == AssessmentPhase.closed &&
          state.snapshot?.closeReason == AssessmentCloseReason.assistance &&
          state.technicalFailure != AssessmentTechnicalFailure.storage,
    );
  }

  Future<void> retry({bool assistedContinuation = false}) {
    _replyOwner = null;
    _factsOwner = null;
    _evaluatingAttemptId = null;
    return _withSession((g, s) async {
      final next = await s.retry(
        attemptId: config.createAttemptId(),
        initialExecution: _replay(const []),
        assistedContinuation: assistedContinuation,
      );
      if (_current(g)) {
        _session = next;
      }
    });
  }

  SaveAssessmentAttempt _save(int generation) => (attempt) async {
    if (!_current(generation)) {
      throw const _Stale();
    }
    await _repository.save(attempt);
  };

  AssessmentExecution _replay(
    List<String> moves, {
    String? expectedFen,
    bool pending = false,
  }) => _adapter.replay(
    initialFen: config.initialFen,
    student: config.student,
    played: moves,
    expectedFen: expectedFen,
    pending: pending,
  );

  Future<void> _withSession(
    Future<void> Function(int, AssessmentSession) action, {
    bool showBusy = true,
  }) => _command((g) async {
    final session = _session;
    if (session == null) {
      throw const _Failure(AssessmentTechnicalFailure.invalidCommand);
    }
    await action(g, session);
  }, showBusy: showBusy);

  Future<void> _command(
    Future<void> Function(int) action, {
    int? generation,
    int? loadRequest,
    bool clearSnapshot = false,
    bool showBusy = true,
  }) {
    if (_closeRequested || isClosed) {
      return Future<void>.error(StateError('Assessment close was requested'));
    }
    Future<void> run() async {
      if (loadRequest != null) {
        _pendingLoads--;
        if (loadRequest != _loadRequest) {
          return;
        }
        _generation++;
        _session = null;
      }
      // Local commands acquire the generation when their FIFO turn begins.
      // Only remote callbacks carry the generation captured before their await.
      final owner = generation ?? _generation;
      if (!_current(owner) || (generation != null && !_remoteCurrent(owner))) {
        return;
      }
      if (showBusy) {
        emit(
          AssessmentState(
            snapshot: clearSnapshot ? null : state.snapshot,
            busy: true,
            conceptualResult: clearSnapshot ? null : state.conceptualResult,
          ),
        );
      }
      AssessmentTechnicalFailure? failure;
      try {
        await action(owner);
      } on _Stale {
        return;
      } on _Failure catch (error) {
        failure = error.reason;
      } on AssessmentExecutionAdapterException {
        failure = AssessmentTechnicalFailure.replay;
      } on AssessmentAttemptStorageException {
        failure = AssessmentTechnicalFailure.storage;
      } on Object {
        failure = AssessmentTechnicalFailure.storage;
      }
      if (!_current(owner) ||
          (loadRequest != null && loadRequest != _loadRequest)) {
        return;
      }
      AssessmentAttempt? snapshot;
      try {
        snapshot = _session?.attempt;
      } on StateError {
        // A post-await closing write failed. observeTime retries that closure.
        failure = AssessmentTechnicalFailure.storage;
      }
      emit(
        AssessmentState(
          snapshot: snapshot ?? (clearSnapshot ? null : state.snapshot),
          technicalFailure: failure,
          conceptualResult: snapshot?.attemptId == state.snapshot?.attemptId
              ? state.conceptualResult
              : null,
        ),
      );
      if (failure == null && snapshot?.phase == AssessmentPhase.closed) {
        _beginEvaluation(owner, snapshot!);
      }
    }

    final previous = _writes;
    final result = previous == null
        ? Future<void>.sync(run)
        : previous.then((_) => run());
    late final Future<void> drained;
    void release() {
      if (identical(_writes, drained)) _writes = null;
    }

    drained = result.then<void>(
      (_) => release(),
      onError: (Object _, StackTrace _) => release(),
    );
    _writes = drained;
    return result;
  }

  Future<void> _advance(int generation, AssessmentSession session) async {
    if (!_current(generation) || !identical(session, _session)) {
      return;
    }
    final attempt = session.attempt;
    if (attempt.phase != AssessmentPhase.execution) {
      return;
    }
    if (attempt.execution.terminal) {
      await session.finishExecution(voluntaryConfirmed: false);
    } else if (!attempt.execution.studentTurn && _remoteCurrent(generation)) {
      if (!attempt.execution.pending) {
        await session.updateExecution(
          token: session.callbackToken,
          contentIdentity: config.contentIdentity,
          execution: _replay(attempt.execution.played, pending: true),
        );
      }
      if (_remoteCurrent(generation) &&
          session.attempt.phase == AssessmentPhase.execution &&
          _replyOwner == null) {
        final owner = Object();
        _replyOwner = owner;
        unawaited(_requestReply(generation, owner, session));
      }
    }
  }

  Future<void> _requestReply(
    int generation,
    Object owner,
    AssessmentSession session,
  ) async {
    final token = session.callbackToken;
    final captured = session.attempt.execution;
    bool valid() =>
        _remoteCurrent(generation) &&
        identical(_session, session) &&
        identical(_replyOwner, owner);
    try {
      final positions = List<Position>.unmodifiable([
        for (var ply = 0; ply <= captured.played.length; ply++)
          ExerciseJudge.exactPosition(captured.visitedSnapshots['ply:$ply']!)!,
      ]);
      final move = await _pickOpponent(positions.last, positions);
      if (!valid()) {
        return;
      }
      await _command((g) async {
        if (!valid()) {
          return;
        }
        await session.observeTime();
        if (!valid() || session.attempt.phase != AssessmentPhase.execution) {
          return;
        }
        final current = session.attempt;
        if (current.callbackEpoch != token.epoch ||
            current.attemptId != token.attemptId ||
            current.execution.historyIdentity != captured.historyIdentity) {
          return;
        }
        if (move == null) {
          throw const _Failure(AssessmentTechnicalFailure.opponentUnavailable);
        }
        final AssessmentExecution next;
        try {
          next = _replay([...captured.played, move.uci]);
        } on AssessmentExecutionAdapterException {
          throw const _Failure(AssessmentTechnicalFailure.illegalOpponent);
        }
        await session.updateExecution(
          token: token,
          contentIdentity: config.contentIdentity,
          execution: next,
        );
        if (valid()) {
          _replyOwner = null;
          await _advance(g, session);
        }
      }, generation: generation);
    } on Object {
      if (valid()) {
        await _command((g) async {
          await session.observeTime();
          if (session.attempt.phase != AssessmentPhase.closed) {
            throw const _Failure(
              AssessmentTechnicalFailure.opponentUnavailable,
            );
          }
        }, generation: generation);
      }
    } finally {
      if (identical(_replyOwner, owner)) {
        _replyOwner = null;
      }
    }
  }

  void _beginEvaluation(int generation, AssessmentAttempt attempt) {
    if (!_remoteCurrent(generation)) {
      return;
    }
    if (attempt.closeReason == AssessmentCloseReason.identityIntegrity ||
        attempt.closeReason == AssessmentCloseReason.historyIntegrity ||
        attempt.closeReason == AssessmentCloseReason.clockIntegrity) {
      emit(
        AssessmentState(
          snapshot: attempt,
          technicalFailure: AssessmentTechnicalFailure.integrity,
        ),
      );
      return;
    }
    if (_evaluatingAttemptId == attempt.attemptId) {
      return;
    }
    _evaluatingAttemptId = attempt.attemptId;
    final owner = Object();
    _factsOwner = owner;
    unawaited(_evaluate(generation, owner, attempt));
  }

  Future<void> _evaluate(
    int generation,
    Object owner,
    AssessmentAttempt attempt,
  ) async {
    bool valid() =>
        _remoteCurrent(generation) &&
        identical(_factsOwner, owner) &&
        state.snapshot?.attemptId == attempt.attemptId &&
        state.snapshot?.phase == AssessmentPhase.closed;
    try {
      final facts = await _facts(attempt);
      if (!valid()) {
        return;
      }
      if (facts == null) {
        throw const _Failure(AssessmentTechnicalFailure.factsUnavailable);
      }
      AssessmentDraft? initial;
      AssessmentDraft? protection;
      for (final submission in attempt.submissions) {
        if (submission.phase == AssessmentPhase.initial) {
          initial = submission.response;
        }
        if (submission.phase == AssessmentPhase.protection) {
          protection = submission.response;
        }
      }
      final result = const AssessmentRelations().evaluate(
        initial: initial ?? attempt.draft,
        protection:
            protection ??
            (attempt.executionFinishedAtUtc == null
                ? AssessmentDraft()
                : attempt.draft),
        facts: facts,
        initialSubmitted: true,
        protectionSubmitted: true,
        executionComplete:
            attempt.execution.studentMate &&
            attempt.executionFinishedAtUtc != null,
      );
      if (valid()) {
        emit(
          AssessmentState(
            snapshot: state.snapshot,
            busy: state.busy,
            conceptualResult: result,
          ),
        );
      }
    } on Object {
      if (valid()) {
        emit(
          AssessmentState(
            snapshot: state.snapshot,
            busy: state.busy,
            technicalFailure: AssessmentTechnicalFailure.factsUnavailable,
          ),
        );
      }
    }
  }

  @override
  Future<void> close() => _closeFuture ??= _close(() => super.close());

  Future<void> _close(Future<void> Function() closeBase) async {
    _closeRequested = true;
    _replyOwner = null;
    _factsOwner = null;
    final pending = _writes;
    if (pending != null) await pending;
    _closing = true;
    _generation++;
    _session = null;
    await closeBase();
  }
}

final class _Failure implements Exception {
  const _Failure(this.reason);
  final AssessmentTechnicalFailure reason;
}

final class _Stale implements Exception {
  const _Stale();
}

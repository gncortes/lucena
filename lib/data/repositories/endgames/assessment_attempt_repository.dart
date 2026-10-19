import 'dart:convert';

import '../../../domain/models/assessment_attempt.dart';
import '../../services/preferences_service.dart';

abstract class AssessmentAttemptRepository {
  Future<AssessmentAttempt?> loadCurrent();
  Future<AssessmentAttempt?> loadById(String attemptId);
  Future<void> save(AssessmentAttempt attempt);
}

/// A technical storage failure; callers must retain the original stored value.
final class AssessmentAttemptStorageException implements Exception {
  const AssessmentAttemptStorageException(this.reason);
  final String reason;

  @override
  String toString() => 'AssessmentAttemptStorageException: $reason';
}

/// Local U1 collection only. One serialized write contains both answers and
/// execution checkpoint; the legacy lesson progress key is never accessed.
/// Instances sharing this key must have a single owner (queue is per instance).
final class LocalAssessmentAttemptRepository
    implements AssessmentAttemptRepository {
  LocalAssessmentAttemptRepository(this._preferences);

  static const key = 'endgames.assessment.u1.attempts';
  static const _schemaVersion = 1;
  final PreferencesService _preferences;
  Future<void> _tail = Future<void>.value();

  @override
  Future<AssessmentAttempt?> loadCurrent() => _serial(() async {
    final envelope = await _read();
    if (envelope == null) return null;
    return envelope.attempts[envelope.currentAttemptId];
  });

  @override
  Future<AssessmentAttempt?> loadById(String attemptId) => _serial(() async {
    final envelope = await _read();
    return envelope?.attempts[attemptId];
  });

  @override
  Future<void> save(AssessmentAttempt attempt) => _serial(() async {
    _validateAttempt(attempt);
    final previous = await _read();
    final attempts = <String, AssessmentAttempt>{...?previous?.attempts};
    if (previous == null) {
      if (attempt.parentAttemptId != null) {
        throw StateError('The first attempt cannot reference a missing parent');
      }
    } else {
      final current = previous.attempts[previous.currentAttemptId]!;
      if (attempt.attemptId == current.attemptId) {
        _validateUpdate(current, attempt);
      } else {
        if (attempts.containsKey(attempt.attemptId) ||
            current.phase != AssessmentPhase.closed ||
            attempt.parentAttemptId != current.attemptId) {
          throw StateError('A new attempt requires the current closed parent');
        }
        _validateContent(current, attempt);
        if (!attempt.exposed) {
          throw StateError('A retry must retain prior item exposure');
        }
      }
    }
    attempts[attempt.attemptId] = attempt;
    await _preferences.setString(
      key,
      jsonEncode({
        'schemaVersion': _schemaVersion,
        'currentAttemptId': attempt.attemptId,
        'attempts': attempts.map((id, value) => MapEntry(id, value.toJson())),
      }),
    );
  });

  Future<T> _serial<T>(Future<T> Function() operation) {
    final result = _tail.then((_) => operation());
    // Keep the caller's original failure, but let later operations proceed.
    _tail = result.then<void>(
      (_) {},
      onError: (Object error, StackTrace stack) {},
    );
    return result;
  }

  Future<_Envelope?> _read() async {
    final text = await _preferences.getString(key);
    if (text == null) return null;
    try {
      final json = (jsonDecode(text) as Map).cast<String, Object?>();
      if (json['schemaVersion'] != _schemaVersion) {
        throw const AssessmentAttemptStorageException(
          'unsupportedEnvelopeVersion',
        );
      }
      final currentId = json['currentAttemptId'] as String;
      final rows = (json['attempts'] as Map).cast<String, Object?>();
      if (rows.isEmpty || !rows.containsKey(currentId)) {
        throw const AssessmentAttemptStorageException('invalidCurrentAttempt');
      }
      final attempts = rows.map((id, value) {
        final attempt = AssessmentAttempt.fromJson(
          (value as Map).cast<String, Object?>(),
        );
        _validateAttempt(attempt);
        if (attempt.attemptId != id) {
          throw const AssessmentAttemptStorageException('attemptIdMismatch');
        }
        return MapEntry(id, attempt);
      });
      // Exactly one retained lineage; malformed history is never reset to empty.
      final visited = <String>{};
      AssessmentAttempt? cursor = attempts[currentId];
      while (cursor != null) {
        if (!visited.add(cursor.attemptId)) {
          throw const AssessmentAttemptStorageException('cyclicAttemptHistory');
        }
        final parentId = cursor.parentAttemptId;
        if (parentId == null) break;
        final parent = attempts[parentId];
        if (parent == null || parent.phase != AssessmentPhase.closed) {
          throw const AssessmentAttemptStorageException('invalidParentAttempt');
        }
        _validateContent(parent, cursor);
        cursor = parent;
      }
      if (visited.length != attempts.length) {
        throw const AssessmentAttemptStorageException(
          'disconnectedAttemptHistory',
        );
      }
      return _Envelope(currentId, attempts);
    } on AssessmentAttemptStorageException {
      rethrow;
    } on FormatException {
      throw const AssessmentAttemptStorageException('malformedStoredAttempt');
    } on TypeError {
      throw const AssessmentAttemptStorageException('malformedStoredAttempt');
    } on ArgumentError {
      throw const AssessmentAttemptStorageException('malformedStoredAttempt');
    } on StateError {
      throw const AssessmentAttemptStorageException('malformedStoredAttempt');
    }
  }
}

final class _Envelope {
  const _Envelope(this.currentAttemptId, this.attempts);
  final String currentAttemptId;
  final Map<String, AssessmentAttempt> attempts;
}

void _validateAttempt(AssessmentAttempt attempt) {
  if (attempt.attemptId.isEmpty ||
      attempt.lessonId != 'mates.bishopKnight.deletang' ||
      attempt.exerciseId != 'finalNetAssessment01' ||
      attempt.contentIdentity.isEmpty ||
      (attempt.parentAttemptId != null && !attempt.exposed) ||
      attempt.revision < 0 ||
      attempt.callbackEpoch < 0 ||
      attempt.lastObservedUtc.isBefore(attempt.startedAtUtc) ||
      (attempt.phase == AssessmentPhase.closed &&
          (attempt.closedAtUtc == null || attempt.closeReason == null))) {
    throw StateError('Invalid U1 attempt snapshot');
  }
}

void _validateContent(AssessmentAttempt previous, AssessmentAttempt next) {
  if (previous.lessonId != next.lessonId ||
      previous.exerciseId != next.exerciseId ||
      !_same(previous.contentIdentity, next.contentIdentity)) {
    throw StateError('Attempt content identity cannot change');
  }
}

void _validateUpdate(AssessmentAttempt previous, AssessmentAttempt next) {
  _validateContent(previous, next);
  final same = _same(previous.toJson(), next.toJson());
  final technicalClosure = _isTechnicalClosure(previous, next);
  if ((!same && next.revision == previous.revision && !technicalClosure) ||
      (previous.phase == AssessmentPhase.closed &&
          !same &&
          !technicalClosure)) {
    throw StateError('Conflicting revision or changed closed attempt');
  }
  if (previous.parentAttemptId != next.parentAttemptId ||
      previous.startedAtUtc != next.startedAtUtc ||
      next.revision < previous.revision ||
      next.callbackEpoch < previous.callbackEpoch ||
      next.lastObservedUtc.isBefore(previous.lastObservedUtc) ||
      previous.assisted != next.assisted ||
      (previous.exposed && !next.exposed) ||
      next.phase.index < previous.phase.index) {
    throw StateError('Attempt identity, revision or lifecycle cannot regress');
  }
  _preservePrefix(
    previous.submissions.map((s) => s.toJson()).toList(),
    next.submissions.map((s) => s.toJson()).toList(),
  );
  _preservePrefix(
    previous.help.map((h) => h.toJson()).toList(),
    next.help.map((h) => h.toJson()).toList(),
  );
  _preservePrefix(previous.execution.played, next.execution.played);
  if (previous.execution.played.length == next.execution.played.length &&
      (previous.execution.gameFen != next.execution.gameFen ||
          previous.execution.historyIdentity !=
              next.execution.historyIdentity)) {
    throw StateError(
      'An unchanged history cannot acquire a different checkpoint',
    );
  }
  if (previous.execution.visitedSnapshots.entries.any(
    (e) => next.execution.visitedSnapshots[e.key] != e.value,
  )) {
    throw StateError('Visited execution snapshots cannot change');
  }
  if (previous.executionFinishedAtUtc != null &&
      (previous.executionFinishedAtUtc != next.executionFinishedAtUtc ||
          !_same(previous.execution.toJson(), next.execution.toJson()))) {
    throw StateError('Finished execution cannot change');
  }
  if (previous.phase == AssessmentPhase.closed &&
      (!_same(previous.draft.toJson(), next.draft.toJson()) ||
          !_same(previous.execution.toJson(), next.execution.toJson()))) {
    throw StateError('Closed collection cannot change');
  }
  // Closure diagnostics may be reclassified after save/await clock checks.
  // Identity, collected submissions and help retain all preceding records.
}

bool _isTechnicalClosure(AssessmentAttempt previous, AssessmentAttempt next) {
  if (next.phase != AssessmentPhase.closed ||
      next.callbackEpoch != previous.callbackEpoch + 1 ||
      next.closedAtUtc == null) {
    return false;
  }
  final at = next.closedAtUtc!;
  final observedFailure = switch (next.closeReason) {
    AssessmentCloseReason.timeLimit => !at.isBefore(next.deadlineUtc),
    AssessmentCloseReason.clockIntegrity => at.isBefore(
      previous.lastObservedUtc,
    ),
    AssessmentCloseReason.identityIntegrity ||
    AssessmentCloseReason.historyIntegrity =>
      previous.phase != AssessmentPhase.closed,
    _ => false,
  };
  if (!observedFailure) return false;
  final original = previous.toJson();
  final updated = next.toJson();
  for (final field in [
    'phase',
    'closedAtUtc',
    'closeReason',
    'callbackEpoch',
  ]) {
    original.remove(field);
    updated.remove(field);
  }
  return _same(original, updated);
}

void _preservePrefix(List<Object?> previous, List<Object?> next) {
  if (next.length < previous.length ||
      previous.asMap().entries.any((e) => !_same(e.value, next[e.key]))) {
    throw StateError('Frozen attempt records cannot be removed or changed');
  }
}

bool _same(Object? a, Object? b) {
  if (a is Map && b is Map) {
    return a.length == b.length &&
        a.entries.every(
          (e) => b.containsKey(e.key) && _same(e.value, b[e.key]),
        );
  }
  if (a is List && b is List) {
    return a.length == b.length &&
        a.asMap().entries.every((e) => _same(e.value, b[e.key]));
  }
  return a == b;
}

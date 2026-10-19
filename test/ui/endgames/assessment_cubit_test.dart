import 'dart:async';

import 'package:dartchess/dartchess.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/data/repositories/endgames/assessment_attempt_repository.dart';
import 'package:lucena/data/services/preferences_service.dart';
import 'package:lucena/domain/models/assessment_attempt.dart';
import 'package:lucena/domain/use_cases/assessment_relations.dart';
import 'package:lucena/domain/use_cases/game_rules.dart';
import 'package:lucena/domain/use_cases/now.dart';
import 'package:lucena/ui/endgames/view_models/assessment_cubit.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

final class TestNow implements Now {
  DateTime value = DateTime.utc(2026, 1, 1);
  @override
  DateTime call() => value;
  void seconds(int count) => value = value.add(Duration(seconds: count));
}

final class FailingPreferences extends PreferencesService {
  int writes = 0;
  bool fail = false;
  int? failAt;
  void Function(int)? afterWrite;
  @override
  Future<void> setString(String key, String value) async {
    writes++;
    if (fail || writes == failAt) {
      throw StateError('synthetic disk failure');
    }
    await super.setString(key, value);
    afterWrite?.call(writes);
  }
}

final class DelayedReadRepository implements AssessmentAttemptRepository {
  DelayedReadRepository(this.delegate);
  final AssessmentAttemptRepository delegate;
  final entered = Completer<void>();
  final release = Completer<void>();
  int reads = 0;
  @override
  Future<AssessmentAttempt?> loadCurrent() async {
    reads++;
    if (reads == 1) {
      entered.complete();
      await release.future;
    }
    return delegate.loadCurrent();
  }

  @override
  Future<AssessmentAttempt?> loadById(String id) => delegate.loadById(id);
  @override
  Future<void> save(AssessmentAttempt value) => delegate.save(value);
}

Future<AssessmentState> until(
  AssessmentCubit cubit,
  bool Function(AssessmentState) check,
) {
  if (check(cubit.state)) {
    return Future.value(cubit.state);
  }
  return cubit.stream.firstWhere(check);
}

AssessmentFacts incompleteHistoryFacts() => AssessmentFacts(
  initialSnapshotRef: 'ply:0',
  snapshots: {},
  bishopCompatibleCorners: {},
  supportedCorners: {},
  knownEscapeSquares: {},
  availableEscapes: {},
  blockedEscapes: {'unverified'},
  visitedHistoryFactsComplete: false,
  protectionOpportunity: false,
);

void main() {
  late TestNow now;
  late FailingPreferences preferences;
  late LocalAssessmentAttemptRepository repository;
  int ids = 0;

  AssessmentCubit create({
    AssessmentAttemptRepository? store,
    AssessmentOpponentPicker? opponent,
    AssessmentFactsProvider? facts,
    String contentHash = 'public-test-content',
  }) => AssessmentCubit(
    config: AssessmentConfig(
      lessonId: 'mates.bishopKnight.deletang',
      exerciseId: 'finalNetAssessment01',
      initialFen: GameRules.initial.fen,
      student: Side.white,
      contentIdentity: {'item': contentHash, 'version': 'u1-relations-v2'},
      createAttemptId: () => 'attempt-${++ids}',
      now: now,
    ),
    repository: store ?? repository,
    pickOpponent: opponent ?? (position, history) async => null,
    facts: facts ?? (attempt) async => null,
  );

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    now = TestNow();
    preferences = FailingPreferences();
    repository = LocalAssessmentAttemptRepository(preferences);
    ids = 0;
  });

  test(
    'clock observations persist without disabling the current board',
    () async {
      final cubit = create();
      await cubit.load();
      await cubit.submitInitial();
      final before = cubit.state.snapshot!;
      final states = <AssessmentState>[];
      final subscription = cubit.stream.listen(states.add);
      now.seconds(2);
      await cubit.observeTime();
      await Future<void>.delayed(Duration.zero);
      expect(states.any((state) => state.busy), isFalse);
      expect(cubit.state.snapshot!.execution.played, before.execution.played);
      expect((await repository.loadCurrent())!.lastObservedUtc, now());
      expect(cubit.state.snapshot!.revision, greaterThan(before.revision));
      await subscription.cancel();
      await cubit.close();
    },
  );

  test(
    'quiet clock observations still expose storage failure and expiry',
    () async {
      final cubit = create();
      await cubit.load();
      preferences.fail = true;
      now.seconds(1);
      await cubit.observeTime();
      expect(cubit.state.technicalFailure, AssessmentTechnicalFailure.storage);
      preferences.fail = false;
      now.seconds(600);
      await cubit.observeTime();
      expect(cubit.state.snapshot!.phase, AssessmentPhase.closed);
      expect((await repository.loadCurrent())!.phase, AssessmentPhase.closed);
      await cubit.close();
    },
  );

  test(
    'an accepted unawaited edit drains before close and survives reopening',
    () async {
      final cubit = create();
      await cubit.load();
      final draft = AssessmentDraft(
        editing: AssessmentEditingState(
          sameColor: false,
          relationTargets: {'partial-before-close'},
        ),
      );
      final edit = cubit.replaceDraft(draft);
      final closing = cubit.close();
      await Future.wait([edit, closing]);
      expect((await repository.loadCurrent())!.draft.toJson(), draft.toJson());
      final reopened = create();
      await reopened.load();
      expect(reopened.state.snapshot!.draft.toJson(), draft.toJson());
      expect(reopened.state.technicalFailure, isNull);
      await reopened.close();
    },
  );

  test(
    'an accepted unawaited edit drains before resume rehydrates the draft',
    () async {
      final cubit = create();
      await cubit.load();
      final draft = AssessmentDraft(
        editing: AssessmentEditingState(
          corner: 'partial-before-resume',
          relationPiece: AssessmentPiece.knight,
        ),
      );
      final edit = cubit.replaceDraft(draft);
      final resumed = cubit.resume();
      await Future.wait([edit, resumed]);
      expect(cubit.state.snapshot!.draft.toJson(), draft.toJson());
      expect((await repository.loadCurrent())!.draft.toJson(), draft.toJson());
      expect(cubit.state.technicalFailure, isNull);
      await cubit.close();
    },
  );

  test('new local commands after close request reject without an acknowledged write', () async {
    final cubit = create();
    await cubit.load();
    final writes = preferences.writes;
    final closing = cubit.close();
    await expectLater(
      cubit.replaceDraft(
        AssessmentDraft(
          editing: AssessmentEditingState(corner: 'must-not-save'),
        ),
      ),
      throwsStateError,
    );
    await expectLater(cubit.resume(), throwsStateError);
    await closing;
    expect(preferences.writes, writes);
    expect((await repository.loadCurrent())!.draft.editing.corner, isNull);
  });

  test(
    'draining an accepted move on close does not start a new remote request',
    () async {
      int opponentCalls = 0;
      final cubit = create(
        opponent: (position, history) {
          opponentCalls++;
          return Completer<Move?>().future;
        },
      );
      await cubit.load();
      await cubit.submitInitial();
      final play = cubit.play(Move.parse('e2e4')!);
      final closing = cubit.close();
      await Future.wait([play, closing]);
      expect((await repository.loadCurrent())!.execution.played, ['e2e4']);
      expect(opponentCalls, 0);
    },
  );

  test(
    'partial editing survives real storage and reload without feedback',
    () async {
      int factCalls = 0;
      final cubit = create(
        facts: (attempt) async {
          factCalls++;
          return incompleteHistoryFacts();
        },
      );
      await cubit.load();
      final draft = AssessmentDraft(
        editing: AssessmentEditingState(
          sameColor: false,
          relationPiece: AssessmentPiece.knight,
          relationTargets: {'learner-selection'},
        ),
      );
      await cubit.replaceDraft(draft);
      expect(cubit.state.conceptualResult, isNull);
      expect(factCalls, 0);
      await cubit.close();
      final reopened = create();
      await reopened.load();
      expect(reopened.state.snapshot!.draft.toJson(), draft.toJson());
      expect(reopened.state.snapshot!.draft.target, isNull);
      expect(reopened.state.snapshot!.draft.relations, isEmpty);
      expect(reopened.state.snapshot!.attemptId, 'attempt-1');
      expect(reopened.state.conceptualResult, isNull);
      await reopened.close();
    },
  );

  test(
    'real legal moves persist pending before opponent and never evaluate early',
    () async {
      final reply = Completer<Move?>();
      int facts = 0;
      final cubit = create(
        opponent: (position, history) async {
          final saved = (await repository.loadCurrent())!;
          expect(saved.execution.pending, isTrue);
          expect(saved.execution.played, ['e2e4']);
          expect(history.last.fen, position.fen);
          return reply.future;
        },
        facts: (attempt) async {
          facts++;
          return null;
        },
      );
      await cubit.load();
      await cubit.submitInitial();
      await cubit.play(Move.parse('e2e5')!);
      expect(
        cubit.state.technicalFailure,
        AssessmentTechnicalFailure.invalidMove,
      );
      expect(cubit.state.snapshot!.execution.played, isEmpty);
      await cubit.play(Move.parse('e2e4')!);
      expect(cubit.state.snapshot!.execution.pending, isTrue);
      expect(cubit.state.conceptualResult, isNull);
      reply.complete(Move.parse('e7e5'));
      await until(
        cubit,
        (s) => s.snapshot?.execution.played.length == 2 && !s.busy,
      );
      expect(cubit.state.snapshot!.execution.studentTurn, isTrue);
      expect(cubit.state.snapshot!.execution.pending, isFalse);
      expect(facts, 0);
      expect(cubit.state.conceptualResult, isNull);
      await cubit.close();
    },
  );

  test('public actual mate opens protection without legacy completion or early result', () async {
    final replies = ['e7e5', 'b8c6', 'g8f6'].iterator;
    final factsGate = Completer<AssessmentFacts?>();
    int factCalls = 0;
    final cubit = create(
      opponent: (position, history) async {
        expect(replies.moveNext(), isTrue);
        return Move.parse(replies.current);
      },
      facts: (attempt) {
        factCalls++;
        return factsGate.future;
      },
    );
    await cubit.load();
    await cubit.submitInitial();
    for (final move in ['e2e4', 'f1c4', 'd1h5']) {
      await cubit.play(Move.parse(move)!);
      await until(
        cubit,
        (s) =>
            !s.busy &&
            s.snapshot!.execution.studentTurn &&
            !s.snapshot!.execution.pending,
      );
    }
    await cubit.play(Move.parse('h5f7')!);
    expect(cubit.state.snapshot!.phase, AssessmentPhase.protection);
    expect(cubit.state.snapshot!.execution.studentMate, isTrue);
    expect(cubit.state.conceptualResult, isNull);
    expect(factCalls, 0);
    final terminalFen = cubit.state.snapshot!.execution.gameFen;
    await cubit.selectVisitedSnapshot('ply:0');
    expect(cubit.state.snapshot!.execution.gameFen, terminalFen);
    await cubit.submitProtection();
    expect(cubit.state.snapshot!.phase, AssessmentPhase.closed);
    expect(factCalls, 1);
    expect(cubit.state.conceptualResult, isNull);
    factsGate.complete(null);
    await until(
      cubit,
      (s) => s.technicalFailure == AssessmentTechnicalFailure.factsUnavailable,
    );
    expect(cubit.state.conceptualResult, isNull);
    await cubit.close();
  });

  test(
    '599 accepts and 600 expires across protection and background resume',
    () async {
      final cubit = create();
      await cubit.load();
      final deadline = cubit.state.snapshot!.deadlineUtc;
      now.seconds(599);
      await cubit.submitInitial();
      await cubit.finishExecution(voluntaryConfirmed: true);
      expect(cubit.state.snapshot!.phase, AssessmentPhase.protection);
      now.seconds(1);
      await cubit.resume();
      expect(cubit.state.snapshot!.phase, AssessmentPhase.closed);
      expect(
        cubit.state.snapshot!.closeReason,
        AssessmentCloseReason.timeLimit,
      );
      expect(cubit.state.snapshot!.deadlineUtc, deadline);
      await cubit.close();
    },
  );

  test(
    'failed saves preserve draft and post-await expiry can recover',
    () async {
      final cubit = create();
      await cubit.load();
      preferences.fail = true;
      await cubit.replaceDraft(
        AssessmentDraft(editing: AssessmentEditingState(corner: 'choice')),
      );
      expect(cubit.state.technicalFailure, AssessmentTechnicalFailure.storage);
      expect(cubit.state.snapshot!.draft.editing.corner, isNull);
      preferences.fail = false;
      await cubit.replaceDraft(
        AssessmentDraft(editing: AssessmentEditingState(corner: 'choice')),
      );
      expect(cubit.state.snapshot!.draft.editing.corner, 'choice');
      final nextWrite = preferences.writes + 1;
      preferences.afterWrite = (count) {
        if (count == nextWrite) {
          now.seconds(600);
        }
      };
      preferences.failAt = nextWrite + 1;
      await cubit.submitInitial();
      expect(cubit.state.technicalFailure, AssessmentTechnicalFailure.storage);
      preferences.failAt = null;
      await cubit.observeTime();
      expect(cubit.state.snapshot!.phase, AssessmentPhase.closed);
      expect(
        cubit.state.snapshot!.closeReason,
        AssessmentCloseReason.timeLimit,
      );
      expect((await repository.loadCurrent())!.phase, AssessmentPhase.closed);
      await cubit.close();
    },
  );

  test('illegal or absent opponent is technical without altering the legal history', () async {
    for (final illegal in [Move.parse('e2e5'), null]) {
      final cubit = create(opponent: (position, history) async => illegal);
      await cubit.load();
      await cubit.submitInitial();
      await cubit.play(Move.parse('e2e4')!);
      await until(
        cubit,
        (s) =>
            s.technicalFailure ==
            (illegal == null
                ? AssessmentTechnicalFailure.opponentUnavailable
                : AssessmentTechnicalFailure.illegalOpponent),
      );
      expect(cubit.state.snapshot!.execution.played, ['e2e4']);
      expect(cubit.state.snapshot!.execution.pending, isTrue);
      expect(cubit.state.conceptualResult, isNull);
      await cubit.close();
      // New isolated local store for the next callback scenario.
      await preferences.remove(LocalAssessmentAttemptRepository.key);
    }
  });

  test(
    'pending replay resumes once and rejects the previous async reply',
    () async {
      final oldReply = Completer<Move?>();
      final newReply = Completer<Move?>();
      int calls = 0;
      final cubit = create(
        opponent: (position, history) {
          calls++;
          return calls == 1 ? oldReply.future : newReply.future;
        },
      );
      await cubit.load();
      await cubit.submitInitial();
      await cubit.play(Move.parse('e2e4')!);
      await cubit.resume();
      expect(calls, 2);
      oldReply.complete(Move.parse('e7e5'));
      newReply.complete(Move.parse('e7e5'));
      await until(
        cubit,
        (s) => !s.busy && s.snapshot?.execution.played.length == 2,
      );
      expect((await repository.loadCurrent())!.execution.played, [
        'e2e4',
        'e7e5',
      ]);
      await cubit.close();
    },
  );

  test(
    'close does not wait for opponent and a late reply cannot persist',
    () async {
      final reply = Completer<Move?>();
      final cubit = create(opponent: (position, history) => reply.future);
      await cubit.load();
      await cubit.submitInitial();
      await cubit.play(Move.parse('e2e4')!);
      final writes = preferences.writes;
      await cubit.close();
      reply.complete(Move.parse('e7e5'));
      expect((await repository.loadCurrent())!.execution.played, ['e2e4']);
      expect(preferences.writes, writes);
    },
  );

  test(
    'opponent reply after deadline closes without appending that move',
    () async {
      final reply = Completer<Move?>();
      final cubit = create(opponent: (position, history) => reply.future);
      await cubit.load();
      await cubit.submitInitial();
      await cubit.play(Move.parse('e2e4')!);
      now.seconds(600);
      reply.complete(Move.parse('e7e5'));
      await until(cubit, (s) => s.snapshot?.phase == AssessmentPhase.closed);
      expect(
        cubit.state.snapshot!.closeReason,
        AssessmentCloseReason.timeLimit,
      );
      expect((await repository.loadCurrent())!.execution.played, ['e2e4']);
      await cubit.close();
    },
  );

  test(
    'concurrent load creates only one attempt and does not reset corrupt data',
    () async {
      final delayed = DelayedReadRepository(repository);
      final cubit = create(store: delayed);
      final first = cubit.load();
      await delayed.entered.future;
      final second = cubit.load();
      delayed.release.complete();
      await Future.wait([first, second]);
      expect(ids, 1);
      expect(cubit.state.snapshot!.attemptId, 'attempt-1');
      await cubit.close();
      await PreferencesService().setString(
        LocalAssessmentAttemptRepository.key,
        '{corrupt',
      );
      final invalid = create();
      await invalid.load();
      expect(invalid.state.snapshot, isNull);
      expect(
        invalid.state.technicalFailure,
        AssessmentTechnicalFailure.storage,
      );
      expect(
        await preferences.getString(LocalAssessmentAttemptRepository.key),
        '{corrupt',
      );
      await invalid.close();
    },
  );

  test(
    'help closes before authorization and retry preserves first responses',
    () async {
      final cubit = create();
      await cubit.load();
      final draft = AssessmentDraft(
        editing: AssessmentEditingState(sameColor: false),
      );
      await cubit.replaceDraft(draft);
      await cubit.submitInitial();
      await cubit.requestHelp(
        source: 'request',
        components: {AssessmentComponent.execution},
      );
      expect(cubit.state.snapshot!.phase, AssessmentPhase.execution);
      preferences.fail = true;
      expect(
        await cubit.receiveHelp(
          source: 'hint',
          components: {AssessmentComponent.execution},
        ),
        isFalse,
      );
      preferences.fail = false;
      expect(
        await cubit.receiveHelp(
          source: 'hint',
          components: {AssessmentComponent.execution},
        ),
        isTrue,
      );
      final first = (await repository.loadCurrent())!;
      expect(first.phase, AssessmentPhase.closed);
      expect(first.help.map((h) => h.received), [false, true]);
      await cubit.retry(assistedContinuation: true);
      expect(cubit.state.snapshot!.parentAttemptId, first.attemptId);
      expect(cubit.state.snapshot!.exposed, isTrue);
      expect(cubit.state.snapshot!.assisted, isTrue);
      expect(
        (await repository.loadById(first.attemptId))!
            .submissions
            .single
            .response
            .toJson(),
        draft.toJson(),
      );
      await cubit.close();
    },
  );

  test(
    'changed content closes technically without evaluating old responses',
    () async {
      final first = create();
      await first.load();
      final originalId = first.state.snapshot!.attemptId;
      await first.close();
      int factCalls = 0;
      final changed = create(
        contentHash: 'new-content',
        facts: (attempt) async {
          factCalls++;
          return incompleteHistoryFacts();
        },
      );
      await changed.load();
      expect(changed.state.snapshot!.attemptId, originalId);
      expect(
        changed.state.snapshot!.closeReason,
        AssessmentCloseReason.identityIntegrity,
      );
      expect(
        changed.state.technicalFailure,
        AssessmentTechnicalFailure.integrity,
      );
      expect(changed.state.conceptualResult, isNull);
      expect(factCalls, 0);
      expect(ids, 1);
      await changed.close();
    },
  );

  test('unknown facts fail technically; supported scope is evaluated only when closed', () async {
    for (final mode in ['missing', 'incompleteHistory', 'failure']) {
      final cubit = create(
        facts: (attempt) async {
          if (mode == 'failure') {
            throw StateError('synthetic facts unavailable');
          }
          return mode == 'incompleteHistory' ? incompleteHistoryFacts() : null;
        },
      );
      await cubit.load();
      expect(cubit.state.conceptualResult, isNull);
      await cubit.submitInitial();
      await cubit.finishExecution(voluntaryConfirmed: true);
      expect(cubit.state.conceptualResult, isNull);
      await cubit.submitProtection();
      await until(
        cubit,
        (s) =>
            s.conceptualResult != null ||
            s.technicalFailure == AssessmentTechnicalFailure.factsUnavailable,
      );
      if (mode != 'incompleteHistory') {
        expect(cubit.state.conceptualResult, isNull);
      } else {
        expect(
          cubit.state.conceptualResult!.components[AssessmentComponent
              .protection],
          AssessmentVerdict.unsupported,
        );
        expect(
          cubit.state.conceptualResult!.components.values,
          isNot(contains(AssessmentVerdict.incorrect)),
        );
      }
      await cubit.close();
      await preferences.remove(LocalAssessmentAttemptRepository.key);
    }
  });
}

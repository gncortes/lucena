import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;
import 'dart:typed_data';

import 'package:dartchess/dartchess.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/data/repositories/endgames/assessment_attempt_repository.dart';
import 'package:lucena/data/repositories/endgames/assessment_definition_repository_asset.dart';
import 'package:lucena/data/repositories/opponent/opponent_repository.dart';
import 'package:lucena/data/services/asset_service.dart';
import 'package:lucena/data/services/preferences_service.dart';
import 'package:lucena/domain/models/assessment_attempt.dart';
import 'package:lucena/domain/models/clock.dart';
import 'package:lucena/domain/models/game_setup.dart';
import 'package:lucena/domain/use_cases/game_rules.dart';
import 'package:lucena/domain/use_cases/now.dart';
import 'package:lucena/ui/endgames/view_models/assessment_cubit.dart';
import 'package:lucena/ui/endgames/view_models/assessment_pilot_factory.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

final class _FixedNow implements Now {
  @override
  DateTime call() => DateTime.utc(2026, 10, 18);
}

final class _TrackingPreferences extends PreferencesService {
  final reads = <String>[];
  final writes = <String>[];

  @override
  Future<String?> getString(String key) {
    reads.add(key);
    return super.getString(key);
  }

  @override
  Future<void> setString(String key, String value) {
    writes.add(key);
    return super.setString(key, value);
  }
}

final class _CheckoutAssets extends AssetService {
  _CheckoutAssets({this.tamper = false, this.tamperSource});

  final bool tamper;
  final String? tamperSource;
  final paths = <String>[];

  @override
  Future<Uint8List> loadBytes(String path) async {
    paths.add(path);
    final bytes = await io.File(path).readAsBytes();
    return tamper || path == tamperSource
        ? Uint8List.fromList([...bytes, 32])
        : bytes;
  }
}

typedef _Request = ({
  Position position,
  Duration thinkTime,
  OpponentKind kind,
  List<Position> history,
});

final class _RecordingOpponent implements OpponentRepository {
  _RecordingOpponent({this.legalReply = false});

  final bool legalReply;
  final requests = <_Request>[];
  final requested = Completer<_Request>();

  @override
  Future<Move?> pickMove(
    Position position, {
    required Duration thinkTime,
    OpponentKind kind = OpponentKind.stockfish,
    int? level,
    List<Position> history = const [],
    TimeControl? time,
  }) async {
    final request = (
      position: position,
      thinkTime: thinkTime,
      kind: kind,
      history: List<Position>.of(history),
    );
    requests.add(request);
    if (!requested.isCompleted) requested.complete(request);
    // Tests capture the wiring; no engine or adjudication is needed.
    if (!legalReply) return null;
    final moves = [
      for (final entry in GameRules.legalMoves(position).entries)
        for (final target in entry.value)
          NormalMove(from: entry.key, to: target),
    ];
    return moves.isEmpty ? null : moves.first;
  }
}

Move _nonterminalMove(Position position) =>
    [
      for (final entry in GameRules.legalMoves(position).entries)
        for (final target in entry.value)
          NormalMove(from: entry.key, to: target),
    ].firstWhere(
      (move) =>
          GameRules.endOf(GameRules.play(position, move)!.position) == null,
    );

Future<AssessmentState> _until(
  AssessmentCubit cubit,
  bool Function(AssessmentState) predicate,
) => predicate(cubit.state)
    ? Future.value(cubit.state)
    : cubit.stream.firstWhere(predicate).timeout(const Duration(seconds: 3));

void main() {
  late _FixedNow now;
  late _TrackingPreferences preferences;
  late _RecordingOpponent opponent;
  late _CheckoutAssets assets;

  AssessmentPilotFactory factory({String Function()? createAttemptId}) =>
      AssessmentPilotFactory(
        opponent: opponent,
        now: now,
        assets: assets,
        preferences: preferences,
        createAttemptId: createAttemptId,
      );

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    now = _FixedNow();
    preferences = _TrackingPreferences();
    opponent = _RecordingOpponent();
    assets = _CheckoutAssets();
  });

  test(
    'create authenticates packaged definition without loading a session',
    () async {
      final cubit = await factory(createAttemptId: () => 'factory-test')
          .create();
      addTearDown(cubit.close);
      expect(assets.paths, [
        AssessmentPilotFactory.definitionPath,
        ...AssessmentPilotFactory.packagedSources.values,
      ]);
      expect(cubit.state.snapshot, isNull);
      expect(cubit.state.busy, isFalse);
      expect(preferences.reads, isEmpty);
      expect(preferences.writes, isEmpty);
      expect(opponent.requests, isEmpty);
      expect(identical(cubit.config.now, now), isTrue);
      final descriptor = await AssetAssessmentDefinitionRepository(assets).load(
        path: AssessmentPilotFactory.definitionPath,
        expectedSha256: AssessmentPilotFactory.definitionSha256,
        expectedLessonId: AssessmentPilotFactory.lessonId,
        expectedExerciseId: AssessmentPilotFactory.exerciseId,
      );
      expect(cubit.config.lessonId, descriptor.lessonId);
      expect(cubit.config.exerciseId, descriptor.exerciseId);
      expect(cubit.config.initialFen, descriptor.initialFen);
      expect(cubit.config.student, descriptor.student);
      expect(cubit.config.contentIdentity, descriptor.contentIdentity);
    },
  );

  test(
    'host load persists a local attempt and reopening resumes its identity',
    () async {
      final cubit = await factory(createAttemptId: () => 'persisted-id')
          .create();
      await cubit.load();
      expect(cubit.state.technicalFailure, isNull);
      expect(cubit.state.snapshot!.attemptId, 'persisted-id');
      expect(cubit.state.snapshot!.startedAtUtc, now());
      expect(preferences.writes, isNotEmpty);
      expect(preferences.writes.toSet(), {
        LocalAssessmentAttemptRepository.key,
      });
      final stored = await LocalAssessmentAttemptRepository(preferences)
          .loadCurrent();
      expect(stored!.contentIdentity, cubit.config.contentIdentity);
      await cubit.close();

      final reopened = await factory(
        createAttemptId: () => throw StateError('Resume must retain the ID'),
      ).create();
      addTearDown(reopened.close);
      await reopened.load();
      expect(reopened.state.technicalFailure, isNull);
      final resumed = reopened.state.snapshot!;
      expect(resumed.attemptId, 'persisted-id');
      expect(resumed.revision, stored.revision + 1);
      expect(resumed.callbackEpoch, stored.callbackEpoch + 1);
      final before = stored.toJson()
        ..remove('revision')
        ..remove('callbackEpoch');
      final after = resumed.toJson()
        ..remove('revision')
        ..remove('callbackEpoch');
      expect(
        jsonEncode(after) == jsonEncode(before),
        isTrue,
        reason: 'Resume must preserve collected content and attempt identity',
      );
      expect(preferences.reads.toSet(), {LocalAssessmentAttemptRepository.key});
    },
  );

  test(
    'default IDs use independent 16-byte lowercase hexadecimal values',
    () async {
      final cubit = await factory().create();
      addTearDown(cubit.close);
      final ids = List.generate(128, (_) => cubit.config.createAttemptId());
      expect(ids.toSet(), hasLength(ids.length));
      expect(ids.every(RegExp(r'^[0-9a-f]{32}$').hasMatch), isTrue);
    },
  );

  test(
    'tampered packaged bytes stop factory before storage or opponent use',
    () async {
      assets = _CheckoutAssets(tamper: true);
      await expectLater(
        factory().create(),
        throwsA(
          isA<AssessmentDefinitionRepositoryException>().having(
            (failure) => failure.reason,
            'reason',
            'hashMismatch',
          ),
        ),
      );
      expect(preferences.reads, isEmpty);
      expect(preferences.writes, isEmpty);
      expect(opponent.requests, isEmpty);
    },
  );

  test(
    'opponent receives current position and complete ordered history',
    () async {
      final cubit = await factory(createAttemptId: () => 'opponent-test')
          .create();
      addTearDown(cubit.close);
      await cubit.load();
      await cubit.submitInitial();
      final root = GameRules.fromFen(cubit.config.initialFen)!;
      // Pick a legal nonterminal action solely to exercise the callback.
      final move = _nonterminalMove(root);
      final failure = _until(
        cubit,
        (state) =>
            state.technicalFailure ==
            AssessmentTechnicalFailure.opponentUnavailable,
      );
      await cubit.play(move);
      final request = await opponent.requested.future.timeout(
        const Duration(seconds: 3),
      );
      expect(request.thinkTime, const Duration(milliseconds: 300));
      expect(request.kind, OpponentKind.stockfish);
      expect(request.history, hasLength(2));
      expect(request.history.first.fen, root.fen);
      expect(request.history.last.fen, request.position.fen);
      expect(request.position.fen, GameRules.play(root, move)!.position.fen);
      await failure;
    },
  );

  test(
    'changed packaged sources reject before storage or opponent use',
    () async {
      for (final path in AssessmentPilotFactory.packagedSources.values) {
        assets = _CheckoutAssets(tamperSource: path);
        await expectLater(
          factory().create(),
          throwsA(
            isA<AssessmentDefinitionRepositoryException>().having(
              (failure) => failure.reason,
              'reason',
              'sourceHashMismatch',
            ),
          ),
        );
      }
      expect(preferences.reads, isEmpty);
      expect(preferences.writes, isEmpty);
      expect(opponent.requests, isEmpty);
    },
  );

  test(
    'closed collection invokes real runtime facts without an engine',
    () async {
      opponent = _RecordingOpponent(legalReply: true);
      final cubit = await factory(createAttemptId: () => 'facts-test').create();
      addTearDown(cubit.close);
      await cubit.load();
      await cubit.submitInitial();
      final replied = _until(
        cubit,
        (state) =>
            !state.busy &&
            state.snapshot!.execution.played.length == 2 &&
            !state.snapshot!.execution.pending,
      );
      await cubit.play(
        _nonterminalMove(GameRules.fromFen(cubit.config.initialFen)!),
      );
      await replied;
      if (cubit.state.snapshot!.phase == AssessmentPhase.execution) {
        await cubit.finishExecution(voluntaryConfirmed: true);
      }
      expect(cubit.state.snapshot!.phase, AssessmentPhase.protection);
      final evaluated = _until(
        cubit,
        (state) =>
            state.conceptualResult != null || state.technicalFailure != null,
      );
      await cubit.submitProtection();
      final state = await evaluated;
      expect(state.technicalFailure, isNull);
      expect(state.conceptualResult, isNotNull);
      expect(opponent.requests, hasLength(1));
      final raw = await preferences.getString(
        LocalAssessmentAttemptRepository.key,
      );
      expect(jsonDecode(raw!), isA<Map<String, dynamic>>());
    },
  );
}

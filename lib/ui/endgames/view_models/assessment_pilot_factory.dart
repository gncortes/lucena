import 'dart:math';

import 'package:crypto/crypto.dart';

import '../../../data/repositories/endgames/assessment_attempt_repository.dart';
import '../../../data/repositories/endgames/assessment_definition_repository_asset.dart';
import '../../../data/repositories/opponent/opponent_repository.dart';
import '../../../data/services/asset_service.dart';
import '../../../data/services/preferences_service.dart';
import '../../../domain/models/game_setup.dart';
import '../../../domain/use_cases/assessment_facts_provider.dart';
import '../../../domain/use_cases/now.dart';
import 'assessment_cubit.dart';

/// Composition boundary for the isolated U1 collection pilot.
/// The host owns the returned cubit and calls load exactly once on entry.
final class AssessmentPilotFactory {
  AssessmentPilotFactory({
    required this._opponent,
    required this._now,
    this._assets = const AssetService(),
    this._preferences,
    String Function()? createAttemptId,
  }) : _createAttemptId = createAttemptId ?? _randomAttemptId;

  static const definitionPath =
      'assets/tablebase/t77_u1_assessment_definition.json';
  static const definitionSha256 =
      '45f235f05e4f6439c50242891f23b3abff2c6fa4987ff460947d3b61689af038';
  static const lessonId = 'mates.bishopKnight.deletang';
  static const exerciseId = 'finalNetAssessment01';
  static const packagedSources = {
    'lessonDescriptor':
        'assets/lessons/endgames/mates.bishopKnight.deletang.json',
    'teaching':
        'assets/lessons/roteiros/mates.bishopKnight.deletang/finalNet.json',
    'textsPt': 'assets/lessons/pt/endgames/mates.bishopKnight.deletang.finalNet.rot.json',
    'proofManifest': 'assets/tablebase/exercise_proofs.json',
  };

  final OpponentRepository _opponent;
  final Now _now;
  final AssetService _assets;
  final PreferencesService? _preferences;
  final String Function() _createAttemptId;

  Future<AssessmentCubit> create() async {
    final descriptor = await AssetAssessmentDefinitionRepository(_assets).load(
      path: definitionPath,
      expectedSha256: definitionSha256,
      expectedLessonId: lessonId,
      expectedExerciseId: exerciseId,
    );
    // Authenticate the sources actually shipped in the app against the pinned
    // definition. Remaining document hashes are provenance identities only:
    // those documents are not available for authentication in the app.
    for (final source in packagedSources.entries) {
      try {
        final bytes = await _assets.loadBytes(source.value);
        if (sha256.convert(bytes).toString() !=
            descriptor.sourceHashes[source.key]) {
          throw const AssessmentDefinitionRepositoryException(
            'sourceHashMismatch',
          );
        }
      } on AssessmentDefinitionRepositoryException {
        rethrow;
      } on Object {
        throw const AssessmentDefinitionRepositoryException(
          'sourceUnavailable',
        );
      }
    }
    final facts = AssessmentRuntimeFactsProvider(descriptor);
    return AssessmentCubit(
      config: AssessmentConfig(
        lessonId: descriptor.lessonId,
        exerciseId: descriptor.exerciseId,
        initialFen: descriptor.initialFen,
        student: descriptor.student,
        contentIdentity: descriptor.contentIdentity,
        createAttemptId: _createAttemptId,
        now: _now,
      ),
      repository: LocalAssessmentAttemptRepository(
        _preferences ?? PreferencesService(),
      ),
      pickOpponent: (position, history) => _opponent.pickMove(
        position,
        thinkTime: const Duration(milliseconds: 300),
        kind: OpponentKind.stockfish,
        history: history,
      ),
      facts: (attempt) => Future.sync(() => facts(attempt)),
    );
  }

  static String _randomAttemptId() {
    final random = Random.secure();
    return List.generate(
      16,
      (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
  }
}

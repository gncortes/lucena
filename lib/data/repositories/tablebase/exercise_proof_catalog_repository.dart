import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

import '../../../domain/use_cases/exercise_judge.dart';
import '../../services/asset_service.dart';
import 'exercise_judge_repository.dart';

/// Trusted manifest with version 1 and an entries list. Each entry supplies
/// path, exact queryFen and lowercase rawSha256, independently of its envelope.
/// Paths point to v1 envelopes, not raw responses. No assets are generated here.
class AssetExerciseProofCatalogRepository implements ExerciseProofProvider {
  AssetExerciseProofCatalogRepository(this._assets, {required this.path});

  static const defaultPath = 'assets/tablebase/exercise_proofs.json';

  final AssetService _assets;
  final String path;
  Future<List<AssetExerciseJudgeRepository>?>? _catalog;

  static Future<bool> _verify(Uint8List bytes, String expectedSha256) async =>
      sha256.convert(bytes).toString() == expectedSha256;

  Future<List<AssetExerciseJudgeRepository>?> _load() async {
    try {
      final manifest = jsonDecode(await _assets.loadString(path)) as Map;
      if (manifest['version'] != 1) return null;
      final entries = manifest['entries'] as List;
      final paths = <String>{};
      final queries = <String>{};
      final providers = <AssetExerciseJudgeRepository>[];
      for (final item in entries) {
        final entry = item as Map;
        final proofPath = entry['path'] as String;
        final queryFen = entry['queryFen'] as String;
        final hash = entry['rawSha256'] as String;
        if (!proofPath.startsWith('assets/') ||
            !proofPath.endsWith('.json') ||
            proofPath.contains('\\') ||
            proofPath
                .split('/')
                .any((part) => part.isEmpty || part == '..' || part == '.') ||
            ExerciseJudge.exactPosition(queryFen) == null ||
            !RegExp(r'^[0-9a-f]{64}$').hasMatch(hash) ||
            !paths.add(proofPath) ||
            !queries.add(queryFen)) {
          return null;
        }
        providers.add(
          AssetExerciseJudgeRepository(
            assets: _assets,
            path: proofPath,
            verify: _verify,
            queryFen: queryFen,
            rawSha256: hash,
          ),
        );
      }
      return providers;
    } on Object {
      return null;
    }
  }

  @override
  Future<ExerciseJudgement> lookup(String fen) async {
    if (ExerciseJudge.exactPosition(fen) == null) {
      return const ExerciseIndeterminate('invalidFen6');
    }
    final providers = await (_catalog ??= _load());
    if (providers == null) {
      return const ExerciseIndeterminate('proofCatalogUnavailable');
    }
    ExerciseKnown? known;
    for (final provider in providers) {
      final result = await provider.lookup(fen);
      if (result is ExerciseKnown) {
        if (known != null &&
            (known.fen != result.fen ||
                known.perspective != result.perspective ||
                known.wdl != result.wdl ||
                known.conditions != result.conditions)) {
          return const ExerciseIndeterminate('conflictingProof');
        }
        // Neighboring API queries can prove the same exact position. Keep
        // its verified provenance only after checking every result agrees.
        known ??= result;
      } else if (result is ExerciseIndeterminate &&
          result.reason != 'noExactProof') {
        // A broken entry cannot be silently skipped in favor of another proof.
        return result;
      }
    }
    return known ?? const ExerciseIndeterminate('noExactProof');
  }
}

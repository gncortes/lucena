import 'dart:convert';
import 'dart:typed_data';

import 'package:dartchess/dartchess.dart';

import '../../../domain/models/wdl.dart';
import '../../../domain/use_cases/exercise_judge.dart';
import '../../../domain/use_cases/game_rules.dart';
import '../../services/asset_service.dart';

/// The caller must verify the digest of the original UTF-8 API response.
/// No verifier default is provided: unverified bytes never become a proof.
typedef ExerciseProofVerifier = Future<bool> Function(
  Uint8List bytes,
  String expectedSha256,
);

/// Offline v1 envelope uses version 1, exact FEN6 queryFen, the API URL source,
/// lowercase rawSha256, and the original UTF-8 API response string as raw.
/// The source URL must contain the same fen query. The envelope binds recorded query
/// metadata to the raw response; a digest alone cannot authenticate that query.
/// Supports only the root and its legally replayed immediate children. It does
/// not extrapolate across clocks, descendants or unknown/cursed categories.
/// [queryFen] and [rawSha256] are independently pinned by the trusted caller,
/// from the recorded public query, rather than accepted from the loaded file.
class AssetExerciseJudgeRepository implements ExerciseProofProvider {
  AssetExerciseJudgeRepository({
    required AssetService assets,
    required String path,
    required this.verify,
    required this.queryFen,
    required this.rawSha256,
  }) : path = path,
       _load = (() => assets.loadBytes(path));

  AssetExerciseJudgeRepository.bytes({
    required Uint8List bytes,
    required this.verify,
    required this.queryFen,
    required this.rawSha256,
  }) : path = null,
       _load = _copiedBytes(bytes);

  final String? path;
  final ExerciseProofVerifier verify;
  final String queryFen;
  final String rawSha256;
  final Future<Uint8List> Function() _load;

  static Future<Uint8List> Function() _copiedBytes(Uint8List bytes) {
    final snapshot = Uint8List.fromList(bytes);
    return () async => Uint8List.fromList(snapshot);
  }

  @override
  Future<ExerciseJudgement> lookup(String fen) async {
    try {
      if (ExerciseJudge.exactPosition(fen) == null) {
        return const ExerciseIndeterminate('invalidFen6');
      }
      final envelope = jsonDecode(utf8.decode(await _load())) as Map;
      if (envelope['version'] != 1) {
        return const ExerciseIndeterminate('unsupportedProofVersion');
      }
      final queryFen = envelope['queryFen'] as String;
      final root = ExerciseJudge.exactPosition(queryFen);
      final source = envelope['source'] as String;
      final uri = Uri.parse(source);
      final hash = envelope['rawSha256'] as String;
      if (root == null ||
          queryFen != this.queryFen ||
          hash != rawSha256 ||
          uri.scheme != 'https' ||
          uri.host != 'tablebase.lichess.ovh' ||
          uri.path != '/standard' ||
          uri.queryParametersAll['fen']?.length != 1 ||
          uri.queryParameters['fen'] != queryFen ||
          !RegExp(r'^[0-9a-f]{64}$').hasMatch(hash)) {
        return const ExerciseIndeterminate('invalidProvenance');
      }
      final raw = envelope['raw'] as String;
      if (!await verify(Uint8List.fromList(utf8.encode(raw)), hash)) {
        return const ExerciseIndeterminate('proofHashMismatch');
      }
      final response = jsonDecode(raw) as Map;
      if (root.fen == fen) {
        return _result(response, root, source, hash);
      }
      for (final entry in response['moves'] as List) {
        final child = entry as Map;
        final move = Move.parse(child['uci'] as String);
        final played = move == null ? null : GameRules.play(root, move);
        if (played?.position.fen == fen) {
          return _result(child, played!.position, source, hash);
        }
      }
      return const ExerciseIndeterminate('noExactProof');
    } on Object {
      return const ExerciseIndeterminate('malformedOrUnavailableProof');
    }
  }

  ExerciseJudgement _result(
    Map data,
    Position position,
    String source,
    String hash,
  ) {
    // API categories include fifty-move semantics at the recorded query clock.
    // Require precise DTZ too: approximate or missing data is not evidence.
    final wdl = switch (data['category']) {
      'win' => Wdl.win,
      'draw' => Wdl.draw,
      'loss' => Wdl.loss,
      _ => null,
    };
    final dtz = data['precise_dtz'];
    if (wdl == null || dtz is! int) {
      return const ExerciseIndeterminate('unsupportedCategoryOrDtz');
    }
    if ((wdl == Wdl.win && dtz <= 0) ||
        (wdl == Wdl.loss && dtz >= 0) ||
        (wdl == Wdl.draw && dtz != 0) ||
        (wdl != Wdl.draw && position.halfmoves + dtz.abs() > 100)) {
      return const ExerciseIndeterminate('unprovedFiftyMoveConditions');
    }
    return ExerciseKnown(
      wdl: wdl,
      perspective: position.turn,
      fen: position.fen,
      source: source,
      sourceSha256: hash,
      conditions:
          'exact root/one legal ply; precise DTZ; fifty-move rule; '
          'repetition must be checked by ExerciseJudge',
    );
  }
}

import 'package:dartchess/dartchess.dart';

/// A peça de um desafio das estrelas.
enum ChallengePiece {
  rook(Role.rook),
  bishop(Role.bishop),
  knight(Role.knight),
  queen(Role.queen),
  king(Role.king),
  pawn(Role.pawn);

  const ChallengePiece(this.role);

  final Role role;

  static ChallengePiece? byName(String name) {
    for (final piece in values) {
      if (piece.name == name) return piece;
    }
    return null;
  }
}

/// O nível de um desafio: quanto tempo, quantos peões no caminho e a que
/// distância (em lances) a próxima estrela aparece.
enum ChallengeLevel {
  easy(
    seconds: 60,
    obstacles: 0,
    minMoves: 1,
    maxMoves: 1,
    thresholds: [10, 16, 22],
  ),
  medium(
    seconds: 60,
    obstacles: 3,
    minMoves: 1,
    maxMoves: 2,
    thresholds: [8, 13, 18],
  ),
  hard(
    seconds: 45,
    obstacles: 6,
    minMoves: 2,
    maxMoves: 3,
    thresholds: [6, 10, 14],
  );

  const ChallengeLevel({
    required this.seconds,
    required this.obstacles,
    required this.minMoves,
    required this.maxMoves,
    required this.thresholds,
  });

  final int seconds;
  final int obstacles;
  final int minMoves;
  final int maxMoves;

  /// Quantas estrelas valem 1, 2 e 3 estrelas de nota.
  final List<int> thresholds;

  Duration get duration => Duration(seconds: seconds);

  static ChallengeLevel? byName(String name) {
    for (final level in values) {
      if (level.name == name) return level;
    }
    return null;
  }
}

/// Os melhores resultados por peça e nível (estrelas pegas).
class StarChallengeProgress {
  const StarChallengeProgress({this.best = const {}});

  final Map<String, int> best;

  static String keyOf(ChallengePiece piece, ChallengeLevel level) =>
      '${piece.name}.${level.name}';

  int? bestOf(ChallengePiece piece, ChallengeLevel level) =>
      best[keyOf(piece, level)];

  StarChallengeProgress withBest(
    ChallengePiece piece,
    ChallengeLevel level,
    int collected,
  ) => StarChallengeProgress(best: {...best, keyOf(piece, level): collected});

  Map<String, dynamic> toJson() => {'best': best};

  static StarChallengeProgress fromJson(Object? json) {
    if (json is! Map) return const StarChallengeProgress();
    final best = json['best'];
    return StarChallengeProgress(
      best: {
        if (best is Map)
          for (final MapEntry(:key, :value) in best.entries)
            if (key is String && value is int) key: value,
      },
    );
  }
}

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

/// O tipo da estrela: quanto vale e quanto tempo fica na tela (a de ouro
/// vale mais e some mais depressa).
enum StarKind {
  bronze(points: 1, lifetimeFactor: 1.0),
  silver(points: 2, lifetimeFactor: 0.75),
  gold(points: 3, lifetimeFactor: 0.5);

  const StarKind({required this.points, required this.lifetimeFactor});

  final int points;
  final double lifetimeFactor;
}

/// O nível de um desafio: quanto tempo, quantos peões no caminho, a que
/// distância (em lances) a próxima estrela aparece e quanto ela dura.
enum ChallengeLevel {
  easy(
    seconds: 60,
    obstacles: 0,
    minMoves: 1,
    maxMoves: 1,
    starMillis: 6000,
    thresholds: [15],
  ),
  medium(
    seconds: 60,
    obstacles: 3,
    minMoves: 1,
    maxMoves: 2,
    starMillis: 4500,
    thresholds: [12, 24],
  ),
  hard(
    seconds: 45,
    obstacles: 6,
    minMoves: 2,
    maxMoves: 3,
    starMillis: 3500,
    thresholds: [9, 18, 27],
  );

  const ChallengeLevel({
    required this.seconds,
    required this.obstacles,
    required this.minMoves,
    required this.maxMoves,
    required this.starMillis,
    required this.thresholds,
  });

  final int seconds;
  final int obstacles;
  final int minMoves;
  final int maxMoves;

  /// Quanto uma estrela de bronze fica na tela (as outras, menos).
  final int starMillis;

  /// Os patamares de pontos de cada estrela da nota: o nível vale tantas
  /// estrelas quanto a dificuldade (fácil 1, médio 2, difícil 3).
  final List<int> thresholds;

  /// Quantas estrelas o nível pode dar.
  int get stars => thresholds.length;

  Duration get duration => Duration(seconds: seconds);

  /// Quanto uma estrela de [kind] fica na tela neste nível.
  Duration starLifetime(StarKind kind) =>
      Duration(milliseconds: (starMillis * kind.lifetimeFactor).round());

  static ChallengeLevel? byName(String name) {
    for (final level in values) {
      if (level.name == name) return level;
    }
    return null;
  }
}

/// Os melhores resultados por peça e nível (pontos).
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

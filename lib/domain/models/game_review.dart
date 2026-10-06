import 'dart:math' as math;

/// A avaliação de uma posição pela engine, sempre do ponto de vista das
/// brancas: centipeões ou mate em N (negativo: as pretas dão o mate).
class EngineScore {
  const EngineScore({this.centipawns, this.mate, this.mated});

  /// A posição já está em mate: [whiteMated] diz quem levou.
  const EngineScore.mated({required bool whiteMated})
    : centipawns = null,
      mate = 0,
      mated = whiteMated ? MatedSide.white : MatedSide.black;

  final int? centipawns;
  final int? mate;

  /// Quem levou mate, se a posição já acabou em mate.
  final MatedSide? mated;

  /// Teto dos centipeões nas contas (e valor de um mate), como no Lichess.
  static const ceiling = 1000;

  /// Os centipeões das contas: entre −1000 e 1000; o mate vale ±1000.
  int get cappedCentipawns {
    final m = mate;
    if (m != null) {
      final whiteWins = m > 0 || (m == 0 && mated == MatedSide.black);
      return whiteWins ? ceiling : -ceiling;
    }
    return (centipawns ?? 0).clamp(-ceiling, ceiling);
  }

  /// A chance de vitória das brancas, de 0 a 100 (fórmula do Lichess).
  double get whiteWinPercent {
    final chances = 2 / (1 + math.exp(-0.00368208 * cappedCentipawns)) - 1;
    return 50 + 50 * chances.clamp(-1, 1);
  }

  Map<String, Object?> toJson() => {
    if (centipawns != null) 'cp': centipawns,
    if (mate != null) 'mate': mate,
    if (mated != null) 'mated': mated!.name,
  };

  static EngineScore fromJson(Map<String, Object?> json) {
    final mated = json['mated'] as String?;
    if (mated != null) {
      return EngineScore.mated(whiteMated: mated == MatedSide.white.name);
    }
    return EngineScore(
      centipawns: json['cp'] as int?,
      mate: json['mate'] as int?,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is EngineScore &&
      other.centipawns == centipawns &&
      other.mate == mate &&
      other.mated == mated;

  @override
  int get hashCode => Object.hash(centipawns, mate, mated);
}

/// Quem levou mate.
enum MatedSide { white, black }

/// Uma linha da engine: a avaliação e os lances (UCI) a partir da posição.
class EngineLine {
  const EngineLine({required this.score, required this.moves, this.depth = 0});

  final EngineScore score;
  final List<String> moves;

  /// A profundidade que a engine alcançou.
  final int depth;

  Map<String, Object?> toJson() => {
    'score': score.toJson(),
    'moves': moves,
    'depth': depth,
  };

  static EngineLine fromJson(Map<String, Object?> json) => EngineLine(
    score: EngineScore.fromJson(json['score']! as Map<String, Object?>),
    moves: (json['moves']! as List).cast<String>(),
    depth: json['depth'] as int? ?? 0,
  );
}

/// O que a revisão diz de um lance, na nomenclatura do xadrez.
enum MoveQuality {
  /// Era o único lance legal.
  forced,

  /// O melhor lance, e o único que segurava a posição.
  great,

  /// O lance que a engine escolheria.
  best,

  /// Quase tão bom quanto o melhor.
  excellent,

  /// Um bom lance.
  good,

  /// Imprecisão (?!): perdeu um pouco.
  inaccuracy,

  /// Erro (?).
  mistake,

  /// Lance perdido: tinha a vitória e a deixou escapar.
  miss,

  /// Erro grave (??).
  blunder;

  /// Os que contam como falha na contagem do resumo.
  bool get isError =>
      this == inaccuracy || this == mistake || this == miss || this == blunder;
}

/// A revisão de um lance da partida.
class ReviewedMove {
  const ReviewedMove({
    required this.before,
    required this.after,
    required this.quality,
    required this.accuracy,
    this.best,
    this.bestLine = const [],
  });

  /// A avaliação antes e depois do lance (brancas).
  final EngineScore before;
  final EngineScore after;

  final MoveQuality quality;

  /// A precisão do lance, de 0 a 100.
  final double accuracy;

  /// O melhor lance na posição antes deste (UCI) e a linha que segue dele.
  final String? best;
  final List<String> bestLine;

  Map<String, Object?> toJson() => {
    'before': before.toJson(),
    'after': after.toJson(),
    'quality': quality.name,
    'accuracy': accuracy,
    'best': ?best,
    'line': bestLine,
  };

  static ReviewedMove fromJson(Map<String, Object?> json) => ReviewedMove(
    before: EngineScore.fromJson(json['before']! as Map<String, Object?>),
    after: EngineScore.fromJson(json['after']! as Map<String, Object?>),
    quality: MoveQuality.values.byName(json['quality']! as String),
    accuracy: (json['accuracy']! as num).toDouble(),
    best: json['best'] as String?,
    bestLine: (json['line'] as List? ?? const []).cast<String>(),
  );
}

/// A revisão da partida inteira: um [ReviewedMove] por lance e a precisão de
/// cada lado.
class GameReview {
  const GameReview({
    required this.moves,
    this.whiteAccuracy,
    this.blackAccuracy,
    this.depth = 0,
  });

  /// Muda quando o cálculo muda: revisão de outra versão é refeita.
  static const version = 2;

  final List<ReviewedMove> moves;

  /// Nula se o lado não jogou nenhum lance.
  final double? whiteAccuracy;
  final double? blackAccuracy;

  /// O peso da revisão: quanto a engine trabalhou em cada posição (o índice
  /// do orçamento de tempo e profundidade, ver `GameDetailsCubit.budgets`).
  /// Uma anotação de peso maior troca a de peso menor.
  final int depth;

  /// Quantos lances de cada qualidade o lado que começa ([firstIsWhite])
  /// fez, se [white], ou o outro.
  Map<MoveQuality, int> counts({
    required bool white,
    required bool firstIsWhite,
  }) {
    final counts = {for (final quality in MoveQuality.values) quality: 0};
    for (final (index, move) in moves.indexed) {
      final isWhite = (index.isEven) == firstIsWhite;
      if (isWhite == white) counts[move.quality] = counts[move.quality]! + 1;
    }
    return counts;
  }

  Map<String, Object?> toJson() => {
    'version': version,
    'depth': depth,
    'white': ?whiteAccuracy,
    'black': ?blackAccuracy,
    'moves': [for (final move in moves) move.toJson()],
  };

  /// Nula se o JSON é de outra versão do cálculo.
  static GameReview? fromJson(Map<String, Object?> json) {
    if (json['version'] != version) return null;
    return GameReview(
      depth: json['depth'] as int? ?? 0,
      whiteAccuracy: (json['white'] as num?)?.toDouble(),
      blackAccuracy: (json['black'] as num?)?.toDouble(),
      moves: [
        for (final move
            in (json['moves']! as List).cast<Map<String, Object?>>())
          ReviewedMove.fromJson(move),
      ],
    );
  }
}

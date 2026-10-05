import '../models/character.dart';
import 'position_assessment.dart';

/// Um evento da partida que o personagem pode comentar.
class GameEvent {
  const GameEvent(this.category, [this.intensity = 1]);

  final LineCategory category;

  /// De 1 (leve) a 3 (forte).
  final int intensity;

  @override
  bool operator ==(Object other) =>
      other is GameEvent &&
      other.category == category &&
      other.intensity == intensity;

  @override
  int get hashCode => Object.hash(category, intensity);

  @override
  String toString() => 'GameEvent(${category.name}, $intensity)';
}

/// O que um lance fez no tabuleiro; quem chama monta a partir da posição.
class MoveFacts {
  const MoveFacts({
    required this.byCharacter,
    this.captured,
    this.promotion = false,
  });

  /// Se o lance foi do personagem (senão, do jogador).
  final bool byCharacter;

  /// A peça capturada: 'pawn', 'knight', 'bishop', 'rook', 'queen' ou null.
  final String? captured;

  /// Se o lance promoveu um peão.
  final bool promotion;
}

/// A memória emocional de uma partida, salva junto com ela para sobreviver
/// a fechar o app.
class TalkMemory {
  const TalkMemory({
    this.scores = const [],
    this.spoken = const [],
    this.movesSinceLine = 0,
    this.onceFlags = const {},
    this.lastLineId,
    this.emotion,
  });

  /// Memória de uma partida que acabou de começar.
  static const empty = TalkMemory();

  /// Quantas avaliações guardar.
  static const maxScores = 12;

  /// Avaliação (do lado do personagem) depois de cada lance avaliado, da
  /// mais antiga para a mais nova.
  final List<int> scores;

  /// Ids das falas já ditas nesta partida.
  final List<String> spoken;

  /// Lances desde a última fala.
  final int movesSinceLine;

  /// Eventos que só acontecem uma vez por partida e já foram ditos.
  final Set<String> onceFlags;
  final String? lastLineId;

  /// A emoção mostrada agora.
  final Emotion? emotion;

  TalkMemory copyWith({
    List<int>? scores,
    List<String>? spoken,
    int? movesSinceLine,
    Set<String>? onceFlags,
    String? lastLineId,
    Emotion? emotion,
  }) => TalkMemory(
    scores: scores ?? this.scores,
    spoken: spoken ?? this.spoken,
    movesSinceLine: movesSinceLine ?? this.movesSinceLine,
    onceFlags: onceFlags ?? this.onceFlags,
    lastLineId: lastLineId ?? this.lastLineId,
    emotion: emotion ?? this.emotion,
  );

  Map<String, dynamic> toJson() => {
    'scores': scores,
    'spoken': spoken,
    'movesSinceLine': movesSinceLine,
    'onceFlags': onceFlags.toList()..sort(),
    'lastLineId': lastLineId,
    'emotion': emotion?.name,
  };

  /// A memória do JSON; o que faltar ou vier errado fica no padrão.
  static TalkMemory fromJson(Map<String, dynamic> json) {
    List<T> listOf<T>(Object? raw) => [
      if (raw is List)
        for (final v in raw)
          if (v is T) v,
    ];
    final moves = json['movesSinceLine'];
    final last = json['lastLineId'];
    final scores = [for (final v in listOf<num>(json['scores'])) v.toInt()];
    return TalkMemory(
      scores: scores.length > maxScores
          ? scores.sublist(scores.length - maxScores)
          : scores,
      spoken: listOf<String>(json['spoken']),
      movesSinceLine: moves is num ? moves.toInt() : 0,
      onceFlags: listOf<String>(json['onceFlags']).toSet(),
      lastLineId: last is String ? last : null,
      emotion: Emotion.fromCode(_string(json['emotion'])),
    );
  }

  static String? _string(Object? v) => v is String ? v : null;

  @override
  bool operator ==(Object other) =>
      other is TalkMemory &&
      _sameList(other.scores, scores) &&
      _sameList(other.spoken, spoken) &&
      other.movesSinceLine == movesSinceLine &&
      other.onceFlags.length == onceFlags.length &&
      other.onceFlags.containsAll(onceFlags) &&
      other.lastLineId == lastLineId &&
      other.emotion == emotion;

  @override
  int get hashCode => Object.hash(
    Object.hashAll(scores),
    Object.hashAll(spoken),
    movesSinceLine,
    Object.hashAllUnordered(onceFlags),
    lastLineId,
    emotion,
  );

  static bool _sameList<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// Detecta os eventos de um lance e do relógio.
abstract final class GameEvents {
  /// Queda depois do lance do jogador que conta como lance forte dele (o
  /// motor raso supõe as melhores respostas, então a avaliação só cai quando
  /// o jogador achou algo bom).
  static const strongMove = 150;

  /// Quantas avaliações recentes (com a atual) olhar para virada e desmoronar.
  static const recent = 8;

  /// Abaixo disto (em centipeões), a vantagem desmoronou.
  static const collapseFloor = 50;

  /// Relógio baixo.
  static const lowTime = Duration(seconds: 20);

  /// Vantagem de relógio: diferença mínima e teto do relógio do jogador.
  static const timeGap = Duration(seconds: 30);
  static const timeAdvantageCeiling = Duration(seconds: 120);

  /// Jogador pensando há bastante tempo (intensidade 1 e 2).
  static const thinking = Duration(seconds: 25);
  static const longThinking = Duration(seconds: 60);

  /// Categorias ditas no máximo uma vez por partida.
  static const onceCategories = {
    LineCategory.opponentLowTime,
    LineCategory.ownLowTime,
    LineCategory.timeAdvantage,
  };

  /// Os eventos do lance [move], do mais importante para o menos. [memory]
  /// ainda não tem a avaliação deste lance (chame [remember] depois).
  static List<GameEvent> afterMove({
    required TalkMemory memory,
    required MoveFacts move,
    required Evaluation? evaluation,
  }) {
    final events = <GameEvent>[];
    final score = evaluation?.score;
    final previous = memory.scores.isEmpty ? null : memory.scores.last;
    final hasDelta = score != null && previous != null;

    // Virada e desmoronar valem mais que o estado simples.
    var turned = false;
    if (hasDelta) {
      final window = [
        ...memory.scores.skip(
          memory.scores.length > recent - 1
              ? memory.scores.length - (recent - 1)
              : 0,
        ),
        score,
      ];
      final low = window.reduce((a, b) => a < b ? a : b);
      final high = window.reduce((a, b) => a > b ? a : b);
      if (low <= -PositionAssessment.better &&
          score >= PositionAssessment.better &&
          previous < PositionAssessment.better) {
        events.add(const GameEvent(LineCategory.comeback, 3));
        turned = true;
      } else if (high >= PositionAssessment.bigAdvantage &&
          score <= collapseFloor &&
          previous > collapseFloor) {
        events.add(const GameEvent(LineCategory.collapse, 3));
        turned = true;
      }
    }

    // Erro grave ou lance forte.
    if (hasDelta) {
      const swing = PositionAssessment.swing;
      final delta = score - previous;
      if (!move.byCharacter) {
        if (delta >= swing) {
          events.add(
            GameEvent(LineCategory.opponentBlunder, delta >= 2 * swing ? 3 : 2),
          );
        } else if (delta <= -strongMove) {
          final size = delta <= -500 ? 3 : (delta <= -300 ? 2 : 1);
          events.add(GameEvent(LineCategory.strongMove, size));
        }
      } else if (delta <= -swing) {
        events.add(
          GameEvent(LineCategory.ownBlunder, delta <= -2 * swing ? 3 : 2),
        );
      }
    }

    if (move.promotion) {
      events.add(
        GameEvent(
          move.byCharacter
              ? LineCategory.ownPromotion
              : LineCategory.opponentPromotion,
          3,
        ),
      );
    }

    final piece = _captureIntensity(move.captured);
    if (piece != null) {
      events.add(
        GameEvent(
          move.byCharacter
              ? LineCategory.pieceCaptured
              : LineCategory.pieceLost,
          piece,
        ),
      );
    }

    if (hasDelta && !turned) {
      final now = PositionAssessment.stateOf(score);
      if (now != PositionAssessment.stateOf(previous)) {
        events.add(_stateEvent(now));
      }
    }
    return events;
  }

  /// Os eventos do relógio. Os de [onceCategories] já ditos (em
  /// `memory.onceFlags`) não voltam; "jogador pensando" pode voltar, e quem
  /// chama limita a frequência.
  static List<GameEvent> clock({
    required TalkMemory memory,
    required Duration characterTime,
    required Duration playerTime,
    required bool playerToMove,
    required Duration playerThinking,
  }) {
    final events = <GameEvent>[];
    bool fresh(LineCategory c) => !memory.onceFlags.contains(c.name);
    if (playerTime < lowTime && fresh(LineCategory.opponentLowTime)) {
      events.add(const GameEvent(LineCategory.opponentLowTime, 2));
    }
    if (characterTime < lowTime && fresh(LineCategory.ownLowTime)) {
      events.add(const GameEvent(LineCategory.ownLowTime, 2));
    }
    if (characterTime >= playerTime * 2 &&
        characterTime - playerTime >= timeGap &&
        playerTime < timeAdvantageCeiling &&
        fresh(LineCategory.timeAdvantage)) {
      events.add(const GameEvent(LineCategory.timeAdvantage));
    }
    if (playerToMove && playerThinking >= thinking) {
      events.add(
        GameEvent(
          LineCategory.opponentThinking,
          playerThinking >= longThinking ? 2 : 1,
        ),
      );
    }
    return events;
  }

  /// A memória com a avaliação [score] do último lance (sem avaliação, não
  /// muda). Guarda só as [TalkMemory.maxScores] mais novas.
  static TalkMemory remember(TalkMemory memory, int? score) {
    if (score == null) return memory;
    final scores = [...memory.scores, score];
    return memory.copyWith(
      scores: scores.length > TalkMemory.maxScores
          ? scores.sublist(scores.length - TalkMemory.maxScores)
          : scores,
    );
  }

  static int? _captureIntensity(String? role) => switch (role) {
    'knight' || 'bishop' => 1,
    'rook' => 2,
    'queen' => 3,
    _ => null,
  };

  static GameEvent _stateEvent(PositionState state) => switch (state) {
    PositionState.bigAdvantage => const GameEvent(LineCategory.bigAdvantage, 2),
    PositionState.better => const GameEvent(LineCategory.better),
    PositionState.equal => const GameEvent(LineCategory.equal),
    PositionState.worse => const GameEvent(LineCategory.worse),
    PositionState.bigDisadvantage => const GameEvent(
      LineCategory.bigDisadvantage,
      2,
    ),
  };
}

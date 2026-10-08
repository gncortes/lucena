import 'attempt.dart';
import 'journey.dart';
import 'pace.dart';
import 'speedrun.dart';

/// Os tipos de regra de conquista. A lista é fechada: uma conquista nova é
/// um tipo daqui com outros parâmetros no JSON.
enum AchievementType {
  /// A primeira partida com o objetivo cumprido.
  firstFulfilled,

  /// Um degrau da Jornada concluído (qualquer um, sem `rungId`).
  rungCompleted,

  /// Uma subcategoria cumprida contra todos os níveis do Maia.
  allLevels,

  /// Uma vitória contra o Maia de um nível.
  beatLevel,

  /// Uma vitória contra o Stockfish.
  beatStockfish,

  /// Um speedrun concluído, do primeiro adversário ao último: qualquer um
  /// ou, com `speedrun` e `pace`, um final num grupo de ritmo (bullet, blitz
  /// ou rápido).
  speedrunCompleted,

  /// Um speedrun concluído sem derrota.
  flawlessSpeedrun,

  /// Um speedrun concluído abaixo do melhor tempo anterior.
  recordImproved,

  /// Um speedrun (ou um desafio, sem modalidade) abaixo de um tempo.
  underTime;

  static AchievementType? fromCode(String? code) => values.asNameMap()[code];
}

/// Uma conquista: um tipo de regra com os parâmetros dela.
class Achievement {
  const Achievement({
    required this.id,
    required this.type,
    this.rungId,
    this.level,
    this.subcategory,
    this.speedrunKind,
    this.speedrunId,
    this.pace,
    this.under,
    this.icon = defaultIcon,
  });

  static const defaultIcon = 'emoji_events';

  /// Os ícones (nomes do Material) que o JSON pode usar.
  static const icons = {
    'emoji_events',
    'military_tech',
    'workspace_premium',
    'star',
    'bolt',
    'local_fire_department',
    'timer',
    'verified',
    'rocket_launch',
    'psychology',
  };

  /// Estável entre versões: a conquista desbloqueada é gravada por ele.
  final String id;
  final AchievementType type;
  final String? rungId;
  final int? level;
  final String? subcategory;

  /// A modalidade de speedrun (`rung`, `ending`). Nula: qualquer uma.
  final String? speedrunKind;

  /// O speedrun de base (`ending.queen`), lido de `speedrun`. Nulo: qualquer
  /// um.
  final String? speedrunId;

  /// O grupo de ritmo em que o speedrun foi jogado. Nulo: qualquer um.
  final PaceCategory? pace;

  /// O tempo limite, lido de `seconds`.
  final Duration? under;
  final String icon;

  /// Lê uma entrada do JSON. Nulo se faltar o id ou o tipo for desconhecido.
  static Achievement? fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final type = AchievementType.fromCode(json['type'] as String?);
    if (id is! String || id.isEmpty || type == null) return null;
    final seconds = json['seconds'];
    final icon = json['icon'];
    return Achievement(
      id: id,
      type: type,
      rungId: json['rungId'] as String?,
      level: (json['level'] as num?)?.toInt(),
      subcategory: json['subcategory'] as String?,
      speedrunKind: json['speedrunKind'] as String?,
      speedrunId: json['speedrun'] as String?,
      pace: PaceCategory.values.asNameMap()[json['pace']],
      under: seconds is num ? Duration(seconds: seconds.toInt()) : null,
      icon: icons.contains(icon) ? icon as String : defaultIcon,
    );
  }
}

/// Os grupos da lista de conquistas, na ordem em que aparecem.
enum AchievementCategory {
  /// A Jornada: o primeiro final, os degraus e os desafios rápidos.
  journey,

  /// Os adversários: cada personagem, o Stockfish e todos os níveis.
  opponents,

  /// Os speedruns.
  speedrun,
}

/// O que dá para contar no caminho de uma conquista: [done] de [total]
/// [unit].
enum AchievementProgressUnit {
  /// Níveis do Maia vencidos.
  levels,

  /// Desafios de um degrau concluídos.
  challenges,
}

/// Quanto falta para uma conquista que dá para medir ("3 de 9 níveis").
class AchievementProgress {
  const AchievementProgress({
    required this.done,
    required this.total,
    required this.unit,
  });

  final int done;
  final int total;
  final AchievementProgressUnit unit;

  /// De 0 a 1, para a barra.
  double get fraction => total <= 0 ? 0 : (done / total).clamp(0, 1);

  @override
  bool operator ==(Object other) =>
      other is AchievementProgress &&
      other.done == done &&
      other.total == total &&
      other.unit == unit;

  @override
  int get hashCode => Object.hash(done, total, unit);

  @override
  String toString() => 'AchievementProgress($done/$total ${unit.name})';
}

extension AchievementGroup on Achievement {
  /// O grupo da conquista na lista.
  AchievementCategory get category => switch (type) {
    AchievementType.firstFulfilled ||
    AchievementType.rungCompleted => AchievementCategory.journey,
    AchievementType.allLevels ||
    AchievementType.beatLevel ||
    AchievementType.beatStockfish => AchievementCategory.opponents,
    AchievementType.speedrunCompleted ||
    AchievementType.flawlessSpeedrun ||
    AchievementType.recordImproved => AchievementCategory.speedrun,
    // Sem modalidade, o tempo é o de um desafio da Jornada.
    AchievementType.underTime =>
      speedrunKind == null
          ? AchievementCategory.journey
          : AchievementCategory.speedrun,
  };

  /// Sai de uma tentativa de speedrun inteira, não de uma partida só.
  bool get fromSpeedrun => category == AchievementCategory.speedrun;
}

/// Uma conquista já mostrada ao jogador, quando e, a partir da T51, de onde
/// veio: a partida ([gameId]) e, numa etapa de speedrun, a tentativa
/// ([speedrunAttemptId]). As gravadas antes não têm a origem.
class UnlockedAchievement {
  const UnlockedAchievement({
    required this.id,
    required this.at,
    this.gameId,
    this.speedrunAttemptId,
  });

  final String id;
  final DateTime at;
  final int? gameId;
  final int? speedrunAttemptId;

  /// Sabe de onde veio (as antigas só têm a data).
  bool get hasSource => gameId != null || speedrunAttemptId != null;

  @override
  bool operator ==(Object other) =>
      other is UnlockedAchievement &&
      other.id == id &&
      other.at == at &&
      other.gameId == gameId &&
      other.speedrunAttemptId == speedrunAttemptId;

  @override
  int get hashCode => Object.hash(id, at, gameId, speedrunAttemptId);

  @override
  String toString() =>
      'UnlockedAchievement($id, $at, game: $gameId, '
      'speedrun: $speedrunAttemptId)';
}

/// Tudo o que as regras de conquista olham, tirado do histórico.
class AchievementFacts {
  const AchievementFacts({
    this.games = const [],
    this.ladder = const [],
    this.subcategoryOf = const {},
    this.runs = const [],
    this.speedruns = const {},
  });

  /// Todas as partidas, em qualquer ordem.
  final List<Attempt> games;
  final List<Rung> ladder;

  /// A subcategoria (`queen`, `rook`, `pawn`...) de cada posição.
  final Map<String, String> subcategoryOf;

  /// As tentativas de speedrun já contadas.
  final List<SpeedrunRun> runs;

  /// Os speedruns, pelo id.
  final Map<String, Speedrun> speedruns;
}

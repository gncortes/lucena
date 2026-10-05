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

/// Uma conquista já mostrada ao jogador e quando.
class UnlockedAchievement {
  const UnlockedAchievement({required this.id, required this.at});

  final String id;
  final DateTime at;
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

import 'package:freezed_annotation/freezed_annotation.dart';

import 'attempt.dart';
import 'clock.dart';
import 'journey.dart';
import 'rating_level.dart';

part 'speedrun.freezed.dart';

/// As modalidades de speedrun.
enum SpeedrunKind {
  /// Todos os desafios de um degrau da Jornada.
  rung,

  /// Um final contra cada degrau: 1000, 1200... 2600 e o Stockfish.
  ending,

  /// Uma sequência fixa de posições, cada uma contra um adversário.
  exercises,

  /// A Jornada inteira, do 1000 ao Stockfish. Pode levar dias: a pausa entre
  /// etapas é livre.
  full,

  /// Um final contra cada degrau, como o de final, com um relógio só para o
  /// jogador: cada etapa começa com o que sobrou da anterior, e uma emenda na
  /// outra, sem pausa.
  marathon;

  static SpeedrunKind? fromCode(String? code) => values.asNameMap()[code];
}

/// A dificuldade de um speedrun de final: a lista abre na do nível do
/// jogador, e as outras ficam a um toque.
enum SpeedrunCategory {
  /// Mate de dama e mate de torre.
  beginner,

  /// Dois bispos, peões, dama contra peão, torre contra peão.
  intermediate,

  /// Bispo e cavalo, dama contra torre, torre e peão contra torre.
  advanced;

  static SpeedrunCategory? fromCode(String? code) => values.asNameMap()[code];

  /// A categoria em que a lista abre para quem está no nível [level].
  static SpeedrunCategory forLevel(RatingLevel level) => switch (level) {
    RatingLevel.beginner || RatingLevel.casual => beginner,
    RatingLevel.intermediate || RatingLevel.advanced => intermediate,
    RatingLevel.expert || RatingLevel.master => advanced,
  };
}

/// Um speedrun: as etapas em ordem, todas com o mesmo ritmo.
@freezed
abstract class Speedrun with _$Speedrun {
  const factory Speedrun({
    required String id,
    required SpeedrunKind kind,

    /// O degrau (`1000`), no speedrun de degrau.
    String? rungId,

    /// A posição do catálogo, no speedrun de final.
    String? positionId,

    /// A dificuldade, nos speedruns de final (e nas Maratonas deles).
    SpeedrunCategory? category,

    /// Só da Jornada (desafio especial de um degrau): fora da lista do
    /// speedrun.
    @Default(false) bool journeyOnly,

    /// O tempo de cada lado em todas as etapas.
    required TimeControl time,

    /// As etapas: posição, adversário e objetivo, como um desafio.
    required List<Challenge> stages,
  }) = _Speedrun;
}

/// Uma tentativa de speedrun, do começo até concluir ou abandonar.
@freezed
abstract class SpeedrunAttempt with _$SpeedrunAttempt {
  const factory SpeedrunAttempt({
    required int id,
    required String speedrunId,
    required DateTime startedAt,

    /// Quando o jogador desistiu da tentativa. Nulo: não desistiu.
    DateTime? abandonedAt,

    /// As partidas da tentativa, na ordem em que foram jogadas.
    @Default(<Attempt>[]) List<Attempt> games,
  }) = _SpeedrunAttempt;
}

/// Uma etapa dentro de uma tentativa.
@freezed
abstract class StageResult with _$StageResult {
  const factory StageResult({
    /// O tempo que o relógio do jogador gastou na etapa, somando as partidas
    /// perdidas.
    required Duration time,
    required int wins,
    required int losses,
  }) = _StageResult;

  const StageResult._();

  bool get done => wins > 0;
}

/// Uma tentativa já contada: tempo por etapa, total e onde está.
@freezed
abstract class SpeedrunRun with _$SpeedrunRun {
  const factory SpeedrunRun({
    required SpeedrunAttempt attempt,

    /// Uma por etapa do speedrun, na ordem.
    required List<StageResult> stages,
  }) = _SpeedrunRun;

  const SpeedrunRun._();

  Duration get total =>
      stages.fold(Duration.zero, (total, stage) => total + stage.time);

  int get losses => stages.fold(0, (total, stage) => total + stage.losses);

  /// A etapa da vez (a primeira não concluída). Igual ao número de etapas
  /// quando a tentativa terminou.
  int get currentStage {
    final index = stages.indexWhere((stage) => !stage.done);
    return index == -1 ? stages.length : index;
  }

  bool get completed => stages.every((stage) => stage.done);

  bool get abandoned => !completed && attempt.abandonedAt != null;

  bool get inProgress => !completed && !abandoned;

  /// Quando a tentativa terminou: a última partida dela.
  DateTime? get finishedAt => completed && attempt.games.isNotEmpty
      ? attempt.games.last.playedAt
      : null;
}

/// Os recordes de um speedrun, de tentativas concluídas.
@freezed
abstract class SpeedrunRecords with _$SpeedrunRecords {
  const factory SpeedrunRecords({
    /// O melhor tempo total. Nulo sem tentativa concluída.
    Duration? best,

    /// O melhor tempo de cada etapa (por adversário), em qualquer tentativa
    /// concluída. Nulo na etapa sem tempo.
    required List<Duration?> bestStages,

    /// As tentativas concluídas, da mais recente para a mais antiga.
    required List<SpeedrunRun> completed,
  }) = _SpeedrunRecords;
}

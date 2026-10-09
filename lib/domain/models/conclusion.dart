import 'package:dartchess/dartchess.dart' show Side;

import 'achievement.dart';
import 'attempt.dart';
import 'clock.dart';
import 'game_end.dart';
import 'journey.dart';
import 'player_rating.dart';
import 'speedrun.dart';

/// De onde a partida veio: decide o cabeçalho, as ações e os extras da tela
/// de conclusão (T51, frente B).
enum ConclusionKind {
  /// Partida avulsa: Treinar finais, posição personalizada, tabuleiro livre.
  game,

  /// Desafio da Jornada.
  journey,

  /// Etapa vencida de um speedrun clássico (há uma próxima).
  speedrunStage,

  /// Etapa perdida de um speedrun clássico: a tentativa acabou ali.
  speedrunLost,

  /// Última etapa vencida: o speedrun concluído.
  speedrunEnd,

  /// Maratona: etapa perdida (ou o banco zerou).
  marathonLost,

  /// Maratona concluída.
  marathonEnd,

  /// Partida às cegas.
  blind,
}

/// Um botão da tela de conclusão.
enum ConclusionAction {
  /// A mesma posição, no mesmo ritmo.
  playAgain,

  /// O mesmo final, abrindo a configuração.
  newGame,

  /// O próximo desafio do degrau.
  nextChallenge,

  /// A próxima etapa do speedrun.
  nextStage,

  /// Um speedrun novo, desde a primeira etapa.
  retry,

  /// O resumo da tentativa de speedrun (tempos de cada etapa).
  summary,

  /// A lista dos speedruns.
  speedruns,

  /// A revisão desta partida (T37).
  analyze,

  /// A tela de rating, com esta partida destacada.
  ratingHistory,

  /// O histórico de partidas do mesmo final.
  gamesHistory,
}

/// Como o jogador saiu da partida, do ponto de vista dele.
enum ConclusionResult { won, lost, draw }

/// O tempo de um speedrun ou Maratona ao fim (ou ao perder uma etapa).
class ConclusionRun {
  const ConclusionRun({
    required this.speedrunId,
    required this.attemptId,
    required this.stage,
    required this.stageCount,
    required this.stages,
    this.spent = const [],
    this.total,
    this.best,
    this.previousBest,
    this.bankLeft,
    this.nextStage,
    this.nextChallenge,
    this.nextTime,
  });

  final String speedrunId;
  final int attemptId;

  /// A etapa jogada (0 é a primeira) e quantas o speedrun tem.
  final int stage;
  final int stageCount;

  /// Os tempos de cada etapa até aqui.
  final List<StageResult> stages;

  /// O tempo de relógio que o jogador gastou em cada etapa, como ele vê no
  /// relógio (na Maratona, sem descontar os acréscimos que voltam ao banco).
  final List<Duration> spent;

  /// O tempo gasto até a etapa jogada.
  Duration get spentSoFar =>
      spent.take(stage + 1).fold(Duration.zero, (sum, time) => sum + time);

  /// O tempo somado das etapas jogadas.
  final Duration? total;

  /// O recorde de agora (já contando esta tentativa) e o de antes dela.
  final Duration? best;
  final Duration? previousBest;

  /// Na Maratona: o que sobrou no banco.
  final Duration? bankLeft;

  /// A etapa seguinte e o desafio dela (nulos no fim ou na derrota).
  final int? nextStage;
  final Challenge? nextChallenge;

  /// Na Maratona: o relógio da etapa seguinte.
  final TimeControl? nextTime;

  /// Bateu o recorde: concluído e mais rápido que o de antes (ou o primeiro).
  bool get newRecord =>
      total != null && (previousBest == null || total! < previousBest!);
}

/// Tudo o que a tela de conclusão mostra, montado a partir da partida
/// gravada (ou, nas que não se gravam, do que a partida deixou).
class Conclusion {
  const Conclusion({
    required this.kind,
    required this.result,
    required this.actions,
    this.gameId,
    this.game,
    this.end,
    this.userSide,
    this.fulfilled,
    this.before,
    this.after,
    this.achievements = const [],
    this.unlocked = const {},
    this.next,
    this.run,
    this.blindMoves,
    this.finalFen,
  });

  final ConclusionKind kind;
  final ConclusionResult result;

  /// Os botões, na ordem: o primeiro é o principal.
  final List<ConclusionAction> actions;

  /// A partida gravada. Nula nas que não se gravam (tabuleiro livre).
  final int? gameId;
  final Attempt? game;

  /// Como acabou (o motivo do cabeçalho).
  final GameEnd? end;
  final Side? userSide;

  /// O objetivo da posição (ganhar ou defender) cumprido. Nulo sem objetivo.
  final bool? fulfilled;

  /// O rating antes e depois. Nulos quando a partida não conta.
  final PlayerRating? before;
  final PlayerRating? after;

  /// As conquistas que esta partida deu.
  final List<Achievement> achievements;
  final Map<String, UnlockedAchievement> unlocked;

  /// Na Jornada: o próximo desafio do degrau.
  final Challenge? next;

  /// No speedrun e na Maratona: os tempos.
  final ConclusionRun? run;

  /// Às cegas: quantos lances o jogador fez sem ver o tabuleiro.
  final int? blindMoves;

  /// A posição final (o fundo do cabeçalho e a imagem de compartilhar).
  final String? finalFen;

  /// A variação do rating; nula quando a partida não contou.
  int? get ratingDelta => before == null || after == null
      ? null
      : after!.rating.round() - before!.rating.round();
}

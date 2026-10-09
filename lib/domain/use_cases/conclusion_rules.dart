import 'package:dartchess/dartchess.dart' show Side;

import '../models/attempt.dart';
import '../models/conclusion.dart';

/// Monta a tela de conclusão de cada contexto (T51, B3): qual é a variante e
/// quais botões ela tem, na ordem (o primeiro é o principal).
abstract final class ConclusionRules {
  /// A variante pela partida: speedrun ou Maratona (pela etapa e se ela foi
  /// vencida ou era a última), desafio da Jornada, às cegas ou avulsa.
  static ConclusionKind kindOf({
    required bool blind,
    String? challengeId,
    bool speedrun = false,
    bool marathon = false,
    bool lost = false,
    bool finished = false,
  }) {
    if (marathon) {
      if (lost) return ConclusionKind.marathonLost;
      if (finished) return ConclusionKind.marathonEnd;
      return ConclusionKind.speedrunStage;
    }
    if (speedrun) {
      if (lost) return ConclusionKind.speedrunLost;
      if (finished) return ConclusionKind.speedrunEnd;
      return ConclusionKind.speedrunStage;
    }
    if (blind) return ConclusionKind.blind;
    if (challengeId != null) return ConclusionKind.journey;
    return ConclusionKind.game;
  }

  /// Quantos dos [plies] lances foram do jogador (às cegas: "N lances sem
  /// ver o tabuleiro"), pela vez na posição de início.
  static int userMoves({
    required int plies,
    required Side userSide,
    String? startFen,
  }) {
    final first = startFen?.split(' ').elementAtOrNull(1) == 'b'
        ? Side.black
        : Side.white;
    return first == userSide ? (plies + 1) ~/ 2 : plies ~/ 2;
  }

  /// O resultado do ponto de vista do jogador.
  static ConclusionResult resultOf(AttemptOutcome outcome) => switch (outcome) {
    AttemptOutcome.win => ConclusionResult.won,
    AttemptOutcome.loss => ConclusionResult.lost,
    AttemptOutcome.draw => ConclusionResult.draw,
  };

  /// Os botões da variante [kind]. [recorded]: a partida foi gravada (dá
  /// para analisar e achar no histórico); [rated]: ela contou no rating;
  /// [hasNext]: há próximo desafio no degrau.
  static List<ConclusionAction> actionsFor(
    ConclusionKind kind, {
    required bool recorded,
    bool rated = false,
    bool hasNext = false,
  }) {
    final main = switch (kind) {
      ConclusionKind.game || ConclusionKind.blind => [
        ConclusionAction.playAgain,
        ConclusionAction.newGame,
      ],
      ConclusionKind.journey => [
        if (hasNext) ConclusionAction.nextChallenge,
        ConclusionAction.playAgain,
      ],
      ConclusionKind.speedrunStage => [ConclusionAction.nextStage],
      ConclusionKind.speedrunLost || ConclusionKind.marathonLost => [
        ConclusionAction.retry,
        ConclusionAction.summary,
      ],
      // O speedrun inteiro concluído: só a volta para a lista, para
      // escolher o próximo (sem "Tentar de novo").
      ConclusionKind.speedrunEnd => [ConclusionAction.speedruns],
      ConclusionKind.marathonEnd => [
        ConclusionAction.retry,
        ConclusionAction.speedruns,
      ],
    };
    return [
      ...main,
      if (recorded) ConclusionAction.analyze,
      // O histórico (rating e partidas, na mesma tela): pelo rating, quando
      // a partida contou; senão, pelas partidas.
      if (rated)
        ConclusionAction.ratingHistory
      else if (recorded)
        ConclusionAction.gamesHistory,
    ];
  }

  /// Até quantos lances (das duas cores) a partida é curta.
  static const shortPlies = 12;

  /// Abaixo deste tempo de jogo a partida é curta...
  static const shortPlayTime = Duration(seconds: 30);

  /// ...desde que não passe deste tanto de lances (uma partida de bala
  /// relâmpago com 80 lances levaria minutos para analisar).
  static const shortTimeMaxPlies = 30;

  /// A partida foi curta: a análise rápida (cerca de 1,5 s por posição) sai
  /// em poucos segundos, então a conclusão a faz sozinha. Curta é ter até
  /// [shortPlies] lances, ou menos de [shortPlayTime] de jogo (do começo ao
  /// fim; sem a hora do começo, o relógio do jogador) com até
  /// [shortTimeMaxPlies] lances. Sem lances, não há o que analisar.
  static bool isShortGame(Attempt game) {
    final plies = game.moves.length;
    if (plies == 0) return false;
    if (plies <= shortPlies) return true;
    final started = game.startedAt;
    final played = started == null
        ? game.userClock
        : game.playedAt.difference(started);
    return played != null &&
        played < shortPlayTime &&
        plies <= shortTimeMaxPlies;
  }
}

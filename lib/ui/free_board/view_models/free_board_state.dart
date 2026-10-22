import 'package:dartchess/dartchess.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../domain/models/attempt.dart';
import '../../../domain/models/challenge_link.dart';
import '../../../domain/models/challenge_result.dart';
import '../../../domain/models/game_setup.dart';
import '../../../domain/models/clock.dart';
import '../../../domain/models/endgame_position.dart';
import '../../../domain/models/game_end.dart';
import '../../../domain/models/game_mode.dart';
import '../../../domain/use_cases/draw_rules.dart';
import '../../../domain/use_cases/game_rules.dart';
import 'game_reporter.dart';

part 'free_board_state.freezed.dart';

/// A proposta de empate do jogador.
enum DrawOffer {
  none,

  /// A máquina está pensando na resposta.
  pending,
  accepted,
  declined,
}

@freezed
abstract class FreeBoardState with _$FreeBoardState {
  const factory FreeBoardState({
    /// A posição em que o tabuleiro abriu; "nova partida" volta para ela.
    required Position start,

    /// A posição atual.
    required Position position,

    /// Falso enquanto a partida em andamento ainda está sendo lida do aparelho.
    @Default(true) bool ready,

    /// Os lances jogados, em notação algébrica (`e4`, `Nf3`, `O-O`).
    @Default(<String>[]) List<String> moves,

    /// Os mesmos lances em UCI (`e2e4`, `g1f3`), como são gravados.
    @Default(<String>[]) List<String> ucis,

    /// Quanto cada lance levou, na ordem de [ucis].
    @Default(<Duration>[]) List<Duration> moveTimes,

    /// O tempo já gasto no lance da vez antes de [turnStartedAt] e o instante
    /// em que a vez (re)começou. Com o instante nulo, o tempo está parado (a
    /// partida terminou ou o jogador saiu da tela).
    @Default(Duration.zero) Duration turnElapsed,
    DateTime? turnStartedAt,

    /// Quantas vezes a posição atual já apareceu nesta partida.
    @Default(1) int repetitions,

    /// O último lance, para o tabuleiro destacar.
    Move? lastMove,

    /// O lado que aparece embaixo no tabuleiro.
    @Default(Side.white) Side orientation,

    /// O lado que o jogador move. Nulo: ele move os dois.
    Side? playerSide,

    /// O relógio da partida. Nulo: partida sem relógio.
    ClockState? clock,

    /// Quanto falta para cada lado, já arredondado como aparece na tela. Só
    /// valem com [clock].
    @Default(Duration.zero) Duration whiteTime,
    @Default(Duration.zero) Duration blackTime,

    /// O fim que não vem do tabuleiro: bandeira ou desistência.
    GameEnd? forcedEnd,

    /// Contra quem, de que lado e, num treino, com que objetivo.
    @Default(GameMode()) GameMode mode,

    /// A máquina está escolhendo o lance.
    @Default(false) bool machineThinking,

    /// O relógio e a máquina esperam o aviso da etapa nova da Maratona sair
    /// da tela.
    @Default(false) bool held,

    /// Quando a partida começou (ou recomeçou).
    DateTime? startedAt,

    /// A última proposta de empate e em que lance (quantos lances já tinham
    /// sido jogados) ela foi recusada.
    @Default(DrawOffer.none) DrawOffer drawOffer,
    int? drawDeclinedAt,

    /// O que a partida terminada mudou (rating, recordes, conquistas). Nulo
    /// enquanto ela continua ou até a conta terminar.
    GameReport? report,

    /// O rating atual do jogador, na linha de detalhe da faixa dele. Nulo até
    /// ser lido ou sem quem o conte.
    int? userRating,

    /// O lance que o jogador está revendo: quantos lances estão no tabuleiro
    /// (0 é a posição de início). Nulo: a posição atual da partida.
    int? viewedPly,

    /// A posição depois de [viewedPly] lances e o último deles. Só valem com
    /// ele.
    Position? viewedPosition,
    Move? viewedMove,
  }) = _FreeBoardState;

  const FreeBoardState._();

  /// Como a partida terminou. Nulo enquanto ela continua.
  GameEnd? get end =>
      forcedEnd ??
      GameRules.endOf(
        position,
        // Contra a máquina, repetição e 50 lances empatam sozinhos; no
        // tabuleiro livre o jogador move os dois lados à vontade.
        repetitions: mode.opponent.isMachine ? repetitions : null,
      );

  /// Como a partida terminou para o jogador. Nulo enquanto ela continua ou
  /// fora do treino.
  AttemptOutcome? get outcome {
    final end = this.end;
    final user = mode.userSide;
    if (end == null || user == null) return null;
    final winner = end.winner;
    if (winner == null) return AttemptOutcome.draw;
    return winner == user ? AttemptOutcome.win : AttemptOutcome.loss;
  }

  /// O desafio de link refeito desta partida: a posição de início, o lado, o
  /// adversário e o relógio do jogador. Nulo fora de partida de link.
  ChallengeLink? get challengeLink {
    final user = mode.userSide;
    if (!mode.fromLink || user == null || !mode.opponent.isMachine) return null;
    final origin = mode.link;
    if (origin != null) return origin;
    return ChallengeLink(
      fen: start.fen,
      goal: mode.goal ?? PositionGoal.win,
      positionId: mode.positionId,
      userSide: user,
      opponent: mode.opponent == OpponentKind.stockfish
          ? OpponentKind.stockfish
          : OpponentKind.maia,
      level: mode.level,
      clock: clock?.config.of(user),
    );
  }

  /// Como o desafio de link terminou, pronto para compartilhar. Nulo
  /// enquanto a partida continua ou fora de partida de link.
  ChallengeResult? get challengeResult {
    final link = challengeLink;
    final outcome = this.outcome;
    final end = this.end;
    if (link == null || outcome == null || end == null) return null;
    final user = link.userSide;
    final mated =
        end.reason == GameEndReason.checkmate && outcome == AttemptOutcome.win;
    final target = lastMove is NormalMove ? (lastMove! as NormalMove).to : null;
    return ChallengeResult(
      link: link,
      outcome: outcome,
      moves: ChallengeResult.movesOf(
        plies: ucis.length,
        userFirst: start.turn == user,
      ),
      remaining: clock == null
          ? null
          : (user == Side.white ? whiteTime : blackTime),
      matingPiece: mated && target != null
          ? position.board.roleAt(target)
          : null,
      finalFen: position.fen,
      lastMove: lastMove,
    );
  }

  /// O objetivo do treino foi cumprido. Nulo enquanto a partida continua ou
  /// fora do treino.
  bool? get fulfilled {
    final outcome = this.outcome;
    final goal = mode.goal;
    if (outcome == null || goal == null) return null;
    return switch (goal) {
      PositionGoal.win => outcome == AttemptOutcome.win,
      PositionGoal.draw => outcome != AttemptOutcome.loss,
    };
  }

  /// O jogador pode propor empate agora: partida contra a máquina, sem
  /// resposta pendente e com uns lances desde a última recusa.
  bool get canOfferDraw {
    if (end != null || !mode.opponent.isMachine || mode.userSide == null) {
      return false;
    }
    if (drawOffer == DrawOffer.pending) return false;
    final declinedAt = drawDeclinedAt;
    return declinedAt == null ||
        ucis.length - declinedAt >= DrawRules.cooldownPlies;
  }

  /// O jogador está revendo um lance anterior: o tabuleiro só mostra, sem
  /// aceitar lances.
  bool get browsing => viewedPly != null;

  /// Quantos lances estão no tabuleiro: os do lance revisto ou todos.
  int get shownPly => viewedPly ?? ucis.length;

  /// A posição que o tabuleiro mostra e o lance em destaque nela.
  Position get shownPosition => viewedPosition ?? position;
  Move? get shownMove => browsing ? viewedMove : lastMove;

  /// Quanto falta para [side], como aparece na tela.
  Duration timeOf(Side side) => side == Side.white ? whiteTime : blackTime;
}

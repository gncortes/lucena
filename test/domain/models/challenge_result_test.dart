import 'package:dartchess/dartchess.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/attempt.dart';
import 'package:lucena/domain/models/challenge_link.dart';
import 'package:lucena/domain/models/challenge_result.dart';
import 'package:lucena/domain/models/game_mode.dart';
import 'package:lucena/domain/models/game_setup.dart';
import 'package:lucena/domain/models/clock.dart';
import 'package:lucena/domain/models/endgame_position.dart';
import 'package:lucena/domain/use_cases/game_rules.dart';
import 'package:lucena/ui/free_board/view_models/free_board_state.dart';

void main() {
  test('os lances do jogador saem dos meios-lances e de quem começa', () {
    expect(ChallengeResult.movesOf(plies: 17, userFirst: true), 9);
    expect(ChallengeResult.movesOf(plies: 18, userFirst: true), 9);
    expect(ChallengeResult.movesOf(plies: 18, userFirst: false), 9);
    expect(ChallengeResult.movesOf(plies: 0, userFirst: true), 0);
  });

  test('o relógio aparece como minutos:segundos', () {
    expect(ChallengeResult.clockText(const Duration(seconds: 292)), '4:52');
    expect(ChallengeResult.clockText(const Duration(seconds: 5)), '0:05');
  });

  group('a partida de link terminada', () {
    const matedFen = '7k/6Q1/6K1/8/8/8/8/8 b - - 0 1';
    FreeBoardState state({bool fromLink = true, ChallengeLink? link}) =>
        FreeBoardState(
          start: GameRules.fromFen('7k/8/6K1/8/8/8/8/5Q2 w - - 0 1')!,
          position: GameRules.fromFen(matedFen)!,
          ucis: List.filled(17, 'a1a2'),
          lastMove: const NormalMove(from: Square.f1, to: Square.g7),
          clock: ClockState(
            config: ClockConfig.same(
              const TimeControl(initial: Duration(minutes: 5)),
            ),
            white: const Duration(seconds: 292),
            black: const Duration(seconds: 100),
          ),
          whiteTime: const Duration(seconds: 292),
          mode: GameMode(
            opponent: OpponentKind.maia,
            level: 1400,
            userSide: Side.white,
            goal: PositionGoal.win,
            fromLink: fromLink,
            link: link,
          ),
        );

    test('conta o mate, a peça, os lances e o relógio de quem jogou', () {
      final result = state().challengeResult!;
      expect(result.outcome, AttemptOutcome.win);
      expect(result.matingPiece, Role.queen);
      expect(result.moves, 9);
      expect(result.remaining, const Duration(seconds: 292));
      expect(result.link.level, 1400);
      expect(result.link.clock?.code, '300+0');
      expect(result.link.userSide, Side.white);
    });

    test('o link do resultado é o do desafio aberto: mesmo código, trava e '
        'cego', () {
      final origin = ChallengeLink(
        fen: '7k/8/6K1/8/8/8/8/5Q2 w - - 0 1',
        userSide: Side.white,
        opponent: OpponentKind.maia,
        level: 1400,
        locked: true,
        blind: true,
      );
      final result = state(link: origin).challengeResult!;
      // Só ganha os lances da vitória, que não mudam o código.
      expect(result.link, origin.copyWith(senderMoves: 9));
      expect(result.link.code, origin.code);
      expect(result.link.locked, isTrue);
      expect(result.link.blind, isTrue);
      expect(result.link.uri.queryParameters['mv'], '9');
      expect(
        {...result.link.uri.queryParameters}..remove('mv'),
        origin.uri.queryParameters,
      );
    });

    test('compara a vitória de quem mandou com a de quem jogou', () {
      final origin = ChallengeLink(
        fen: '7k/8/6K1/8/8/8/8/5Q2 w - - 0 1',
        userSide: Side.white,
        senderMoves: 7,
      );
      expect(state(link: origin).challengeComparison, (sender: 7, you: 9));
      // Link antigo (sem o resultado de quem mandou): nada a comparar.
      expect(
        state(link: origin.copyWith(senderMoves: null)).challengeComparison,
        isNull,
      );
    });

    test('o lance final vai para a imagem', () {
      expect(
        state().challengeResult!.lastMove,
        const NormalMove(from: Square.f1, to: Square.g7),
      );
    });

    test('fora de partida de link não há resultado para mandar', () {
      expect(state(fromLink: false).challengeResult, isNull);
    });
  });
}

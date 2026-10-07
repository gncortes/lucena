import 'package:dartchess/dartchess.dart' show Side;

import '../models/attempt.dart';
import '../models/clock.dart';
import '../models/speedrun.dart';

/// A Maratona: o mesmo final do 1000 ao Stockfish, com um banco de tempo só
/// para o jogador. Cada etapa começa com o que sobrou da anterior (os
/// acréscimos entram no banco); o adversário recebe o tempo cheio do ritmo em
/// cada etapa. Perder, empatar ou o banco acabar encerra a tentativa.
abstract final class Marathon {
  static const _prefix = 'marathon.';
  static const _endingPrefix = 'ending.';

  /// A Maratona do speedrun de final [ending]: as mesmas etapas.
  static Speedrun of(Speedrun ending) {
    final name = ending.id.startsWith(_endingPrefix)
        ? ending.id.substring(_endingPrefix.length)
        : ending.id;
    final id = '$_prefix$name';
    return ending.copyWith(
      id: id,
      kind: SpeedrunKind.marathon,
      stages: [
        for (final stage in ending.stages)
          stage.copyWith(id: '$id/${stage.id.split('/').last}'),
      ],
    );
  }

  /// O speedrun [speedrunId] (com ou sem ritmo) é uma Maratona.
  static bool isMarathon(String? speedrunId) =>
      speedrunId != null && speedrunId.startsWith(_prefix);

  /// Quanto do banco a partida [game] gastou: o que o relógio do jogador
  /// correu menos os acréscimos que ele ganhou. Pode ser negativo (ganhou
  /// mais acréscimo do que gastou).
  static Duration consumed(Attempt game) {
    final spent = game.userClock ?? Duration.zero;
    final increment = game.userTime?.increment ?? Duration.zero;
    if (increment == Duration.zero) return spent;
    final plies = game.moves.length;
    final first = game.startFen?.split(' ').elementAtOrNull(1) == 'b'
        ? Side.black
        : Side.white;
    final userFirst = (game.userSide ?? Side.white) == first;
    final userMoves = userFirst ? (plies + 1) ~/ 2 : plies ~/ 2;
    return spent - increment * userMoves;
  }

  /// O que sobra no banco depois de [run], no ritmo [pace]: o tempo do ritmo
  /// menos o que as partidas gastaram (o total da Maratona).
  static Duration bank(SpeedrunRun run, TimeControl pace) =>
      left(pace, run.total);

  /// O que sobra no banco do ritmo [pace] depois de as partidas gastarem
  /// [total].
  static Duration left(TimeControl pace, Duration total) {
    final left = pace.initial - total;
    return left.isNegative ? Duration.zero : left;
  }

  /// O relógio do jogador numa etapa: o [bank] com o acréscimo do ritmo.
  static TimeControl stageTime(TimeControl pace, Duration bank) =>
      TimeControl(initial: bank, increment: pace.increment);
}

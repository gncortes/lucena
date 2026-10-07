import '../models/clock.dart';
import '../models/rating_level.dart';

/// O ritmo com que o speedrun (e a Maratona) abre para quem ainda não
/// escolheu um: o que combina com o nível do jogador. O ritmo escolhido
/// sempre vence.
abstract final class DefaultPace {
  /// O ritmo inicial de cada nível: quem está começando tem mais tempo.
  static TimeControl forLevel(RatingLevel level) => switch (level) {
    RatingLevel.beginner => const TimeControl(
      initial: Duration(minutes: 15),
      increment: Duration(seconds: 10),
    ),
    RatingLevel.casual => const TimeControl(initial: Duration(minutes: 10)),
    RatingLevel.intermediate => const TimeControl(
      initial: Duration(minutes: 5),
      increment: Duration(seconds: 3),
    ),
    RatingLevel.advanced => const TimeControl(
      initial: Duration(minutes: 3),
      increment: Duration(seconds: 2),
    ),
    RatingLevel.expert => const TimeControl(initial: Duration(minutes: 3)),
    RatingLevel.master => const TimeControl(initial: Duration(minutes: 1)),
  };

  /// O ritmo a usar: o [saved] (a última escolha) ou, sem ele, o do nível.
  static TimeControl of({TimeControl? saved, required RatingLevel level}) =>
      saved ?? forLevel(level);
}

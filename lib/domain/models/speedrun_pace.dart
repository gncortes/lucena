import 'clock.dart';
import 'pace.dart';
import 'speedrun.dart';

/// Os ritmos do speedrun, como no chess.com, agrupados em ultra bullet,
/// bullet, blitz e rápido. Cada ritmo é um speedrun próprio, com recordes separados: o id do
/// speedrun leva o ritmo (`rung.1000@180+2`). O ritmo padrão (5+3) fica com o
/// id de antes, e os recordes antigos continuam valendo.
abstract final class SpeedrunPaces {
  static const standard = TimeControl(
    initial: Duration(minutes: 5),
    increment: Duration(seconds: 3),
  );

  static const all = [
    TimeControl(initial: Duration(seconds: 10)),
    TimeControl(initial: Duration(seconds: 15)),
    TimeControl(initial: Duration(seconds: 30)),
    TimeControl(initial: Duration(minutes: 1)),
    TimeControl(initial: Duration(minutes: 2), increment: Duration(seconds: 1)),
    TimeControl(initial: Duration(minutes: 3)),
    TimeControl(initial: Duration(minutes: 3), increment: Duration(seconds: 2)),
    standard,
    TimeControl(initial: Duration(minutes: 10)),
    TimeControl(
      initial: Duration(minutes: 15),
      increment: Duration(seconds: 10),
    ),
  ];

  /// Os ritmos de cada grupo, na ordem da tela.
  static Map<PaceCategory, List<TimeControl>> get groups => {
    for (final category in [
      PaceCategory.ultraBullet,
      PaceCategory.bullet,
      PaceCategory.blitz,
      PaceCategory.rapid,
    ])
      category: [
        for (final time in all)
          if (PaceCategory.of(time) == category) time,
      ],
  };

  static const _separator = '@';

  /// O id do speedrun [baseId] no ritmo [time].
  static String idFor(String baseId, TimeControl time) =>
      time == standard ? baseId : '$baseId$_separator${time.code}';

  /// O speedrun de base e o ritmo de um id. Ritmo desconhecido: o padrão.
  static (String baseId, TimeControl time) parse(String id) {
    final index = id.indexOf(_separator);
    if (index < 0) return (id, standard);
    final time = TimeControl.tryParse(id.substring(index + 1));
    return (id.substring(0, index), time ?? standard);
  }

  /// O speedrun [base] jogado no ritmo [time]: as mesmas etapas, com o
  /// relógio do ritmo.
  static Speedrun withTime(Speedrun base, TimeControl time) => base.copyWith(
    id: idFor(base.id, time),
    time: time,
    stages: [for (final stage in base.stages) stage.copyWith(time: time)],
  );

  /// O speedrun de um id (com ou sem ritmo), a partir dos de base. Nulo se o
  /// de base não existe.
  static Speedrun? resolve(List<Speedrun> bases, String? id) {
    if (id == null) return null;
    final (baseId, time) = parse(id);
    for (final base in bases) {
      if (base.id == baseId) return withTime(base, time);
    }
    return null;
  }
}

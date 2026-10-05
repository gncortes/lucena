import '../models/journey.dart';

/// Domínio da Jornada, calculado do histórico: um desafio está concluído
/// quando há uma partida dele com o objetivo cumprido; um degrau libera quando
/// o anterior foi todo concluído.
///
/// [startRung] é o degrau escolhido no tour: ele e os de baixo já começam
/// liberados, e a Jornada começa por ele.
abstract final class Mastery {
  static JourneyProgress of(
    List<Rung> ladder,
    Set<String> fulfilled, {
    String? startRung,
  }) {
    final start = ladder.indexWhere((rung) => rung.id == startRung);
    var previousDone = true;
    final rungs = <RungProgress>[];
    for (final (index, rung) in ladder.indexed) {
      if (index <= start) previousDone = true;
      final completed = {
        for (final challenge in rung.challenges)
          if (fulfilled.contains(challenge.id)) challenge.id,
      };
      final done = completed.length == rung.challenges.length;
      rungs.add(
        RungProgress(
          rung: rung,
          completed: completed,
          status: !previousDone
              ? RungStatus.locked
              : done
              ? RungStatus.completed
              : RungStatus.open,
        ),
      );
      // Degrau trancado não libera o seguinte, mesmo com partidas antigas.
      previousDone = previousDone && done;
    }
    return JourneyProgress(rungs: rungs, start: start < 0 ? 0 : start);
  }
}

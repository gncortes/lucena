import '../models/journey.dart';

/// Domínio da Jornada, calculado do histórico: um desafio está concluído
/// quando há uma partida dele com o objetivo cumprido; um degrau libera quando
/// o anterior foi todo concluído.
abstract final class Mastery {
  static JourneyProgress of(List<Rung> ladder, Set<String> fulfilled) {
    var previousDone = true;
    final rungs = <RungProgress>[];
    for (final rung in ladder) {
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
    return JourneyProgress(rungs: rungs);
  }
}

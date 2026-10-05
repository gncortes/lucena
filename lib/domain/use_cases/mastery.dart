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

  /// O desafio para jogar depois de [challengeId]: o próximo ainda não
  /// concluído do mesmo degrau (voltando ao começo dele) ou, com o degrau
  /// todo concluído, o primeiro por fazer do degrau seguinte, se ele já está
  /// liberado. Nulo fora da Jornada ou quando não há mais nada a fazer.
  static NextChallenge? nextChallenge(
    List<Rung> ladder,
    Set<String> fulfilled,
    String challengeId, {
    String? startRung,
  }) {
    final rungIndex = ladder.indexWhere(
      (rung) => rung.challenges.any((c) => c.id == challengeId),
    );
    if (rungIndex < 0) return null;
    final rung = ladder[rungIndex];
    final index = rung.challenges.indexWhere((c) => c.id == challengeId);
    final count = rung.challenges.length;
    for (var step = 1; step < count; step++) {
      final challenge = rung.challenges[(index + step) % count];
      if (!fulfilled.contains(challenge.id)) {
        return NextChallenge(rungId: rung.id, challenge: challenge);
      }
    }
    final progress = of(ladder, fulfilled, startRung: startRung);
    for (final next in progress.rungs.skip(rungIndex + 1)) {
      if (next.status == RungStatus.locked) return null;
      for (final challenge in next.rung.challenges) {
        if (!next.completed.contains(challenge.id)) {
          return NextChallenge(rungId: next.rung.id, challenge: challenge);
        }
      }
    }
    return null;
  }
}

/// Um desafio da Jornada e o degrau em que ele está.
class NextChallenge {
  const NextChallenge({required this.rungId, required this.challenge});

  final String rungId;
  final Challenge challenge;
}

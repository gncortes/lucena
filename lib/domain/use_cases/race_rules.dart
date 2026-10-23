import 'dart:math';

import 'package:dartchess/dartchess.dart';

import '../models/clock.dart';
import '../models/race.dart';
import 'clock_engine.dart';

/// As regras da Corrida de problemas: 3 minutos ou 3 erros. O tempo usa o
/// relógio da partida (`ClockEngine`), sempre pelo instante recebido de fora.
abstract final class RaceRules {
  static const limit = Duration(minutes: 3);
  static const maxErrors = 3;

  /// Quantos problemas tem o aquecimento.
  static const warmUpLength = 5;

  static final _config = ClockConfig.same(TimeControl(initial: limit));

  /// O relógio da Corrida: só corre o lado de quem joga, que nunca troca.
  static ClockState _clock(RaceRun run) =>
      ClockEngine.start(_config, turn: Side.white, now: run.startedAt);

  /// Quanto falta no instante [now]. Nunca menos que zero.
  static Duration remaining(RaceRun run, DateTime now) =>
      ClockEngine.remaining(_clock(run), Side.white, now);

  /// Como a Corrida acabou, ou nulo se ainda corre. Os erros valem primeiro:
  /// se as duas coisas aconteceram, o terceiro erro foi o que parou.
  static RaceEnd? endOf(RaceRun run, DateTime now) {
    if (run.errors >= maxErrors) return RaceEnd.errors;
    if (remaining(run, now) == Duration.zero) return RaceEnd.time;
    return null;
  }

  /// A faixa mais baixa e o passo entre faixas (300, 350, ..., 2600).
  static const firstBucket = 300;
  static const bucketStep = 50;

  /// Quantas Corridas recentes o sorteio evita repetir.
  static const recentRuns = 3;

  /// A faixa em que a Corrida está: sobe uma a cada acerto (como o Puzzle
  /// Rush); o erro não faz subir.
  static int bucketFor(RaceRun run) => firstBucket + bucketStep * run.corrects;

  /// O próximo problema: sorteado dentro da faixa da Corrida (sobe uma faixa a
  /// cada acerto), sem repetir os da Corrida e evitando os de [recent]. Com o
  /// filtro de final, a faixa sem problema daquele final pula para a próxima
  /// acima que tenha; passando da última faixa, fica nela. O sorteio sai só do
  /// instante de início e da posição na Corrida: retomar dá o mesmo problema.
  /// Nulo só se não há problema nenhum para o tema.
  static RaceProblem? next(
    List<RaceProblem> bank,
    RaceRun run, {
    Set<String> recent = const {},
  }) {
    final pool = [
      for (final problem in bank)
        if (run.theme == null || problem.theme == run.theme) problem,
    ];
    if (pool.isEmpty) return null;
    final seen = {for (final answer in run.answers) answer.problemId};
    final wanted = bucketFor(run);
    final top = pool.map((problem) => problem.bucket).reduce(max);
    final random = Random(
      run.startedAt.millisecondsSinceEpoch ^ (run.answers.length * 7919),
    );
    // Da faixa pedida para cima. Na faixa, o que não saiu nem é recente; se só
    // sobrou recente, usa um dele (a régua não pula faixa por isso).
    for (var bucket = min(wanted, top); bucket <= top; bucket += bucketStep) {
      final inBucket = [
        for (final problem in pool)
          if (problem.bucket == bucket && !seen.contains(problem.id)) problem,
      ];
      if (inBucket.isEmpty) continue;
      final fresh = [
        for (final problem in inBucket)
          if (!recent.contains(problem.id)) problem,
      ];
      final from = fresh.isNotEmpty ? fresh : inBucket;
      return from[random.nextInt(from.length)];
    }
    // Acabou tudo do tema: dá a volta no banco.
    return pool[random.nextInt(pool.length)];
  }

  /// Os ids dos problemas das últimas [recentRuns] Corridas de [history].
  static Set<String> recentIds(List<RaceResult> history) => {
    for (final result in history.take(recentRuns))
      for (final answer in result.run.answers) answer.problemId,
  };

  /// O fim de [run] e o que ele muda no [record].
  static RaceOutcome finish(
    RaceRun run,
    RaceEnd end,
    RaceRecord record,
    DateTime now,
  ) {
    final isRecord = run.corrects > record.corrects;
    return RaceOutcome(
      result: RaceResult(run: run, end: end, finishedAt: now),
      previous: record,
      isRecord: isRecord,
    );
  }

  /// O recorde depois de [run]: mais acertos, e o problema mais difícil
  /// resolvido em qualquer Corrida.
  static RaceRecord merge(RaceRecord record, RaceRun run) => RaceRecord(
    corrects: run.corrects > record.corrects ? run.corrects : record.corrects,
    hardest: run.hardestSolved > record.hardest
        ? run.hardestSolved
        : record.hardest,
  );

  /// Os problemas do aquecimento: [warmUpLength] do mesmo final do desafio
  /// ([theme]), do mais fácil ao mais difícil. Faltando no banco, completa no
  /// fim com os mais fáceis dos outros temas (também do mais fácil ao mais
  /// difícil), sem reordenar o conjunto.
  static List<RaceProblem> warmUp(List<RaceProblem> bank, {RaceTheme? theme}) {
    int byLevel(RaceProblem a, RaceProblem b) => a.level.compareTo(b.level);
    final same = [...bank.where((problem) => problem.theme == theme)]
      ..sort(byLevel);
    final others = [...bank.where((problem) => problem.theme != theme)]
      ..sort(byLevel);
    // Os do mesmo final primeiro; os de fora só completam, no fim.
    return [...same, ...others].take(warmUpLength).toList();
  }
}

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

  /// O limite de [duration].
  static Duration limitOf(RaceDuration duration) => duration.limit;

  /// O relógio da Corrida: só corre o lado de quem joga, que nunca troca.
  static ClockState _clock(RaceRun run) => ClockEngine.start(
    ClockConfig.same(TimeControl(initial: run.duration.limit)),
    turn: Side.white,
    now: run.startedAt,
  );

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

  /// A primeira faixa, onde toda Corrida começa.
  static const firstBucket = 300;

  /// Até [slowFrom] cada acerto sobe [bigStep] pontos; dali em diante, [step].
  /// As faixas do banco seguem o mesmo passo (50 até 1500, 25 depois).
  static const slowFrom = 1500;
  static const bigStep = 50;
  static const smallStep = 25;

  /// Quantas Corridas recentes o sorteio evita repetir.
  static const recentRuns = 3;

  /// O rating-alvo depois de [corrects] acertos (sobe como o Puzzle Rush, sem
  /// o erro fazer subir): +50 por acerto até 1500, +25 depois.
  static int targetRating(int corrects) {
    final bigSteps = (slowFrom - firstBucket) ~/ bigStep;
    return corrects <= bigSteps
        ? firstBucket + bigStep * corrects
        : slowFrom + smallStep * (corrects - bigSteps);
  }

  /// A faixa do banco (o piso do alvo) em que a Corrida está.
  static int bucketFor(RaceRun run) => targetRating(run.corrects);

  /// Quantos acertos levam a [bucket] (o inverso de [targetRating]).
  static int correctsToReach(int bucket) => bucket <= slowFrom
      ? (bucket - firstBucket) ~/ bigStep
      : (slowFrom - firstBucket) ~/ bigStep + (bucket - slowFrom) ~/ smallStep;

  /// O próximo problema: sorteado dentro da faixa da Corrida (sobe uma faixa a
  /// cada acerto), sem repetir os da Corrida e evitando os de [recent]. Com o
  /// filtro de final, a faixa sem problema daquele final pula para a próxima
  /// acima que tenha; passando da última faixa, fica nela e, esgotada, desce à
  /// mais alta com problema novo (só então repete). O sorteio sai só do
  /// instante de início e da posição na Corrida: retomar dá o mesmo problema.
  /// Nulo só se não há problema nenhum para o filtro.
  static RaceProblem? next(
    List<RaceProblem> bank,
    RaceRun run, {
    Set<String> recent = const {},
  }) {
    final pool = [
      for (final problem in bank)
        if (run.filter.matches(problem)) problem,
    ];
    if (pool.isEmpty) return null;
    final seen = {for (final answer in run.answers) answer.problemId};
    final wanted = bucketFor(run);
    final buckets = ({for (final problem in pool) problem.bucket}.toList())
      ..sort();
    final random = Random(
      run.startedAt.millisecondsSinceEpoch ^ (run.answers.length * 7919),
    );
    RaceProblem? pick(int bucket) {
      final inBucket = [
        for (final problem in pool)
          if (problem.bucket == bucket && !seen.contains(problem.id)) problem,
      ];
      if (inBucket.isEmpty) return null;
      final fresh = [
        for (final problem in inBucket)
          if (!recent.contains(problem.id)) problem,
      ];
      final from = fresh.isNotEmpty ? fresh : inBucket;
      return from[random.nextInt(from.length)];
    }

    // Da faixa pedida para cima, pelas faixas que o banco tem (com o filtro,
    // a faixa sem problema pula para a próxima). Na faixa, o que não saiu nem
    // é recente; se só sobrou recente, usa um deles (a régua não pula faixa
    // por isso). Passando da última faixa, fica nela.
    var start = buckets.indexWhere((bucket) => bucket >= wanted);
    if (start < 0) start = buckets.length - 1;
    for (var i = start; i < buckets.length; i++) {
      final found = pick(buckets[i]);
      if (found != null) return found;
    }
    // Nada novo daí para cima: as faixas de baixo, da mais alta para a mais
    // baixa, que ainda tenham problema que não saiu.
    for (var i = start - 1; i >= 0; i--) {
      final found = pick(buckets[i]);
      if (found != null) return found;
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

  /// Quantos problemas do filtro [filter] o banco tem.
  static int count(List<RaceProblem> bank, RaceFilter filter) =>
      bank.where(filter.matches).length;

  /// As categorias do catálogo de Finais, na ordem dele.
  static const categories = [
    'basic',
    'pawn',
    'bishop',
    'knight',
    'knightBishop',
    'rookPawn',
    'rookPieces',
    'queen',
  ];

  /// Os tipos de final que o banco tem para [goal], por categoria (na ordem
  /// de [categories]; categoria sem tipo fica de fora). Na categoria, do
  /// final com menos peças ao com mais, e pela chave no empate. Assim o
  /// filtro só mostra o que tem problema.
  static Map<String, List<RaceEndgameType>> types(
    List<RaceProblem> bank,
    RaceGoal goal,
  ) {
    final found = <String, RaceEndgameType>{};
    for (final problem in bank) {
      if (!goal.accepts(problem)) continue;
      found.putIfAbsent(problem.subcategory, () => RaceEndgameType.of(problem));
    }
    return {
      for (final category in categories)
        if (found.values.any((type) => type.category == category))
          category: [...found.values.where((type) => type.category == category)]
            ..sort(
              (a, b) => a.size != b.size
                  ? a.size.compareTo(b.size)
                  : a.subcategory.compareTo(b.subcategory),
            ),
    };
  }

  /// Os problemas do aquecimento (de ganhar): [warmUpLength] do mesmo tipo
  /// de final do desafio ([subcategory]), do mais fácil ao mais difícil.
  /// Faltando, completa com os da mesma categoria ([category]) e depois com
  /// os dos outros finais, cada grupo do mais fácil ao mais difícil, sem
  /// reordenar o conjunto.
  static List<RaceProblem> warmUp(
    List<RaceProblem> bank, {
    String? subcategory,
    String? category,
  }) {
    int byLevel(RaceProblem a, RaceProblem b) => a.level.compareTo(b.level);
    final wins = bank.where((problem) => !problem.defend);
    final same = [...wins.where((p) => p.subcategory == subcategory)]
      ..sort(byLevel);
    final near = [
      ...wins.where(
        (p) => p.subcategory != subcategory && p.category == category,
      ),
    ]..sort(byLevel);
    final others = [
      ...wins.where(
        (p) => p.subcategory != subcategory && p.category != category,
      ),
    ]..sort(byLevel);
    // Os do mesmo final primeiro; os de fora só completam, no fim.
    return [...same, ...near, ...others].take(warmUpLength).toList();
  }
}

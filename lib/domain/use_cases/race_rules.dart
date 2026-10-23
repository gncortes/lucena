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

  /// Se [move] (UCI) é o lance do problema.
  static bool isSolution(RaceProblem problem, String move) =>
      move == problem.solution;

  /// A resposta ao problema com o lance [move].
  static RaceAnswer answer(RaceProblem problem, String move) => RaceAnswer(
    problemId: problem.id,
    level: problem.level,
    move: move,
    correct: isSolution(problem, move),
  );

  /// O próximo problema: o mais fácil que ainda não saiu, subindo de nível a
  /// cada acerto. Acabando os do tema, recomeça do mais fácil. Nulo só se
  /// não há problema nenhum para o tema.
  static RaceProblem? next(List<RaceProblem> bank, RaceRun run) {
    final pool = [
      for (final problem in bank)
        if (run.theme == null || problem.theme == run.theme) problem,
    ]..sort((a, b) => a.level.compareTo(b.level));
    if (pool.isEmpty) return null;
    final seen = {for (final answer in run.answers) answer.problemId};
    // Dá a volta no banco quando todos já saíram.
    final fresh = pool.where((problem) => !seen.contains(problem.id));
    if (fresh.isNotEmpty) return fresh.first;
    return pool[run.answers.length % pool.length];
  }

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

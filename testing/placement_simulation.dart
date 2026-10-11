// A simulação do teste de nível (T52, Parte 4.5): jogadores simulados fazem o
// teste no motor de verdade e as métricas saem comparadas com as metas. Usada
// pelo `simulate.dart` (relatório) e pelo teste de CI
// `test/domain/placement_simulation_test.dart`.
import 'dart:math';

import 'package:lucena/domain/models/placement.dart';
import 'package:lucena/domain/models/rating_level.dart';
import 'package:lucena/domain/use_cases/placement_engine.dart';
import 'package:lucena/domain/use_cases/placement_roadmap.dart';

/// Os tipos de jogador simulado.
enum SimKind {
  rasch,
  careless,
  gapBishop,
  gapReti,
  gapRook,
  allRight,
  allWrong,
}

/// Um jogador simulado: responde pela logística da diferença entre o θ
/// verdadeiro e a dificuldade (com chute nas `choice`), com nós forçados a
/// errar ou a acertar e, no desatento, 10% de erros nas perguntas fáceis.
class SimPlayer {
  const SimPlayer({
    required this.kind,
    required this.theta,
    this.forcedWrong = const {},
    this.forcedRight = const {},
    this.careless = 0,
  });

  final SimKind kind;
  final double theta;
  final Set<String> forcedWrong;
  final Set<String> forcedRight;

  /// Chance de errar por desatenção uma pergunta fácil (d < θ − 300).
  final double careless;

  bool answer(PlacementItem item, Random random) {
    if (kind == SimKind.allRight) return true;
    if (kind == SimKind.allWrong) return false;
    if (forcedWrong.contains(item.node)) return false;
    if (forcedRight.contains(item.node)) return true;
    if (careless > 0 &&
        item.difficulty < theta - 300 &&
        random.nextDouble() < careless) {
      return false;
    }
    final p = PlacementEngine.probability(
      theta,
      item.difficulty,
      options: item.optionCount,
    );
    return random.nextDouble() < p;
  }

  /// Se o jogador "sabe" o nó. Fora as lacunas forçadas, pela faixa: a
  /// faixa do nó é "a faixa em que se espera o domínio" (Parte 2), então quem
  /// está abaixo dela não sabe. Com [median], o critério severo: o θ
  /// verdadeiro passa da dificuldade mediana das perguntas do nó.
  bool knows(SkillNode node, {int? median}) {
    if (kind == SimKind.allRight) return true;
    if (kind == SimKind.allWrong) return false;
    if (forcedWrong.contains(node.id)) return false;
    if (forcedRight.contains(node.id)) return true;
    if (median != null) return theta >= median;
    return RatingLevel.of(theta.round()).index >= node.band.index;
  }
}

/// Um teste simulado.
class SimRun {
  const SimRun(this.player, this.result, this.roadmap, this.items);

  final SimPlayer player;
  final PlacementResult result;
  final PlacementRoadmap roadmap;
  final List<String> items;
}

/// Faz o teste inteiro com [player].
SimRun runTest(
  PlacementEngine engine,
  SimPlayer player, {
  required int seed,
  required Random random,
  required List<String> schoolLessons,
  required List<String> endgameLessons,
}) {
  var state = engine.start(seed: seed);
  final items = <String>[];
  while (!state.isFinished) {
    final item = engine.next(state);
    if (item == null) break;
    items.add(item.id);
    state = engine.answer(
      state,
      item,
      player.answer(item, random)
          ? PlacementOutcome.correct
          : PlacementOutcome.wrong,
      elapsed: const Duration(seconds: 20),
    );
  }
  final result = engine.result(state, takenAt: DateTime.utc(2026, 10, 8));
  return SimRun(
    player,
    result,
    PlacementRoadmap.build(
      result: result,
      skills: engine.skills,
      schoolLessons: schoolLessons,
      endgameLessons: endgameLessons,
    ),
    items,
  );
}

/// As métricas de um grupo de testes da mesma faixa de jogador.
class BandStats {
  int n = 0;
  int exact = 0;
  int neighbor = 0;
  int covered = 0;
  double squaredError = 0;
  double bias = 0;
  double width = 0;

  void add(SimRun run) {
    final truth = RatingLevel.of(run.player.theta.round()).index;
    final found = RatingLevel.of(run.result.theta).index;
    n++;
    if (truth == found) exact++;
    if ((truth - found).abs() <= 1) neighbor++;
    if (run.result.low <= run.player.theta &&
        run.player.theta <= run.result.high) {
      covered++;
    }
    final error = run.result.theta - run.player.theta;
    squaredError += error * error;
    bias += error;
    width += run.result.high - run.result.low;
  }

  double get exactRate => n == 0 ? 0 : exact / n;
  double get neighborRate => n == 0 ? 0 : neighbor / n;
  double get coverage => n == 0 ? 0 : covered / n;
  double get rmse => n == 0 ? 0 : sqrt(squaredError / n);
  double get meanBias => n == 0 ? 0 : bias / n;
  double get meanWidth => n == 0 ? 0 : width / n;
}

/// O relatório de uma rodada de simulação.
class SimReport {
  SimReport(this.tuning);

  final PlacementTuning tuning;
  final rasch = BandStats();
  final careless = BandStats();

  /// Testes em que a lacuna forçada aparece no roteiro (algum nó forçado de
  /// faixa ≤ faixa verdadeira não foi dispensado), por cenário.
  final gapHits = <SimKind, int>{};
  final gapTotals = <SimKind, int>{};

  /// Por nó forçado (em vez de por teste): no roteiro e achado como `gap`
  /// confirmado.
  final gapNodes = <SimKind, int>{};
  final gapNodeHits = <SimKind, int>{};
  final gapConfirmed = <SimKind, int>{};

  /// Testes com lacuna forçada num nó de faixa ≤ faixa(θ) − 2 e, deles, os
  /// em que alguma dessas aparece no roteiro.
  final deepTotals = <SimKind, int>{};
  final deepHits = <SimKind, int>{};

  /// Nós dispensados (domina ou provável) e, deles, os que o jogador não
  /// sabia.
  int skipped = 0;
  int falseSkipped = 0;

  /// Os falsos "já domina" por tipo de jogador e por origem (confirmado ou
  /// inferido).
  final falseByKind = <SimKind, int>{};
  final skippedByKind = <SimKind, int>{};
  int falseConfirmed = 0;

  /// Idem, sem a margem de 100 pontos (mais severo).
  int falseSkippedStrict = 0;

  RatingLevel? allRight;
  RatingLevel? allWrong;

  /// Fração de perguntas diferentes entre dois testes da mesma pessoa.
  double exposureSum = 0;
  int exposureN = 0;

  /// O quanto θ andou na primeira resposta e nas da confirmação.
  double firstJump = 0;
  int firstJumpN = 0;
  double confirmationMove = 0;
  int confirmationMoveN = 0;

  /// Pares (θ verdadeiro, θ estimado) dos jogadores Rasch, para o gráfico.
  final points = <(double, int)>[];

  double get gapRate {
    final total = gapTotals.values.fold(0, (a, b) => a + b);
    final hits = gapHits.values.fold(0, (a, b) => a + b);
    return total == 0 ? 0 : hits / total;
  }

  double get falseSkipRate => skipped == 0 ? 0 : falseSkipped / skipped;
  double get falseSkipStrictRate =>
      skipped == 0 ? 0 : falseSkippedStrict / skipped;
  double get exposure => exposureN == 0 ? 0 : exposureSum / exposureN;
  double get meanFirstJump => firstJumpN == 0 ? 0 : firstJump / firstJumpN;
  double get meanConfirmationMove =>
      confirmationMoveN == 0 ? 0 : confirmationMove / confirmationMoveN;

  /// Se todas as metas da 4.5 foram atingidas.
  bool get passes =>
      rasch.neighborRate >= 0.9 &&
      rasch.exactRate >= 0.6 &&
      careless.neighborRate >= 0.9 &&
      gapRate >= 0.9 &&
      falseSkipRate <= 0.05 &&
      (allRight?.index ?? 0) >= RatingLevel.expert.index &&
      allWrong == RatingLevel.beginner &&
      exposure >= 0.4;
}

/// Os nós forçados de cada cenário de lacuna e a faixa de θ verdadeiro em que
/// o cenário faz sentido, como na T52: quem não sabe o bispo é iniciante; quem
/// sabe a oposição e não Réti é um jogador de finais médio.
const gapScenarios = {
  SimKind.gapBishop: (
    wrong: {'rules.bishop'},
    right: <String>{},
    low: 400,
    high: 999,
  ),
  SimKind.gapReti: (
    wrong: {'pawns.reti'},
    right: {'pawns.opposition'},
    low: 1500,
    high: 2200,
  ),
  SimKind.gapRook: (
    wrong: {
      'rook.vsPawn',
      'rook.lucena',
      'rook.philidor',
      'rook.cutOff',
      'rook.backRank',
      'rook.shortSide',
      'rook.behindPasser',
      'rook.rookPawn',
    },
    right: {'tactics.basic', 'tactics.endgame', 'mate.patterns', 'mate.inOne'},
    low: 1600,
    high: 2400,
  ),
};

/// Roda [count] jogadores de cada tipo e junta as métricas.
SimReport simulate({
  required SkillMap skills,
  required PlacementBank bank,
  required List<String> schoolLessons,
  required List<String> endgameLessons,
  PlacementTuning tuning = PlacementTuning.standard,
  int count = 1000,
  int seed = 2026,
}) {
  final engine = PlacementEngine(skills: skills, bank: bank, tuning: tuning);
  final random = Random(seed);
  final report = SimReport(tuning);
  final medians = _medians(skills, bank);
  var testSeed = seed * 1000;

  SimRun run(SimPlayer player) => runTest(
    engine,
    player,
    seed: testSeed++,
    random: random,
    schoolLessons: schoolLessons,
    endgameLessons: endgameLessons,
  );

  void countSkips(SimRun run) {
    for (final entry in run.result.nodes.entries) {
      if (!entry.value.skippable) continue;
      report.skipped++;
      final kind = run.player.kind;
      report.skippedByKind.update(kind, (n) => n + 1, ifAbsent: () => 1);
      final node = skills.node(entry.key)!;
      if (!run.player.knows(node)) {
        report.falseSkipped++;
        report.falseByKind.update(kind, (n) => n + 1, ifAbsent: () => 1);
        if (entry.value.confirmed) report.falseConfirmed++;
      }
      if (!run.player.knows(node, median: medians[entry.key]!)) {
        report.falseSkippedStrict++;
      }
    }
  }

  double uniform(int low, int high) => low + random.nextDouble() * (high - low);

  for (var i = 0; i < count; i++) {
    // Rasch puro.
    final player = SimPlayer(kind: SimKind.rasch, theta: uniform(400, 2600));
    final first = run(player);
    report.rasch.add(first);
    report.points.add((player.theta, first.result.theta));
    countSkips(first);
    final answers = first.result.answers;
    if (answers.isNotEmpty) {
      report.firstJump += (answers.first.thetaAfter! - 1200).abs();
      report.firstJumpN++;
      for (var q = 16; q < answers.length; q++) {
        report.confirmationMove +=
            (answers[q].thetaAfter! - answers[q - 1].thetaAfter!).abs();
        report.confirmationMoveN++;
      }
    }
    // A mesma pessoa refaz o teste (outra semente).
    final second = run(player);
    final same = first.items.toSet().intersection(second.items.toSet()).length;
    report.exposureSum += 1 - same / PlacementState.questionCount;
    report.exposureN++;

    // Desatento.
    final careless = run(
      SimPlayer(
        kind: SimKind.careless,
        theta: uniform(400, 2600),
        careless: 0.1,
      ),
    );
    report.careless.add(careless);
    countSkips(careless);

    // Com lacunas.
    for (final entry in gapScenarios.entries) {
      final scenario = entry.value;
      final gapPlayer = SimPlayer(
        kind: entry.key,
        theta: uniform(scenario.low, scenario.high),
        forcedWrong: scenario.wrong,
        forcedRight: scenario.right,
      );
      final gapRun = run(gapPlayer);
      countSkips(gapRun);
      final band = RatingLevel.of(gapPlayer.theta.round()).index;
      // Só contam as lacunas de nós que o jogador "deveria" saber na faixa
      // dele (faixa do nó ≤ faixa verdadeira).
      final relevant = [
        for (final node in scenario.wrong)
          if (skills.node(node)!.band.index <= band) node,
      ];
      if (relevant.isEmpty) continue;
      bool inRoadmap(String node) => gapRun.roadmap.nodes.contains(node);
      report.gapTotals.update(entry.key, (n) => n + 1, ifAbsent: () => 1);
      if (relevant.any(inRoadmap)) {
        report.gapHits.update(entry.key, (n) => n + 1, ifAbsent: () => 1);
      }
      for (final node in relevant) {
        report.gapNodes.update(entry.key, (n) => n + 1, ifAbsent: () => 1);
        if (inRoadmap(node)) {
          report.gapNodeHits.update(entry.key, (n) => n + 1, ifAbsent: () => 1);
        }
        if (gapRun.result.status(node).isGap) {
          report.gapConfirmed.update(
            entry.key,
            (n) => n + 1,
            ifAbsent: () => 1,
          );
        }
      }
      // O caso difícil: lacuna num nó de faixa ≤ faixa(θ) − 2, que as regras
      // dariam como provável se o teste não a achasse.
      final deep = [
        for (final node in relevant)
          if (skills.node(node)!.band.index <= band - 2) node,
      ];
      if (deep.isNotEmpty) {
        report.deepTotals.update(entry.key, (n) => n + 1, ifAbsent: () => 1);
        if (deep.any(inRoadmap)) {
          report.deepHits.update(entry.key, (n) => n + 1, ifAbsent: () => 1);
        }
      }
    }
  }

  report.allRight = run(const SimPlayer(kind: SimKind.allRight, theta: 3000))
      .result
      .level;
  report.allWrong = run(const SimPlayer(kind: SimKind.allWrong, theta: 0))
      .result
      .level;
  return report;
}

/// A dificuldade mediana das perguntas de cada nó (o centro da faixa, se o
/// nó não tiver pergunta).
Map<String, int> _medians(SkillMap skills, PlacementBank bank) => {
  for (final node in skills.nodes)
    node.id: () {
      final values = [
        for (final item in bank.items)
          if (item.node == node.id) item.difficulty,
      ]..sort();
      return values.isEmpty ? node.band.rating : values[values.length ~/ 2];
    }(),
};

/// Gráfico ASCII de θ verdadeiro (horizontal) × θ estimado (vertical), de 400
/// a 2800, células de 100 × 100; a diagonal é marcada com `/`.
String asciiPlot(List<(double, int)> points) {
  const low = 400;
  const high = 2800;
  const cell = 100;
  const size = (high - low) ~/ cell;
  final grid = List.generate(size, (_) => List.filled(size, 0));
  for (final (truth, estimate) in points) {
    final x = ((truth - low) / cell).floor().clamp(0, size - 1);
    final y = ((estimate - low) / cell).floor().clamp(0, size - 1);
    grid[y][x]++;
  }
  final top = grid.expand((row) => row).fold(0, max);
  const shades = ' .:-=+*#%@';
  final buffer = StringBuffer();
  for (var y = size - 1; y >= 0; y--) {
    final label = '${low + y * cell}'.padLeft(5);
    buffer.write('$label |');
    for (var x = 0; x < size; x++) {
      final count = grid[y][x];
      if (count == 0) {
        buffer.write(x == y ? '/' : ' ');
      } else {
        final shade = (count * (shades.length - 1) / top).ceil();
        buffer.write(shades[shade.clamp(1, shades.length - 1)]);
      }
    }
    buffer.writeln();
  }
  buffer.writeln('      +${'-' * size}');
  buffer.writeln('       400       1400      2400  (θ verdadeiro)');
  return buffer.toString();
}

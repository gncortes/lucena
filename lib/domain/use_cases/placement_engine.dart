import 'dart:math';

import '../models/placement.dart';
import '../models/rating_level.dart';

/// Os parâmetros do motor, escolhidos na simulação
/// (`tools/placement/simulate.dart`, resultados em
/// `docs/spikes/T52-simulacao.md`).
class PlacementTuning {
  const PlacementTuning({
    this.a = 1.5,
    this.b = 0.4,
    this.randomesque = 3,
    this.intervalCut = 1.0,
  });

  /// Incerteza U(n) = a / (1 + b·n) (Pelánek, 2016), escolhida na grade da
  /// simulação (a de 1 a 2, b de 0,1 a 0,6; 1000 jogadores de cada tipo):
  ///
  /// - a = 1,5: a primeira resposta move θ 300 pontos, o meio da meta da
  ///   triagem (200 a 400).
  /// - b = 0,4: U(16) ≈ 0,20, ou seja, uma resposta da confirmação move θ uns
  ///   20 pontos em média e 40 no máximo típico (meta: menos de 50). Com b =
  ///   0,1 a confirmação ainda anda 40 a 90 pontos; com a = 1 e b = 0,6 o
  ///   passo encolhe cedo demais e a faixa exata cai para uns 60%.
  /// - Na região a de 1,25 a 1,75 e b de 0,3 a 0,4 todos ficam iguais dentro
  ///   do ruído (±3 pontos percentuais); (1,5; 0,4) é o meio dela.
  ///
  /// Com (1,5; 0,4): faixa exata 82%, certa ou vizinha 100%, RMSE ~105
  /// (detalhes em `docs/spikes/T52-simulacao.md`).
  final double a;
  final double b;

  /// Quantos candidatos entram no sorteio "randomesque" (k = 3, Parte 0.6).
  final int randomesque;

  /// Corte na log-verossimilhança para o intervalo: ficam os θ cujo log da
  /// verossimilhança está a menos de [intervalCut] do máximo (1,0 equivale a
  /// cerca de ±1,4 desvio-padrão, uns 84%).
  final double intervalCut;

  static const standard = PlacementTuning();

  double uncertainty(int answered) => a / (1 + b * answered);
}

/// O motor adaptativo do teste de nível (T52, Parte 4), em três módulos
/// (Papoušek et al., 2014): estimativa ([answer]), escolha da próxima
/// pergunta ([next]) e diagnóstico por nó ([diagnose]). Determinístico: a
/// mesma semente e as mesmas respostas dão as mesmas perguntas.
class PlacementEngine {
  PlacementEngine({
    required this.skills,
    required this.bank,
    this.tuning = PlacementTuning.standard,
  });

  final SkillMap skills;
  final PlacementBank bank;
  final PlacementTuning tuning;

  static const minTheta = 400.0;
  static const maxTheta = 2800.0;
  static const defaultTheta = 1200.0;

  /// Dificuldades-alvo da triagem.
  static const screeningTargets = [800, 1200, 1600, 2000];

  /// No máximo 6 perguntas `choice` por teste (o chute pesa).
  static const maxChoice = 6;

  /// Abaixo de θ − 300 a pergunta é "fácil para a pessoa": só aí o tempo de
  /// resposta vira evidência extra no nó.
  static const easyMargin = 300;

  /// O blueprint da adaptação (12 perguntas), por faixa de θ (Parte 4.2).
  static const blueprint = <int, Map<SkillGroup, int>>{
    // θ < 1000
    0: {
      SkillGroup.rules: 6,
      SkillGroup.mates: 3,
      SkillGroup.pawns: 2,
      SkillGroup.tactics: 1,
    },
    // 1000–1599
    1000: {
      SkillGroup.rules: 1,
      SkillGroup.mates: 3,
      SkillGroup.pawns: 4,
      SkillGroup.queenRook: 2,
      SkillGroup.minor: 1,
      SkillGroup.tactics: 1,
    },
    // 1600–2199
    1600: {
      SkillGroup.mates: 1,
      SkillGroup.pawns: 4,
      SkillGroup.queenRook: 4,
      SkillGroup.minor: 2,
      SkillGroup.tactics: 1,
    },
    // ≥ 2200
    2200: {
      SkillGroup.mates: 1,
      SkillGroup.pawns: 3,
      SkillGroup.queenRook: 4,
      SkillGroup.minor: 3,
      SkillGroup.tactics: 1,
    },
  };

  /// A linha do blueprint para [theta].
  static Map<SkillGroup, int> blueprintFor(double theta) => theta < 1000
      ? blueprint[0]!
      : theta < 1600
      ? blueprint[1000]!
      : theta < 2200
      ? blueprint[1600]!
      : blueprint[2200]!;

  /// Chance de acerto (Parte 4.3). Com [options] > 0 (pergunta `choice`), a
  /// logística deslocada: o chute acerta 1/k.
  static double probability(double theta, int difficulty, {int options = 0}) {
    final logistic = 1 / (1 + pow(10, (difficulty - theta) / 400));
    if (options <= 1) return logistic;
    final guess = 1 / options;
    return guess + (1 - guess) * logistic;
  }

  /// Começa um teste. Com [prior] (faixa já escolhida), θ parte do meio dela.
  PlacementState start({required int seed, RatingLevel? prior}) {
    final theta = prior?.rating.toDouble() ?? defaultTheta;
    return PlacementState(theta: theta, initialTheta: theta, seed: seed);
  }

  /// A próxima pergunta, ou nula se o teste acabou (ou o banco esgotou).
  PlacementItem? next(PlacementState state) {
    if (state.isFinished) return null;
    final index = state.answered.length;
    final random = Random(state.seed * 7919 + index * 104729);
    final pool = _available(state);
    if (pool.isEmpty) return null;
    return switch (PlacementPhase.of(index)) {
      PlacementPhase.screening => _screening(state, pool, random),
      PlacementPhase.adaptation => _adaptation(state, pool, random),
      PlacementPhase.confirmation =>
        index < 18
            ? _boundary(state, pool, random)
            : _confirmGap(state, pool, random) ??
                  _boundary(state, pool, random),
    };
  }

  /// Registra a resposta a [item] e atualiza θ:
  /// θ ← θ + U(n)·400·(resultado − P), limitado a [400, 2800].
  PlacementState answer(
    PlacementState state,
    PlacementItem item,
    PlacementOutcome outcome, {
    Duration elapsed = Duration.zero,
  }) {
    if (state.isFinished) throw StateError('o teste já terminou');
    final n = state.answered.length;
    final p = probability(
      state.theta,
      item.difficulty,
      options: item.optionCount,
    );
    final theta =
        (state.theta + tuning.uncertainty(n) * 400 * (outcome.score - p))
            .clamp(minTheta, maxTheta)
            .toDouble();
    final correct = outcome == PlacementOutcome.correct;
    final fast =
        correct &&
        item.difficulty < state.theta - easyMargin &&
        _isFast(state, elapsed);
    final previous = state.evidence[item.node] ?? const NodeEvidence();
    return state.copyWith(
      theta: theta,
      answered: [
        ...state.answered,
        PlacementAnswer(
          itemId: item.id,
          node: item.node,
          difficulty: item.difficulty,
          outcome: outcome,
          phase: PlacementPhase.of(n),
          options: item.optionCount,
          elapsed: elapsed,
          thetaAfter: theta,
        ),
      ],
      evidence: {
        ...state.evidence,
        item.node: previous.add(correct: correct, fast: fast),
      },
    );
  }

  /// O resultado: θ arredondado, o intervalo e o diagnóstico por nó.
  /// [takenAt] vem do `Now` de quem chama.
  PlacementResult result(PlacementState state, {required DateTime takenAt}) {
    final theta = state.theta.round();
    final (low, high) = interval(state.answered, theta: state.theta);
    return PlacementResult(
      theta: theta,
      low: low,
      high: high,
      nodes: diagnose(state.evidence, theta.toDouble()),
      takenAt: takenAt,
      answers: state.answered,
    );
  }

  /// O intervalo plausível: os θ (de 10 em 10, em [400, 2800]) cuja
  /// log-verossimilhança das respostas fica a menos do corte do máximo.
  /// Sempre contém [theta].
  (int, int) interval(List<PlacementAnswer> answers, {required double theta}) {
    if (answers.isEmpty) return (minTheta.round(), maxTheta.round());
    final grid = [
      for (var value = minTheta; value <= maxTheta; value += 10) value,
    ];
    final logs = [for (final value in grid) _logLikelihood(answers, value)];
    final best = logs.reduce(max);
    var low = maxTheta;
    var high = minTheta;
    for (var i = 0; i < grid.length; i++) {
      if (logs[i] >= best - tuning.intervalCut) {
        low = min(low, grid[i]);
        high = max(high, grid[i]);
      }
    }
    return (min(low, theta).round(), max(high, theta).round());
  }

  /// O diagnóstico por nó (Parte 4.4), nas regras e na ordem do documento:
  ///
  /// 1. acertou → `mastered` confirmado; errou → `gap` confirmado; acertou e
  ///    errou → decide a última. Exceção do desatento: um erro isolado num nó
  ///    muito abaixo de θ (faixa ≤ faixa(θ) − 2) não vira lacuna sem
  ///    confirmação; o nó segue para as regras seguintes.
  /// 2. nó `mastered` → os pré-requisitos (recursivamente) abaixo da faixa
  ///    de θ viram `likely`, salvo os que já têm estado pela regra 1.
  /// 3. sem evidência e faixa ≤ faixa(θ) − 2 → `likely`.
  /// 4 e 5. o resto → `unknown` (o roteiro decide pela faixa).
  Map<String, NodeStatus> diagnose(
    Map<String, NodeEvidence> evidence,
    double theta,
  ) {
    final band = RatingLevel.of(theta.round()).index;
    final status = <String, NodeStatus>{};
    for (final node in skills.nodes) {
      final ev = evidence[node.id];
      if (ev == null || ev.total == 0) continue;
      if (_isSlip(node, ev, band)) continue;
      status[node.id] = NodeStatus(
        ev.lastCorrect ? NodeState.mastered : NodeState.gap,
        confirmed: true,
      );
    }
    final mastered = [
      for (final entry in status.entries)
        if (entry.value.state == NodeState.mastered) entry.key,
    ];
    for (final id in mastered) {
      for (final prerequisite in skills.prerequisitesOf(id)) {
        // Só abaixo da faixa do jogador: na faixa dele, o pré-requisito sem
        // pergunta fica sem evidência (o iniciante que acerta o xeque pode
        // não saber o bispo).
        if ((skills.node(prerequisite)?.band.index ?? band) >= band) continue;
        status.putIfAbsent(
          prerequisite,
          () => const NodeStatus(NodeState.likely),
        );
      }
    }
    for (final node in skills.nodes) {
      status.putIfAbsent(
        node.id,
        () => node.band.index <= band - 2
            ? const NodeStatus(NodeState.likely)
            : NodeStatus.unknown,
      );
    }
    return status;
  }

  /// Um erro só, sem acerto, num nó com faixa ≤ faixa(θ) − 2.
  static bool _isSlip(SkillNode node, NodeEvidence ev, int band) =>
      ev.correct == 0 && ev.wrong == 1 && node.band.index <= band - 2;

  double _logLikelihood(List<PlacementAnswer> answers, double theta) {
    var total = 0.0;
    for (final answer in answers) {
      final p = probability(
        theta,
        answer.difficulty,
        options: answer.options,
      ).clamp(1e-9, 1 - 1e-9);
      total += log(answer.correct ? p : 1 - p);
    }
    return total;
  }

  /// Um acerto em menos da metade da mediana de tempo das respostas
  /// anteriores do jogador (o banco não tem tempo médio por pergunta).
  static bool _isFast(PlacementState state, Duration elapsed) {
    final times = [
      for (final answer in state.answered)
        if (answer.elapsed > Duration.zero) answer.elapsed.inMilliseconds,
    ]..sort();
    if (times.length < 3 || elapsed <= Duration.zero) return false;
    final median = times[times.length ~/ 2];
    return elapsed.inMilliseconds * 2 < median;
  }

  /// As perguntas ainda possíveis: não repetidas e sem passar do limite de
  /// `choice`.
  List<PlacementItem> _available(PlacementState state) {
    final used = state.usedItems;
    final choiceFull = state.choiceCount >= maxChoice;
    return [
      for (final item in bank.items)
        if (!used.contains(item.id) &&
            !(choiceFull && item.type == PlacementItemType.choice) &&
            skills.contains(item.node))
          item,
    ];
  }

  SkillGroup _group(String node) => skills.node(node)!.group;

  /// Bônus (até 150 pontos de "custo") para nós que são base de muitos
  /// outros e têm poucos pré-requisitos: as peças, a oposição, Lucena. Um
  /// acerto neles diz pouco de θ, mas um erro muda o roteiro inteiro, e sem
  /// perguntar eles viram "prováveis" por qualquer nó acima (regra 2). É o
  /// "uma por peça" do blueprint do iniciante: entre as peças e o xeque (que
  /// também é base de quase tudo), as peças vêm antes, porque o xeque já
  /// depende delas (25 pontos a menos por pré-requisito).
  late final Map<String, double> _foundations = () {
    final counts = {
      for (final node in skills.nodes)
        node.id: skills.dependentsOf(node.id).length,
    };
    final most = counts.values.fold(1, max);
    return {
      for (final node in skills.nodes)
        node.id: max(
          0.0,
          150.0 * counts[node.id]! / most -
              25.0 * skills.prerequisitesOf(node.id).length,
        ),
    };
  }();

  double _foundation(String node) => _foundations[node] ?? 0;

  /// Sorteia entre os k candidatos de menor custo.
  PlacementItem _randomesque(
    List<PlacementItem> pool,
    double Function(PlacementItem) cost,
    Random random,
  ) {
    final ranked = [...pool]
      ..sort((x, y) {
        final byCost = cost(x).compareTo(cost(y));
        return byCost != 0 ? byCost : x.id.compareTo(y.id);
      });
    return ranked[random.nextInt(min(tuning.randomesque, ranked.length))];
  }

  /// Quantas vezes o nó já foi perguntado.
  static int _asked(PlacementState state, String node) =>
      state.answered.where((answer) => answer.node == node).length;

  /// Triagem: alvos de 800 a 2000, cada um de uma área diferente. Começa no
  /// alvo mais perto de θ inicial; acertou, sobe para o próximo alvo não
  /// usado; errou, desce.
  PlacementItem _screening(
    PlacementState state,
    List<PlacementItem> pool,
    Random random,
  ) {
    final target = screeningTarget(state);
    final usedGroups = {
      for (final answer in state.answered) _group(answer.node),
    };
    final fresh = [
      for (final item in pool)
        if (!usedGroups.contains(_group(item.node))) item,
    ];
    // Na triagem, `choice` só se não houver outra perto do alvo: um chute
    // certo aqui pesa muito.
    return _randomesque(
      fresh.isEmpty ? pool : fresh,
      (item) =>
          (item.difficulty - target).abs() +
          (item.type == PlacementItemType.choice ? 100.0 : 0.0),
      random,
    );
  }

  /// O alvo de dificuldade da próxima pergunta da triagem.
  static int screeningTarget(PlacementState state) {
    final unused = [...screeningTargets];
    int nearest(double theta) =>
        unused.reduce((x, y) => (x - theta).abs() <= (y - theta).abs() ? x : y);
    var target = nearest(state.initialTheta);
    for (final answer in state.answered.take(screeningTargets.length - 1)) {
      unused.remove(target);
      final up = unused.where((value) => value > target);
      final down = unused.where((value) => value < target);
      if (answer.correct) {
        target = up.isNotEmpty ? up.reduce(min) : down.reduce(max);
      } else {
        target = down.isNotEmpty ? down.reduce(max) : up.reduce(min);
      }
    }
    return target;
  }

  /// Adaptação: a área mais atrasada no blueprint da faixa de θ (Kingsbury e
  /// Zara); dentro dela, os 3 itens de dificuldade mais perto de θ (com um
  /// custo para nó já perguntado, para cobrir os temas), e um dos 3 sorteado.
  PlacementItem _adaptation(
    PlacementState state,
    List<PlacementItem> pool,
    Random random,
  ) {
    final row = blueprintFor(state.theta);
    final asked = <SkillGroup, int>{};
    for (final answer in state.answered) {
      if (answer.phase == PlacementPhase.adaptation) {
        asked.update(_group(answer.node), (n) => n + 1, ifAbsent: () => 1);
      }
    }
    final step = state.answered.length - 4 + 1;
    final byGroup = <SkillGroup, List<PlacementItem>>{};
    for (final item in pool) {
      byGroup.putIfAbsent(_group(item.node), () => []).add(item);
    }
    double deficit(SkillGroup group) =>
        (row[group] ?? 0) * step / 12 - (asked[group] ?? 0);
    final groups = byGroup.keys.toList()
      ..sort((x, y) => x.index.compareTo(y.index));
    final best = groups.map(deficit).reduce(max);
    final behind = [
      for (final group in groups)
        if (deficit(group) >= best - 1e-9) group,
    ];
    final group = behind[random.nextInt(behind.length)];
    return _randomesque(
      byGroup[group]!,
      (item) =>
          (item.difficulty - state.theta).abs() +
          120.0 * _asked(state, item.node) -
          _foundation(item.node),
      random,
    );
  }

  /// Confirmação, perguntas 17 e 18: dificuldade no limite mais perto entre
  /// a faixa de θ e a vizinha. `choice` só se não houver outra perto: o chute
  /// informa pouco justo onde se decide a faixa.
  PlacementItem _boundary(
    PlacementState state,
    List<PlacementItem> pool,
    Random random,
  ) {
    final boundary = nearestBoundary(state.theta);
    return _randomesque(
      pool,
      (item) =>
          (item.difficulty - boundary).abs() +
          60.0 * _asked(state, item.node) +
          (item.type == PlacementItemType.choice ? 100.0 : 0.0),
      random,
    );
  }

  /// O limite de faixa mais perto de [theta] (1000, 1300, ..., 2200).
  static int nearestBoundary(double theta) {
    final limits = [
      for (final level in RatingLevel.values)
        if (level.min != null) level.min!,
    ];
    return limits.reduce(
      (x, y) => (x - theta).abs() <= (y - theta).abs() ? x : y,
    );
  }

  /// Confirmação, perguntas 19 e 20: confirmar a lacuna que vai abrir o
  /// roteiro. Nesta ordem:
  ///
  /// 1. nós em dúvida (acerto e erro, ou o erro isolado do desatento);
  /// 2. um pré-requisito direto, ainda não perguntado, da primeira lacuna em
  ///    ordem topológica (desce a cadeia: se errar, a lacuna começa antes; se
  ///    acertar, os de baixo viram prováveis pela regra 2);
  /// 3. as lacunas, para confirmar de novo.
  ///
  /// Tática de meio-jogo sempre por último (não abre roteiro). Dentro do nó,
  /// a pergunta mais fácil ainda não feita.
  PlacementItem? _confirmGap(
    PlacementState state,
    List<PlacementItem> pool,
    Random random,
  ) {
    final band = RatingLevel.of(state.theta.round()).index;
    final confirmed = {
      for (final answer in state.answered)
        if (answer.phase == PlacementPhase.confirmation) answer.node,
    };
    final wrong = [
      for (final node in skills.nodes)
        if ((state.evidence[node.id]?.wrong ?? 0) > 0) node,
    ];
    bool doubtful(SkillNode node) {
      final ev = state.evidence[node.id]!;
      return ev.mixed || _isSlip(node, ev, band);
    }

    final gaps = [
      for (final node in wrong)
        if (!doubtful(node) && !state.evidence[node.id]!.lastCorrect) node,
    ];
    final below = <SkillNode>[];
    for (final gap in gaps.where((node) => !node.midgameTactic)) {
      final requires =
          [
            for (final id in gap.requires)
              if (!state.evidence.containsKey(id)) skills.node(id)!,
          ]..sort(
            (x, y) => (x.group == gap.group ? 0 : 1).compareTo(
              y.group == gap.group ? 0 : 1,
            ),
          );
      below.addAll(requires);
    }
    final ordered = [
      for (final node in wrong)
        if (doubtful(node) && !node.midgameTactic) node,
      ...below.where((node) => !node.midgameTactic),
      for (final node in gaps)
        if (!node.midgameTactic) node,
      for (final node in wrong)
        if (node.midgameTactic) node,
    ].where((node) => !confirmed.contains(node.id));
    for (final node in ordered) {
      final items = [
        for (final item in pool)
          if (item.node == node.id) item,
      ];
      if (items.isEmpty) continue;
      items.sort((x, y) {
        final byDifficulty = x.difficulty.compareTo(y.difficulty);
        return byDifficulty != 0 ? byDifficulty : x.id.compareTo(y.id);
      });
      return items.first;
    }
    return null;
  }
}

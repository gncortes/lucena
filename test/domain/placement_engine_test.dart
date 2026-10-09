import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/placement.dart';
import 'package:lucena/domain/models/rating_level.dart';
import 'package:lucena/domain/use_cases/placement_engine.dart';

import '../../tools/placement/synthetic.dart';
import 'placement_fixtures.dart';

void main() {
  final skills = SkillMap.fromJson(syntheticSkillsJson());
  final bank = PlacementBank.fromJson(syntheticItemsJson());
  final engine = PlacementEngine(skills: skills, bank: bank);

  /// Faz o teste inteiro respondendo com [answer].
  PlacementState run(
    bool Function(PlacementItem item) answer, {
    int seed = 1,
    RatingLevel? prior,
  }) {
    var state = engine.start(seed: seed, prior: prior);
    while (!state.isFinished) {
      final item = engine.next(state)!;
      state = engine.answer(
        state,
        item,
        answer(item) ? PlacementOutcome.correct : PlacementOutcome.wrong,
      );
    }
    return state;
  }

  SkillGroup groupOf(String node) => skills.node(node)!.group;

  group('estimativa', () {
    test('chance de acerto: logística e logística deslocada', () {
      expect(PlacementEngine.probability(1200, 1200), closeTo(0.5, 1e-9));
      expect(PlacementEngine.probability(1600, 1200), closeTo(10 / 11, 1e-9));
      // Com 2 opções, o chute já acerta metade.
      expect(
        PlacementEngine.probability(1200, 1200, options: 2),
        closeTo(0.75, 1e-9),
      );
      expect(
        PlacementEngine.probability(0, 2600, options: 3),
        closeTo(1 / 3, 1e-3),
      );
    });

    test('θ ← θ + U(n)·400·(resultado − P)', () {
      final start = engine.start(seed: 1);
      final move = PlacementItem.fromJson({
        'id': 'm',
        'node': 'rules.rook',
        'type': 'move',
        'difficulty': 1200,
        'fen': '',
        'prompt': '',
      });
      final up = engine.answer(start, move, PlacementOutcome.correct);
      expect(up.theta, closeTo(1200 + 1.5 * 400 * 0.5, 1e-9));
      final down = engine.answer(start, move, PlacementOutcome.wrong);
      expect(down.theta, closeTo(1200 - 300, 1e-9));
    });

    test('acerto em choice sobe menos (pode ser chute)', () {
      final start = engine.start(seed: 1);
      final choice = PlacementItem.fromJson({
        'id': 'c',
        'node': 'rules.stalemate',
        'type': 'choice',
        'difficulty': 1200,
        'fen': '',
        'prompt': '',
        'options': ['win', 'draw'],
        'answer': 'win',
      });
      final right = engine.answer(start, choice, PlacementOutcome.correct);
      expect(right.theta, closeTo(1200 + 1.5 * 400 * 0.25, 1e-9));
      // E o erro em choice desce mais: nem o chute acertou.
      final wrong = engine.answer(start, choice, PlacementOutcome.wrong);
      expect(wrong.theta, closeTo(1200 - 1.5 * 400 * 0.75, 1e-9));
    });

    test('"não sei" conta como erro', () {
      final start = engine.start(seed: 1);
      final item = engine.next(start)!;
      expect(
        engine.answer(start, item, PlacementOutcome.dontKnow).theta,
        engine.answer(start, item, PlacementOutcome.wrong).theta,
      );
    });

    test('a incerteza encolhe: a confirmação anda menos de 50', () {
      const tuning = PlacementTuning.standard;
      expect(tuning.uncertainty(0) * 400 * 0.5, inInclusiveRange(200, 400));
      expect(tuning.uncertainty(16) * 400 * 0.5, lessThan(50));
      for (var n = 1; n < 20; n++) {
        expect(tuning.uncertainty(n), lessThan(tuning.uncertainty(n - 1)));
      }
    });

    test(
      'θ fica em [400, 2800]; acerta tudo ≥ expert, erra tudo iniciante',
      () {
        final right = run((_) => true);
        final wrong = run((_) => false);
        expect(right.theta, lessThanOrEqualTo(2800));
        expect(wrong.theta, greaterThanOrEqualTo(400));
        final takenAt = DateTime.utc(2026, 10, 8);
        final high = engine.result(right, takenAt: takenAt);
        final low = engine.result(wrong, takenAt: takenAt);
        expect(
          high.level.index,
          greaterThanOrEqualTo(RatingLevel.expert.index),
        );
        expect(low.level, RatingLevel.beginner);
        expect(high.high, 2800);
        expect(low.low, 400);
        expect(high.takenAt, takenAt);
      },
    );

    test('faixa já escolhida: θ parte do meio dela', () {
      final state = engine.start(seed: 1, prior: RatingLevel.expert);
      expect(state.theta, 2050);
      expect(PlacementEngine.screeningTarget(state), 2000);
    });

    test('o intervalo contém θ e encolhe com as respostas', () {
      // Um jogador médio: acerta abaixo de 1500, erra acima.
      final state = run((item) => item.difficulty < 1500);
      final (low, high) = engine.interval(state.answered, theta: state.theta);
      expect(low, lessThanOrEqualTo(state.theta));
      expect(high, greaterThanOrEqualTo(state.theta));
      final (low5, high5) = engine.interval(
        state.answered.take(5).toList(),
        theta: state.answered[4].thetaAfter!,
      );
      expect(high - low, lessThan(high5 - low5));
      final result = engine.result(state, takenAt: DateTime.utc(2026));
      expect(result.levels, contains(result.level));
    });

    test('o tempo nunca mexe em θ; acerto rápido em pergunta fácil é '
        'evidência extra no nó', () {
      var state = engine.start(seed: 3);
      // Três acertos de 20 s: a mediana, e θ alto o bastante para haver
      // pergunta fácil.
      for (var i = 0; i < 3; i++) {
        state = engine.answer(
          state,
          engine.next(state)!,
          PlacementOutcome.correct,
          elapsed: const Duration(seconds: 20),
        );
      }
      final easy = bank.items.firstWhere(
        (item) =>
            item.difficulty < state.theta - 300 &&
            !state.usedItems.contains(item.id),
      );
      final fast = engine.answer(
        state,
        easy,
        PlacementOutcome.correct,
        elapsed: const Duration(seconds: 3),
      );
      final slow = engine.answer(
        state,
        easy,
        PlacementOutcome.correct,
        elapsed: const Duration(seconds: 30),
      );
      expect(fast.theta, slow.theta);
      expect(fast.evidence[easy.node]!.fastCorrect, 1);
      expect(slow.evidence[easy.node]!.fastCorrect, 0);
    });
  });

  group('escolha das perguntas', () {
    test('sempre 20 perguntas, sem repetir, e depois nada', () {
      for (var seed = 0; seed < 20; seed++) {
        final state = run(
          (item) => item.difficulty < 400 + seed * 110,
          seed: seed,
        );
        expect(state.answered, hasLength(20));
        expect(state.usedItems, hasLength(20));
        expect(engine.next(state), isNull);
        expect(
          () =>
              engine.answer(state, bank.items.first, PlacementOutcome.correct),
          throwsStateError,
        );
      }
    });

    test('no máximo 6 perguntas choice', () {
      for (var seed = 0; seed < 30; seed++) {
        // Acerta só as choice: o motor seria tentado a pedir mais delas.
        final state = run(
          (item) => item.type == PlacementItemType.choice,
          seed: seed,
        );
        expect(state.choiceCount, lessThanOrEqualTo(PlacementEngine.maxChoice));
      }
    });

    test('fases: triagem, adaptação e confirmação nas posições certas', () {
      final state = run((item) => item.difficulty < 1400);
      expect(state.answered.map((a) => a.phase), [
        ...List.filled(4, PlacementPhase.screening),
        ...List.filled(12, PlacementPhase.adaptation),
        ...List.filled(4, PlacementPhase.confirmation),
      ]);
    });

    test('triagem: alvos 800 a 2000, áreas diferentes, ordem adapta', () {
      // Começa em 1200; errou, desce para 800; acertou, sobe para 1600.
      var state = engine.start(seed: 5);
      expect(PlacementEngine.screeningTarget(state), 1200);
      final first = engine.next(state)!;
      expect((first.difficulty - 1200).abs(), lessThan(150));
      state = engine.answer(state, first, PlacementOutcome.wrong);
      expect(PlacementEngine.screeningTarget(state), 800);
      final second = engine.next(state)!;
      state = engine.answer(state, second, PlacementOutcome.correct);
      expect(PlacementEngine.screeningTarget(state), 1600);
      final third = engine.next(state)!;
      state = engine.answer(state, third, PlacementOutcome.correct);
      expect(PlacementEngine.screeningTarget(state), 2000);
      final fourth = engine.next(state)!;
      final groups = {
        for (final item in [first, second, third, fourth]) groupOf(item.node),
      };
      expect(groups, hasLength(4));
    });

    test('adaptação segue o blueprint da faixa de θ (iniciante)', () {
      // Erra tudo: θ fica abaixo de 1000 a adaptação inteira.
      final state = run((_) => false);
      final counts = <SkillGroup, int>{};
      for (final answer in state.answered) {
        if (answer.phase == PlacementPhase.adaptation) {
          counts.update(groupOf(answer.node), (n) => n + 1, ifAbsent: () => 1);
        }
      }
      expect(counts, PlacementEngine.blueprint[0]);
      // "Uma por peça": o bispo e o cavalo entram.
      final nodes = state.answered.map((a) => a.node).toSet();
      expect(nodes, containsAll(['rules.bishop', 'rules.knight']));
    });

    test('adaptação do jogador forte cobre dama e torre e peças menores', () {
      final state = run((_) => true);
      final groups = [
        for (final answer in state.answered)
          if (answer.phase == PlacementPhase.adaptation) groupOf(answer.node),
      ];
      expect(
        groups.where((g) => g == SkillGroup.queenRook).length,
        greaterThanOrEqualTo(3),
      );
      expect(
        groups.where((g) => g == SkillGroup.minor).length,
        greaterThanOrEqualTo(2),
      );
      expect(groups, isNot(contains(SkillGroup.rules)));
    });

    test('confirmação: a fronteira mais perto entre as faixas', () {
      expect(PlacementEngine.nearestBoundary(1180), 1300);
      expect(PlacementEngine.nearestBoundary(1120), 1000);
      expect(PlacementEngine.nearestBoundary(450), 1000);
      expect(PlacementEngine.nearestBoundary(2700), 2200);
      final state = run((item) => item.difficulty < 1450);
      final boundary = state.answered[16];
      final before = state.answered[15].thetaAfter!;
      expect(
        (boundary.difficulty - PlacementEngine.nearestBoundary(before)).abs(),
        lessThan(200),
      );
    });

    test('confirmação: primeiro o erro isolado do desatento', () {
      // θ 2000 (expert): o erro único na torre (iniciante) fica em dúvida.
      final state = PlacementState(
        theta: 2000,
        initialTheta: 1200,
        seed: 1,
        answered: [
          for (var i = 0; i < 18; i++)
            answered(
              'x$i',
              i == 3 ? 'rules.rook' : 'rook.vancura',
              index: i,
              correct: i != 3,
            ),
        ],
        evidence: {
          'rules.rook': const NodeEvidence().add(correct: false),
          'rook.vancura': const NodeEvidence().add(correct: true),
        },
      );
      expect(engine.next(state)!.node, 'rules.rook');
    });

    test('confirmação: desce a cadeia da primeira lacuna', () {
      // Errou Philidor e nunca viu Lucena: pergunta Lucena.
      final state = PlacementState(
        theta: 1500,
        initialTheta: 1200,
        seed: 1,
        answered: [
          for (var i = 0; i < 18; i++)
            answered('x$i', 'rook.philidor', index: i, correct: false),
        ],
        evidence: {'rook.philidor': const NodeEvidence().add(correct: false)},
      );
      expect(engine.next(state)!.node, 'rook.lucena');
    });
  });

  group('determinismo e exposição', () {
    test('mesma semente e mesmas respostas: mesmas perguntas', () {
      bool answer(PlacementItem item) => item.difficulty < 1700;
      final first = run(answer, seed: 42);
      final second = run(answer, seed: 42);
      expect(
        second.answered.map((a) => a.itemId),
        first.answered.map((a) => a.itemId),
      );
      expect(second.theta, first.theta);
    });

    test('outra semente: perguntas diferentes (randomesque)', () {
      bool answer(PlacementItem item) => item.difficulty < 1700;
      final first = run(answer, seed: 1).usedItems;
      final second = run(answer, seed: 2).usedItems;
      expect(first.intersection(second).length, lessThan(12));
    });

    test('retomar depois de fechar à força: a mesma pergunta', () {
      var state = engine.start(seed: 9);
      for (var i = 0; i < 10; i++) {
        final item = engine.next(state)!;
        state = engine.answer(
          state,
          item,
          i.isEven ? PlacementOutcome.correct : PlacementOutcome.dontKnow,
        );
      }
      final saved = jsonEncode(state.toJson());
      final restored = PlacementState.fromJson(
        jsonDecode(saved) as Map<String, dynamic>,
      );
      expect(restored.questionNumber, 11);
      expect(engine.next(restored)!.id, engine.next(state)!.id);
    });
  });
}

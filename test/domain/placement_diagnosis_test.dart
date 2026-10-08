import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/placement.dart';
import 'package:lucena/domain/models/rating_level.dart';
import 'package:lucena/domain/use_cases/placement_engine.dart';

import 'placement_fixtures.dart';

void main() {
  final engine = PlacementEngine(
    skills: smallSkills(),
    bank: PlacementBank(const []),
  );

  NodeEvidence right([int times = 1]) {
    var evidence = const NodeEvidence();
    for (var i = 0; i < times; i++) {
      evidence = evidence.add(correct: true);
    }
    return evidence;
  }

  NodeEvidence wrong([int times = 1]) {
    var evidence = const NodeEvidence();
    for (var i = 0; i < times; i++) {
      evidence = evidence.add(correct: false);
    }
    return evidence;
  }

  Map<String, NodeStatus> diagnose(
    Map<String, NodeEvidence> evidence,
    RatingLevel level,
  ) => engine.diagnose(evidence, mid(level).toDouble());

  group('regra 1: resposta direta', () {
    test('acertou → domina (confirmado); errou → lacuna (confirmada)', () {
      final status = diagnose({
        'rook.lucena': right(),
        'rook.philidor': wrong(),
      }, RatingLevel.intermediate);
      expect(status['rook.lucena'], mastered);
      expect(status['rook.philidor'], gap);
    });

    test('acertou e errou: decide a última', () {
      final status = diagnose({
        'rook.lucena': right().add(correct: false),
        'rook.philidor': wrong().add(correct: true),
      }, RatingLevel.intermediate);
      expect(status['rook.lucena'], gap);
      expect(status['rook.philidor'], mastered);
    });
  });

  group('regra 2: pré-requisitos de quem domina', () {
    test('viram prováveis, recursivamente', () {
      final status = diagnose({'rook.lucena': right()}, RatingLevel.casual);
      for (final id in [
        'mate.queen',
        'rules.queen',
        'rules.rook',
        'rules.bishop',
      ]) {
        expect(status[id], likely, reason: id);
      }
    });

    test('salvo a lacuna confirmada (o bispo do iniciante)', () {
      final status = diagnose({
        'rules.queen': right(),
        'rules.rook': right(),
        'rules.bishop': wrong(),
      }, RatingLevel.beginner);
      expect(status['rules.bishop'], gap);
      expect(status['rules.rook'], mastered);
      expect(status['rules.queen'], mastered);
    });
  });

  group('regras 3 a 5: sem evidência, pela faixa', () {
    test('faixa ≤ faixa(θ) − 2 → provável; o resto → desconhecido', () {
      final status = diagnose({}, RatingLevel.advanced);
      // beginner e casual: até 2 faixas abaixo de advanced.
      expect(status['rules.rook'], likely);
      expect(status['pawns.opposition'], likely);
      // intermediate (anterior) e advanced (a de θ): candidatos ao roteiro.
      expect(status['rook.lucena'], unknown);
      expect(status['pawns.reti'], unknown);
    });

    test('acima da faixa de θ → desconhecido', () {
      final status = diagnose({}, RatingLevel.beginner);
      expect(status['pawns.reti'], unknown);
      expect(status['rook.lucena'], unknown);
      expect(status['rules.rook'], unknown);
    });

    test('todo nó do mapa tem estado', () {
      final status = diagnose({}, RatingLevel.master);
      expect(status.keys.toSet(), smallSkills().nodes.map((n) => n.id).toSet());
    });
  });

  group('desatento', () {
    test('um erro isolado bem abaixo de θ não vira lacuna confirmada', () {
      final status = diagnose({'rules.rook': wrong()}, RatingLevel.expert);
      expect(status['rules.rook']!.isGap, isFalse);
      expect(status['rules.rook'], likely);
    });

    test('dois erros viram lacuna confirmada', () {
      final status = diagnose({'rules.rook': wrong(2)}, RatingLevel.expert);
      expect(status['rules.rook'], gap);
    });

    test('o erro perto de θ (faixa anterior) vale como lacuna', () {
      final status = diagnose({
        'pawns.opposition': wrong(),
      }, RatingLevel.intermediate);
      expect(status['pawns.opposition'], gap);
    });

    test('o erro isolado não bloqueia a inferência pela regra 2', () {
      final status = diagnose({
        'rules.rook': wrong(),
        'rook.philidor': right(),
      }, RatingLevel.expert);
      expect(status['rules.rook'], likely);
    });
  });

  test('tática de meio-jogo fica no resultado', () {
    final status = diagnose({'tactics.basic': wrong()}, RatingLevel.casual);
    expect(status['tactics.basic'], gap);
  });
}

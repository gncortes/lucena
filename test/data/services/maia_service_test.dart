import 'dart:convert';
import 'dart:io' as io;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/data/services/maia_service.dart';
import 'package:lucena/domain/use_cases/game_rules.dart';

/// O serviço roda o modelo de verdade num isolate, com o arquivo de pesos do
/// repositório.
void main() {
  Future<Uint8List> weights() =>
      io.File('assets/models/maia3-5m.bin').readAsBytes();

  final reference = jsonDecode(
    io.File('test/fixtures/maia/reference.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  Map<String, dynamic> fixture(String name) =>
      (reference['cases'] as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .firstWhere((fixture) => fixture['name'] == name);

  final rookMate = [GameRules.fromFen('8/8/8/4k3/8/8/8/R3K3 w - - 0 1')!];

  test('o lance mais provável é o das fixtures', () async {
    final service = MaiaService(weights);
    addTearDown(service.dispose);

    for (final level in [1000, 2200]) {
      final expected = fixture('rook-mate@${level}v$level');
      final evaluation = await service.evaluate(
        rookMate,
        selfElo: level,
        oppoElo: level,
      );

      expect(evaluation.policy.keys.first, expected['best']);
      expect(
        evaluation.policy.values.first,
        closeTo(
          (expected['policy'] as Map<String, dynamic>).values.first as num,
          1e-4,
        ),
      );
      expect(evaluation.elapsed, greaterThan(Duration.zero));
    }
  });

  test('a mesma posição em 1000 e 2600 dá distribuições diferentes', () async {
    final service = MaiaService(weights);
    addTearDown(service.dispose);

    final beginner = await service.evaluate(
      rookMate,
      selfElo: 1000,
      oppoElo: 1000,
    );
    final master = await service.evaluate(
      rookMate,
      selfElo: 2600,
      oppoElo: 2600,
    );

    expect(beginner.policy.keys.toSet(), master.policy.keys.toSet());
    expect(beginner.policy.keys.first, isNot(master.policy.keys.first));
    expect(master.win, greaterThan(beginner.win));
  });

  test('pedidos simultâneos recebem cada um a sua resposta', () async {
    final service = MaiaService(weights);
    addTearDown(service.dispose);
    final start = [GameRules.initial];

    final answers = await Future.wait([
      service.evaluate(rookMate, selfElo: 1400, oppoElo: 1400),
      service.evaluate(start, selfElo: 1400, oppoElo: 1400),
    ]);

    expect(answers[0].policy.keys, contains('a1a4'));
    expect(answers[1].policy.keys.first, 'e2e4');
  });

  test('posição sem lances devolve uma previsão vazia', () async {
    final service = MaiaService(weights);
    addTearDown(service.dispose);
    // Afogado: as pretas não têm lance.
    final stalemate = [GameRules.fromFen('7k/5Q2/6K1/8/8/8/8/8 b - - 0 1')!];

    final evaluation = await service.evaluate(
      stalemate,
      selfElo: 1400,
      oppoElo: 1400,
    );

    expect(evaluation.policy, isEmpty);
  });

  test(
    'se o arquivo não carrega, o pedido falha e o próximo tenta de novo',
    () async {
      var attempts = 0;
      final service = MaiaService(() {
        attempts++;
        return attempts == 1
            ? Future<Uint8List>.error(StateError('sem arquivo'))
            : weights();
      });
      addTearDown(service.dispose);

      await expectLater(
        service.evaluate(rookMate, selfElo: 1400, oppoElo: 1400),
        throwsStateError,
      );
      final evaluation = await service.evaluate(
        rookMate,
        selfElo: 1400,
        oppoElo: 1400,
      );

      expect(evaluation.policy, isNotEmpty);
      expect(attempts, 2);
    },
  );

  test('depois de desligado, liga de novo no próximo pedido', () async {
    final service = MaiaService(weights);
    addTearDown(service.dispose);
    await service.evaluate(rookMate, selfElo: 1400, oppoElo: 1400);

    await service.dispose();
    final evaluation = await service.evaluate(
      rookMate,
      selfElo: 1400,
      oppoElo: 1400,
    );

    expect(evaluation.policy, isNotEmpty);
  });
}

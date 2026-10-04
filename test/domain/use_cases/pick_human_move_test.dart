import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/use_cases/pick_human_move.dart';

void main() {
  const moves = {'e2e4': 0.6, 'd2d4': 0.3, 'g1f3': 0.1};

  String? pick(double roll, {double temperature = 1}) =>
      PickHumanMove.pick(moves, temperature: temperature, roll: roll);

  test('sem lances, não escolhe nada', () {
    expect(PickHumanMove.pick({}, temperature: 1, roll: 0.5), isNull);
  });

  test('com temperatura 1, sorteia na proporção das probabilidades', () {
    expect(pick(0), 'e2e4');
    expect(pick(0.59), 'e2e4');
    expect(pick(0.61), 'd2d4');
    expect(pick(0.89), 'd2d4');
    expect(pick(0.91), 'g1f3');
    expect(pick(0.999), 'g1f3');
  });

  test('com temperatura 0, joga sempre o mais provável', () {
    for (final roll in [0.0, 0.5, 0.999]) {
      expect(pick(roll, temperature: 0), 'e2e4');
    }
  });

  test('temperatura baixa favorece os lances mais prováveis', () {
    // Com 0,5 os pesos viram 0,36, 0,09 e 0,01: o primeiro fica com 78%.
    expect(pick(0.7, temperature: 0.5), 'e2e4');
    expect(pick(0.7), 'd2d4');
    expect(pick(0.99, temperature: 0.5), 'g1f3');
  });

  test('em muitos sorteios, cada lance sai na proporção esperada', () {
    final counts = <String, int>{};
    const draws = 1000;
    for (var i = 0; i < draws; i++) {
      final move = pick((i + 0.5) / draws)!;
      counts[move] = (counts[move] ?? 0) + 1;
    }
    expect(counts, {'e2e4': 600, 'd2d4': 300, 'g1f3': 100});
  });
}

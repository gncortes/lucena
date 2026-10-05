import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/maia_timing.dart';

void main() {
  Duration ms(int value) => Duration(milliseconds: value);

  test('sem tempos, não há medição', () {
    expect(MaiaTiming.of([]), isNull);
  });

  test('número ímpar de contas: a mediana é a do meio', () {
    final timing = MaiaTiming.of([ms(300), ms(100), ms(120)]);

    expect(
      timing,
      MaiaTiming(runs: 3, median: ms(120), fastest: ms(100), slowest: ms(300)),
    );
  });

  test('número par de contas: a mediana é a média das duas do meio', () {
    final timing = MaiaTiming.of([ms(100), ms(400), ms(110), ms(130)])!;

    expect(timing.median, ms(120));
    expect(timing.fastest, ms(100));
    expect(timing.slowest, ms(400));
    expect(timing.runs, 4);
  });

  test('uma conta lenta isolada não muda a mediana', () {
    final steady = MaiaTiming.of([for (var i = 0; i < 9; i++) ms(110)])!;
    final withSpike = MaiaTiming.of([
      for (var i = 0; i < 9; i++) ms(110),
      ms(900),
    ])!;

    expect(withSpike.median, steady.median);
    expect(withSpike.slowest, ms(900));
  });
}

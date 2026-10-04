import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/use_cases/think_time_policy.dart';

void main() {
  Duration think(Duration remaining, [Duration increment = Duration.zero]) =>
      ThinkTimePolicy.of(remaining: remaining, increment: increment);

  test('sem relógio, a máquina pensa um segundo', () {
    expect(ThinkTimePolicy.of(), const Duration(seconds: 1));
  });

  test('com bastante tempo, o teto de 2 s', () {
    expect(think(const Duration(minutes: 5)), const Duration(seconds: 2));
  });

  test('uma fatia do que resta mais quase todo o incremento', () {
    expect(
      think(const Duration(seconds: 30), const Duration(seconds: 1)),
      const Duration(milliseconds: 1750),
    );
  });

  test('com pouco tempo, joga rápido e nunca gasta mais de um quarto', () {
    expect(
      think(const Duration(seconds: 3)),
      const Duration(milliseconds: 100),
    );
    expect(
      think(const Duration(milliseconds: 120)),
      const Duration(milliseconds: 30),
    );
  });

  test('sem tempo nenhum, não pensa', () {
    expect(think(Duration.zero), Duration.zero);
  });
}

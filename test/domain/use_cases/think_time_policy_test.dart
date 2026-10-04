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

  test('com menos de 10 s, joga rápido mesmo com incremento', () {
    const increment = Duration(seconds: 2);
    expect(
      think(const Duration(seconds: 9), increment),
      ThinkTimePolicy.lowTimeMax,
    );
    expect(
      think(const Duration(seconds: 11), increment),
      greaterThan(ThinkTimePolicy.lowTimeMax),
    );
  });

  group('tempo de pensar humano', () {
    const budget = Duration(seconds: 2);

    Duration human(double certainty, [double roll = 0.5]) =>
        ThinkTimePolicy.human(budget: budget, certainty: certainty, roll: roll);

    test('lance óbvio sai quase na hora', () {
      expect(human(0.95), ThinkTimePolicy.instant);
      expect(human(0.95, 0), const Duration(milliseconds: 210));
      expect(human(0.95, 1), const Duration(milliseconds: 390));
    });

    test('quanto mais dúvida, mais tempo', () {
      expect(human(0.8), lessThan(human(0.5)));
      expect(human(0.5), lessThan(human(0.2)));
      expect(human(0.8), greaterThan(ThinkTimePolicy.instant));
    });

    test('o sorteio varia o tempo de um lance para o outro', () {
      expect(human(0.4, 0.1), lessThan(human(0.4, 0.9)));
    });

    test('nunca passa do tempo disponível', () {
      for (final certainty in [0.0, 0.1, 0.5, 0.84, 0.99]) {
        for (final roll in [0.0, 0.5, 1.0]) {
          expect(human(certainty, roll), lessThanOrEqualTo(budget));
        }
      }
      expect(
        ThinkTimePolicy.human(
          budget: const Duration(milliseconds: 100),
          certainty: 0.99,
          roll: 1,
        ),
        const Duration(milliseconds: 100),
      );
    });

    test('sem tempo disponível, não pensa', () {
      expect(
        ThinkTimePolicy.human(budget: Duration.zero, certainty: 0.3, roll: 0.5),
        Duration.zero,
      );
    });
  });
}

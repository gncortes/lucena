import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/use_cases/step_clock.dart';

import '../../../testing/fakes/fake_now.dart';

/// T60: o cronômetro do passo conta para cima, sem limite.
void main() {
  final start = DateTime.utc(2026, 10, 9, 20);

  test('ao abrir o passo: zero', () {
    expect(StepClock.elapsed(startedAt: start, now: start), Duration.zero);
  });

  test('cresce com o tempo', () {
    final now = FakeNow(start)..advance(const Duration(seconds: 90));
    expect(
      StepClock.elapsed(startedAt: start, now: now()),
      const Duration(seconds: 90),
    );
  });

  test('relógio do aparelho voltou: nunca negativo', () {
    final now = FakeNow(start)..advance(const Duration(hours: -1));
    expect(StepClock.elapsed(startedAt: start, now: now()), Duration.zero);
  });

  test('depois de 10 minutos continua contando, sem efeito nenhum', () {
    final now = FakeNow(start)
      ..advance(const Duration(minutes: 10, seconds: 7));
    expect(
      StepClock.elapsed(startedAt: start, now: now()),
      const Duration(minutes: 10, seconds: 7),
    );
  });

  test('formato m:ss e, depois de uma hora, h:mm:ss', () {
    expect(StepClock.format(Duration.zero), '0:00');
    expect(StepClock.format(const Duration(seconds: 9)), '0:09');
    expect(
      StepClock.format(const Duration(minutes: 6, milliseconds: 999)),
      '6:00',
    );
    expect(StepClock.format(const Duration(minutes: 12, seconds: 5)), '12:05');
    expect(
      StepClock.format(const Duration(hours: 1, minutes: 2, seconds: 3)),
      '1:02:03',
    );
    expect(StepClock.format(const Duration(seconds: -5)), '0:00');
  });
}

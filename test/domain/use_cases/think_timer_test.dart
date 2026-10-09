import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/use_cases/think_timer.dart';

import '../../../testing/fakes/fake_now.dart';

void main() {
  final start = DateTime.utc(2026, 10, 8, 20);
  const five = Duration(minutes: 5);

  test('pensando: o tempo que falta', () {
    final now = FakeNow(start)..advance(const Duration(minutes: 2));
    expect(
      ThinkTimer.phase(startedAt: start, time: five, now: now()),
      const Thinking(Duration(minutes: 3)),
    );
  });

  test('no fim do tempo: acabou', () {
    final now = FakeNow(start)..advance(five);
    expect(
      ThinkTimer.phase(startedAt: start, time: five, now: now()),
      const ThinkExpired(),
    );
  });

  test('saiu do app e voltou: conta desde o começo', () {
    // O aluno saiu com 1 minuto e voltou 10 minutos depois.
    final now = FakeNow(start)..advance(const Duration(minutes: 11));
    expect(
      ThinkTimer.phase(startedAt: start, time: five, now: now()),
      const ThinkExpired(),
    );
  });

  test('relógio voltou: no máximo o tempo todo', () {
    final now = FakeNow(start)..advance(const Duration(hours: -1));
    expect(
      ThinkTimer.phase(startedAt: start, time: five, now: now()),
      const Thinking(five),
    );
  });
}

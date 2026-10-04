import 'package:dartchess/dartchess.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/clock.dart';
import 'package:lucena/domain/use_cases/clock_engine.dart';

void main() {
  final t0 = DateTime.utc(2026, 1, 1, 12);
  DateTime after(Duration elapsed) => t0.add(elapsed);

  const threeTwo = TimeControl(
    initial: Duration(minutes: 3),
    increment: Duration(seconds: 2),
  );
  const oneZero = TimeControl(initial: Duration(minutes: 1));
  const config = ClockConfig(white: threeTwo, black: oneZero);

  ClockState started() => ClockEngine.start(config, turn: Side.white, now: t0);

  test('no começo cada lado tem o seu tempo e corre o de quem joga', () {
    final clock = started();

    expect(clock.running, Side.white);
    expect(ClockEngine.remaining(clock, Side.white, t0), threeTwo.initial);
    expect(ClockEngine.remaining(clock, Side.black, t0), oneZero.initial);
  });

  test('só o relógio de quem está na vez desconta', () {
    final clock = started();
    final now = after(const Duration(seconds: 7));

    expect(
      ClockEngine.remaining(clock, Side.white, now),
      const Duration(minutes: 2, seconds: 53),
    );
    expect(ClockEngine.remaining(clock, Side.black, now), oneZero.initial);
  });

  test('incremento soma 2 s após o lance e a vez passa', () {
    final clock = ClockEngine.press(started(), t0);

    expect(clock.running, Side.black);
    expect(
      ClockEngine.remaining(clock, Side.white, t0),
      const Duration(minutes: 3, seconds: 2),
    );
  });

  test('o lance desconta o tempo gasto antes de somar o incremento', () {
    final now = after(const Duration(seconds: 10));
    final clock = ClockEngine.press(started(), now);

    expect(clock.white, const Duration(minutes: 2, seconds: 52));
    expect(clock.turnStartedAt, now);
  });

  test('lado sem incremento não ganha tempo ao jogar', () {
    final afterWhite = ClockEngine.press(started(), t0);
    final now = after(const Duration(seconds: 5));
    final afterBlack = ClockEngine.press(afterWhite, now);

    expect(afterBlack.black, const Duration(seconds: 55));
    expect(afterBlack.running, Side.white);
  });

  test('o tempo nunca fica negativo', () {
    final now = after(const Duration(hours: 1));

    expect(ClockEngine.remaining(started(), Side.white, now), Duration.zero);
  });

  test('a bandeira cai quando o tempo de quem joga acaba', () {
    final clock = started();

    expect(
      ClockEngine.flagged(clock, after(const Duration(seconds: 179))),
      isNull,
    );
    expect(
      ClockEngine.flagged(clock, after(const Duration(minutes: 3))),
      Side.white,
    );
  });

  test('o desconto vale mesmo depois de muito tempo sem olhar o relógio', () {
    // Como ao voltar do segundo plano: nenhuma chamada no meio do caminho.
    final clock = ClockEngine.press(started(), t0);
    final now = after(const Duration(seconds: 42));

    expect(
      ClockEngine.remaining(clock, Side.black, now),
      const Duration(seconds: 18),
    );
  });

  test('parar guarda o tempo de cada lado e nada mais desconta', () {
    final stopped = ClockEngine.stop(
      started(),
      after(const Duration(seconds: 30)),
    );
    final later = after(const Duration(hours: 2));

    expect(stopped.running, isNull);
    expect(
      ClockEngine.remaining(stopped, Side.white, later),
      const Duration(minutes: 2, seconds: 30),
    );
    expect(ClockEngine.flagged(stopped, later), isNull);
  });

  test('retomar volta a descontar a partir do instante da retomada', () {
    final stopped = ClockEngine.stop(
      started(),
      after(const Duration(seconds: 30)),
    );
    final resumedAt = after(const Duration(hours: 2));
    final resumed = ClockEngine.resume(
      stopped,
      turn: Side.white,
      now: resumedAt,
    );

    expect(
      ClockEngine.remaining(
        resumed,
        Side.white,
        resumedAt.add(const Duration(seconds: 10)),
      ),
      const Duration(minutes: 2, seconds: 20),
    );
  });

  test('relógio do aparelho atrasado não devolve tempo', () {
    final earlier = t0.subtract(const Duration(minutes: 5));

    expect(
      ClockEngine.remaining(started(), Side.white, earlier),
      threeTwo.initial,
    );
  });

  test('o tempo é lido e escrito como segundos+incremento', () {
    expect(TimeControl.tryParse('180+2'), threeTwo);
    expect(threeTwo.code, '180+2');
    expect(
      TimeControl.tryParse('5+0'),
      const TimeControl(initial: Duration(seconds: 5)),
    );
    expect(TimeControl.tryParse('0+5'), isNull);
    expect(TimeControl.tryParse('3 2'), isNull);
    expect(TimeControl.tryParse(null), isNull);
  });
}

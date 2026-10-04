import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/use_cases/clock_format.dart';

void main() {
  String format({int h = 0, int m = 0, int s = 0, int ms = 0}) =>
      ClockFormat.format(
        Duration(hours: h, minutes: m, seconds: s, milliseconds: ms),
      );

  test('minutos e segundos no formato m:ss', () {
    expect(format(m: 5), '5:00');
    expect(format(m: 3, s: 2), '3:02');
    expect(format(s: 59), '0:59');
    expect(format(m: 15, s: 10), '15:10');
  });

  test('a partir de uma hora, h:mm:ss', () {
    expect(format(h: 1, m: 5), '1:05:00');
    expect(format(h: 2, s: 7), '2:00:07');
  });

  test('abaixo de 10 s aparecem os décimos', () {
    expect(format(s: 9, ms: 940), '0:09.9');
    expect(format(s: 5), '0:05.0');
    expect(format(ms: 250), '0:00.2');
    expect(format(), '0:00.0');
  });

  test('com 10 s ou mais não há décimos', () {
    expect(format(s: 10), '0:10');
    expect(format(s: 10, ms: 900), '0:10');
  });

  test('o tempo mostrado arredonda para baixo', () {
    expect(format(m: 4, s: 59, ms: 999), '4:59');
    expect(
      ClockFormat.displayed(const Duration(seconds: 12, milliseconds: 345)),
      const Duration(seconds: 12),
    );
    expect(
      ClockFormat.displayed(const Duration(seconds: 3, milliseconds: 345)),
      const Duration(seconds: 3, milliseconds: 300),
    );
    expect(ClockFormat.displayed(const Duration(seconds: -1)), Duration.zero);
  });
}

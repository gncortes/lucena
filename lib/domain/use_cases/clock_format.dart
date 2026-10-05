import 'clock_engine.dart';

/// Como o tempo do relógio é escrito.
abstract final class ClockFormat {
  /// `1:05:00` com horas, `5:00` normalmente e `0:09.4` (com décimos) quando
  /// falta pouco.
  static String format(Duration time) {
    final shown = displayed(time);
    final minutes = shown.inMinutes.remainder(60);
    final seconds = _twoDigits(shown.inSeconds.remainder(60));
    if (shown.inHours > 0) {
      return '${shown.inHours}:${_twoDigits(minutes)}:$seconds';
    }
    if (shown < ClockEngine.lowTime) {
      final tenths = shown.inMilliseconds.remainder(1000) ~/ 100;
      return '$minutes:$seconds.$tenths';
    }
    return '$minutes:$seconds';
  }

  /// O tempo arredondado para baixo até a menor unidade que aparece na tela:
  /// décimos quando falta pouco, segundos no resto. Dois tempos com o mesmo
  /// valor aqui aparecem iguais.
  static Duration displayed(Duration time) {
    if (time.isNegative) return Duration.zero;
    final unit = time < ClockEngine.lowTime ? 100 : 1000;
    return Duration(milliseconds: time.inMilliseconds ~/ unit * unit);
  }

  static String _twoDigits(int value) => value.toString().padLeft(2, '0');
}

/// O tempo de um speedrun (ou de uma etapa), com as unidades à vista para
/// não ser confundido com horas e minutos: `13.8 s`, `1 min 15.8 s`,
/// `1 h 02 min 15 s`.
abstract final class RunTimeFormat {
  /// [decimal] é o separador dos décimos no idioma da tela.
  static String format(Duration time, {String decimal = '.'}) {
    if (time.isNegative) time = Duration.zero;
    final tenths = time.inMilliseconds.remainder(1000) ~/ 100;
    final seconds = time.inSeconds.remainder(60);
    final minutes = time.inMinutes.remainder(60);
    String two(int value) => value.toString().padLeft(2, '0');
    if (time.inHours > 0) {
      return '${time.inHours} h ${two(minutes)} min ${two(seconds)} s';
    }
    if (minutes > 0) return '$minutes min ${two(seconds)}$decimal$tenths s';
    return '$seconds$decimal$tenths s';
  }

  /// O tempo como num relógio de xadrez: `0:13.8`, `3:25.0`, `1:02:15`.
  static String clock(Duration time, {String decimal = '.'}) {
    if (time.isNegative) time = Duration.zero;
    final tenths = time.inMilliseconds.remainder(1000) ~/ 100;
    final seconds = time.inSeconds.remainder(60).toString().padLeft(2, '0');
    final minutes = time.inMinutes.remainder(60);
    if (time.inHours > 0) {
      return '${time.inHours}:${minutes.toString().padLeft(2, '0')}:$seconds';
    }
    return '$minutes:$seconds$decimal$tenths';
  }

  /// A diferença para o recorde, com sinal, em segundos com décimos: `+3.2`
  /// ou `-64.0`.
  static String difference(Duration difference, {String decimal = '.'}) {
    final sign = difference.isNegative ? '-' : '+';
    final abs = difference.abs();
    final tenths = abs.inMilliseconds.remainder(1000) ~/ 100;
    return '$sign${abs.inSeconds}$decimal$tenths';
  }
}

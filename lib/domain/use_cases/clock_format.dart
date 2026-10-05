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

/// Como o tempo de um speedrun é escrito: sempre com décimos (`4:05.3`,
/// `1:02:03.4`), para dois tempos próximos não parecerem iguais.
abstract final class RunTimeFormat {
  static String format(Duration time) {
    if (time.isNegative) time = Duration.zero;
    final tenths = time.inMilliseconds.remainder(1000) ~/ 100;
    final seconds = time.inSeconds.remainder(60).toString().padLeft(2, '0');
    final minutes = time.inMinutes.remainder(60);
    if (time.inHours > 0) {
      return '${time.inHours}:${minutes.toString().padLeft(2, '0')}:'
          '$seconds.$tenths';
    }
    return '$minutes:$seconds.$tenths';
  }

  /// A diferença para o recorde, com sinal: `+3.2` ou `-1:04.0` (segundos
  /// com décimos; minutos quando passa de um).
  static String difference(Duration difference) {
    final sign = difference.isNegative ? '-' : '+';
    final abs = difference.abs();
    final tenths = abs.inMilliseconds.remainder(1000) ~/ 100;
    if (abs.inMinutes == 0) return '$sign${abs.inSeconds}.$tenths';
    return '$sign${format(abs)}';
  }
}

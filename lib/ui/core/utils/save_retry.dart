import 'dart:async';

/// Nova tentativa automática de uma gravação que falhou (H-TRE-17).
///
/// A espera dobra a cada falha (1 s, 2 s, 4 s...) e, passadas [maxAttempts]
/// tentativas, o view model para de insistir: o erro fica na tela e o botão de
/// tentar de novo continua valendo. Uma gravação bem-sucedida chama [reset].
final class SaveRetry {
  SaveRetry({
    this.maxAttempts = 5,
    this.firstDelay = const Duration(seconds: 1),
    this.maxDelay = const Duration(seconds: 30),
  });

  final int maxAttempts;
  final Duration firstDelay, maxDelay;
  Timer? _timer;
  int _attempts = 0;

  /// Agenda [action] e devolve `false` quando o limite já foi atingido.
  bool schedule(void Function() action) {
    _timer?.cancel();
    if (_attempts >= maxAttempts) return false;
    var delay = firstDelay * (1 << _attempts);
    if (delay > maxDelay) delay = maxDelay;
    _attempts++;
    _timer = Timer(delay, action);
    return true;
  }

  /// Gravou: a próxima falha volta a começar da espera curta.
  void reset() {
    _timer?.cancel();
    _attempts = 0;
  }

  void cancel() => _timer?.cancel();
}

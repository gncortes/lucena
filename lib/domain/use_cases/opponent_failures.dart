/// As tentativas do app de conseguir o lance do adversário (H-PAR-18).
///
/// A partir da primeira falha o relógio de ninguém corre. O app tenta
/// [maxAttempts] vezes, esperando [interval] entre elas, sem dizer nada; na
/// última falha a pessoa é avisada. Lance que não vem (`null`) conta como falha.
class OpponentFailures {
  /// Quantas falhas seguidas até avisar.
  static const maxAttempts = 3;

  /// A espera entre uma tentativa e a seguinte.
  static const interval = Duration(seconds: 2);

  int _count = 0;
  DateTime? _lastAt;

  /// Houve falha desde a última resposta boa (o relógio fica parado).
  bool get failing => _count > 0;

  /// As tentativas acabaram: é hora de avisar.
  bool get exhausted => _count >= maxAttempts;

  /// Conta uma falha em [now].
  void record(DateTime now) {
    _count++;
    _lastAt = now;
  }

  /// Já dá para tentar de novo em [now]: sobrou tentativa e passou o
  /// intervalo da última falha.
  bool canTry(DateTime now) {
    if (exhausted) return false;
    final last = _lastAt;
    return last == null || now.difference(last) >= interval;
  }

  /// A resposta veio, ou a pessoa pediu para tentar de novo: recomeça.
  void reset() {
    _count = 0;
    _lastAt = null;
  }
}

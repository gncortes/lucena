/// Relógio do app. Todo código que precisa da hora recebe um [Now],
/// para os testes controlarem o tempo.
abstract interface class Now {
  DateTime call();
}

/// Relógio do sistema: o único lugar que chama `DateTime.now()`.
final class SystemNow implements Now {
  const SystemNow();

  @override
  DateTime call() => DateTime.now();
}

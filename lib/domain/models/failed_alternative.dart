/// Uma alternativa que falha no estado correto da lição (T70, crit. 7c):
/// só o lance numerado com `?` (`1.Re3?`), em SAN com as letras inglesas.
class FailedAlternative {
  const FailedAlternative({
    required this.uci,
    required this.label,
    this.seen = false,
  });

  final String uci;
  final String label;

  /// O aluno já abriu este lance (o erro dele ou um ramo visitado): a lista
  /// mostra "Já visto".
  final bool seen;

  FailedAlternative copyWith({bool? seen}) =>
      FailedAlternative(uci: uci, label: label, seen: seen ?? this.seen);

  @override
  bool operator ==(Object other) =>
      other is FailedAlternative &&
      other.uci == uci &&
      other.label == label &&
      other.seen == seen;

  @override
  int get hashCode => Object.hash(uci, label, seen);
}

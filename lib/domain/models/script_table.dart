import 'wdl.dart';

/// A tabela de um roteiro com mais de 3 peças (T76): o resultado de cada
/// posição que a lição pode alcançar e, nas posições em que a máquina pode
/// jogar, o lance dela. Gerada da tablebase do Lichess por
/// `tools/script_tables.py`; a chave é o FEN sem os relógios.
class ScriptTable {
  const ScriptTable(this._positions);

  static const empty = ScriptTable({});

  /// O asset: `{"versao": 1, "posicoes": {"<fen>": "w" | "d" | "l" [uci]}}`.
  factory ScriptTable.fromJson(Map<String, dynamic> json) => ScriptTable({
    for (final MapEntry(:key, :value)
        in (json['posicoes'] as Map? ?? const {}).entries)
      key as String: value as String,
  });

  final Map<String, String> _positions;

  int get length => _positions.length;

  /// As posições da tabela (chaves de [keyOf]).
  Iterable<String> get keys => _positions.keys;

  /// Peças, vez, roque e en passant: o FEN sem os relógios.
  static String keyOf(String fen) => fen.split(' ').take(4).join(' ');

  /// O resultado de [fen] para quem joga; nulo fora da tabela.
  Wdl? wdl(String fen) {
    final value = _positions[keyOf(fen)];
    return value == null ? null : Wdl.parse(value.substring(0, 1));
  }

  /// O melhor lance (UCI) de [fen]; nulo se a tabela não o guarda.
  String? best(String fen) {
    final value = _positions[keyOf(fen)];
    if (value == null || value.length < 3) return null;
    return value.substring(2);
  }
}

import 'package:dartchess/dartchess.dart';
import 'package:lucena/domain/models/script_table.dart';
import 'package:lucena/domain/models/wdl.dart';
import 'package:lucena/domain/use_cases/position_judge.dart';

/// Um juiz de mentira (T76): responde [results] (chave: FEN sem relógios) e,
/// fora deles, [fallback]. Guarda em [asked] toda posição perguntada.
class FakePositionJudge implements PositionJudge {
  FakePositionJudge({Map<String, Wdl>? results, this.fallback})
    : results = {
        for (final MapEntry(:key, :value) in (results ?? const {}).entries)
          ScriptTable.keyOf(key): value,
      };

  final Map<String, Wdl> results;
  final Wdl? fallback;
  final asked = <String>[];

  @override
  Future<Wdl?> evaluate(Position position) async {
    final key = ScriptTable.keyOf(position.fen);
    asked.add(key);
    return results[key] ?? fallback;
  }
}

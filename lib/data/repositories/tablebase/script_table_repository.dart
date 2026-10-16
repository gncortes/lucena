import 'dart:convert';

import '../../../domain/models/script_table.dart';
import '../../services/asset_service.dart';

/// As tabelas dos roteiros com mais de 3 peças (T76).
abstract class ScriptTableRepository {
  /// A tabela do roteiro [scriptPath]; vazia se o roteiro não tem tabela.
  Future<ScriptTable> table(String scriptPath);
}

/// Lê `assets/tablebase/roteiros/<lição>.<parte>.json`, gerado por
/// `tools/script_tables.py`.
class AssetScriptTableRepository implements ScriptTableRepository {
  AssetScriptTableRepository(this._assets);

  static const scriptsDir = 'assets/lessons/roteiros/';
  static const tablesDir = 'assets/tablebase/roteiros/';

  final AssetService _assets;
  final _cache = <String, ScriptTable>{};

  /// O asset da tabela do roteiro [scriptPath]:
  /// `assets/lessons/roteiros/pawns.distantOpposition/edge.json` →
  /// `assets/tablebase/roteiros/pawns.distantOpposition.edge.json`.
  static String pathFor(String scriptPath) {
    final relative = scriptPath.startsWith(scriptsDir)
        ? scriptPath.substring(scriptsDir.length)
        : scriptPath.split('/').last;
    return '$tablesDir${relative.replaceAll('/', '.')}';
  }

  @override
  Future<ScriptTable> table(String scriptPath) async {
    final cached = _cache[scriptPath];
    if (cached != null) return cached;
    ScriptTable table;
    try {
      final raw = await _assets.loadString(pathFor(scriptPath));
      table = ScriptTable.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } on Object {
      // Roteiro sem tabela (até 3 peças, ou só tarefa/mate).
      table = ScriptTable.empty;
    }
    return _cache[scriptPath] = table;
  }
}

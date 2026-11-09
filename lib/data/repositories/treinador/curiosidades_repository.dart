import 'dart:convert';

import '../../../domain/models/treinador/curiosidade.dart';
import '../../services/asset_service.dart';

/// As curiosidades que o Viktor conta enquanto a partida é analisada.
abstract interface class CuriosidadesRepository {
  Future<List<Curiosidade>> todas();
}

/// Lidas de `assets/treinador/curiosidades.json` (uma vez por sessão).
final class AssetCuriosidadesRepository implements CuriosidadesRepository {
  AssetCuriosidadesRepository(this._assets);

  static const caminho = 'assets/treinador/curiosidades.json';

  final AssetService _assets;
  Future<List<Curiosidade>>? _cache;

  @override
  Future<List<Curiosidade>> todas() => _cache ??= _ler().catchError((Object e) {
    _cache = null;
    throw e;
  });

  Future<List<Curiosidade>> _ler() async {
    final json = jsonDecode(await _assets.loadString(caminho));
    return [
      if (json is List)
        for (final item in json) ?Curiosidade.fromJson(item),
    ];
  }
}

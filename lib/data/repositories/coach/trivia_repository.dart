import 'dart:convert';

import '../../../domain/models/coach/trivia.dart';
import '../../services/asset_service.dart';

/// As curiosidades que o Viktor conta enquanto a partida é analisada.
abstract interface class TriviaRepository {
  Future<List<Trivia>> all();
}

/// Lidas de `assets/treinador/curiosidades.json` (uma vez por sessão).
final class AssetTriviaRepository implements TriviaRepository {
  AssetTriviaRepository(this._assets);

  static const path = 'assets/treinador/curiosidades.json';

  final AssetService _assets;
  Future<List<Trivia>>? _cache;

  @override
  Future<List<Trivia>> all() => _cache ??= _read().catchError((Object e) {
    _cache = null;
    throw e;
  });

  Future<List<Trivia>> _read() async {
    final json = jsonDecode(await _assets.loadString(path));
    return [
      if (json is List)
        for (final item in json) ?Trivia.fromJson(item),
    ];
  }
}

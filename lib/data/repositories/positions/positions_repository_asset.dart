import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../../domain/models/endgame_position.dart';
import '../../services/asset_service.dart';
import 'positions_repository.dart';

/// Catálogo lido de `assets/positions/positions.json`, gerado por
/// `tools/import_positions.py`. O arquivo só é lido na primeira consulta, fora
/// da linha da interface, e fica na memória depois disso.
class AssetPositionsRepository implements PositionsRepository {
  AssetPositionsRepository(this._assets);

  static const path = 'assets/positions/positions.json';

  final AssetService _assets;
  Future<_Catalog>? _catalog;

  Future<_Catalog> _load() => _catalog ??= () async {
    final text = await _assets.loadString(path);
    return compute(_Catalog.parse, text);
  }();

  @override
  Future<List<CatalogCategory>> catalog() async => (await _load()).categories;

  @override
  Future<List<EndgamePosition>> bySubcategory(String subcategory) async =>
      (await _load()).bySubcategory[subcategory] ?? const [];

  @override
  Future<EndgamePosition?> byId(String id) async => (await _load()).byId[id];
}

class _Catalog {
  _Catalog(this.categories, this.bySubcategory, this.byId);

  final List<CatalogCategory> categories;
  final Map<String, List<EndgamePosition>> bySubcategory;
  final Map<String, EndgamePosition> byId;

  static _Catalog parse(String text) {
    final json = jsonDecode(text) as Map<String, dynamic>;
    final bySubcategory = <String, List<EndgamePosition>>{};
    final byId = <String, EndgamePosition>{};
    // Categoria -> subcategorias, na ordem em que aparecem no arquivo.
    final order = <String, List<String>>{};
    for (final item
        in (json['positions'] as List).cast<Map<String, dynamic>>()) {
      final position = EndgamePosition(
        id: item['id'] as String,
        category: item['category'] as String,
        subcategory: item['subcategory'] as String,
        fen: item['fen'] as String,
        goal: PositionGoal.fromCode(item['goal'] as String)!,
        mateIn: item['mateIn'] as int?,
        verified: item['verified'] as bool? ?? false,
      );
      byId[position.id] = position;
      final list = bySubcategory.putIfAbsent(position.subcategory, () {
        order
            .putIfAbsent(position.category, () => [])
            .add(position.subcategory);
        return [];
      });
      list.add(position);
    }
    final categories = [
      for (final MapEntry(key: category, value: subs) in order.entries)
        CatalogCategory(
          key: category,
          subcategories: [
            for (final sub in subs)
              CatalogSubcategory(
                key: sub,
                category: category,
                winCount: bySubcategory[sub]!
                    .where((p) => p.goal == PositionGoal.win)
                    .length,
                drawCount: bySubcategory[sub]!
                    .where((p) => p.goal == PositionGoal.draw)
                    .length,
              ),
          ],
        ),
    ];
    return _Catalog(categories, bySubcategory, byId);
  }
}

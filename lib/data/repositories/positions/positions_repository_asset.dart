import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../../domain/models/endgame_position.dart';
import '../../services/asset_service.dart';
import 'positions_repository.dart';

/// Catálogo lido de `assets/positions/positions.json` (gerado por
/// `tools/import_positions.py` e ampliado por `tools/lesson_positions.py`),
/// com as ligações às lições de `assets/positions/lesson_links.json`. Os
/// arquivos só são lidos na primeira consulta, fora da linha da interface, e
/// ficam na memória depois disso.
class AssetPositionsRepository implements PositionsRepository {
  AssetPositionsRepository(this._assets);

  static const path = 'assets/positions/positions.json';
  static const linksPath = 'assets/positions/lesson_links.json';

  final AssetService _assets;
  Future<_Catalog>? _catalog;

  Future<_Catalog> _load() => _catalog ??= () async {
    final text = await _assets.loadString(path);
    final links = await _assets.loadString(linksPath);
    return compute(_Catalog.parse, (text, links));
  }();

  @override
  Future<List<CatalogCategory>> catalog() async => (await _load()).categories;

  @override
  Future<List<EndgamePosition>> bySubcategory(String subcategory) async =>
      (await _load()).bySubcategory[subcategory] ?? const [];

  @override
  Future<EndgamePosition?> byId(String id) async => (await _load()).byId[id];

  @override
  Future<List<String>> lessonsWithLinks() async => (await _load()).lessons;
}

class _Catalog {
  _Catalog(this.categories, this.bySubcategory, this.byId, this.lessons);

  final List<CatalogCategory> categories;
  final Map<String, List<EndgamePosition>> bySubcategory;
  final Map<String, EndgamePosition> byId;
  final List<String> lessons;

  static _Catalog parse((String, String) files) {
    final (text, linksText) = files;
    final json = jsonDecode(text) as Map<String, dynamic>;
    final linksJson = jsonDecode(linksText) as Map<String, dynamic>;
    final links = <String, List<LessonLink>>{
      for (final MapEntry(:key, :value)
          in (linksJson['links'] as Map<String, dynamic>).entries)
        key: [
          for (final link in (value as List).cast<Map<String, dynamic>>())
            if (LessonRelation.fromCode(link['relation'] as String?)
                case final relation?)
              LessonLink(
                lessonId: link['lesson'] as String,
                relation: relation,
                ply: link['ply'] as int? ?? 0,
              ),
        ],
    };
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
        section: item['section'] as String?,
        difficulty: item['difficulty'] as int?,
        links: links[item['id']] ?? const [],
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
                lessonLinks: [
                  for (final p in bySubcategory[sub]!)
                    if (p.links.isNotEmpty) p,
                ],
              ),
          ],
        ),
    ];
    final lessons = (linksJson['lessons'] as List? ?? const []).cast<String>();
    return _Catalog(categories, bySubcategory, byId, lessons);
  }
}

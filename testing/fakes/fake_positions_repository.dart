import 'package:lucena/data/repositories/positions/positions_repository.dart';
import 'package:lucena/domain/models/endgame_position.dart';

/// Catálogo pequeno, na memória.
class FakePositionsRepository implements PositionsRepository {
  FakePositionsRepository([List<EndgamePosition>? positions])
    : positions = positions ?? samplePositions;

  final List<EndgamePosition> positions;

  @override
  Future<List<CatalogCategory>> catalog() async {
    final order = <String, List<String>>{};
    for (final p in positions) {
      final subs = order.putIfAbsent(p.category, () => []);
      if (!subs.contains(p.subcategory)) subs.add(p.subcategory);
    }
    return [
      for (final MapEntry(key: category, value: subs) in order.entries)
        CatalogCategory(
          key: category,
          subcategories: [
            for (final sub in subs)
              CatalogSubcategory(
                key: sub,
                category: category,
                winCount: positions
                    .where(
                      (p) => p.subcategory == sub && p.goal == PositionGoal.win,
                    )
                    .length,
                drawCount: positions
                    .where(
                      (p) =>
                          p.subcategory == sub && p.goal == PositionGoal.draw,
                    )
                    .length,
              ),
          ],
        ),
    ];
  }

  @override
  Future<List<EndgamePosition>> bySubcategory(String subcategory) async =>
      positions.where((p) => p.subcategory == subcategory).toList();

  @override
  Future<EndgamePosition?> byId(String id) async {
    for (final p in positions) {
      if (p.id == id) return p;
    }
    return null;
  }
}

/// Posições de exemplo: duas categorias, três subcategorias, os dois objetivos.
const samplePositions = [
  EndgamePosition(
    id: 'basic.queen.0001',
    category: 'basic',
    subcategory: 'queen',
    fen: '8/3k4/8/8/8/8/2K5/2Q5 w - - 0 1',
    goal: PositionGoal.win,
    mateIn: 8,
    verified: true,
  ),
  EndgamePosition(
    id: 'basic.rook.0001',
    category: 'basic',
    subcategory: 'rook',
    fen: '8/8/3k4/8/8/4K3/8/7R w - - 0 1',
    goal: PositionGoal.win,
    verified: true,
  ),
  EndgamePosition(
    id: 'rookPawn.rookPawnVsRook.0001',
    category: 'rookPawn',
    subcategory: 'rookPawnVsRook',
    fen: '8/8/8/4k3/8/r7/4P3/4K2R b - - 0 1',
    goal: PositionGoal.draw,
    verified: true,
  ),
  EndgamePosition(
    id: 'rookPawn.rookPawnVsRook.0002',
    category: 'rookPawn',
    subcategory: 'rookPawnVsRook',
    fen: '1K1k4/1P6/8/8/8/8/r7/2R5 w - - 0 1',
    goal: PositionGoal.win,
    verified: true,
  ),
];

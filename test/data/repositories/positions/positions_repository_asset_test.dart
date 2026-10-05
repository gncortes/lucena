import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/data/repositories/positions/positions_repository_asset.dart';
import 'package:lucena/data/services/asset_service.dart';
import 'package:lucena/domain/models/endgame_position.dart';
import 'package:lucena/domain/use_cases/position_validation.dart';

/// Lê os arquivos do próprio projeto, como o app lê os dele.
class _ProjectBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async {
    final bytes = await File(key).readAsBytes();
    return ByteData.sublistView(bytes);
  }
}

void main() {
  late AssetPositionsRepository repository;

  setUp(() {
    repository = AssetPositionsRepository(AssetService(_ProjectBundle()));
  });

  test('o catálogo do app tem as categorias dos finais de iniciante', () async {
    final catalog = await repository.catalog();

    // Os mates de dois bispos e de bispo e cavalo entraram pelo speedrun.
    expect(catalog.map((c) => c.key), [
      'basic',
      'pawn',
      'bishop',
      'knightBishop',
      'rookPawn',
      'queen',
    ]);
    final total = catalog.fold(0, (sum, c) => sum + c.count(GoalFilter.all));
    expect(total, inInclusiveRange(40, 60));
  });

  test('toda posição do catálogo é jogável e foi conferida', () async {
    final catalog = await repository.catalog();
    for (final category in catalog) {
      for (final sub in category.subcategories) {
        for (final position in await repository.bySubcategory(sub.key)) {
          final check = PositionValidation.check(position.fen);
          expect(check.problem, isNull, reason: position.id);
          expect(position.verified, isTrue, reason: position.id);
        }
      }
    }
  });

  test('as contagens por objetivo batem com as posições', () async {
    final catalog = await repository.catalog();
    final sub = catalog
        .expand((c) => c.subcategories)
        .firstWhere((s) => s.key == 'pawnVsKing');
    final positions = await repository.bySubcategory('pawnVsKing');

    expect(
      sub.winCount,
      positions.where((p) => p.goal == PositionGoal.win).length,
    );
    expect(
      sub.drawCount,
      positions.where((p) => p.goal == PositionGoal.draw).length,
    );
    expect(sub.drawCount, greaterThan(0));
  });

  test('busca pelo id e informa o mate quando a fonte informa', () async {
    final position = await repository.byId('basic.queen.0001');

    expect(position?.fen, '8/3k4/8/8/8/8/2K5/2Q5 w - - 0 1');
    expect(position?.goal, PositionGoal.win);
    expect(position?.mateIn, 8);
    expect(position?.number, 1);
    expect(await repository.byId('nao.existe.0001'), isNull);
  });
}

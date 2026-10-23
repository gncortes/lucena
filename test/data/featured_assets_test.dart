import 'dart:convert';
import 'dart:io';

import 'package:dartchess/dartchess.dart' hide File;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/data/repositories/featured/featured_repository_asset.dart';
import 'package:lucena/data/services/asset_service.dart';
import 'package:lucena/domain/models/featured.dart';
import 'package:lucena/domain/use_cases/game_rules.dart';

class _FileBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async {
    final bytes = await File(key).readAsBytes();
    return ByteData.sublistView(bytes);
  }
}

void main() {
  late FeaturedCatalog catalog;

  setUpAll(() async {
    catalog = await AssetFeaturedRepository(AssetService(_FileBundle()))
        .catalog();
  });

  test('o arquivo carrega e tem finais e torneios', () {
    expect(catalog.finals, isNotEmpty);
    expect(catalog.tournaments, isNotEmpty);
  });

  test('ids únicos e torneios existentes', () {
    final ids = [for (final each in catalog.finals) each.id];
    expect(ids.toSet(), hasLength(ids.length));
    final tournaments = [for (final each in catalog.tournaments) each.id];
    expect(tournaments.toSet(), hasLength(tournaments.length));
    for (final each in catalog.finals) {
      final id = each.tournamentId;
      if (id != null) {
        expect(catalog.tournament(id), isNotNull, reason: '${each.id}: $id');
      }
    }
  });

  test('toda posição é legal, não terminou e é a vez de quem joga', () {
    for (final each in catalog.finals) {
      final position = GameRules.fromFen(each.fen);
      expect(position, isNotNull, reason: each.id);
      expect(position!.isGameOver, isFalse, reason: each.id);
      expect(position.turn, each.userSide, reason: each.id);
    }
  });

  test('Ache o lance tem solução legal; jogar não precisa de solução', () {
    for (final each in catalog.finals) {
      if (!each.isFindMove) continue;
      expect(each.solutions, isNotEmpty, reason: each.id);
      final position = GameRules.fromFen(each.fen)!;
      for (final uci in each.solutions) {
        final move = Move.parse(uci);
        expect(move, isNotNull, reason: '${each.id}: $uci');
        expect(position.isLegal(move!), isTrue, reason: '${each.id}: $uci');
      }
    }
  });

  test('resultado é um dos três e há textos em português e inglês', () {
    for (final each in catalog.finals) {
      final result = each.result;
      if (result != null) {
        expect(['1-0', '0-1', '1/2-1/2'], contains(result), reason: each.id);
      }
      for (final text in [each.title, each.hook]) {
        expect(text.values['pt'], isNotEmpty, reason: each.id);
        expect(text.values['en'], isNotEmpty, reason: each.id);
      }
      expect(each.suggested, isNotNull);
    }
    for (final each in catalog.tournaments) {
      expect(each.summary.values['pt'], isNotEmpty, reason: each.id);
      expect(each.summary.values['en'], isNotEmpty, reason: each.id);
    }
  });

  test('o JSON é válido e declara a versão', () {
    final json = jsonDecode(
      File(AssetFeaturedRepository.path).readAsStringSync(),
    ) as Map<String, dynamic>;
    expect(json['version'], 1);
  });

  test('o catálogo embutido não traz torneio de exemplo "ao vivo"', () {
    expect(
      catalog.tournaments.where((each) => each.isOngoing(DateTime(2031, 1, 1))),
      isEmpty,
    );
    final raw = File(AssetFeaturedRepository.path).readAsStringSync();
    expect(raw, isNot(contains('"live"')));
    expect(raw, isNot(contains('Norway Chess 2026')));
  });

  test('Ache o lance com só o rei traz dica própria', () {
    for (final each in catalog.finals) {
      if (!each.isFindMove) continue;
      final board = GameRules.fromFen(each.fen)!.board;
      if (board.bySide(each.userSide).size == 1) {
        expect(each.hint.isEmpty, isFalse, reason: each.id);
      }
    }
  });
}

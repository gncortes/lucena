import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/data/repositories/journey/journey_repository_asset.dart';
import 'package:lucena/data/repositories/positions/positions_repository_asset.dart';
import 'package:lucena/data/services/asset_service.dart';
import 'package:lucena/domain/models/game_setup.dart';
import 'package:lucena/domain/models/maia_level.dart';
import 'package:lucena/domain/models/speedrun.dart';

/// Lê os arquivos do próprio projeto, como o app lê os dele.
class _ProjectBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async {
    final bytes = await File(key).readAsBytes();
    return ByteData.sublistView(bytes);
  }
}

void main() {
  late AssetJourneyRepository repository;

  setUp(() {
    final assets = AssetService(_ProjectBundle());
    repository = AssetJourneyRepository(
      assets,
      AssetPositionsRepository(assets),
    );
  });

  test('a escada vai do Maia 1000 ao 2600 e termina no Stockfish', () async {
    final ladder = await repository.ladder();

    expect(ladder.map((rung) => rung.id), [
      for (final level in MaiaLevels.all) '$level',
      'stockfish',
    ]);
    for (final rung in ladder.take(ladder.length - 1)) {
      expect(rung.opponent.kind, OpponentKind.maia);
      expect('${rung.opponent.level}', rung.id);
    }
    expect(ladder.last.opponent.kind, OpponentKind.stockfish);
  });

  test(
    'todo degrau tem desafios, com ids únicos e posições do catálogo',
    () async {
      final ladder = await repository.ladder();
      final ids = <String>{};
      for (final rung in ladder) {
        expect(rung.challenges, isNotEmpty, reason: rung.id);
        for (final challenge in rung.challenges) {
          expect(ids.add(challenge.id), isTrue, reason: challenge.id);
          expect(challenge.opponent, rung.opponent);
          expect(challenge.time, isNull);
        }
      }
    },
  );

  test('o degrau do iniciante tem mates básicos e rei e peão', () async {
    final first = (await repository.ladder()).first;
    final subcategories = {
      for (final challenge in first.challenges) challenge.position.subcategory,
    };

    expect(
      subcategories,
      containsAll(['queen', 'rook', 'twoRooks', 'pawnVsKing']),
    );
  });

  test('speedrun de degrau: os desafios do degrau, com o ritmo dele', () async {
    final ladder = await repository.ladder();
    final speedruns = await repository.speedruns();
    final rungRuns = speedruns.where((s) => s.kind == SpeedrunKind.rung);

    expect(rungRuns, hasLength(ladder.length));
    for (final speedrun in rungRuns) {
      final rung = ladder.firstWhere((rung) => rung.id == speedrun.rungId);
      expect(
        speedrun.stages.map((stage) => stage.position.id),
        rung.challenges.map((challenge) => challenge.position.id),
      );
      expect(speedrun.stages.every((s) => s.time == speedrun.time), isTrue);
    }
  });

  test('speedrun de final: a mesma posição contra cada degrau', () async {
    final ladder = await repository.ladder();
    final endings = (await repository.speedruns()).where(
      (s) => s.kind == SpeedrunKind.ending,
    );

    expect(endings, isNotEmpty);
    for (final speedrun in endings) {
      expect(speedrun.stages, hasLength(ladder.length));
      expect(
        speedrun.stages.map((stage) => stage.opponent),
        ladder.map((rung) => rung.opponent),
      );
      expect(speedrun.stages.map((stage) => stage.position.id).toSet(), {
        speedrun.positionId,
      });
    }
  });

  test('ids de speedrun e de etapa são únicos', () async {
    final speedruns = await repository.speedruns();
    final ids = speedruns.map((s) => s.id).toList();
    expect(ids.toSet(), hasLength(ids.length));
    final stages = [
      for (final speedrun in speedruns)
        for (final stage in speedrun.stages) stage.id,
    ];
    expect(stages.toSet(), hasLength(stages.length));
  });
}

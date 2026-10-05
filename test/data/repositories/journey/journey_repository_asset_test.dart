import 'dart:convert';
import 'dart:io' as io;

import 'package:dartchess/dartchess.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/data/repositories/journey/journey_repository_asset.dart';
import 'package:lucena/data/repositories/positions/positions_repository_asset.dart';
import 'package:lucena/data/services/asset_service.dart';
import 'package:lucena/domain/models/game_setup.dart';
import 'package:lucena/domain/models/maia_level.dart';
import 'package:lucena/domain/models/speedrun.dart';
import 'package:lucena/domain/use_cases/position_validation.dart';
import 'package:lucena/domain/use_cases/subcategory_material.dart';

/// Lê os arquivos do próprio projeto, como o app lê os dele. Os de
/// [overrides] vêm do texto dado (para as modalidades de speedrun que o app
/// ainda sabe ler mas não leva).
class _ProjectBundle extends CachingAssetBundle {
  _ProjectBundle([this.overrides = const {}]);

  final Map<String, String> overrides;

  @override
  Future<ByteData> load(String key) async {
    final text = overrides[key];
    final bytes = text == null
        ? await io.File(key).readAsBytes()
        : Uint8List.fromList(utf8.encode(text));
    return ByteData.sublistView(bytes);
  }
}

// As modalidades fora do app: por degrau, exercícios e Jornada completa.
const _otherKinds = '''
{"speedruns": [
  {"id": "rung.1000", "kind": "rung", "rung": "1000", "time": "300+3"},
  {"id": "rung.stockfish", "kind": "rung", "rung": "stockfish", "time": "300+3"},
  {"id": "exercises.basic", "kind": "exercises", "time": "180+2", "stages": [
    {"position": "basic.queen.0001", "opponent": "maia:1200"},
    {"position": "basic.rook.0001", "opponent": "maia:1400"}
  ]},
  {"id": "full", "kind": "full", "time": "300+3"}
]}
''';

// Os mates: quem defende só tem o rei (ou a torre, contra a dama).
const _mates = {
  'rook',
  'queen',
  'twoBishopsVsKing',
  'queenVsRook',
  'knightBishopVsKing',
};

// As peças de [side], da mais forte para a mais fraca, como em
// SubcategoryMaterial: o rei só aparece quando não há mais nada.
List<Role> _roles(Board board, Side side) {
  const order = [Role.queen, Role.rook, Role.bishop, Role.knight, Role.pawn];
  final roles = [
    for (final square in board.bySide(side).squares)
      if (board.roleAt(square) case final role? when role != Role.king) role,
  ]..sort((a, b) => order.indexOf(a).compareTo(order.indexOf(b)));
  return roles.isEmpty ? const [Role.king] : roles;
}

void main() {
  late AssetJourneyRepository repository;

  AssetJourneyRepository build([Map<String, String> overrides = const {}]) {
    final assets = AssetService(_ProjectBundle(overrides));
    return AssetJourneyRepository(assets, AssetPositionsRepository(assets));
  }

  setUp(() => repository = build());

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

  test('o app leva só speedruns de final: nove, do mate de torre ao de bispo '
      'e cavalo', () async {
    final speedruns = await repository.speedruns();

    expect(speedruns.map((s) => s.kind).toSet(), {SpeedrunKind.ending});
    expect(speedruns.map((s) => s.stages.first.position.subcategory), [
      'rook',
      'queen',
      'twoBishopsVsKing',
      'queenVsRook',
      'rookPawnVsRook',
      'pawnVsKing',
      'rookVsPawn',
      'queenVsPawn',
      'knightBishopVsKing',
    ]);
  });

  test('speedrun de degrau: os desafios do degrau, com o ritmo dele', () async {
    repository = build({AssetJourneyRepository.speedrunsPath: _otherKinds});
    final ladder = await repository.ladder();
    final speedruns = await repository.speedruns();
    final rungRuns = speedruns.where((s) => s.kind == SpeedrunKind.rung);

    expect(rungRuns, hasLength(2));
    for (final speedrun in rungRuns) {
      final rung = ladder.firstWhere((rung) => rung.id == speedrun.rungId);
      expect(
        speedrun.stages.map((stage) => stage.position.id),
        rung.challenges.map((challenge) => challenge.position.id),
      );
      expect(speedrun.stages.every((s) => s.time == speedrun.time), isTrue);
    }
  });

  test('speedrun de final: o mesmo final contra cada degrau, com as peças em '
      'casas diferentes e às vezes com as pretas', () async {
    final ladder = await repository.ladder();
    final endings = (await repository.speedruns()).where(
      (s) => s.kind == SpeedrunKind.ending,
    );
    final catalog = AssetPositionsRepository(AssetService(_ProjectBundle()));

    expect(endings, hasLength(9));
    for (final speedrun in endings) {
      final base = (await catalog.byId(speedrun.positionId!))!;
      expect(speedrun.stages, hasLength(ladder.length), reason: speedrun.id);
      expect(
        speedrun.stages.map((stage) => stage.opponent),
        ladder.map((rung) => rung.opponent),
      );
      final positions = [for (final stage in speedrun.stages) stage.position];
      expect(positions.map((p) => p.fen).toSet(), hasLength(ladder.length));
      expect(positions.map((p) => p.id).toSet(), hasLength(ladder.length));
      var black = 0;
      for (final position in positions) {
        final reason = '${speedrun.id} ${position.fen}';
        // O final do speedrun, fora do catálogo.
        expect(position.category, base.category, reason: reason);
        expect(position.subcategory, base.subcategory, reason: reason);
        expect(position.goal, base.goal, reason: reason);
        expect(position.verified, isTrue, reason: reason);
        expect(await catalog.byId(position.id), isNull, reason: reason);

        final checked = PositionValidation.check(position.fen);
        expect(checked.problem, isNull, reason: reason);
        final board = checked.position!.board;
        final turn = checked.position!.turn;
        if (turn == Side.black) black++;
        final (strong, weak) = SubcategoryMaterial.of(position.subcategory);
        expect(_roles(board, turn), strong, reason: reason);
        expect(_roles(board, turn.opposite), weak, reason: reason);
        // Nos mates, o rei de quem defende nunca começa na borda.
        if (_mates.contains(position.subcategory)) {
          final king = board.kingOf(turn.opposite)!;
          final edges = [File.a.value, File.h.value];
          expect(
            edges.contains(king.file.value) ||
                [Rank.first.value, Rank.eighth.value].contains(king.rank.value),
            isFalse,
            reason: reason,
          );
        }
      }
      expect(black, greaterThanOrEqualTo(3), reason: speedrun.id);
    }
  });

  test('speedrun de final sem posições no arquivo: a do speedrun em todas as '
      'etapas', () async {
    repository = build({
      AssetJourneyRepository.speedrunPositionsPath: '{"speedruns": {}}',
    });
    final ladder = await repository.ladder();
    final endings = (await repository.speedruns()).where(
      (s) => s.kind == SpeedrunKind.ending,
    );

    expect(endings, isNotEmpty);
    for (final speedrun in endings) {
      expect(speedrun.stages, hasLength(ladder.length));
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

  test('speedrun de exercícios: as posições da lista, cada uma com o seu '
      'adversário', () async {
    repository = build({AssetJourneyRepository.speedrunsPath: _otherKinds});
    final exercises = (await repository.speedruns())
        .where((s) => s.kind == SpeedrunKind.exercises)
        .toList();

    expect(exercises, isNotEmpty);
    for (final speedrun in exercises) {
      expect(speedrun.stages, isNotEmpty);
      for (final stage in speedrun.stages) {
        expect(stage.opponent.kind, OpponentKind.maia);
        expect(MaiaLevels.all, contains(stage.opponent.level));
        expect(stage.time, speedrun.time);
      }
    }
  });

  test('speedrun completo: todos os desafios da Jornada, em ordem', () async {
    repository = build({AssetJourneyRepository.speedrunsPath: _otherKinds});
    final ladder = await repository.ladder();
    final full = (await repository.speedruns()).singleWhere(
      (s) => s.kind == SpeedrunKind.full,
    );

    final challenges = [for (final rung in ladder) ...rung.challenges];
    expect(full.stages, hasLength(challenges.length));
    expect(
      full.stages.map((stage) => stage.position.id),
      challenges.map((challenge) => challenge.position.id),
    );
    expect(full.stages.first.opponent.level, MaiaLevels.min);
    expect(full.stages.last.opponent.kind, OpponentKind.stockfish);
  });
}

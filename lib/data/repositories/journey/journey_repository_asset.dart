import 'dart:convert';

import '../../../domain/models/clock.dart';
import '../../../domain/models/endgame_position.dart';
import '../../../domain/models/journey.dart';
import '../../../domain/models/speedrun.dart';
import '../../services/asset_service.dart';
import '../positions/positions_repository.dart';
import 'journey_repository.dart';

/// Degraus e speedruns lidos de `assets/progression/`, com as posições do
/// catálogo. Lidos uma vez e guardados na memória.
class AssetJourneyRepository implements JourneyRepository {
  AssetJourneyRepository(this._assets, this._positions);

  static const ladderPath = 'assets/progression/ladder.json';
  static const speedrunsPath = 'assets/progression/speedruns.json';

  final AssetService _assets;
  final PositionsRepository _positions;
  Future<List<Rung>>? _ladder;
  Future<List<Speedrun>>? _speedruns;

  @override
  Future<List<Rung>> ladder() => _ladder ??= _loadLadder();

  @override
  Future<List<Speedrun>> speedruns() => _speedruns ??= _loadSpeedruns();

  Future<List<Rung>> _loadLadder() async {
    final json = jsonDecode(
      await _assets.loadString(ladderPath),
    ) as Map<String, dynamic>;
    final rungs = <Rung>[];
    for (final item in (json['rungs'] as List).cast<Map<String, dynamic>>()) {
      final id = item['id'] as String;
      final opponent = OpponentRef.tryParse(item['opponent'] as String)!;
      rungs.add(
        Rung(
          id: id,
          opponent: opponent,
          challenges: [
            for (final positionId
                in (item['challenges'] as List).cast<String>())
              Challenge(
                id: '$id/$positionId',
                position: await _position(positionId),
                opponent: opponent,
              ),
          ],
        ),
      );
    }
    return rungs;
  }

  Future<List<Speedrun>> _loadSpeedruns() async {
    final json = jsonDecode(
      await _assets.loadString(speedrunsPath),
    ) as Map<String, dynamic>;
    final ladder = await this.ladder();
    final speedruns = <Speedrun>[];
    for (final item
        in (json['speedruns'] as List).cast<Map<String, dynamic>>()) {
      // Modalidade que esta versão não conhece fica de fora.
      final kind = SpeedrunKind.fromCode(item['kind'] as String?);
      if (kind == null) continue;
      final id = item['id'] as String;
      final time = TimeControl.tryParse(item['time'] as String)!;
      final rungId = item['rung'] as String?;
      final positionId = item['position'] as String?;
      final stages = switch (kind) {
        // As etapas são os desafios do degrau, com o ritmo do speedrun.
        SpeedrunKind.rung => [
          for (final challenge
              in ladder.firstWhere((rung) => rung.id == rungId).challenges)
            challenge.copyWith(id: '$id/${challenge.position.id}', time: time),
        ],
        // A mesma posição contra o adversário de cada degrau.
        SpeedrunKind.ending => [
          for (final rung in ladder)
            Challenge(
              id: '$id/${rung.id}',
              position: await _position(positionId!),
              opponent: rung.opponent,
              time: time,
            ),
        ],
        // As posições da lista, cada uma contra o seu adversário.
        SpeedrunKind.exercises => [
          for (final stage
              in (item['stages'] as List).cast<Map<String, dynamic>>())
            Challenge(
              id: '$id/${stage['position']}',
              position: await _position(stage['position'] as String),
              opponent: OpponentRef.tryParse(stage['opponent'] as String)!,
              time: time,
            ),
        ],
        // Todos os desafios da Jornada, degrau por degrau.
        SpeedrunKind.full => [
          for (final rung in ladder)
            for (final challenge in rung.challenges)
              challenge.copyWith(id: '$id/${challenge.id}', time: time),
        ],
      };
      speedruns.add(
        Speedrun(
          id: id,
          kind: kind,
          rungId: rungId,
          positionId: positionId,
          time: time,
          stages: stages,
        ),
      );
    }
    return speedruns;
  }

  Future<EndgamePosition> _position(String id) async {
    final position = await _positions.byId(id);
    if (position == null) {
      throw StateError('a posição $id não está no catálogo');
    }
    return position;
  }
}

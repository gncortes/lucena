import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../../domain/models/clock.dart';
import '../../../domain/models/endgame_position.dart';
import '../../../domain/models/journey.dart';
import '../../../domain/models/speedrun.dart';
import '../../../domain/use_cases/marathon.dart';
import '../../services/asset_service.dart';
import '../positions/positions_repository.dart';
import 'journey_repository.dart';

/// Degraus e speedruns lidos de `assets/progression/`, com as posições do
/// catálogo. Lidos uma vez e guardados na memória.
class AssetJourneyRepository implements JourneyRepository {
  AssetJourneyRepository(this._assets, this._positions);

  static const ladderPath = 'assets/progression/ladder.json';
  static const speedrunsPath = 'assets/progression/speedruns.json';

  /// As posições de cada etapa dos speedruns de final (geradas por
  /// `tools/gen_speedrun_positions.py`). Ficam fora do catálogo.
  static const speedrunPositionsPath =
      'assets/progression/speedrun_positions.json';

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
          // Os especiais: o mesmo final de outro jeito (às cegas).
          specials: [
            for (final special
                in (item['specials'] as List? ?? const [])
                    .cast<Map<String, dynamic>>())
              Challenge(
                // O às cegas leva a posição no id; o speedrun e a Maratona
                // curtos, o speedrun.
                id:
                    '$id/${special['mode']}.'
                    '${special['speedrun'] ?? special['position']}',
                position: await _position(special['position'] as String),
                opponent: opponent,
                mode: ChallengeMode.fromCode(special['mode'] as String?),
                hideBoard: special['view'] == 'none',
                speedrunId: special['speedrun'] == null
                    ? null
                    : '${special['speedrun']}@${special['time']}',
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
    final stagePositions = await _loadStagePositions();
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
        // O mesmo final contra o adversário de cada degrau, cada etapa com as
        // peças em outras casas (e às vezes com as pretas). Sem as posições
        // do arquivo, a posição do speedrun em todas as etapas.
        SpeedrunKind.ending => [
          for (final (index, rung) in ladder.indexed)
            Challenge(
              id: '$id/${rung.id}',
              position: _stagePosition(
                await _position(positionId!),
                stagePositions[id],
                index,
              ),
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
        // A Maratona vem do speedrun de final, logo abaixo; a curta, da
        // Jornada, traz as etapas no arquivo.
        SpeedrunKind.marathon => [
          for (final stage
              in (item['stages'] as List? ?? const [])
                  .cast<Map<String, dynamic>>())
            Challenge(
              id: '$id/${stage['position']}',
              position: await _position(stage['position'] as String),
              opponent: OpponentRef.tryParse(stage['opponent'] as String)!,
              time: time,
            ),
        ],
      };
      if (kind == SpeedrunKind.marathon && stages.isEmpty) continue;
      speedruns.add(
        Speedrun(
          id: id,
          kind: kind,
          rungId: rungId,
          positionId: positionId,
          category: SpeedrunCategory.fromCode(item['category'] as String?),
          journeyOnly: item['journey'] == true,
          time: time,
          stages: stages,
        ),
      );
    }
    // Cada final também tem a sua Maratona, com as mesmas etapas.
    return [
      ...speedruns,
      for (final speedrun in speedruns)
        if (speedrun.kind == SpeedrunKind.ending) Marathon.of(speedrun),
    ];
  }

  /// As posições das etapas, por id de speedrun. Vazio se o arquivo não
  /// existe.
  Future<Map<String, List<Map<String, dynamic>>>> _loadStagePositions() async {
    final String text;
    try {
      text = await _assets.loadString(speedrunPositionsPath);
    } on FlutterError {
      return const {};
    } on Exception {
      return const {};
    }
    final json = jsonDecode(text) as Map<String, dynamic>;
    return {
      for (final MapEntry(:key, :value)
          in (json['speedruns'] as Map<String, dynamic>).entries)
        key: (value as List).cast<Map<String, dynamic>>(),
    };
  }

  /// A posição da etapa [index]: a do arquivo, com o final (categoria,
  /// subcategoria e objetivo) de [base]; sem ela, a própria [base].
  EndgamePosition _stagePosition(
    EndgamePosition base,
    List<Map<String, dynamic>>? stages,
    int index,
  ) {
    if (stages == null || index >= stages.length) return base;
    final stage = stages[index];
    return base.copyWith(
      id: stage['id'] as String,
      fen: stage['fen'] as String,
      mateIn: stage['mateIn'] as int?,
      verified: stage['verified'] as bool? ?? false,
    );
  }

  Future<EndgamePosition> _position(String id) async {
    final position = await _positions.byId(id);
    if (position == null) {
      throw StateError('a posição $id não está no catálogo');
    }
    return position;
  }
}

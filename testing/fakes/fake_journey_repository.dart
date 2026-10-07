import 'package:lucena/data/repositories/journey/journey_repository.dart';
import 'package:lucena/domain/models/clock.dart';
import 'package:lucena/domain/models/game_setup.dart';
import 'package:lucena/domain/models/journey.dart';
import 'package:lucena/domain/models/speedrun.dart';
import 'package:lucena/domain/use_cases/marathon.dart';

import 'fake_positions_repository.dart';

/// Jornada pequena, na memória: três degraus com as posições de exemplo.
class FakeJourneyRepository implements JourneyRepository {
  FakeJourneyRepository({List<Rung>? ladder, List<Speedrun>? speedruns})
    : _ladder = ladder ?? sampleLadder,
      _speedruns = speedruns ?? sampleSpeedruns;

  final List<Rung> _ladder;
  final List<Speedrun> _speedruns;

  @override
  Future<List<Rung>> ladder() async => _ladder;

  @override
  Future<List<Speedrun>> speedruns() async => _speedruns;
}

const _maia1000 = OpponentRef(kind: OpponentKind.maia, level: 1000);
const _maia1200 = OpponentRef(kind: OpponentKind.maia, level: 1200);
const _stockfish = OpponentRef(kind: OpponentKind.stockfish);

/// 1000 com dois desafios, 1200 com um e o Stockfish com um.
final sampleLadder = [
  Rung(
    id: '1000',
    opponent: _maia1000,
    challenges: [
      Challenge(
        id: '1000/basic.queen.0001',
        position: samplePositions[0],
        opponent: _maia1000,
      ),
      Challenge(
        id: '1000/basic.rook.0001',
        position: samplePositions[1],
        opponent: _maia1000,
      ),
    ],
  ),
  Rung(
    id: '1200',
    opponent: _maia1200,
    challenges: [
      Challenge(
        id: '1200/rookPawn.rookPawnVsRook.0002',
        position: samplePositions[3],
        opponent: _maia1200,
      ),
    ],
  ),
  Rung(
    id: 'stockfish',
    opponent: _stockfish,
    challenges: [
      Challenge(
        id: 'stockfish/rookPawn.rookPawnVsRook.0001',
        position: samplePositions[2],
        opponent: _stockfish,
      ),
    ],
  ),
];

const sampleSpeedrunTime = TimeControl(
  initial: Duration(minutes: 3),
  increment: Duration(seconds: 2),
);

/// O speedrun do degrau 1000 e o do mate de dama contra cada degrau.
final sampleSpeedruns = [
  Speedrun(
    id: 'rung.1000',
    kind: SpeedrunKind.rung,
    rungId: '1000',
    time: sampleSpeedrunTime,
    stages: [
      for (final challenge in sampleLadder.first.challenges)
        challenge.copyWith(
          id: 'rung.1000/${challenge.position.id}',
          time: sampleSpeedrunTime,
        ),
    ],
  ),
  Speedrun(
    id: 'ending.queen',
    kind: SpeedrunKind.ending,
    positionId: samplePositions[0].id,
    category: SpeedrunCategory.beginner,
    time: sampleSpeedrunTime,
    stages: [
      for (final rung in sampleLadder)
        Challenge(
          id: 'ending.queen/${rung.id}',
          position: samplePositions[0],
          opponent: rung.opponent,
          time: sampleSpeedrunTime,
        ),
    ],
  ),
];

/// A Maratona do mate de dama: as etapas do speedrun de final.
final sampleMarathon = Marathon.of(sampleSpeedruns[1]);

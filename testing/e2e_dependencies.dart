import 'dart:math';

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'package:lucena/config/dependencies.dart';
import 'package:lucena/data/repositories/journey/journey_repository_asset.dart';
import 'package:lucena/data/repositories/maia/maia_repository_device.dart';
import 'package:lucena/data/repositories/speedrun/speedrun_repository_local.dart';
import 'package:lucena/data/repositories/opponent/opponent_repository_maia.dart';
import 'package:lucena/data/services/maia_service.dart';
import 'package:lucena/domain/models/game_setup.dart';
import 'package:lucena/data/repositories/ongoing_game/ongoing_game_repository_local.dart';
import 'package:dartchess/dartchess.dart';
import 'package:lucena/data/repositories/opponent/opponent_repository.dart';
import 'package:lucena/data/repositories/opponent/opponent_repository_stockfish.dart';
import 'package:lucena/data/repositories/positions/positions_repository_asset.dart';
import 'package:lucena/data/repositories/progress/progress_repository_local.dart';
import 'package:lucena/data/services/stockfish_service.dart';
import 'package:lucena/data/repositories/profile/profile_repository_local.dart';
import 'package:lucena/data/repositories/settings/settings_repository_local.dart';
import 'package:lucena/data/repositories/training/training_repository_local.dart';
import 'package:lucena/data/services/asset_service.dart';
import 'package:lucena/data/services/database/app_database.dart';
import 'package:lucena/data/services/preferences_service.dart';
import 'package:lucena/data/repositories/journey/journey_repository.dart';
import 'package:lucena/domain/models/app_language.dart';
import 'package:lucena/domain/models/clock.dart';
import 'package:lucena/domain/models/endgame_position.dart';
import 'package:lucena/domain/models/journey.dart';
import 'package:lucena/domain/models/speedrun.dart';

import 'package:lucena/data/repositories/achievements/achievements_repository_local.dart';
import 'package:lucena/data/repositories/characters/character_repository_asset.dart';
import 'package:lucena/data/repositories/characters/talk_repository.dart';
import 'package:lucena/data/repositories/maia/maia_repository.dart';
import 'package:lucena/data/repositories/onboarding/onboarding_repository.dart';
import 'package:lucena/data/repositories/pace/pace_repository.dart';
import 'package:lucena/data/repositories/rating/rating_repository_local.dart';
import 'package:lucena/domain/models/move_prediction.dart';
import 'package:lucena/domain/models/onboarding.dart';
import 'package:lucena/domain/use_cases/position_assessment.dart';

import 'fakes/fake_evaluation_repository.dart';
import 'fakes/fake_haptics_repository.dart';
import 'fakes/fake_now.dart';
import 'fakes/fake_opponent_repository.dart';

/// O relógio dos cenários: só anda quando o cenário manda.
final e2eNow = FakeNow(_e2eStart);

final _e2eStart = DateTime.utc(2026, 1, 1, 12);

/// O Maia de verdade, um só para todos os cenários (o modelo fica carregado).
final _maia = MaiaService(
  () => const AssetService().loadBytes(MaiaService.weightsAsset),
);

/// O adversário dos cenários: previsível e controlado pelo cenário (o relógio
/// dele anda o tempo que ele pensa). Com [E2EOpponent.useStockfish] ou
/// [E2EOpponent.useMaia], quem joga é o motor de verdade.
final e2eOpponent = E2EOpponent();

class E2EOpponent implements OpponentRepository {
  final fake = FakeOpponentRepository(now: e2eNow);
  bool useStockfish = false;
  bool useMaia = false;

  /// Quanto o Maia de verdade pensou em cada lance (além da conta do modelo).
  final maiaThinkTimes = <Duration>[];

  late final _stockfish = StockfishOpponentRepository(StockfishService());

  // O Maia de verdade, com o sorteio fixo. Em vez de esperar, o relógio do
  // cenário anda o tempo que ele "pensou".
  late final _realMaia = MaiaOpponentRepository(
    _maia,
    now: e2eNow,
    pace: AssetPaceRepository(const AssetService()),
    random: Random(7),
    wait: (duration) async {
      maiaThinkTimes.add(duration);
      e2eNow.advance(duration);
    },
  );

  @override
  Future<Move?> pickMove(
    Position position, {
    required Duration thinkTime,
    OpponentKind kind = OpponentKind.stockfish,
    int? level,
    List<Position> history = const [],
    TimeControl? time,
  }) {
    final OpponentRepository engine;
    if (kind == OpponentKind.maia && useMaia) {
      engine = _realMaia;
    } else if (kind == OpponentKind.stockfish && useStockfish) {
      engine = _stockfish;
    } else {
      engine = fake;
    }
    return engine.pickMove(
      position,
      thinkTime: thinkTime,
      kind: kind,
      level: level,
      history: history,
      time: time,
    );
  }

  void reset() {
    useStockfish = false;
    useMaia = false;
    maiaThinkTimes.clear();
    fake.release();
    fake.requests.clear();
    fake.thinkTimes.clear();
    fake.kinds.clear();
    fake.levels.clear();
    fake.histories.clear();
    fake.times.clear();
  }
}

// O banco aberto pelo app em execução: fechado antes de abrir o próximo.
AppDatabase? _database;

/// Composição dos cenários Patrol: relógio controlado e o pseudo-idioma na lista,
/// mas com a gravação de verdade no aparelho (preferências e banco), para os
/// cenários de persistência (reiniciar o app e conferir o dado) valerem.
///
/// Cada chamada fecha o banco da anterior e abre outro, como um app reaberto.
Future<Dependencies> e2eDependencies() async {
  await _database?.close();
  final database = _database = AppDatabase();
  final positions = AssetPositionsRepository(const AssetService());
  return Dependencies(
    now: e2eNow,
    settingsRepository: LocalSettingsRepository(PreferencesService()),
    profileRepository: LocalProfileRepository(database),
    hapticsRepository: FakeHapticsRepository(),
    ongoingGameRepository: LocalOngoingGameRepository(PreferencesService()),
    // O catálogo de verdade: os cenários abrem posições conhecidas dele.
    positionsRepository: positions,
    trainingRepository: LocalTrainingRepository(PreferencesService()),
    opponentRepository: e2eOpponent,
    // O modelo de verdade: a tela de depuração mostra o que ele responde.
    maiaRepository: e2eMaia,
    progressRepository: LocalProgressRepository(database),
    // A Jornada e os speedruns de verdade.
    journeyRepository: E2EJourneyRepository(
      AssetJourneyRepository(const AssetService(), positions),
    ),
    speedrunRepository: LocalSpeedrunRepository(database),
    ratingRepository: LocalRatingRepository(
      database,
      maia: e2eMaia,
      profile: LocalProfileRepository(database),
      now: e2eNow,
    ),
    achievementsRepository: LocalAchievementsRepository(
      const AssetService(),
      database,
    ),
    // Os personagens e as falas de verdade.
    characterRepository: AssetCharacterRepository(const AssetService()),
    evaluationRepository: e2eEvaluation,
    talkRepository: LocalTalkRepository(PreferencesService()),
    onboardingRepository: LocalOnboardingRepository(PreferencesService()),
    paceRepository: AssetPaceRepository(const AssetService()),
    languages: AppLanguage.values,
  );
}

/// A avaliação da posição para os personagens, combinada pelo cenário.
final e2eEvaluation = FakeEvaluationRepository();

/// O Maia do rating: a chance de cada partida é a combinada pelo cenário
/// (meio a meio), sem esperar o modelo. As outras previsões são as do modelo.
final e2eMaia = E2EMaia();

class E2EMaia implements MaiaRepository {
  final _real = DeviceMaiaRepository(_maia);

  /// A chance de quem joga ganhar, empatar e perder, em toda partida.
  MovePrediction match = _even;

  static const _even = MovePrediction(
    moves: {},
    win: 0.5,
    draw: 0,
    loss: 0.5,
    elapsed: Duration.zero,
  );

  @override
  Future<MovePrediction> predict(Position position, {required int level}) =>
      _real.predict(position, level: level);

  @override
  Future<MovePrediction> predictMatch(
    Position position, {
    required int selfElo,
    required int oppoElo,
  }) async => match;

  void reset() => match = _even;
}

/// Apaga o que os cenários anteriores gravaram: cada cenário começa do zero.
Future<void> resetE2EData() async {
  e2eNow.value = _e2eStart;
  e2eOpponent.reset();
  e2eMaia.reset();
  e2eEvaluation
    ..next.clear()
    ..requests.clear()
    ..fallback = const Evaluation(centipawns: 0);
  await PreferencesService().clear();
  // O tour da primeira abertura só aparece nos cenários dele.
  await LocalOnboardingRepository(PreferencesService())
      .save(const Onboarding(done: true));
  await _database?.close();
  _database = null;
  final database = AppDatabase();
  await database.deleteEverything();
  await database.close();
}

/// A Jornada de verdade e, antes dos speedruns de verdade, dois curtos de
/// mate em um lance: os cenários percorrem um speedrun inteiro em segundos.
class E2EJourneyRepository implements JourneyRepository {
  E2EJourneyRepository(this._real);

  final JourneyRepository _real;

  static const mateInOne = EndgamePosition(
    id: 'e2e.queen.0001',
    category: 'basic',
    subcategory: 'queen',
    fen: '3k4/8/3K4/8/8/8/8/7Q w - - 0 1',
    goal: PositionGoal.win,
  );

  /// O lance que dá o mate em [mateInOne].
  static const mate = ('h1', 'h8');

  static const time = TimeControl(
    initial: Duration(minutes: 3),
    increment: Duration(seconds: 2),
  );

  @override
  Future<List<Rung>> ladder() => _real.ladder();

  @override
  Future<List<Speedrun>> speedruns() async {
    final ladder = await _real.ladder();
    final maia1000 = ladder.first.opponent;
    // Três adversários da escada: o primeiro, o segundo e o Stockfish.
    final opponents = [ladder[0], ladder[1], ladder.last];
    return [
      Speedrun(
        id: 'e2e.rung',
        kind: SpeedrunKind.rung,
        rungId: ladder.first.id,
        time: time,
        stages: [
          for (var index = 0; index < 2; index++)
            Challenge(
              id: 'e2e.rung/$index',
              position: mateInOne,
              opponent: maia1000,
              time: time,
            ),
        ],
      ),
      Speedrun(
        id: 'e2e.ending',
        kind: SpeedrunKind.ending,
        positionId: mateInOne.id,
        time: time,
        stages: [
          for (final rung in opponents)
            Challenge(
              id: 'e2e.ending/${rung.id}',
              position: mateInOne,
              opponent: rung.opponent,
              time: time,
            ),
        ],
      ),
      // A campanha inteira e os exercícios, em três e duas etapas.
      Speedrun(
        id: 'e2e.full',
        kind: SpeedrunKind.full,
        time: time,
        stages: [
          for (final rung in opponents)
            Challenge(
              id: 'e2e.full/${rung.id}',
              position: mateInOne,
              opponent: rung.opponent,
              time: time,
            ),
        ],
      ),
      Speedrun(
        id: 'e2e.exercises',
        kind: SpeedrunKind.exercises,
        time: time,
        stages: [
          for (var index = 0; index < 2; index++)
            Challenge(
              id: 'e2e.exercises/$index',
              position: mateInOne,
              opponent: ladder[index].opponent,
              time: time,
            ),
        ],
      ),
      ...await _real.speedruns(),
    ];
  }
}

/// Troca o banco do aparelho por um da versão 3 do app (antes da Jornada),
/// com as partidas [rows] na tabela antiga `attempts`: cada uma é
/// `(posição, cumprida, adversário)`. O próximo `AppRobot.restart` abre o app
/// novo sobre ele, como numa atualização.
Future<void> installVersion3Database(List<(String, bool, String)> rows) async {
  await _database?.close();
  _database = null;
  final executor = driftDatabase(name: 'lucena');
  await executor.ensureOpen(_Version3(rows));
  await executor.close();
}

class _Version3 extends QueryExecutorUser {
  _Version3(this.rows);

  final List<(String, bool, String)> rows;

  @override
  int get schemaVersion => 3;

  @override
  Future<void> beforeOpen(
    QueryExecutor executor,
    OpeningDetails details,
  ) async {
    // O executor recebido aqui também precisa ser aberto antes de usar.
    await executor.ensureOpen(this);
    for (final table in [
      'games',
      'speedrun_attempts',
      'rating_history',
      'unlocked_achievements',
      'attempts',
    ]) {
      await executor.runCustom('DROP TABLE IF EXISTS $table');
    }
    await executor.runCustom(
      'CREATE TABLE attempts (id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, '
      'position_id TEXT NOT NULL, played_at INTEGER NOT NULL, '
      'outcome TEXT NOT NULL, '
      'fulfilled INTEGER NOT NULL CHECK (fulfilled IN (0, 1)), '
      'opponent TEXT NOT NULL, opponent_level INTEGER NULL)',
    );
    for (final (position, fulfilled, opponent) in rows) {
      await executor.runCustom(
        'INSERT INTO attempts (position_id, played_at, outcome, fulfilled, '
        'opponent) VALUES (?, ?, ?, ?, ?)',
        [
          position,
          _e2eStart.millisecondsSinceEpoch ~/ 1000,
          fulfilled ? 'win' : 'loss',
          fulfilled ? 1 : 0,
          opponent,
        ],
      );
    }
  }
}

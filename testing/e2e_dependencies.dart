import 'dart:math';

import 'package:lucena/config/dependencies.dart';
import 'package:lucena/data/repositories/maia/maia_repository_device.dart';
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
import 'package:lucena/domain/models/app_language.dart';

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
  return Dependencies(
    now: e2eNow,
    settingsRepository: LocalSettingsRepository(PreferencesService()),
    profileRepository: LocalProfileRepository(database),
    hapticsRepository: FakeHapticsRepository(),
    ongoingGameRepository: LocalOngoingGameRepository(PreferencesService()),
    // O catálogo de verdade: os cenários abrem posições conhecidas dele.
    positionsRepository: AssetPositionsRepository(const AssetService()),
    trainingRepository: LocalTrainingRepository(PreferencesService()),
    opponentRepository: e2eOpponent,
    // O modelo de verdade: a tela de depuração mostra o que ele responde.
    maiaRepository: DeviceMaiaRepository(_maia),
    progressRepository: LocalProgressRepository(database),
    languages: AppLanguage.values,
  );
}

/// Apaga o que os cenários anteriores gravaram: cada cenário começa do zero.
Future<void> resetE2EData() async {
  e2eNow.value = _e2eStart;
  e2eOpponent.reset();
  await PreferencesService().clear();
  await _database?.close();
  _database = null;
  final database = AppDatabase();
  await database.deleteEverything();
  await database.close();
}

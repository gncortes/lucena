import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

/// Perfil do jogador: uma linha só.
class Profiles extends Table {
  IntColumn get id => integer()();
  TextColumn get nickname => text()();
  IntColumn get rating => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Partidas de treino terminadas (soltas, desafios da Jornada e etapas de
/// speedrun). Substitui a antiga `attempts` desde a versão 4.
@DataClassName('GameRow')
class Games extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get positionId => text()();

  /// Quando a partida terminou.
  DateTimeColumn get playedAt => dateTime()();

  /// `win`, `draw` ou `loss`, do ponto de vista do jogador.
  TextColumn get outcome => text()();
  BoolColumn get fulfilled => boolean()();
  TextColumn get opponent => text()();

  /// O nível do Maia, quando ele foi o adversário.
  IntColumn get opponentLevel => integer().nullable()();

  // O resto é nulo nas partidas migradas das versões antigas.
  DateTimeColumn get startedAt => dateTime().nullable()();
  TextColumn get startFen => text().nullable()();

  /// Os lances em UCI, separados por espaço.
  TextColumn get moves => text().withDefault(const Constant(''))();
  TextColumn get endReason => text().nullable()();

  /// O tempo de cada lado (`segundos+incremento`).
  TextColumn get userTime => text().nullable()();
  TextColumn get opponentTime => text().nullable()();

  /// Quanto o relógio do jogador gastou, em milissegundos.
  IntColumn get userClockMs => integer().nullable()();
  TextColumn get challengeId => text().nullable()();
  IntColumn get speedrunAttemptId => integer().nullable()();
  IntColumn get speedrunStage => integer().nullable()();
}

/// Tentativas de speedrun. As etapas saem das partidas (`games`) da tentativa.
@DataClassName('SpeedrunAttemptRow')
class SpeedrunAttempts extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get speedrunId => text()();
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get abandonedAt => dateTime().nullable()();
}

/// O rating do jogador depois de cada partida que conta (contra o Maia ou o
/// Stockfish). A última linha é o rating atual.
@DataClassName('RatingRow')
class RatingHistory extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// A partida que mudou o rating.
  IntColumn get gameId => integer().nullable()();
  DateTimeColumn get at => dateTime()();
  RealColumn get rating => real()();
  RealColumn get deviation => real()();
  RealColumn get volatility => real()();
}

/// As conquistas já mostradas ao jogador. Se ele tem ou não sai das partidas;
/// aqui fica só quando ela apareceu, para não aparecer de novo como nova.
@DataClassName('UnlockedAchievementRow')
class UnlockedAchievements extends Table {
  TextColumn get achievementId => text()();
  DateTimeColumn get at => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {achievementId};
}

/// Banco local do app (SQLite). Só os repositórios falam com ele.
@DriftDatabase(
  tables: [
    Profiles,
    Games,
    SpeedrunAttempts,
    RatingHistory,
    UnlockedAchievements,
  ],
)
class AppDatabase extends _$AppDatabase {
  /// Sem [executor], usa o arquivo do app no aparelho, aberto só no primeiro uso.
  AppDatabase([QueryExecutor? executor])
    : super(executor ?? LazyDatabase(() => driftDatabase(name: 'lucena')));

  @override
  int get schemaVersion => 5;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (migrator, from, to) async {
      if (from < 4) await _toVersion4(migrator, from);
      if (from < 5) {
        await migrator.createTable(ratingHistory);
        await migrator.createTable(unlockedAchievements);
      }
    },
  );

  Future<void> _toVersion4(Migrator migrator, int from) async {
    await migrator.createTable(games);
    await migrator.createTable(speedrunAttempts);
    // 2 e 3 -> 4: as partidas de `attempts` passam para `games`, sem perder
    // nenhuma. A versão 2 ainda não tinha o nível do Maia.
    if (from >= 2) {
      final level = from >= 3 ? 'opponent_level' : 'NULL';
      await customStatement(
        'INSERT INTO games '
        '(position_id, played_at, outcome, fulfilled, opponent, '
        'opponent_level) '
        'SELECT position_id, played_at, outcome, fulfilled, opponent, $level '
        'FROM attempts ORDER BY id',
      );
      await customStatement('DROP TABLE attempts');
    }
  }

  /// Apaga todas as linhas de todas as tabelas.
  Future<void> deleteEverything() {
    return transaction(() async {
      for (final table in allTables) {
        await delete(table).go();
      }
    });
  }
}

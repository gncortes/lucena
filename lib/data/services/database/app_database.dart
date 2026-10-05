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

/// Banco local do app (SQLite). Só os repositórios falam com ele.
@DriftDatabase(tables: [Profiles, Games, SpeedrunAttempts])
class AppDatabase extends _$AppDatabase {
  /// Sem [executor], usa o arquivo do app no aparelho, aberto só no primeiro uso.
  AppDatabase([QueryExecutor? executor])
    : super(executor ?? LazyDatabase(() => driftDatabase(name: 'lucena')));

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (migrator, from, to) async {
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
    },
  );

  /// Apaga todas as linhas de todas as tabelas.
  Future<void> deleteEverything() {
    return transaction(() async {
      for (final table in allTables) {
        await delete(table).go();
      }
    });
  }
}

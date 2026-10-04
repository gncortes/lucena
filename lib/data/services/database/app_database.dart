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

/// Partidas jogadas nas posições do catálogo.
@DataClassName('AttemptRow')
class Attempts extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get positionId => text()();
  DateTimeColumn get playedAt => dateTime()();

  /// `win`, `draw` ou `loss`, do ponto de vista do jogador.
  TextColumn get outcome => text()();
  BoolColumn get fulfilled => boolean()();
  TextColumn get opponent => text()();
}

/// Banco local do app (SQLite). Só os repositórios falam com ele.
@DriftDatabase(tables: [Profiles, Attempts])
class AppDatabase extends _$AppDatabase {
  /// Sem [executor], usa o arquivo do app no aparelho, aberto só no primeiro uso.
  AppDatabase([QueryExecutor? executor])
    : super(executor ?? LazyDatabase(() => driftDatabase(name: 'lucena')));

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (migrator, from, to) async {
      // 1 -> 2: histórico das partidas nas posições.
      if (from < 2) await migrator.createTable(attempts);
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

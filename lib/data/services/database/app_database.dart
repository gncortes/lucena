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

/// Banco local do app (SQLite). Só os repositórios falam com ele.
@DriftDatabase(tables: [Profiles])
class AppDatabase extends _$AppDatabase {
  /// Sem [executor], usa o arquivo do app no aparelho, aberto só no primeiro uso.
  AppDatabase([QueryExecutor? executor])
    : super(executor ?? LazyDatabase(() => driftDatabase(name: 'lucena')));

  @override
  int get schemaVersion => 1;

  /// Apaga todas as linhas de todas as tabelas.
  Future<void> deleteEverything() {
    return transaction(() async {
      for (final table in allTables) {
        await delete(table).go();
      }
    });
  }
}

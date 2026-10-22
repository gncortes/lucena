import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

/// Perfil do jogador: uma linha só.
class Profiles extends Table {
  IntColumn get id => integer()();
  TextColumn get nickname => text()();
  IntColumn get rating => integer()();

  /// O objetivo da primeira abertura (`GoalPreference`). Desde a versão 9.
  TextColumn get goal => text().nullable()();

  /// De onde veio o rating (`LevelSource`) e as contas ligadas. Desde a
  /// versão 10.
  TextColumn get levelSource => text().nullable()();
  TextColumn get lichessUser => text().nullable()();
  TextColumn get chessComUser => text().nullable()();

  /// O avatar e o país (E1.13). Desde a versão 11.
  IntColumn get avatarColor => integer().withDefault(const Constant(0))();
  BoolColumn get googlePhoto => boolean().withDefault(const Constant(false))();
  TextColumn get country => text().nullable()();

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

  /// Quanto cada lance levou, em milissegundos, separados por espaço. Vazio
  /// nas partidas de antes da versão 6.
  TextColumn get moveTimesMs => text().withDefault(const Constant(''))();

  /// O lado do jogador (`white` ou `black`). Nulo antes da versão 6.
  TextColumn get userSide => text().nullable()();

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

  /// A tentativa pode dar o bônus de rating da conclusão (versão 8). As de
  /// antes da 8 ficam sem: o bônus não é retroativo.
  BoolColumn get bonusEligible => boolean().withDefault(const Constant(true))();
}

/// O rating do jogador depois de cada partida que conta (contra o Maia ou o
/// Stockfish) e de cada bônus de speedrun. A última linha é o rating atual.
@DataClassName('RatingRow')
@TableIndex(
  name: 'rating_history_speedrun_attempt',
  columns: {#speedrunAttemptId},
  unique: true,
)
class RatingHistory extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// A partida que mudou o rating.
  IntColumn get gameId => integer().nullable()();
  DateTimeColumn get at => dateTime()();
  RealColumn get rating => real()();
  RealColumn get deviation => real()();
  RealColumn get volatility => real()();

  /// O bônus da conclusão desta tentativa de speedrun (versão 8). Uma linha
  /// por tentativa: o índice único impede pagar duas vezes.
  IntColumn get speedrunAttemptId => integer().nullable()();
}

/// As conquistas já mostradas ao jogador. Se ele tem ou não sai das partidas;
/// aqui fica só quando ela apareceu, para não aparecer de novo como nova.
@DataClassName('UnlockedAchievementRow')
class UnlockedAchievements extends Table {
  TextColumn get achievementId => text()();
  DateTimeColumn get at => dateTime()();

  /// A partida que a desbloqueou e, numa etapa de speedrun, a tentativa
  /// (versão 7). As de antes ficam sem.
  IntColumn get gameId => integer().nullable()();
  IntColumn get speedrunAttemptId => integer().nullable()();

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
  int get schemaVersion => 11;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (migrator, from, to) async {
      if (from < 4) await _toVersion4(migrator, from);
      if (from < 5) {
        await migrator.createTable(ratingHistory);
        await migrator.createTable(unlockedAchievements);
      }
      // 5 -> 6: o tempo de cada lance e o lado do jogador. Quem cria `games`
      // agora (vindo de antes da 4) já cria com as colunas.
      if (from >= 4 && from < 6) {
        await migrator.addColumn(games, games.moveTimesMs);
        await migrator.addColumn(games, games.userSide);
      }
      // 5 e 6 -> 7: a origem da conquista. Quem cria a tabela agora (vindo de
      // antes da 5) já cria com as colunas.
      if (from >= 5 && from < 7) {
        await migrator.addColumn(
          unlockedAchievements,
          unlockedAchievements.gameId,
        );
        await migrator.addColumn(
          unlockedAchievements,
          unlockedAchievements.speedrunAttemptId,
        );
      }
      // 7 -> 8: o bônus de rating do speedrun. As tentativas que já existiam
      // não dão bônus (sem retroativo); quem cria as tabelas agora já cria
      // com as colunas.
      if (from >= 4 && from < 8) {
        await migrator.addColumn(
          speedrunAttempts,
          speedrunAttempts.bonusEligible,
        );
        await customStatement(
          'UPDATE speedrun_attempts SET bonus_eligible = 0',
        );
      }
      if (from >= 5 && from < 8) {
        await migrator.addColumn(
          ratingHistory,
          ratingHistory.speedrunAttemptId,
        );
      }
      if (from < 8) {
        await migrator.createIndex(ratingHistorySpeedrunAttempt);
      }
      // 8 -> 9: o objetivo da primeira abertura. O perfil existe desde a
      // versão 1; quem já tinha o app fica sem objetivo.
      if (from < 9) await migrator.addColumn(profiles, profiles.goal);
      // 9 -> 10: a origem do rating e as contas do Lichess e do Chess.com.
      if (from < 10) {
        await migrator.addColumn(profiles, profiles.levelSource);
        await migrator.addColumn(profiles, profiles.lichessUser);
        await migrator.addColumn(profiles, profiles.chessComUser);
      }
      // 10 -> 11: o avatar e o país da conta.
      if (from < 11) {
        await migrator.addColumn(profiles, profiles.avatarColor);
        await migrator.addColumn(profiles, profiles.googlePhoto);
        await migrator.addColumn(profiles, profiles.country);
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

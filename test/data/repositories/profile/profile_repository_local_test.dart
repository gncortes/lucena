import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/data/repositories/profile/profile_repository_local.dart';
import 'package:lucena/data/services/database/app_database.dart';
import 'package:lucena/domain/models/goal_preference.dart';
import 'package:lucena/domain/models/level_source.dart';
import 'package:lucena/domain/models/user_profile.dart';

void main() {
  late Directory directory;

  // Cada chamada abre o arquivo do banco de novo, como ao reabrir o app.
  Future<T> reopen<T>(
    Future<T> Function(LocalProfileRepository repository) body,
  ) async {
    final database = AppDatabase(
      NativeDatabase(File('${directory.path}/lucena.sqlite')),
    );
    try {
      return await body(LocalProfileRepository(database));
    } finally {
      await database.close();
    }
  }

  setUp(() => directory = Directory.systemTemp.createTempSync('lucena_test'));
  tearDown(() => directory.deleteSync(recursive: true));

  test('sem nada gravado, devolve o perfil padrão', () async {
    expect(
      await reopen((repository) => repository.load()),
      const UserProfile(),
    );
  });

  test('o perfil gravado volta ao reabrir', () async {
    const profile = UserProfile(nickname: 'Capablanca', rating: 2700);
    await reopen((repository) => repository.save(profile));

    expect(await reopen((repository) => repository.load()), profile);
  });

  test('o objetivo gravado volta ao reabrir', () async {
    const profile = UserProfile(
      nickname: 'Ana',
      rating: 1450,
      goal: GoalPreference.train,
    );
    await reopen((repository) => repository.save(profile));

    expect(await reopen((repository) => repository.load()), profile);
  });

  test('a origem do rating e as contas voltam ao reabrir', () async {
    const profile = UserProfile(
      rating: 1712,
      levelSource: LevelSource.lichess,
      lichessUser: 'ana_xadrez',
      chessComUser: 'ana_cc',
    );
    await reopen((repository) => repository.save(profile));

    expect(await reopen((repository) => repository.load()), profile);
  });

  test('o avatar e o país voltam ao reabrir', () async {
    const profile = UserProfile(
      nickname: 'Ana',
      avatarColor: 3,
      googlePhoto: true,
      country: 'BR',
    );
    await reopen((repository) => repository.save(profile));

    expect(await reopen((repository) => repository.load()), profile);
  });

  test('o perfil da versão 10 volta com o avatar padrão e sem país', () async {
    final database = AppDatabase(
      NativeDatabase.memory(
        setup: (raw) {
          raw
            ..execute(
              'CREATE TABLE profiles (id INTEGER NOT NULL, nickname TEXT NOT '
              'NULL, rating INTEGER NOT NULL, goal TEXT NULL, level_source '
              'TEXT NULL, lichess_user TEXT NULL, chess_com_user TEXT NULL, '
              'PRIMARY KEY (id))',
            )
            ..execute(
              'INSERT INTO profiles (id, nickname, rating, lichess_user) '
              "VALUES (1, 'Ana', 1712, 'ana_xadrez')",
            )
            ..execute('PRAGMA user_version = 10');
        },
      ),
    );
    addTearDown(database.close);

    expect(
      await LocalProfileRepository(database).load(),
      const UserProfile(nickname: 'Ana', rating: 1712, lichessUser: 'ana_xadrez'),
    );
  });

  test('o perfil da versão 9 volta sem origem nem contas', () async {
    final database = AppDatabase(
      NativeDatabase.memory(
        setup: (raw) {
          raw
            ..execute(
              'CREATE TABLE profiles (id INTEGER NOT NULL, nickname TEXT NOT '
              'NULL, rating INTEGER NOT NULL, goal TEXT NULL, PRIMARY KEY (id))',
            )
            ..execute(
              'INSERT INTO profiles (id, nickname, rating, goal) '
              "VALUES (1, 'Ana', 1650, 'train')",
            )
            ..execute('PRAGMA user_version = 9');
        },
      ),
    );
    addTearDown(database.close);
    final repository = LocalProfileRepository(database);

    expect(
      await repository.load(),
      const UserProfile(
        nickname: 'Ana',
        rating: 1650,
        goal: GoalPreference.train,
      ),
    );
    await repository.save(
      const UserProfile(nickname: 'Ana', levelSource: LevelSource.manual),
    );
    expect((await repository.load()).levelSource, LevelSource.manual);
  });

  test('o perfil de antes do objetivo (versão 8) volta sem objetivo', () async {
    final database = AppDatabase(
      NativeDatabase.memory(
        setup: (raw) {
          raw
            ..execute(
              'CREATE TABLE profiles (id INTEGER NOT NULL, nickname TEXT NOT '
              'NULL, rating INTEGER NOT NULL, PRIMARY KEY (id))',
            )
            ..execute(
              "INSERT INTO profiles (id, nickname, rating) VALUES (1, 'Ana', 1650)",
            )
            ..execute('PRAGMA user_version = 8');
        },
      ),
    );
    addTearDown(database.close);
    final repository = LocalProfileRepository(database);

    expect(
      await repository.load(),
      const UserProfile(nickname: 'Ana', rating: 1650),
    );
    await repository.save(
      const UserProfile(
        nickname: 'Ana',
        rating: 1650,
        goal: GoalPreference.learn,
      ),
    );
    expect((await repository.load()).goal, GoalPreference.learn);
  });

  test('gravar de novo substitui o perfil anterior', () async {
    await reopen(
      (repository) =>
          repository.save(const UserProfile(nickname: 'Ana', rating: 900)),
    );
    await reopen(
      (repository) =>
          repository.save(const UserProfile(nickname: 'Bia', rating: 1650)),
    );

    expect(
      await reopen((repository) => repository.load()),
      const UserProfile(nickname: 'Bia', rating: 1650),
    );
  });

  test('apagar tudo volta ao perfil padrão', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final repository = LocalProfileRepository(database);
    await repository.save(const UserProfile(nickname: 'Ana', rating: 900));

    await database.deleteEverything();

    expect(await repository.load(), const UserProfile());
  });
}

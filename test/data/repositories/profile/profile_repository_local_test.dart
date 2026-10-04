import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/data/repositories/profile/profile_repository_local.dart';
import 'package:lucena/data/services/database/app_database.dart';
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

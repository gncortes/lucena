import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/goal_preference.dart';
import 'package:lucena/domain/models/level_source.dart';
import 'package:lucena/domain/models/user_profile.dart';
import 'package:lucena/ui/profile/view_models/profile_cubit.dart';

import '../../../../testing/fakes/fake_profile_repository.dart';

void main() {
  late FakeProfileRepository repository;

  const saved = UserProfile(nickname: 'Ana', rating: 1450);

  ProfileCubit build() => ProfileCubit(repository);

  setUp(() => repository = FakeProfileRepository(saved));

  test('começa sem perfil até a leitura terminar', () {
    expect(build().state, isNull);
  });

  blocTest<ProfileCubit, UserProfile?>(
    'carrega o perfil gravado',
    build: build,
    act: (cubit) => cubit.load(),
    expect: () => [saved],
  );

  blocTest<ProfileCubit, UserProfile?>(
    'salvar os dados grava o apelido limpo e o avatar, e mantém o resto',
    setUp: () => repository = FakeProfileRepository(
      saved.copyWith(
        goal: GoalPreference.learn,
        levelSource: LevelSource.lichess,
        lichessUser: 'ana_finais',
      ),
    ),
    build: build,
    act: (cubit) async {
      await cubit.load();
      await cubit.saveData(
        nickname: ' Bia ',
        avatarColor: 3,
        googlePhoto: true,
      );
    },
    skip: 1,
    expect: () => [
      saved.copyWith(
        nickname: 'Bia',
        avatarColor: 3,
        googlePhoto: true,
        goal: GoalPreference.learn,
        levelSource: LevelSource.lichess,
        lichessUser: 'ana_finais',
      ),
    ],
    verify: (cubit) => expect(repository.saved.last, cubit.state),
  );

  blocTest<ProfileCubit, UserProfile?>(
    'apelido vazio é gravado vazio (a tela mostra o padrão)',
    build: build,
    act: (cubit) async {
      await cubit.load();
      await cubit.saveData(nickname: '   ', avatarColor: 0, googlePhoto: false);
    },
    skip: 1,
    expect: () => [saved.copyWith(nickname: '')],
  );

  blocTest<ProfileCubit, UserProfile?>(
    'sem país gravado, fica o da região do celular',
    build: () => ProfileCubit(repository, region: () => 'br'),
    act: (cubit) => cubit.load(),
    expect: () => [saved.copyWith(country: 'BR')],
    verify: (_) => expect(repository.saved.single.country, 'BR'),
  );

  blocTest<ProfileCubit, UserProfile?>(
    'o país gravado não muda com a região',
    setUp: () =>
        repository = FakeProfileRepository(saved.copyWith(country: 'PT')),
    build: () => ProfileCubit(repository, region: () => 'BR'),
    act: (cubit) => cubit.load(),
    expect: () => [saved.copyWith(country: 'PT')],
    verify: (_) => expect(repository.saved, isEmpty),
  );

  blocTest<ProfileCubit, UserProfile?>(
    'trocar o objetivo grava só ele',
    build: build,
    act: (cubit) async {
      await cubit.load();
      await cubit.setGoal(GoalPreference.train);
    },
    skip: 1,
    expect: () => [saved.copyWith(goal: GoalPreference.train)],
    verify: (_) => expect(repository.saved, hasLength(1)),
  );
}

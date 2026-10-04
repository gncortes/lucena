import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/user_profile.dart';
import 'package:lucena/ui/profile/view_models/profile_cubit.dart';

import '../../../../testing/fakes/fake_profile_repository.dart';

void main() {
  late FakeProfileRepository repository;

  const saved = UserProfile(nickname: 'Ana', rating: 1500);

  ProfileCubit build() => ProfileCubit(repository);

  setUp(() => repository = FakeProfileRepository(saved));

  test('começa sem perfil até a leitura terminar', () {
    expect(build().state, const ProfileState());
  });

  blocTest<ProfileCubit, ProfileState>(
    'carrega o perfil gravado',
    build: build,
    act: (cubit) => cubit.load(),
    expect: () => [const ProfileState(profile: saved)],
  );

  blocTest<ProfileCubit, ProfileState>(
    'salvar com dados válidos grava e atualiza o estado',
    build: build,
    act: (cubit) async {
      await cubit.load();
      expect(await cubit.save(nickname: ' Bia ', rating: '1800'), isTrue);
    },
    skip: 1,
    expect: () => [
      const ProfileState(profile: UserProfile(nickname: 'Bia', rating: 1800)),
    ],
    verify: (_) => expect(repository.saved, [
      const UserProfile(nickname: 'Bia', rating: 1800),
    ]),
  );

  blocTest<ProfileCubit, ProfileState>(
    'rating fora da faixa aponta o erro e não grava nada',
    build: build,
    act: (cubit) async {
      await cubit.load();
      expect(await cubit.save(nickname: 'Bia', rating: '5000'), isFalse);
    },
    skip: 1,
    expect: () => [const ProfileState(profile: saved, ratingInvalid: true)],
    verify: (_) => expect(repository.saved, isEmpty),
  );

  blocTest<ProfileCubit, ProfileState>(
    'apelido vazio é gravado vazio (a tela mostra o padrão)',
    build: build,
    act: (cubit) async {
      await cubit.load();
      await cubit.save(nickname: '   ', rating: '1500');
    },
    skip: 1,
    expect: () => [const ProfileState(profile: UserProfile(rating: 1500))],
  );

  blocTest<ProfileCubit, ProfileState>(
    'salvar certo depois de um erro limpa o erro',
    build: build,
    act: (cubit) async {
      await cubit.load();
      await cubit.save(nickname: 'Ana', rating: '9999');
      await cubit.save(nickname: 'Ana', rating: '2000');
    },
    skip: 2,
    expect: () => [
      const ProfileState(profile: UserProfile(nickname: 'Ana', rating: 2000)),
    ],
  );

  blocTest<ProfileCubit, ProfileState>(
    'voltar a editar limpa o erro sem mexer no perfil',
    build: build,
    act: (cubit) async {
      await cubit.load();
      await cubit.save(nickname: 'Ana', rating: '9999');
      cubit.clearError();
    },
    skip: 2,
    expect: () => [const ProfileState(profile: saved)],
  );
}

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/rating_level.dart';
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
    'salvar grava o apelido limpo e o rating da faixa escolhida',
    build: build,
    act: (cubit) async {
      await cubit.load();
      await cubit.save(nickname: ' Bia ', level: RatingLevel.advanced);
    },
    skip: 1,
    expect: () => [
      UserProfile(nickname: 'Bia', rating: RatingLevel.advanced.rating),
    ],
    verify: (cubit) {
      expect(repository.saved, [cubit.state]);
      expect(cubit.state!.level, RatingLevel.advanced);
    },
  );

  blocTest<ProfileCubit, UserProfile?>(
    'apelido vazio é gravado vazio (a tela mostra o padrão)',
    build: build,
    act: (cubit) async {
      await cubit.load();
      await cubit.save(nickname: '   ', level: RatingLevel.intermediate);
    },
    skip: 1,
    expect: () => [UserProfile(rating: RatingLevel.intermediate.rating)],
  );
}

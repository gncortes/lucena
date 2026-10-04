import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/user_profile.dart';
import 'package:lucena/ui/core/keys/profile_keys.dart';
import 'package:lucena/ui/profile/view_models/profile_cubit.dart';
import 'package:lucena/ui/profile/widgets/profile_screen.dart';

import '../../../../testing/fakes/fake_profile_repository.dart';
import '../../../../testing/test_app.dart';

void main() {
  late FakeProfileRepository repository;

  Future<void> pumpScreen(
    WidgetTester tester, {
    UserProfile profile = const UserProfile(),
    Locale locale = const Locale('en'),
  }) async {
    repository = FakeProfileRepository(profile);
    final cubit = ProfileCubit(repository);
    addTearDown(cubit.close);
    await cubit.load();
    await tester.pumpWidget(
      TestApp(
        profileCubit: cubit,
        locale: locale,
        child: const ProfileScreen(),
      ),
    );
  }

  TextField field(WidgetTester tester, Key key) =>
      tester.widget<TextField>(find.byKey(key));

  Future<void> save(WidgetTester tester) async {
    await tester.tap(find.byKey(ProfileKeys.saveButton));
    await tester.pumpAndSettle();
  }

  testWidgets('os campos abrem com o perfil gravado', (tester) async {
    await pumpScreen(
      tester,
      profile: const UserProfile(nickname: 'Ana', rating: 1500),
    );

    expect(field(tester, ProfileKeys.nicknameField).controller!.text, 'Ana');
    expect(field(tester, ProfileKeys.ratingField).controller!.text, '1500');
  });

  testWidgets('sem apelido, o campo sugere o apelido padrão', (tester) async {
    await pumpScreen(tester);

    final nickname = field(tester, ProfileKeys.nicknameField);
    expect(nickname.controller!.text, isEmpty);
    expect(nickname.decoration!.hintText, 'Player');
  });

  testWidgets('salvar grava o que foi digitado', (tester) async {
    await pumpScreen(tester);

    await tester.enterText(find.byKey(ProfileKeys.nicknameField), 'Bia');
    await tester.enterText(find.byKey(ProfileKeys.ratingField), '1800');
    await save(tester);

    expect(repository.saved, [
      const UserProfile(nickname: 'Bia', rating: 1800),
    ]);
  });

  testWidgets('rating fora da faixa mostra o erro traduzido e não grava', (
    tester,
  ) async {
    await pumpScreen(tester, locale: const Locale('pt'));

    await tester.enterText(find.byKey(ProfileKeys.ratingField), '5000');
    await save(tester);

    expect(
      field(tester, ProfileKeys.ratingField).decoration!.errorText,
      'Digite um número de 100 a 3500',
    );
    expect(repository.saved, isEmpty);
  });

  testWidgets('o erro some quando o rating volta a ser editado', (
    tester,
  ) async {
    await pumpScreen(tester);
    await tester.enterText(find.byKey(ProfileKeys.ratingField), '5000');
    await save(tester);

    await tester.enterText(find.byKey(ProfileKeys.ratingField), '500');
    await tester.pump();

    expect(
      field(tester, ProfileKeys.ratingField).decoration!.errorText,
      isNull,
    );
  });

  testWidgets('o apelido não passa do tamanho máximo', (tester) async {
    await pumpScreen(tester);

    await tester.enterText(
      find.byKey(ProfileKeys.nicknameField),
      'a' * (UserProfile.maxNicknameLength + 10),
    );

    expect(
      field(tester, ProfileKeys.nicknameField).controller!.text,
      hasLength(UserProfile.maxNicknameLength),
    );
  });
}

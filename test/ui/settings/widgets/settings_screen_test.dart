import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/app_language.dart';
import 'package:lucena/domain/models/app_settings.dart';
import 'package:lucena/domain/models/app_theme_mode.dart';
import 'package:lucena/domain/models/user_profile.dart';
import 'package:lucena/ui/core/keys/settings_keys.dart';
import 'package:lucena/ui/profile/view_models/profile_cubit.dart';
import 'package:lucena/ui/settings/view_models/settings_cubit.dart';
import 'package:lucena/ui/settings/widgets/settings_screen.dart';

import '../../../../testing/fakes/fake_profile_repository.dart';
import '../../../../testing/fakes/fake_settings_repository.dart';
import '../../../../testing/test_app.dart';

void main() {
  Future<void> pumpScreen(
    WidgetTester tester,
    AppSettings settings, {
    UserProfile profile = const UserProfile(),
  }) async {
    final cubit = SettingsCubit(
      FakeSettingsRepository(settings),
      languages: AppLanguage.selectable,
    );
    addTearDown(cubit.close);
    await cubit.load();
    final profileCubit = ProfileCubit(FakeProfileRepository(profile));
    addTearDown(profileCubit.close);
    await profileCubit.load();
    await tester.pumpWidget(
      TestApp(
        settingsCubit: cubit,
        profileCubit: profileCubit,
        child: const SettingsScreen(),
      ),
    );
  }

  String languageValue(WidgetTester tester) =>
      tester.widget<Text>(find.byKey(SettingsKeys.languageValue)).data!;

  testWidgets('sem idioma escolhido, mostra "padrão do sistema"', (
    tester,
  ) async {
    await pumpScreen(tester, const AppSettings());

    expect(languageValue(tester), 'System default');
  });

  testWidgets('mostra o idioma escolhido com o nome na própria língua', (
    tester,
  ) async {
    await pumpScreen(tester, const AppSettings(languageCode: 'de'));

    expect(languageValue(tester), 'Deutsch');
  });

  String themeValue(WidgetTester tester) =>
      tester.widget<Text>(find.byKey(SettingsKeys.themeValue)).data!;

  testWidgets('sem tema escolhido, mostra "padrão do sistema"', (tester) async {
    await pumpScreen(tester, const AppSettings());

    expect(themeValue(tester), 'System default');
  });

  testWidgets('mostra o tema escolhido', (tester) async {
    await pumpScreen(tester, const AppSettings(themeMode: AppThemeMode.dark));

    expect(themeValue(tester), 'Dark');
  });

  String profileValue(WidgetTester tester) =>
      tester.widget<Text>(find.byKey(SettingsKeys.profileValue)).data!;

  testWidgets('sem apelido, o perfil mostra o apelido padrão e o rating', (
    tester,
  ) async {
    await pumpScreen(tester, const AppSettings());

    expect(profileValue(tester), 'Player · 1200');
  });

  testWidgets('mostra o apelido e o rating gravados', (tester) async {
    await pumpScreen(
      tester,
      const AppSettings(),
      profile: const UserProfile(nickname: 'Ana', rating: 1850),
    );

    expect(profileValue(tester), 'Ana · 1850');
  });
}

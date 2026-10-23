import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/data/repositories/account/account_repository.dart';
import 'package:lucena/domain/models/account.dart';
import 'package:lucena/domain/models/app_language.dart';
import 'package:lucena/domain/models/app_settings.dart';
import 'package:lucena/domain/models/app_theme_mode.dart';
import 'package:lucena/domain/models/goal_preference.dart';
import 'package:lucena/domain/models/user_profile.dart';
import 'package:lucena/ui/core/keys/settings_keys.dart';
import 'package:lucena/ui/profile/view_models/profile_cubit.dart';
import 'package:lucena/ui/settings/view_models/settings_cubit.dart';
import 'package:lucena/ui/settings/widgets/about_screen.dart';
import 'package:lucena/ui/settings/widgets/settings_screen.dart';
import 'package:lucena/ui/settings/widgets/settings_tiles.dart';

import '../../../../testing/fakes/fake_account_repository.dart';
import '../../../../testing/fakes/fake_profile_repository.dart';
import '../../../../testing/fakes/fake_settings_repository.dart';
import '../../../../testing/test_app.dart';

void main() {
  Future<void> pumpScreen(
    WidgetTester tester,
    AppSettings settings, {
    UserProfile profile = const UserProfile(),
    Widget screen = const SettingsScreen(),
    FakeAccountRepository? account,
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
      RepositoryProvider<AccountRepository>.value(
        value: account ?? FakeAccountRepository(),
        child: TestApp(
          settingsCubit: cubit,
          profileCubit: profileCubit,
          child: screen,
        ),
      ),
    );
  }

  String languageValue(WidgetTester tester) =>
      tester.widget<Text>(find.byKey(SettingsKeys.languageValue)).data!;

  testWidgets('sem idioma escolhido, mostra "padrão do sistema"', (
    tester,
  ) async {
    await pumpScreen(
      tester,
      const AppSettings(),
      screen: const AppearanceSettingsScreen(),
    );

    expect(languageValue(tester), 'System default');
  });

  testWidgets('mostra o idioma escolhido com o nome na própria língua', (
    tester,
  ) async {
    await pumpScreen(
      tester,
      const AppSettings(languageCode: 'de'),
      screen: const AppearanceSettingsScreen(),
    );

    expect(languageValue(tester), 'Deutsch');
  });

  String themeValue(WidgetTester tester) =>
      tester.widget<Text>(find.byKey(SettingsKeys.themeValue)).data!;

  testWidgets('sem tema escolhido, mostra "padrão do sistema"', (tester) async {
    await pumpScreen(
      tester,
      const AppSettings(),
      screen: const AppearanceSettingsScreen(),
    );

    expect(themeValue(tester), 'System default');
  });

  testWidgets('mostra o tema escolhido', (tester) async {
    await pumpScreen(
      tester,
      const AppSettings(themeMode: AppThemeMode.dark),
      screen: const AppearanceSettingsScreen(),
    );

    expect(themeValue(tester), 'Dark');
  });

  String profileValue(WidgetTester tester) =>
      tester.widget<Text>(find.byKey(SettingsKeys.profileValue)).data!;

  String profileName(WidgetTester tester) =>
      tester.widget<Text>(find.byKey(SettingsKeys.profileName)).data!;

  testWidgets('sem apelido e sem conta: o apelido padrão, "No account" e o '
      'rating', (tester) async {
    await pumpScreen(tester, const AppSettings());

    expect(profileName(tester), 'Player');
    expect(profileValue(tester), 'No account · ${UserProfile.defaultRating}');
  });

  testWidgets('com conta: o apelido, o e-mail, o objetivo e o rating', (
    tester,
  ) async {
    await pumpScreen(
      tester,
      const AppSettings(),
      profile: const UserProfile(
        nickname: 'Ana',
        rating: 1850,
        goal: GoalPreference.endgames,
      ),
      account: FakeAccountRepository(
        account: const Account(
          uid: 'u1',
          email: 'ana@example.com',
          provider: AccountProvider.email,
        ),
      ),
    );

    expect(profileName(tester), 'Ana');
    expect(profileValue(tester), startsWith('ana@example.com · '));
    expect(profileValue(tester), endsWith(' · 1850'));
  });

  testWidgets('mostra a versão do app no rodapé', (tester) async {
    await pumpScreen(
      tester,
      const AppSettings(),
      screen: const SettingsScreen(version: '0.3.2-rc.1'),
    );
    await tester.scrollUntilVisible(find.byKey(SettingsKeys.version), 200);

    expect(
      tester.widget<Text>(find.byKey(SettingsKeys.version)).data,
      'Version 0.3.2-rc.1',
    );
  });

  testWidgets('build local, sem versão: não mostra nada no rodapé', (
    tester,
  ) async {
    await pumpScreen(
      tester,
      const AppSettings(),
      screen: const SettingsScreen(version: ''),
    );

    expect(find.byKey(SettingsKeys.version), findsNothing);
  });

  testWidgets('o interruptor dos sons vem ligado e desligar muda a '
      'preferência', (tester) async {
    await pumpScreen(
      tester,
      const AppSettings(),
      screen: const SoundSettingsScreen(),
    );
    final tile = find.byKey(SettingsKeys.soundSwitch);
    await tester.scrollUntilVisible(tile, 200);
    expect(tester.widget<SwitchListTile>(tile).value, isTrue);

    await tester.tap(tile);
    await tester.pumpAndSettle();

    expect(tester.widget<SwitchListTile>(tile).value, isFalse);
  });

  testWidgets('o menu principal mostra o perfil, os grupos e o Sobre', (
    tester,
  ) async {
    await pumpScreen(tester, const AppSettings());

    for (final key in [
      SettingsKeys.profileTile,
      SettingsKeys.appearanceTile,
      SettingsKeys.gameTile,
      SettingsKeys.soundTile,
      SettingsKeys.alertsTile,
      SettingsKeys.aboutTile,
    ]) {
      expect(find.byKey(key), findsOneWidget);
    }
    // As opções ficam dentro dos grupos, não no menu.
    expect(find.byKey(SettingsKeys.languageTile), findsNothing);
    expect(find.byKey(SettingsKeys.soundSwitch), findsNothing);
  });

  testWidgets('Avisos diz quantas chaves estão ligadas', (tester) async {
    await pumpScreen(tester, const AppSettings());
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byKey(SettingsKeys.alertsTile),
        matching: find.text('3 of 4 on'),
      ),
      findsOneWidget,
    );
  });

  test('o site abre no idioma de quem usa', () {
    expect(
      AboutScreen.websiteFor('pt').toString(),
      'https://gncortes.github.io/lucena/',
    );
    expect(
      AboutScreen.websiteFor('es').toString(),
      'https://gncortes.github.io/lucena/es/',
    );
    expect(
      AboutScreen.websiteFor('de').toString(),
      'https://gncortes.github.io/lucena/en/',
    );
  });

  testWidgets('Sobre: Política e Termos depois das licenças, com o endereço', (
    tester,
  ) async {
    await pumpScreen(tester, const AppSettings(), screen: const AboutScreen());
    await tester.pumpAndSettle();
    final language = Localizations.localeOf(
      tester.element(find.byType(AboutScreen)),
    ).languageCode;

    final licenses = tester.getTopLeft(find.byKey(SettingsKeys.aboutLicenses));
    final privacy = tester.getTopLeft(find.byKey(SettingsKeys.aboutPrivacy));
    final terms = tester.getTopLeft(find.byKey(SettingsKeys.aboutTerms));
    expect(privacy.dy, greaterThan(licenses.dy));
    expect(terms.dy, greaterThan(privacy.dy));
    expect(
      find.descendant(
        of: find.byKey(SettingsKeys.aboutTerms),
        matching: find.text(AboutScreen.shown(AboutScreen.termsFor(language))),
      ),
      findsOneWidget,
    );
  });

  test('a política e os termos abrem no idioma de quem usa', () {
    expect(
      AboutScreen.privacyFor('pt').toString(),
      'https://gncortes.github.io/lucena/privacidade/',
    );
    expect(
      AboutScreen.termsFor('pt').toString(),
      'https://gncortes.github.io/lucena/termos/',
    );
    expect(
      AboutScreen.privacyFor('es').toString(),
      'https://gncortes.github.io/lucena/es/privacidad/',
    );
    expect(
      AboutScreen.termsFor('de').toString(),
      'https://gncortes.github.io/lucena/en/terms/',
    );
    expect(
      AboutScreen.shown(AboutScreen.privacyFor('pt')),
      'gncortes.github.io/lucena/privacidade',
    );
  });
}

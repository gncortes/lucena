import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/app_language.dart';
import 'package:lucena/domain/models/app_settings.dart';
import 'package:lucena/domain/models/user_profile.dart';
import 'package:lucena/ui/alerts/view_models/alerts_cubit.dart';
import 'package:lucena/ui/core/keys/region_keys.dart';
import 'package:lucena/ui/featured/view_models/featured_catalog_cubit.dart';
import 'package:lucena/ui/featured/widgets/featured_list_screen.dart';
import 'package:lucena/ui/profile/view_models/profile_cubit.dart';
import 'package:lucena/ui/region/widgets/country_screen.dart';
import 'package:lucena/ui/region/widgets/region_sheet.dart';
import 'package:lucena/ui/settings/view_models/settings_cubit.dart';

import '../../../testing/fakes/fake_alerts_repository.dart';
import '../../../testing/fakes/fake_featured_repositories.dart';
import '../../../testing/fakes/fake_now.dart';
import '../../../testing/fakes/fake_profile_repository.dart';
import '../../../testing/fakes/fake_push_repository.dart';
import '../../../testing/fakes/fake_region_prompt_repository.dart';
import '../../../testing/fakes/fake_settings_repository.dart';
import '../../../testing/test_app.dart';

void main() {
  late FakeProfileRepository profiles;
  late FakeRegionPromptRepository prompt;
  late ProfileCubit profile;
  late AlertsCubit alerts;

  Future<void> pump(WidgetTester tester, Widget Function() page) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(412, 915);
    addTearDown(tester.view.reset);
    profile = ProfileCubit(profiles, region: () => 'BR');
    alerts = AlertsCubit(
      alerts: FakeAlertsRepository(),
      push: FakePushRepository(allowed: true),
      profile: profiles,
    );
    addTearDown(profile.close);
    addTearDown(alerts.close);
    await profile.load();
    await alerts.load();
    await tester.pumpWidget(
      TestApp(
        locale: const Locale('pt'),
        profileCubit: profile,
        alertsCubit: alerts,
        regionPromptRepository: prompt,
        child: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: FilledButton(
                onPressed: () =>
                    Navigator.of(context)
                        .push(MaterialPageRoute<void>(builder: (_) => page())),
                child: const Text('abrir'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
  }

  setUp(() {
    profiles = FakeProfileRepository(
      const UserProfile(country: 'BR', state: 'PR', city: 'Curitiba'),
    );
    prompt = FakeRegionPromptRepository();
  });

  group('Seu país', () {
    testWidgets('o do celular em cima, com a nota e marcado', (tester) async {
      await pump(tester, CountryScreen.new);

      expect(find.text('Do seu celular'), findsOneWidget);
      expect(
        find.text('Escolhido pelo idioma e região do celular'),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(RegionKeys.countryOption('BR')),
          matching: find.byIcon(Icons.check_circle),
        ),
        findsOneWidget,
      );
    });

    testWidgets('escolher outro grava, limpa o estado e reinscreve', (
      tester,
    ) async {
      await pump(tester, CountryScreen.new);

      await tester.enterText(find.byKey(RegionKeys.countrySearch), 'portu');
      await tester.pumpAndSettle();
      expect(find.text('Do seu celular'), findsNothing);
      await tester.tap(find.byKey(RegionKeys.countryOption('PT')));
      await tester.pumpAndSettle();

      expect(find.byKey(RegionKeys.countryScreen), findsNothing);
      expect(profiles.profile, const UserProfile(country: 'PT'));
      expect(alerts.state.country, 'PT');
      expect(alerts.state.state, isNull);
    });

    testWidgets('a busca ignora acento; sem resultado, avisa', (tester) async {
      await pump(tester, CountryScreen.new);

      await tester.enterText(find.byKey(RegionKeys.countrySearch), 'japao');
      await tester.pumpAndSettle();
      expect(find.text('Japão'), findsOneWidget);

      await tester.enterText(find.byKey(RegionKeys.countrySearch), 'xyzw');
      await tester.pumpAndSettle();
      expect(find.byKey(RegionKeys.countryNotFound), findsOneWidget);
    });
  });

  group('folha de estado e cidade', () {
    Widget opener() => Builder(
      builder: (context) => Scaffold(
        body: Center(
          child: TextButton(
            onPressed: () => showRegionSheet(context),
            child: const Text('folha'),
          ),
        ),
      ),
    );

    Future<void> open(WidgetTester tester) async {
      await pump(tester, opener);
      await tester.tap(find.text('folha'));
      await tester.pumpAndSettle();
    }

    testWidgets('no Brasil, escolhe um dos estados e grava a sigla', (
      tester,
    ) async {
      profiles = FakeProfileRepository(const UserProfile(country: 'BR'));
      await open(tester);

      expect(find.text('Quer ver torneios perto de você?'), findsOneWidget);
      expect(
        find.textContaining('País: Brasil, do seu celular.'),
        findsOneWidget,
      );
      await tester.tap(find.byKey(RegionKeys.state));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.descendant(
          of: find.byKey(RegionKeys.state),
          matching: find.byType(TextField),
        ),
        'Paran',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Paraná').last);
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(RegionKeys.city), ' Curitiba ');
      await tester.tap(find.byKey(RegionKeys.save));
      await tester.pumpAndSettle();

      expect(find.byKey(RegionKeys.sheet), findsNothing);
      expect(
        profiles.profile,
        const UserProfile(country: 'BR', state: 'PR', city: 'Curitiba'),
      );
      expect(prompt.asked, isTrue);
      expect(alerts.state.state, 'PR');
    });

    testWidgets('fora do Brasil, o estado é digitado', (tester) async {
      profiles = FakeProfileRepository(const UserProfile(country: 'PT'));
      await open(tester);

      expect(find.textContaining('País: Portugal.'), findsOneWidget);
      await tester.enterText(find.byKey(RegionKeys.state), 'Lisboa');
      await tester.tap(find.byKey(RegionKeys.save));
      await tester.pumpAndSettle();

      expect(
        profiles.profile,
        const UserProfile(country: 'PT', state: 'Lisboa'),
      );
    });

    testWidgets('"Agora não" fecha sem gravar e não pergunta de novo', (
      tester,
    ) async {
      await open(tester);

      await tester.tap(find.byKey(RegionKeys.notNow));
      await tester.pumpAndSettle();

      expect(find.byKey(RegionKeys.sheet), findsNothing);
      expect(profiles.saved, isEmpty);
      expect(prompt.asked, isTrue);
    });
  });

  group('lista de finais de torneios', () {
    Widget list() => MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => SettingsCubit(
            FakeSettingsRepository(const AppSettings()),
            languages: AppLanguage.selectable,
          )..load(),
        ),
        BlocProvider(
          create: (_) => FeaturedCatalogCubit(
            featured: FakeFeaturedRepository(sampleFeaturedCatalog()),
            progress: FakeFeaturedProgressRepository(),
            now: FakeNow(DateTime(2026, 1, 1, 12)),
          )..load(),
        ),
      ],
      child: const FeaturedListScreen(),
    );

    testWidgets('na primeira abertura, pergunta o estado e a cidade', (
      tester,
    ) async {
      await pump(tester, list);

      expect(find.byKey(RegionKeys.sheet), findsOneWidget);
    });

    testWidgets('depois da primeira, não pergunta mais', (tester) async {
      prompt = FakeRegionPromptRepository(asked: true);
      await pump(tester, list);

      expect(find.byKey(RegionKeys.sheet), findsNothing);
    });
  });
}

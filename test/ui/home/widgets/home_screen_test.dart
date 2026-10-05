import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/ui/home/view_models/home_cubit.dart';
import 'package:lucena/ui/core/keys/home_keys.dart';
import 'package:lucena/ui/home/widgets/home_screen.dart';
import 'package:lucena/domain/models/app_language.dart';
import 'package:lucena/domain/models/app_settings.dart';
import 'package:lucena/ui/settings/view_models/settings_cubit.dart';

import '../../../../testing/fakes/fake_character_repository.dart';
import '../../../../testing/fakes/fake_journey_repository.dart';
import '../../../../testing/fakes/fake_onboarding_repository.dart';
import '../../../../testing/fakes/fake_progress_repository.dart';
import '../../../../testing/fakes/fake_rating_repository.dart';
import '../../../../testing/fakes/fake_profile_repository.dart';
import '../../../../testing/fakes/fake_school_repositories.dart';
import '../../../../testing/test_app.dart';
import '../../../../testing/fakes/fake_settings_repository.dart';

/// A tela inicial com o que ela lê (a Jornada, o rating), tudo falso.
class _Home extends StatelessWidget {
  const _Home(this.child);

  final Widget child;

  @override
  Widget build(BuildContext context) => MultiBlocProvider(
    providers: [
      // A miniatura do próximo desafio usa as cores do tabuleiro.
      BlocProvider(
        create: (_) => SettingsCubit(
          FakeSettingsRepository(const AppSettings()),
          languages: AppLanguage.selectable,
        )..load(),
      ),
      BlocProvider(
        create: (_) => HomeCubit(
          journey: FakeJourneyRepository(),
          progress: FakeProgressRepository(),
          onboarding: FakeOnboardingRepository(),
          characters: FakeCharacterRepository(),
          rating: FakeRatingRepository(),
          lessons: FakeLessonRepository(),
          school: FakeSchoolProgressRepository(),
          profile: FakeProfileRepository(),
        )..load(),
      ),
    ],
    child: child,
  );
}

void main() {
  String mascotAsset(WidgetTester tester) {
    final image = tester.widget<Image>(find.byKey(HomeKeys.mascot));
    return (image.image as AssetImage).assetName;
  }

  double opacityOf(WidgetTester tester, Key key) {
    final fade = tester.widget<FadeTransition>(
      find
          .ancestor(of: find.byKey(key), matching: find.byType(FadeTransition))
          .first,
    );
    return fade.opacity.value;
  }

  testWidgets('mostra o mascote claro no tema claro', (tester) async {
    await tester.pumpWidget(TestApp(child: _Home(HomeScreen())));

    expect(find.byKey(HomeKeys.screen), findsOneWidget);
    expect(mascotAsset(tester), 'assets/branding/mascot_light.png');
  });

  testWidgets('mostra o mascote escuro no tema escuro', (tester) async {
    await tester.pumpWidget(
      TestApp(themeMode: ThemeMode.dark, child: _Home(HomeScreen())),
    );

    expect(mascotAsset(tester), 'assets/branding/mascot_dark.png');
  });

  testWidgets('descreve o mascote para o leitor de tela', (tester) async {
    await tester.pumpWidget(TestApp(child: _Home(HomeScreen())));
    await tester.pumpAndSettle();

    expect(
      find.bySemanticsLabel('Lucena mascot: a chess pawn lifting dumbbells'),
      findsOneWidget,
    );
  });

  testWidgets('mostra o nome do app e a frase no idioma da tela', (
    tester,
  ) async {
    await tester.pumpWidget(
      TestApp(locale: Locale('pt'), child: _Home(HomeScreen())),
    );
    await tester.pumpAndSettle();

    expect(tester.widget<Text>(find.byKey(HomeKeys.title)).data, 'Lucena');
    expect(
      tester.widget<Text>(find.byKey(HomeKeys.tagline)).data,
      'Treino de finais de xadrez',
    );
  });

  testWidgets('entra em sequência: mascote, depois nome, depois frase', (
    tester,
  ) async {
    await tester.pumpWidget(TestApp(child: _Home(HomeScreen())));

    expect(opacityOf(tester, HomeKeys.mascot), 0);
    expect(opacityOf(tester, HomeKeys.title), 0);
    expect(opacityOf(tester, HomeKeys.tagline), 0);

    await tester.pump(const Duration(milliseconds: 450));

    expect(opacityOf(tester, HomeKeys.mascot), greaterThan(0));
    expect(opacityOf(tester, HomeKeys.tagline), 0);

    await tester.pumpAndSettle();

    expect(opacityOf(tester, HomeKeys.mascot), 1);
    expect(opacityOf(tester, HomeKeys.title), 1);
    expect(opacityOf(tester, HomeKeys.tagline), 1);
  });

  testWidgets('com animações reduzidas no sistema a tela já abre pronta', (
    tester,
  ) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);

    await tester.pumpWidget(TestApp(child: _Home(HomeScreen())));

    expect(opacityOf(tester, HomeKeys.mascot), 1);
    expect(opacityOf(tester, HomeKeys.tagline), 1);
  });

  testWidgets('mostra a versão do app no pé da tela', (tester) async {
    await tester.pumpWidget(
      TestApp(child: _Home(HomeScreen(version: '0.3.2-rc.1'))),
    );
    await tester.pumpAndSettle();
    // A versão fica no fim da tela, depois dos atalhos.
    await tester.scrollUntilVisible(find.byKey(HomeKeys.version), 200);

    expect(
      tester.widget<Text>(find.byKey(HomeKeys.version)).data,
      'Version 0.3.2-rc.1',
    );
  });

  testWidgets('build local, sem versão: não mostra nada no lugar', (
    tester,
  ) async {
    await tester.pumpWidget(TestApp(child: _Home(HomeScreen(version: ''))));
    await tester.pumpAndSettle();

    expect(find.byKey(HomeKeys.version), findsNothing);
  });
}

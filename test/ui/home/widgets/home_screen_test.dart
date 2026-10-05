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
  double opacityOf(WidgetTester tester, Key key) {
    final fade = tester.widget<FadeTransition>(
      find
          .ancestor(of: find.byKey(key), matching: find.byType(FadeTransition))
          .first,
    );
    return fade.opacity.value;
  }

  testWidgets('no alto, só o nome do app (sem mascote nem frase)', (
    tester,
  ) async {
    await tester.pumpWidget(
      TestApp(locale: Locale('pt'), child: _Home(HomeScreen())),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(HomeKeys.screen), findsOneWidget);
    expect(tester.widget<Text>(find.byKey(HomeKeys.title)).data, 'Lucena');
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Image &&
            widget.image is AssetImage &&
            (widget.image as AssetImage).assetName.contains('mascot'),
      ),
      findsNothing,
    );
    expect(find.text('Treino de finais de xadrez'), findsNothing);
  });

  testWidgets('entra em sequência: o nome, depois o painel', (tester) async {
    await tester.pumpWidget(TestApp(child: _Home(HomeScreen())));

    expect(opacityOf(tester, HomeKeys.title), 0);

    await tester.pump(const Duration(milliseconds: 450));
    expect(opacityOf(tester, HomeKeys.title), greaterThan(0));

    await tester.pumpAndSettle();
    expect(opacityOf(tester, HomeKeys.title), 1);
    expect(opacityOf(tester, HomeKeys.journeyButton), 1);
  });

  testWidgets('com animações reduzidas no sistema a tela já abre pronta', (
    tester,
  ) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);

    await tester.pumpWidget(TestApp(child: _Home(HomeScreen())));
    await tester.pump();

    expect(opacityOf(tester, HomeKeys.title), 1);
  });
}

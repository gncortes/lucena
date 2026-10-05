import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/ui/home/view_models/home_cubit.dart';
import 'package:lucena/ui/core/keys/home_keys.dart';
import 'package:lucena/ui/home/widgets/home_screen.dart';
import 'package:lucena/ui/home/widgets/path_card.dart';
import 'package:lucena/domain/models/rating_level.dart';
import 'package:lucena/domain/models/user_profile.dart';
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
  const _Home(this.child, {this.profile = const UserProfile()});

  final Widget child;
  final UserProfile profile;

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
          profile: FakeProfileRepository(profile),
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

  // Uma tela alta, para a lista montar todos os caminhos de uma vez.
  Future<void> pumpTall(
    WidgetTester tester, {
    UserProfile profile = const UserProfile(),
  }) async {
    tester.view.physicalSize = const Size(1080, 4800);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      TestApp(
        locale: const Locale('pt'),
        child: _Home(const HomeScreen(), profile: profile),
      ),
    );
    await tester.pumpAndSettle();
  }

  double top(WidgetTester tester, Key key) =>
      tester.getTopLeft(find.byKey(key)).dy;

  testWidgets('cada caminho diz o que se faz nele; para quem já joga, a '
      'Jornada vem primeiro e as aulas por último', (tester) async {
    await pumpTall(tester);

    expect(find.text('O que você quer fazer?'), findsOneWidget);
    for (final (key, title, body) in [
      (
        HomeKeys.journeyButton,
        'Jornada',
        'Treino guiado: vença os finais de cada adversário, do mais fraco '
            'até o Stockfish.',
      ),
      (
        HomeKeys.speedrunButton,
        'Speedrun',
        'Escolha um final e vença todos os adversários em sequência, até o '
            'Stockfish, contra o relógio.',
      ),
      (
        HomeKeys.catalogButton,
        'Treinar finais',
        'Escolha qualquer final e o adversário, e jogue quantas vezes '
            'quiser.',
      ),
      (
        HomeKeys.schoolButton,
        'Aprender a jogar xadrez',
        'Aulas com o Viktor: como as peças se movem, xeque, mate e os '
            'primeiros finais.',
      ),
    ]) {
      final card = find.byKey(key);
      expect(
        find.descendant(of: card, matching: find.text(title)),
        findsOneWidget,
      );
      expect(
        find.descendant(of: card, matching: find.text(body)),
        findsOneWidget,
      );
    }
    final order = [
      HomeKeys.whereCard,
      HomeKeys.journeyButton,
      HomeKeys.speedrunButton,
      HomeKeys.catalogButton,
      HomeKeys.schoolButton,
      HomeKeys.stats,
      HomeKeys.freeBoardButton,
    ].map((key) => top(tester, key)).toList();
    expect(order, [...order]..sort());
    expect(
      tester.widget<PathCard>(find.byKey(HomeKeys.journeyButton)).highlighted,
      isTrue,
    );
  });

  testWidgets('para o iniciante, "Aprender a jogar xadrez" vem primeiro e em '
      'destaque', (tester) async {
    await pumpTall(
      tester,
      profile: UserProfile(rating: RatingLevel.beginner.rating),
    );

    expect(
      top(tester, HomeKeys.schoolButton),
      lessThan(top(tester, HomeKeys.journeyButton)),
    );
    expect(
      tester.widget<PathCard>(find.byKey(HomeKeys.schoolButton)).highlighted,
      isTrue,
    );
    expect(
      tester.widget<PathCard>(find.byKey(HomeKeys.journeyButton)).highlighted,
      isFalse,
    );
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

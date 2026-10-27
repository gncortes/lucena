import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/ui/home/view_models/home_cubit.dart';
import 'package:lucena/ui/core/keys/home_keys.dart';
import 'package:lucena/ui/home/widgets/home_screen.dart';
import 'package:lucena/domain/models/endgame_lesson.dart';
import 'package:lucena/domain/models/goal_preference.dart';
import 'package:lucena/domain/models/onboarding.dart';
import 'package:lucena/domain/models/user_profile.dart';
import 'package:lucena/domain/models/app_language.dart';
import 'package:lucena/domain/models/app_settings.dart';
import 'package:lucena/ui/settings/view_models/settings_cubit.dart';
import 'package:lucena/domain/models/attempt.dart';
import 'package:lucena/domain/models/game_setup.dart';
import 'package:lucena/domain/models/home_shortcut.dart';
import 'package:lucena/ui/core/keys/featured_keys.dart';
import 'package:lucena/ui/home/widgets/mode_tile.dart';

import '../../../../testing/fakes/fake_character_repository.dart';
import '../../../../testing/fakes/fake_home_layout_repository.dart';
import '../../../../testing/fakes/fake_journey_repository.dart';
import '../../../../testing/fakes/fake_onboarding_repository.dart';
import '../../../../testing/fakes/fake_progress_repository.dart';
import '../../../../testing/fakes/fake_rating_repository.dart';
import '../../../../testing/fakes/fake_positions_repository.dart';
import '../../../../testing/fakes/fake_profile_repository.dart';
import '../../../../testing/fakes/fake_school_repositories.dart';
import '../../../../testing/test_app.dart';
import '../../../../testing/fakes/fake_settings_repository.dart';
import '../../../../testing/fakes/fake_endgame_repositories.dart';
import '../../../../testing/fakes/fake_featured_repositories.dart';
import '../../../../testing/fakes/fake_now.dart';
import '../../../../testing/goldens/golden_harness.dart';

/// A tela inicial com o que ela lê (a Jornada, o rating), tudo falso.
class _Home extends StatelessWidget {
  const _Home(
    this.child, {
    this.profile = const UserProfile(),
    this.endgames = const EndgameProgress(),
    this.onboarding,
    this.trail,
    this.progress,
    this.featured = false,
  });

  final Widget child;
  final UserProfile profile;
  final EndgameProgress endgames;
  final FakeOnboardingRepository? onboarding;
  final EndgameTrail? trail;
  final FakeProgressRepository? progress;

  /// Com o catálogo de finais em destaque de exemplo.
  final bool featured;

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
          progress: progress ?? FakeProgressRepository(),
          onboarding: onboarding ?? FakeOnboardingRepository(),
          characters: FakeCharacterRepository(),
          rating: FakeRatingRepository(),
          lessons: FakeLessonRepository(),
          school: FakeSchoolProgressRepository(),
          profile: FakeProfileRepository(profile),
          endgameLessons: FakeEndgameLessonRepository(trail: trail),
          endgameProgress: FakeEndgameProgressRepository(endgames),
          homeLayout: FakeHomeLayoutRepository(),
          featured: featured
              ? FakeFeaturedRepository(sampleFeaturedCatalog())
              : null,
          featuredProgress: featured ? FakeFeaturedProgressRepository() : null,
          now: FakeNow(DateTime(2026, 1, 1, 12)),
          positions: FakePositionsRepository(),
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

  double top(WidgetTester tester, Key key) =>
      tester.getTopLeft(find.byKey(key)).dy;

  Future<void> pumpHome(
    WidgetTester tester, {
    UserProfile profile = const UserProfile(),
    EndgameProgress endgames = const EndgameProgress(),
    EndgameTrail? trail,
    FakeOnboardingRepository? onboarding,
    FakeProgressRepository? progress,
    bool featured = false,
    Locale locale = const Locale('pt'),
    Size size = const Size(360, 1600),
  }) async {
    tester.view
      ..physicalSize = size
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      TestApp(
        locale: locale,
        child: _Home(
          const HomeScreen(),
          profile: profile,
          endgames: endgames,
          trail: trail,
          onboarding: onboarding,
          progress: progress,
          featured: featured,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  String text(WidgetTester tester, Key key) =>
      tester.widget<Text>(find.byKey(key)).data!;

  String action(WidgetTester tester) => tester
      .widget<Text>(
        find.descendant(
          of: find.byKey(HomeKeys.goalAction),
          matching: find.byType(Text),
        ),
      )
      .data!;

  /// As keys dos atalhos na tela, na ordem.
  List<Key> tiles(WidgetTester tester) {
    final shown =
        [
          for (final shortcut in HomeShortcut.values)
            if (find.byKey(shortcut.key).evaluate().isNotEmpty) shortcut,
        ]..sort((a, b) {
          final pa = tester.getTopLeft(find.byKey(a.key));
          final pb = tester.getTopLeft(find.byKey(b.key));
          return pa.dy == pb.dy
              ? pa.dx.compareTo(pb.dx)
              : pa.dy.compareTo(pb.dy);
        });
    return [for (final shortcut in shown) shortcut.key];
  }

  Future<FakeProgressRepository> wonCoco() async {
    final progress = FakeProgressRepository();
    final challenge = sampleLadder.first.challenges.first;
    await progress.addAttempt(
      Attempt(
        positionId: challenge.position.id,
        challengeId: challenge.id,
        playedAt: DateTime(2026, 1, 1, 10),
        outcome: AttemptOutcome.win,
        fulfilled: true,
        opponent: OpponentKind.maia,
        opponentLevel: 1000,
      ),
    );
    return progress;
  }

  const firstSteps = FakeOnboardingRepository.new;
  const learner = UserProfile(rating: 800, goal: GoalPreference.learn);

  testWidgets('aprender a jogar, antes da 1ª partida: os primeiros passos e '
      'só Estrelas e Problemas', (tester) async {
    await pumpHome(tester, profile: learner);

    expect(text(tester, HomeKeys.heroLabel), 'Primeiros passos');
    expect(text(tester, HomeKeys.goalTitle), 'Como mover as peças');
    expect(action(tester), 'Começar');
    expect(tiles(tester), [HomeKeys.starsButton, HomeKeys.raceButton]);
    // Sem destaque antes da primeira vitória.
    expect(find.byKey(FeaturedKeys.homeSection), findsNothing);
  });

  testWidgets('aprender a jogar, depois do Coco: a Jornada no cartão e as '
      'Estrelas primeiro', (tester) async {
    await pumpHome(
      tester,
      profile: learner,
      onboarding: firstSteps(
        const Onboarding(done: true, boardControlsDone: true),
      ),
      progress: await wonCoco(),
    );

    expect(text(tester, HomeKeys.heroLabel), 'Jornada');
    expect(action(tester), 'Jogar');
    expect(find.byKey(HomeKeys.heroBoard), findsOneWidget);
    final shown = tiles(tester);
    expect(shown, hasLength(4));
    expect(shown.first, HomeKeys.starsButton);
    expect(shown.last, HomeKeys.raceButton);
    expect(shown, isNot(contains(HomeKeys.journeyButton)));
  });

  testWidgets('aprender finais: o capítulo no cartão, sem o Curso nos '
      'atalhos', (tester) async {
    await pumpHome(
      tester,
      profile: const UserProfile(rating: 1450, goal: GoalPreference.endgames),
      locale: const Locale('en'),
    );

    expect(text(tester, HomeKeys.heroLabel), 'Endgame course');
    expect(text(tester, HomeKeys.goalTitle), 'The Lucena position');
    expect(action(tester), 'Start');
    expect(tiles(tester), [
      HomeKeys.journeyButton,
      HomeKeys.catalogButton,
      HomeKeys.speedrunButton,
      HomeKeys.raceButton,
    ]);
  });

  testWidgets('aula de final aberta: Continuar, a barra e o exercício em '
      'miniatura', (tester) async {
    await pumpHome(
      tester,
      locale: const Locale('en'),
      endgames: const EndgameProgress(
        lessons: {
          'rook.lucena': EndgameLessonProgress(
            lessonDone: true,
            stars: {'e01': 1},
            exercise: ExerciseCheckpoint(exerciseId: 'e02'),
          ),
        },
      ),
    );

    expect(text(tester, HomeKeys.goalTitle), 'The Lucena position');
    expect(action(tester), 'Continue');
    expect(find.byKey(HomeKeys.heroProgress), findsOneWidget);
    expect(find.byKey(HomeKeys.heroBoard), findsOneWidget);
  });

  testWidgets('treinar finais: o final da faixa no cartão, sem Treinar nos '
      'atalhos', (tester) async {
    await pumpHome(
      tester,
      profile: const UserProfile(rating: 1450, goal: GoalPreference.train),
    );

    expect(text(tester, HomeKeys.heroLabel), 'Treinar finais');
    expect(action(tester), 'Treinar');
    expect(tiles(tester), [
      HomeKeys.journeyButton,
      HomeKeys.endgamesButton,
      HomeKeys.speedrunButton,
      HomeKeys.raceButton,
    ]);
  });

  testWidgets('sem objetivo: a Jornada no cartão e quatro atalhos', (
    tester,
  ) async {
    await pumpHome(tester, profile: const UserProfile(rating: 1450));

    expect(text(tester, HomeKeys.heroLabel), 'Jornada');
    expect(find.byKey(HomeKeys.journeyButton), findsNothing);
    expect(tiles(tester), hasLength(4));
    expect(tiles(tester).last, HomeKeys.raceButton);
  });

  testWidgets('sem aula liberada: nem o Curso de finais nos atalhos', (
    tester,
  ) async {
    await pumpHome(
      tester,
      profile: const UserProfile(rating: 1450, goal: GoalPreference.endgames),
      trail: const EndgameTrail(modules: []),
    );

    expect(text(tester, HomeKeys.heroLabel), 'Treinar finais');
    expect(find.byKey(HomeKeys.endgamesButton), findsNothing);
    expect(find.byKey(HomeKeys.forYouButton), findsNothing);
    expect(tiles(tester), hasLength(4));
  });

  testWidgets('finais em destaque: o título, "Ver mais" e o cartão compacto', (
    tester,
  ) async {
    await pumpHome(
      tester,
      profile: const UserProfile(rating: 1450),
      featured: true,
    );

    expect(text(tester, HomeKeys.featuredTitle), 'Finais em destaque');
    expect(find.byKey(FeaturedKeys.homeSeeAll), findsOneWidget);
    expect(find.byKey(FeaturedKeys.homeCard), findsOneWidget);
    expect(
      top(tester, HomeKeys.goalCard),
      lessThan(top(tester, FeaturedKeys.homeCard)),
    );
    expect(
      top(tester, FeaturedKeys.homeCard),
      lessThan(top(tester, HomeKeys.shortcutsTitle)),
    );
  });

  testWidgets('a 360: os atalhos com a mesma altura, a frase em duas linhas '
      'e nada estourando', (tester) async {
    await Goldens.loadFonts();
    await pumpHome(tester, profile: const UserProfile(rating: 1450));

    final heights = {
      for (final key in tiles(tester)) tester.getSize(find.byKey(key)).height,
    };
    expect(heights, {ModeTile.height});
    for (final key in tiles(tester)) {
      final body = find
          .descendant(of: find.byKey(key), matching: find.byType(Text))
          .last;
      expect(tester.widget<Text>(body).maxLines, 2);
    }
    expect(find.text('Mais de 3.500 finais de todos os tipos'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('o topo: o rating com a seta, sem "Seu rating" nem "Olá"', (
    tester,
  ) async {
    await pumpHome(
      tester,
      profile: const UserProfile(nickname: 'Ana', rating: 1450),
    );

    expect(find.byKey(HomeKeys.ratingValue), findsOneWidget);
    expect(find.byKey(HomeKeys.ratingPending), findsNothing);
    expect(find.text('Seu rating'), findsNothing);
    expect(find.textContaining('Olá'), findsNothing);
    expect(find.textContaining('Ana'), findsNothing);
    expect(find.byKey(HomeKeys.settingsButton), findsOneWidget);
  });

  testWidgets('quem aprende a jogar: "Começando" no lugar do número', (
    tester,
  ) async {
    await pumpHome(tester, profile: learner);

    expect(find.byKey(HomeKeys.ratingValue), findsNothing);
    expect(text(tester, HomeKeys.ratingPending), 'Começando');
  });

  testWidgets('o nome do app e o rating ficam fixos ao rolar a tela', (
    tester,
  ) async {
    await pumpHome(tester, size: const Size(360, 640));
    final before = tester.getTopLeft(find.byKey(HomeKeys.title));

    await tester.scrollUntilVisible(
      find.byKey(HomeKeys.raceButton),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(tester.getTopLeft(find.byKey(HomeKeys.title)), before);
    expect(find.byKey(HomeKeys.settingsButton).hitTestable(), findsOneWidget);
  });

  testWidgets('entra em sequência: o nome, depois o painel', (tester) async {
    await tester.pumpWidget(TestApp(child: _Home(HomeScreen())));

    expect(opacityOf(tester, HomeKeys.title), 0);

    await tester.pump(const Duration(milliseconds: 450));
    expect(opacityOf(tester, HomeKeys.title), greaterThan(0));

    await tester.pumpAndSettle();
    expect(opacityOf(tester, HomeKeys.title), 1);
    expect(opacityOf(tester, HomeKeys.goalCard), 1);
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

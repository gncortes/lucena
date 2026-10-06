import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/ui/home/view_models/home_cubit.dart';
import 'package:lucena/ui/core/keys/home_keys.dart';
import 'package:lucena/ui/home/widgets/home_screen.dart';
import 'package:lucena/domain/models/endgame_lesson.dart';
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
import '../../../../testing/fakes/fake_endgame_repositories.dart';

/// A tela inicial com o que ela lê (a Jornada, o rating), tudo falso.
class _Home extends StatelessWidget {
  const _Home(
    this.child, {
    this.profile = const UserProfile(),
    this.endgames = const EndgameProgress(),
  });

  final Widget child;
  final UserProfile profile;
  final EndgameProgress endgames;

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
          endgameLessons: FakeEndgameLessonRepository(),
          endgameProgress: FakeEndgameProgressRepository(endgames),
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

  testWidgets('a aula de final aberta: o cartão diz onde parou e continua '
      'direto no exercício', (tester) async {
    await tester.pumpWidget(
      TestApp(
        locale: Locale('en'),
        child: _Home(
          HomeScreen(),
          endgames: EndgameProgress(
            lessons: {
              'rook.lucena': EndgameLessonProgress(
                lessonDone: true,
                stars: {'e01': 1},
                exercise: ExerciseCheckpoint(exerciseId: 'e02'),
              ),
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(HomeKeys.endgameCard), findsOneWidget);
    expect(find.byKey(HomeKeys.schoolCard), findsNothing);
    expect(
      tester.widget<Text>(find.byKey(HomeKeys.endgameTitle)).data,
      'The Lucena position',
    );
    expect(
      tester.widget<Text>(find.byKey(HomeKeys.endgameWhere)).data,
      'Exercise 2 of 3',
    );
    expect(find.byKey(HomeKeys.endgameContinue), findsOneWidget);
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

  testWidgets('cada caminho diz o que se faz nele, na ordem de quem está '
      'aprendendo: aulas, Jornada, speedrun e finais avulsos', (tester) async {
    await pumpTall(tester);

    expect(find.text('O que você quer fazer?'), findsOneWidget);
    for (final (key, title, body) in [
      (
        HomeKeys.schoolButton,
        'Aprender a jogar xadrez',
        'Aulas com o Viktor: como as peças se movem, xeque, mate e os '
            'primeiros finais.',
      ),
      (
        HomeKeys.journeyButton,
        'Jornada',
        'O passo seguinte às aulas: pratique vencendo os finais de cada '
            'adversário, do mais fraco até o Stockfish.',
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
      HomeKeys.schoolButton,
      HomeKeys.journeyButton,
      HomeKeys.speedrunButton,
      HomeKeys.catalogButton,
      HomeKeys.freeBoardButton,
    ].map((key) => top(tester, key)).toList();
    expect(order, [...order]..sort());
    // Os quatro caminhos têm a mesma cor: nenhum em destaque.
    final colors = {
      for (final key in [
        HomeKeys.schoolButton,
        HomeKeys.journeyButton,
        HomeKeys.speedrunButton,
        HomeKeys.catalogButton,
      ])
        tester
            .widget<Material>(
              find
                  .descendant(
                    of: find.byKey(key),
                    matching: find.byType(Material),
                  )
                  .first,
            )
            .color,
    };
    expect(colors, hasLength(1));
    // Os números do jogador saíram daqui: ficam nos detalhes do rating.
    expect(find.text('Partidas'), findsNothing);
    expect(find.text('Dias seguidos'), findsNothing);
  });

  testWidgets('o nome do app e os botões ficam fixos ao rolar a tela', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 1500);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      TestApp(locale: const Locale('pt'), child: _Home(const HomeScreen())),
    );
    await tester.pumpAndSettle();
    final before = tester.getTopLeft(find.byKey(HomeKeys.title));

    await tester.scrollUntilVisible(
      find.byKey(HomeKeys.freeBoardButton),
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

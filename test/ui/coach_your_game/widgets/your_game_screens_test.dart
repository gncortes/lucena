import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lucena/data/repositories/training/course_training_repository.dart';
import 'package:lucena/data/repositories/coach/your_game_filter_repository.dart';
import 'package:lucena/data/repositories/coach/coach_repository.dart';
import 'package:lucena/data/services/preferences_service.dart';
import 'package:lucena/domain/models/app_language.dart';
import 'package:lucena/domain/models/course_access.dart';
import 'package:lucena/domain/models/training/training_content.dart';
import 'package:lucena/domain/models/training/training_course.dart';
import 'package:lucena/domain/models/training/training_course_config.dart';
import 'package:lucena/domain/models/training/training_resources.dart';
import 'package:lucena/domain/models/coach/coach.dart';
import 'package:lucena/domain/use_cases/now.dart';
import 'package:lucena/ui/core/keys/coach_your_game_keys.dart';
import 'package:lucena/ui/core/widgets/highlight_card.dart';
import 'package:lucena/ui/core/widgets/tip_box.dart';
import 'package:lucena/ui/course_guide/view_models/course_guide_cubit.dart';
import 'package:lucena/ui/settings/view_models/settings_cubit.dart';
import 'package:lucena/ui/coach_your_game/widgets/coach_goals_highlight.dart';
import 'package:lucena/ui/coach_your_game/widgets/model_games_screen.dart';
import 'package:lucena/ui/coach_your_game/widgets/pilares_opening_screen.dart';
import 'package:lucena/ui/coach_your_game/widgets/your_game_tab.dart';
import 'package:lucena/ui/coach_your_game/widgets/your_game_parts.dart';
import 'package:lucena/ui/coach_your_game/widgets/motif_screen.dart';
import 'package:lucena/ui/coach_your_game/widgets/theory_screen.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import '../../../../testing/fakes/fake_course_training_repository.dart';
import '../../../../testing/fakes/fake_lesson_ad_repositories.dart';
import '../../../../testing/fakes/fake_now.dart';
import '../../../../testing/fakes/fake_settings_repository.dart';
import '../../../../testing/fakes/fake_coach_repository.dart';
import '../../../../testing/test_app.dart';
import '../../../../testing/coach_fixtures.dart';
import '../../../../testing/coach_your_game_fixtures.dart';

final _resources = TrainingResources(
  lessons: [
    for (final id in ['pilares.ab1.caroKann1', 'pilares.ab2.caroKann2'])
      TrainingLesson(id: id, kind: TrainingLessonKind.opening, title: id),
  ],
);

void main() {
  setUp(
    () => SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty(),
  );

  /// Aparelho padrão (1080x2400 a 420 dpi) e as dependências da frente.
  Future<void> open(
    WidgetTester tester,
    Widget screen, {
    CoachRepository? repo,
    CourseAccess grant = CourseAccess.demo,
    GoRouter? router,
  }) async {
    tester.view
      ..physicalSize = const Size(1080, 2400)
      ..devicePixelRatio = 420 / 160;
    addTearDown(tester.view.reset);
    final training = FakeTrainingRepository(
      content: {TrainingCourse.pilares: _resources},
    );
    final settings = SettingsCubit(
      FakeSettingsRepository(),
      languages: AppLanguage.selectable,
    );
    await settings.load();
    addTearDown(settings.close);
    await tester.pumpWidget(
      MultiRepositoryProvider(
        providers: [
          RepositoryProvider<CoachRepository>.value(
            value:
                repo ??
                FakeCoachRepository(
                  account: CoachFixtures.account,
                  games: YourGameFixtures.games(),
                  stats: YourGameFixtures.stats(),
                ),
          ),
          RepositoryProvider<YourGameFilterRepository>.value(
            value: YourGameFilterRepository(PreferencesService()),
          ),
          RepositoryProvider<Now>.value(
            value: FakeNow(YourGameFixtures.currentTime),
          ),
          RepositoryProvider<TrainingRepository>.value(value: training),
        ],
        child: TestApp(
          locale: const Locale('pt'),
          settingsCubit: settings,
          courseAccessRepository: FakeCourseAccessRepository(grant),
          router: router,
          child: screen,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('aba Seu jogo', () {
    testWidgets('60 partidas: números, foco na abertura e temas', (
      tester,
    ) async {
      await open(tester, const YourGameScreen());
      expect(find.byKey(YourGameKeys.base), findsOneWidget);
      expect(find.byKey(YourGameKeys.numbers), findsOneWidget);
      expect(find.byKey(YourGameKeys.focus), findsOneWidget);
      expect(find.byKey(YourGameKeys.fewNotice), findsNothing);
      await tester.scrollUntilVisible(
        find.byKey(YourGameKeys.motifs),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.byKey(YourGameKeys.motif('garfo')), findsOneWidget);
    });

    testWidgets('poucas partidas: o aviso no lugar dos números', (
      tester,
    ) async {
      await open(
        tester,
        const YourGameScreen(),
        repo: FakeCoachRepository(
          account: CoachFixtures.account,
          games: YourGameFixtures.games(5),
          stats: YourGameFixtures.stats(level: 'primeira'),
        ),
      );
      expect(find.byKey(YourGameKeys.few), findsOneWidget);
      expect(find.byKey(YourGameKeys.numbers), findsNothing);
      // Canvas DSeuJogoPoucas: o estilo abre com a ressalva.
      final style = tester.widget<Text>(find.byKey(YourGameKeys.styleText));
      expect(style.data, startsWith('Ainda é cedo para falar de estilo. '));
      await tester.scrollUntilVisible(
        find.byKey(YourGameKeys.fewNotice),
        300,
        scrollable: find.byType(Scrollable).first,
      );
    });

    testWidgets('sem partida: o estado vazio', (tester) async {
      await open(
        tester,
        const YourGameScreen(),
        repo: FakeCoachRepository(account: CoachFixtures.account),
      );
      expect(find.byKey(YourGameKeys.empty), findsOneWidget);
    });
  });

  group('layout do QA (411x914)', () {
    testWidgets('chips de ritmo numa linha só', (tester) async {
      await open(tester, const YourGameScreen());
      final tops = [
        for (final r in ['todos', 'bullet', 'blitz', 'rapida'])
          tester.getTopLeft(find.byKey(YourGameKeys.timeControl(r))).dy,
      ];
      expect(tops.toSet(), hasLength(1));
    });

    testWidgets('barra do placar tem altura e largura', (tester) async {
      await open(tester, const YourGameScreen());
      await tester.scrollUntilVisible(
        find.byKey(YourGameKeys.opening(0)),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      final bar = find.descendant(
        of: find.byKey(YourGameKeys.opening(0)),
        matching: find.byType(ScoreBar),
      );
      final size_ = tester.getSize(bar);
      expect(size_.height, greaterThan(0));
      expect(size_.width, greaterThan(100));
      final bands = find.descendant(of: bar, matching: find.byType(ColoredBox));
      expect(bands, findsWidgets);
      for (final f in bands.evaluate()) {
        expect(f.size!.height, greaterThan(0));
        expect(f.size!.width, greaterThan(0));
      }
    });

    testWidgets('degraus do medidor de confiança têm largura', (tester) async {
      await open(tester, const YourGameScreen());
      await tester.scrollUntilVisible(
        find.byKey(YourGameKeys.style),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      final steps = find.descendant(
        of: find.byType(ConfidenceMeter),
        matching: find.byType(ColoredBox),
      );
      expect(steps, findsNWidgets(3));
      for (final d in steps.evaluate()) {
        expect(d.size!.width, greaterThan(50));
        expect(d.size!.height, greaterThan(0));
      }
    });

    testWidgets('cartão Seu estilo com o medidor de 3 etapas', (tester) async {
      await open(tester, const YourGameScreen());
      await tester.scrollUntilVisible(
        find.byKey(YourGameKeys.style),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Primeira leitura'), findsOneWidget);
      expect(find.text('Em formação'), findsOneWidget);
      expect(find.text('Leitura firme'), findsOneWidget);
      expect(find.text('Ver meu estilo'), findsOneWidget);
      // Com 10 partidas ou mais, sem a ressalva das poucas.
      final style = tester.widget<Text>(find.byKey(YourGameKeys.styleText));
      expect(style.data, isNot(startsWith('Ainda é cedo')));
    });

    testWidgets('cartão Seu estilo é o cartão de destaque comum', (
      tester,
    ) async {
      await open(tester, const YourGameScreen());
      expect(
        tester.widget(find.byKey(YourGameKeys.style, skipOffstage: false)),
        isA<HighlightCard>(),
      );
    });

    testWidgets('teoria: lista de lances, jogada marcada e navegação', (
      tester,
    ) async {
      final game = YourGameFixtures.games(2)[1];
      await open(
        tester,
        YourGameTheoryScreen(gameId: game.id),
        repo: FakeCoachRepository(games: [game]),
      );
      expect(find.byKey(YourGameKeys.theoryMoves), findsOneWidget);
      expect(find.byKey(YourGameKeys.theoryPlayed), findsOneWidget);
      await tester.tap(find.byKey(YourGameKeys.theoryNext));
      await tester.pumpAndSettle();
      expect(find.byKey(YourGameKeys.theoryLine), findsOneWidget);
      await tester.tap(find.byKey(YourGameKeys.theoryStart));
      await tester.pumpAndSettle();
      final tab = tester.widget<IconButton>(
        find.byKey(YourGameKeys.theoryPrevious),
      );
      expect(tab.onPressed, isNull);
    });
  });

  testWidgets('teoria: candidatos e a linha ao tocar', (tester) async {
    final game = YourGameFixtures.games(2)[1];
    await open(
      tester,
      YourGameTheoryScreen(gameId: game.id),
      repo: FakeCoachRepository(games: [game]),
    );
    expect(find.byKey(YourGameKeys.theoryScreen), findsOneWidget);
    expect(find.byKey(YourGameKeys.theoryLine), findsNothing);
    final variant = find.descendant(
      of: find.byKey(YourGameKeys.theoryMoves),
      matching: find.text('('),
    );
    expect(variant, findsNothing);
    await tester.tap(find.byKey(YourGameKeys.theoryCandidate('Nd7')));
    await tester.pumpAndSettle();
    expect(find.byKey(YourGameKeys.theoryLine), findsOneWidget);
    // A linha entra na lista como variante, entre parênteses.
    expect(variant, findsOneWidget);
    // A barra das cores mostra o % das brancas e o das pretas dentro dela.
    final bar = find.descendant(
      of: find.byKey(YourGameKeys.theoryCandidate('Nd7')),
      matching: find.byType(ScoreBar),
    );
    expect(
      find.descendant(of: bar, matching: find.text('48%')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: bar, matching: find.text('43%')),
      findsOneWidget,
    );
  });

  testWidgets('partidas-modelo: lista e o aviso grava', (tester) async {
    final repo = FakeCoachRepository(
      account: CoachFixtures.account,
      modelGamesByEco: {
        'B12': [const ModelGame(source: 'torneio', title: 'Carlsen x Caruana')],
      },
    );
    await open(
      tester,
      const ModelGamesScreen(eco: 'B12', name: 'Defesa Caro-Kann'),
      repo: repo,
    );
    expect(find.byKey(YourGameKeys.modelGame(0)), findsOneWidget);
    expect(find.text('Carlsen x Caruana'), findsOneWidget);
    await tester.tap(find.byKey(YourGameKeys.modelGamesNoticeKey));
    await tester.pumpAndSettle();
    expect(repo.modelGamesNotices, [true]);
  });

  group('Pilares da abertura', () {
    testWidgets('sem o curso: partes travadas, destaque e oferta', (
      tester,
    ) async {
      await open(
        tester,
        const PilaresOpeningScreen(slot: 'caroKann', part: 2, chessMove: 'c5'),
      );
      expect(
        find.byKey(YourGameKeys.pilaresPart('pilares.ab1.caroKann1')),
        findsOneWidget,
      );
      expect(find.byKey(YourGameKeys.pilaresHighlight), findsOneWidget);
      await tester.scrollUntilVisible(
        find.byKey(YourGameKeys.pilaresDiscover),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.byKey(YourGameKeys.pilaresOffer), findsOneWidget);
      // Componente único: a oferta usa o mesmo cartão azul do "Seu estilo".
      expect(
        tester.widget(find.byKey(YourGameKeys.pilaresOffer)),
        isA<HighlightCard>(),
      );
    });
  });

  testWidgets('Metas de hoje: a parte do Treinador em destaque', (
    tester,
  ) async {
    final repository = FakeTrainingRepository(
      content: {TrainingCourse.pilares: _resources},
    );
    final cubit = CourseGuideCubit(
      repository: repository,
      config: TrainingCourseConfig.pilares,
      now: FakeNow(YourGameFixtures.currentTime),
    );
    addTearDown(cubit.close);
    await cubit.load();
    TrainingLesson? opened;
    await open(
      tester,
      BlocProvider.value(
        value: cubit,
        child: Scaffold(
          body: CoachGoalsHighlight(
            lessonId: 'pilares.ab2.caroKann2',
            onOpen: (l) => opened = l,
          ),
        ),
      ),
      grant: CourseAccess.owned,
    );
    expect(find.byKey(YourGameKeys.goalsHighlight), findsOneWidget);
    // Componente único: o aviso é o TipBox do app.
    expect(
      tester.widget(find.byKey(YourGameKeys.goalsHighlightNotice)),
      isA<TipBox>(),
    );
    // Canvas DMetasEslava: "{abertura} · Parte {n}" e o título curto embaixo.
    expect(find.text('Caro-Kann · Parte 2'), findsOneWidget);
    expect(find.text('pilares.ab2.caroKann2'), findsOneWidget);
    await tester.tap(find.byKey(YourGameKeys.goalsHighlightPart));
    expect(opened?.id, 'pilares.ab2.caroKann2');
  });

  group('texto longo, 411×914', () {
    // Dados reais no limite: usuário do Lichess com 30 letras, abertura com
    // variante e subvariante, partida-modelo com evento e cidade.
    const opening =
        'Defesa Siciliana, Variante Najdorf, Ataque Inglês, Linha Principal';
    const rival = 'Grande_Mestre_Do_Final_De_Torre';
    const modelGame =
        'Magnus Carlsen x Fabiano Caruana, Campeonato Mundial, Londres 2018';

    List<CoachGame> games() => [
      for (var i = 0; i < 60; i++)
        CoachGame.fromJson(YourGameFixtures.id(i), {
          ...YourGameFixtures.gameJson(i),
          'adversario': {'nome': rival, 'rating': 2950},
          if (i.isOdd) 'abertura': {'eco': 'B90', 'nome': opening},
        })!,
    ];

    CoachStats stats() {
      final json = YourGameFixtures.statsJson();
      final ab = (json['aberturas']! as List).first as Map<String, Object?>;
      return CoachStats.fromJson({
        ...json,
        'aberturas': [
          {...ab, 'nome': opening, 'eco': 'B90', 'partidas': 1234},
        ],
      });
    }

    FakeCoachRepository repo() => FakeCoachRepository(
      account: CoachFixtures.account,
      games: games(),
      stats: stats(),
      modelGamesByEco: {
        'B90': [
          for (var i = 0; i < 3; i++)
            const ModelGame(source: 'torneio', title: modelGame),
        ],
      },
    );

    /// Nenhum texto com reticências ou cortado, nem estouro de layout.
    void noCutoff(WidgetTester tester) {
      expect(tester.takeException(), isNull);
      for (final e in find.byType(RichText).evaluate()) {
        final p = e.renderObject! as RenderParagraph;
        expect(
          p.didExceedMaxLines,
          isFalse,
          reason: 'texto cortado: "${p.text.toPlainText()}"',
        );
      }
    }

    /// Rola a tela inteira conferindo a cada tela.
    Future<void> scrollChecking(WidgetTester tester) async {
      noCutoff(tester);
      final scrollableArea = find.byType(Scrollable).first;
      for (var i = 0; i < 30; i++) {
        final pos = tester.state<ScrollableState>(scrollableArea).position;
        if (pos.pixels >= pos.maxScrollExtent) break;
        await tester.drag(scrollableArea, const Offset(0, -500));
        await tester.pumpAndSettle();
        noCutoff(tester);
      }
    }

    testWidgets('aba Seu jogo', (tester) async {
      await open(tester, const YourGameScreen(), repo: repo());
      await scrollChecking(tester);
      expect(find.textContaining(opening), findsWidgets);
    });

    testWidgets('teoria', (tester) async {
      final p = games()[1];
      await open(
        tester,
        YourGameTheoryScreen(gameId: p.id),
        repo: FakeCoachRepository(games: [p]),
      );
      await tester.tap(find.byKey(YourGameKeys.theoryCandidate('Nd7')));
      await tester.pumpAndSettle();
      await scrollChecking(tester);
    });

    testWidgets('partidas-modelo', (tester) async {
      await open(
        tester,
        const ModelGamesScreen(eco: 'B90', name: opening),
        repo: repo(),
      );
      await scrollChecking(tester);
      expect(find.text(modelGame), findsWidgets);
    });

    testWidgets('posição do tema abre a análise no meio-lance do erro', (
      tester,
    ) async {
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => const YourGameMotifScreen(motif: 'garfo'),
          ),
          GoRoute(
            path: '/treinador/partida/:id/analise',
            builder: (_, state) => Text(
              'análise ${state.pathParameters['id']} '
              '${state.uri.queryParameters['lance']}',
            ),
          ),
        ],
      );
      addTearDown(router.dispose);
      await open(tester, const SizedBox(), repo: repo(), router: router);
      await tester.tap(find.byKey(YourGameKeys.motifPosition(0)));
      await tester.pumpAndSettle();
      expect(find.textContaining('análise '), findsOneWidget);
    });

    testWidgets('posições de um tema, com o adversário', (tester) async {
      await open(
        tester,
        const YourGameMotifScreen(motif: 'garfo'),
        repo: repo(),
      );
      await scrollChecking(tester);
      expect(find.textContaining(rival), findsWidgets);
    });
  });
}

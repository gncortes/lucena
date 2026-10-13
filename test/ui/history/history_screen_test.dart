import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lucena/domain/models/app_settings.dart';
import 'package:lucena/domain/models/attempt.dart';
import 'package:lucena/domain/models/clock.dart';
import 'package:lucena/domain/models/history_filter.dart';
import 'package:lucena/domain/models/speedrun.dart';
import 'package:lucena/routing/routes.dart';
import 'package:lucena/ui/core/keys/history_keys.dart';
import 'package:lucena/ui/core/keys/rating_keys.dart';
import 'package:lucena/ui/history/view_models/history_cubit.dart';
import 'package:lucena/ui/history/widgets/history_screen.dart';

import '../../../testing/fakes/fake_settings_repository.dart';
import '../../../testing/goldens/golden_harness.dart';
import '../../../testing/test_app.dart';
import 'history_harness.dart';

void main() {
  late HistoryWorld world;
  const win = AttemptOutcome.win;
  const draw = AttemptOutcome.draw;
  const loss = AttemptOutcome.loss;
  const blitz = TimeControl(
    initial: Duration(minutes: 3),
    increment: Duration(seconds: 2),
  );
  const bullet = TimeControl(initial: Duration(minutes: 1));

  setUpAll(Goldens.loadFonts);
  setUp(() => world = HistoryWorld());

  Future<void> pump(
    WidgetTester tester, {
    Size size = const Size(360, 740),
    double textScale = 1,
    Locale locale = const Locale('pt'),
    ThemeMode theme = ThemeMode.light,
    int? highlightedGame,
    HistoryCubit? cubit,
    List<String>? pushed,
  }) async {
    tester.view
      ..devicePixelRatio = 1
      ..physicalSize = size;
    addTearDown(tester.view.reset);
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, _) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(textScale),
              disableAnimations: true,
            ),
            child: BlocProvider(
              create: (_) =>
                  (cubit ?? world.cubit(highlightedGame: highlightedGame))
                    ..load(),
              child: const HistoryScreen(),
            ),
          ),
        ),
        GoRoute(
          path: '/speedruns/:id/history',
          builder: (_, state) {
            pushed?.add(state.pathParameters['id']!);
            return const Scaffold(body: Text('detalhe'));
          },
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      TestApp(
        locale: locale,
        themeMode: theme,
        router: router,
        child: const SizedBox(),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> openTab(WidgetTester tester, int index) async {
    await tester.tap(find.byKey(HistoryKeys.tab(index)));
    await tester.pumpAndSettle();
  }

  /// Abre a folha, escolhe [group]/[value] e aplica.
  Future<void> filter(
    WidgetTester tester,
    String chip,
    String group,
    String value,
  ) async {
    await tester.tap(find.byKey(HistoryKeys.filterChip(chip)));
    await tester.pumpAndSettle();
    final option = find.byKey(HistoryKeys.filterOption(group, value));
    await tester.ensureVisible(option);
    await tester.tap(option);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(HistoryKeys.filterApply));
    await tester.pumpAndSettle();
  }

  String scoreText(WidgetTester tester, int index) => find
      .descendant(
        of: find.byKey(HistoryKeys.score(index)),
        matching: find.byType(Text),
      )
      .evaluate()
      .map((e) => (e.widget as Text).data)
      .first!;

  Future<void> populate() async {
    await world.play([win, loss, draw, win, win], time: blitz);
    await world.play([win, loss], daysAgo: 60, time: bullet);
  }

  group('Partidas', () {
    testWidgets('três abas, o cartão do rating, o placar e os meses', (
      tester,
    ) async {
      await populate();
      await pump(tester);

      expect(find.byKey(HistoryKeys.tab(0)), findsOneWidget);
      expect(find.byKey(HistoryKeys.tab(1)), findsOneWidget);
      expect(find.byKey(HistoryKeys.tab(2)), findsOneWidget);
      expect(find.byKey(RatingKeys.chart), findsOneWidget);
      expect(scoreText(tester, 0), '4');
      expect(scoreText(tester, 1), '1');
      expect(scoreText(tester, 2), '2');
      expect(find.byKey(HistoryKeys.month(0)), findsOneWidget);
      expect(find.text('Outubro de 2026', skipOffstage: false), findsOneWidget);
    });

    testWidgets('Resultado e Ritmo mudam lista e placar, não o gráfico', (
      tester,
    ) async {
      await populate();
      await pump(tester);
      final points = tester.getSize(find.byKey(RatingKeys.chart));

      await filter(tester, 'result', 'result', 'win');
      expect(scoreText(tester, 0), '4');
      expect(scoreText(tester, 1), '0');
      expect(find.byKey(RatingKeys.chart), findsOneWidget);
      expect(tester.getSize(find.byKey(RatingKeys.chart)), points);
      expect(
        find.byKey(RatingKeys.entry(3), skipOffstage: false),
        findsOneWidget,
      );
      expect(
        find.byKey(RatingKeys.entry(4), skipOffstage: false),
        findsNothing,
      );

      await filter(tester, 'pace', 'pace', 'bullet');
      expect(scoreText(tester, 0), '1');
      expect(find.byKey(RatingKeys.entry(1)), findsNothing);
    });

    testWidgets('Período muda o gráfico e a contagem', (tester) async {
      await populate();
      await pump(tester);
      expect(find.textContaining('7'), findsWidgets);

      await filter(tester, 'period', 'period', 'week');

      expect(scoreText(tester, 0), '3');
      expect(find.byKey(RatingKeys.entry(5)), findsNothing);
    });

    testWidgets('sem resultado no filtro: aviso e Limpar', (tester) async {
      await world.play([win, win]);
      // O painel não aplica um filtro sem resultado: ele vem gravado.
      world.settings = FakeSettingsRepository(
        const AppSettings(historyGamesFilter: GamesHistoryFilter(result: loss)),
      );
      await pump(tester);

      expect(find.byKey(HistoryKeys.emptyFiltered), findsOneWidget);
      expect(find.text('Nenhuma partida com esses filtros.'), findsOneWidget);
      await tester.tap(find.byKey(HistoryKeys.emptyClear));
      await tester.pumpAndSettle();
      expect(find.byKey(HistoryKeys.emptyFiltered), findsNothing);
      expect(find.byKey(RatingKeys.entry(0)), findsOneWidget);
    });

    testWidgets('sem partidas: o convite', (tester) async {
      await pump(tester);

      expect(find.byKey(HistoryKeys.empty), findsOneWidget);
      expect(find.byKey(RatingKeys.emptyHistoryAction), findsOneWidget);
    });

    testWidgets('bônus e etapas de speedrun não viram linha de partida', (
      tester,
    ) async {
      await world.play([win]);
      await world.speedrun(time: blitz);
      await pump(tester);

      expect(find.byKey(RatingKeys.entry(0)), findsOneWidget);
      expect(find.byKey(RatingKeys.entry(1)), findsNothing);
    });

    testWidgets('?game= destaca a partida e ignora o filtro gravado', (
      tester,
    ) async {
      final ids = await world.play([win, loss]);
      await world.speedrun(time: blitz, daysAgo: 1);
      await pump(tester, highlightedGame: ids.first);

      expect(find.byKey(RatingKeys.entryHighlighted), findsOneWidget);
    });

    testWidgets('id que não existe é ignorado', (tester) async {
      await world.play([win]);
      await pump(tester, highlightedGame: 999);

      expect(find.byKey(RatingKeys.entryHighlighted), findsNothing);
      expect(find.byKey(RatingKeys.entry(0)), findsOneWidget);
    });
  });

  group('Clássico e Maratona', () {
    testWidgets('vazias: a mensagem de cada uma, sem botão', (tester) async {
      await pump(tester);

      await openTab(tester, 1);
      expect(find.text('Conclua um speedrun e ele aparece aqui.'), findsOne);
      expect(find.byKey(HistoryKeys.empty), findsOneWidget);
      await openTab(tester, 2);
      expect(find.byKey(HistoryKeys.empty), findsOneWidget);
      expect(find.byType(FilledButton), findsNothing);
    });

    testWidgets('bônus só na linha da conclusão; recorde só ao bater', (
      tester,
    ) async {
      await world.play([win, win, win]);
      // A primeira conclusão paga o bônus; as outras não são recorde novo
      // sem bater o tempo.
      await world.speedrun(time: blitz, seconds: 30, daysAgo: 3);
      // As do bullet são de antes do bônus: só a do blitz recebe.
      world.speedruns.beforeBonus(
        await world.speedrun(time: bullet, seconds: 30, daysAgo: 2),
      );
      world.speedruns.beforeBonus(
        await world.speedrun(time: bullet, seconds: 20, daysAgo: 1),
      );
      await pump(tester);
      await openTab(tester, 1);

      expect(find.byKey(HistoryKeys.row(0)), findsOneWidget);
      expect(find.byKey(HistoryKeys.row(1)), findsOneWidget);
      expect(find.text('Recorde novo'), findsOneWidget);
      expect(find.byKey(HistoryKeys.rowBonus(0)), findsNothing);
      expect(find.byKey(HistoryKeys.rowBonus(1)), findsOneWidget);
    });

    testWidgets('a linha abre o detalhe do speedrun', (tester) async {
      await world.speedrun(time: blitz, stages: 1);
      final pushed = <String>[];
      await pump(tester, pushed: pushed);
      await openTab(tester, 1);
      expect(find.textContaining('Melhor: etapa 2 de 3'), findsOneWidget);

      await tester.tap(find.byKey(HistoryKeys.row(0)));
      await tester.pumpAndSettle();

      expect(pushed, hasLength(1));
      expect(
        Routes.speedrunHistory(pushed.single),
        startsWith('/speedruns/ending.queen'),
      );
    });

    testWidgets('filtro de nível sem resultado mostra o aviso', (tester) async {
      await world.speedrun(time: blitz);
      world.settings = FakeSettingsRepository(
        const AppSettings(
          historyTab: HistoryTab.classic,
          historyClassicFilter: SpeedrunHistoryFilter(
            level: SpeedrunCategory.advanced,
          ),
        ),
      );
      await pump(tester);

      expect(find.byKey(HistoryKeys.emptyFiltered), findsOneWidget);
    });
  });

  group('persistência', () {
    testWidgets('aba e filtro voltam ao reabrir a tela', (tester) async {
      await populate();
      await pump(tester);
      await filter(tester, 'result', 'result', 'win');
      await openTab(tester, 1);
      await tester.pumpWidget(const SizedBox());

      await pump(tester);

      expect(
        find.byKey(HistoryKeys.empty),
        findsOneWidget,
        reason: 'abre no Clássico, que está vazio',
      );
      expect(world.settings.settings.historyTab, HistoryTab.classic);
      await openTab(tester, 0);
      expect(scoreText(tester, 0), '4');
    });
  });

  group('tamanhos e acessibilidade', () {
    for (final size in const [Size(360, 740), Size(412, 917)]) {
      for (final scale in const [1.0, 2.0]) {
        for (final theme in ThemeMode.values.where(
          (m) => m != ThemeMode.system,
        )) {
          for (final locale in const [Locale('pt'), Locale('ar')]) {
            testWidgets('${size.width.toInt()}x${size.height.toInt()} '
                'fonte $scale ${theme.name} ${locale.languageCode}: '
                'sem estouro, alvos >= 48', (tester) async {
              await populate();
              await world.speedrun(time: blitz);
              await world.speedrun(time: bullet, stages: 1);
              await pump(
                tester,
                size: size,
                textScale: scale,
                theme: theme,
                locale: locale,
              );

              for (var tab = 0; tab < 3; tab++) {
                await openTab(tester, tab);
                expect(tester.takeException(), isNull);
                final tabBox = tester.getSize(find.byKey(HistoryKeys.tab(tab)));
                expect(tabBox.height, greaterThanOrEqualTo(48));
                // A Maratona está vazia: sem filtros.
                for (final name in switch (tab) {
                  0 => ['period', 'result', 'pace'],
                  1 => ['level', 'pace'],
                  _ => <String>[],
                }) {
                  final chip = find.byKey(HistoryKeys.filterChip(name));
                  expect(chip, findsOneWidget);
                  expect(tester.getSize(chip).height, greaterThanOrEqualTo(48));
                }
              }
              await openTab(tester, 1);
              final row = tester.getSize(find.byKey(HistoryKeys.row(0)));
              expect(row.height, greaterThanOrEqualTo(48));
              // A lista tem 16 dp de margem de cada lado (artboard).
              expect(row.width, size.width - 32);
            });
          }
        }
      }
    }

    testWidgets('medidas do artboard em 360: abas e chips', (tester) async {
      await populate();
      await pump(tester);

      // As três abas dividem a largura; o toque tem 48 dp ou mais.
      final tabs = [
        for (var i = 0; i < 3; i++)
          tester.getRect(find.byKey(HistoryKeys.tab(i))),
      ];
      expect(tabs[0].width, closeTo(120, 1));
      expect(tabs[1].width, closeTo(120, 1));
      expect(tabs.map((r) => r.top).toSet(), hasLength(1));
      // O botão de filtros e os chips ficam na mesma linha.
      final tune = tester.getRect(find.byKey(HistoryKeys.filterChip('all')));
      final period = tester.getRect(
        find.byKey(HistoryKeys.filterChip('period')),
      );
      expect(tune.center.dy, closeTo(period.center.dy, 1));
      expect(tune.left, greaterThanOrEqualTo(0));
    });
  });
}

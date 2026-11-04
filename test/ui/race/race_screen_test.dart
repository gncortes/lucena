import 'package:chessground/chessground.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../core/motion/entrada_helpers.dart';

import 'package:lucena/ui/core/theme/app_spacing.dart';
import 'package:lucena/domain/models/app_language.dart';
import 'package:lucena/domain/models/app_settings.dart';
import 'package:lucena/domain/models/race.dart';
import 'package:lucena/domain/use_cases/race_rules.dart';
import 'package:lucena/ui/core/keys/motion_keys.dart';
import 'package:lucena/ui/core/keys/next_steps_keys.dart';
import 'package:lucena/ui/core/motion/tabuleiro_animado.dart';
import 'package:lucena/ui/core/keys/race_keys.dart';
import 'package:lucena/ui/race/view_models/race_cubit.dart';
import 'package:lucena/ui/race/view_models/race_warm_up_cubit.dart';
import 'package:lucena/ui/race/widgets/race_screen.dart';
import 'package:lucena/ui/race/widgets/race_warm_up_screen.dart';
import 'package:lucena/ui/settings/view_models/settings_cubit.dart';

import '../../../testing/board_gestures.dart';
import '../../../testing/fakes/fake_now.dart';
import '../../../testing/fakes/fake_race_repository.dart';
import '../../../testing/fakes/fake_settings_repository.dart';
import '../../../testing/motion_expectations.dart';
import '../../../testing/test_app.dart';

void main() {
  late FakeNow now;
  late FakeRaceRepository repository;

  setUp(() {
    now = FakeNow(DateTime.utc(2026, 10, 22, 10));
    repository = FakeRaceRepository(now: now);
  });

  Future<SettingsCubit> settings() async {
    final cubit = SettingsCubit(
      FakeSettingsRepository(const AppSettings()),
      languages: AppLanguage.selectable,
    );
    addTearDown(cubit.close);
    await cubit.load();
    return cubit;
  }

  void phone(WidgetTester tester) {
    tester.view.physicalSize = const Size(412, 915) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
  }

  Future<RaceCubit> pumpRace(WidgetTester tester) async {
    phone(tester);
    final cubit = RaceCubit(repository, now);
    addTearDown(cubit.close);
    await cubit.load();
    await tester.pumpWidget(
      TestApp(
        settingsCubit: await settings(),
        child: BlocProvider.value(value: cubit, child: const RaceScreen()),
      ),
    );
    await tester.pumpAndSettle();
    return cubit;
  }

  // Os acertos do resultado contam pelo NumeroQueConta (H-ANI-25): o texto
  // visível é o Text dentro da chave.
  String? acertos(WidgetTester tester) => tester
      .widget<Text>(
        find.descendant(
          of: find.byKey(RaceKeys.resultCorrects),
          matching: find.byType(Text),
        ),
      )
      .data;

  // H-ANI-16: a introdução da Corrida se monta em ordem, o "Começar" por
  // último, e o toque fica liberado desde o início.
  testWidgets('introdução: entra em cascata e o Começar vem por último', (
    tester,
  ) async {
    phone(tester);
    final cubit = RaceCubit(repository, now);
    addTearDown(cubit.close);
    await cubit.load();
    await tester.pumpWidget(
      TestApp(
        settingsCubit: await settings(),
        child: BlocProvider.value(value: cubit, child: const RaceScreen()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    final porque = opacidadeAcima(tester, find.byKey(RaceKeys.whyEndgames));
    final comecar = opacidadeAcima(tester, find.byKey(RaceKeys.start));
    expect(porque, greaterThan(0));
    expect(comecar, lessThan(porque));
    await tester.pump(const Duration(milliseconds: 1000));
    expect(opacidadeAcima(tester, find.byKey(RaceKeys.whyEndgames)), 1);
    expect(opacidadeAcima(tester, find.byKey(RaceKeys.start)), 1);
    await tester.pumpAndSettle();
  });

  // Joga [from] -> [to] no tabuleiro da vez, em dois toques.
  Future<void> move(WidgetTester tester, String from, String to) async {
    final rect = tester.getRect(find.byType(Chessboard));
    await tester.tapAt(squareCenter(rect, from));
    await tester.pump();
    await tester.tapAt(squareCenter(rect, to));
    await tester.pump();
  }

  Future<void> start(WidgetTester tester) async {
    await tester.tap(find.byKey(RaceKeys.start));
    await tester.pumpAndSettle();
  }

  testWidgets('abertura: regras, filtro de finais, recorde vazio e Começar', (
    tester,
  ) async {
    await pumpRace(tester);

    expect(find.byKey(RaceKeys.introView), findsOneWidget);
    expect(find.text('3 minutes'), findsOneWidget);
    // Por que só finais, logo abaixo do título (canvas V2 · Ligações, L4).
    expect(find.byKey(RaceKeys.whyEndgames), findsOneWidget);
    expect(find.textContaining('Why only endgames?'), findsOneWidget);
    expect(find.text('Three mistakes and it is over'), findsOneWidget);
    final list = find.descendant(
      of: find.byKey(RaceKeys.introView),
      matching: find.byType(Scrollable),
    );
    await tester.scrollUntilVisible(
      find.text('The shortest path counts'),
      200,
      scrollable: list,
    );
    // A linha de filtros resume o objetivo e os finais.
    await tester.scrollUntilVisible(
      find.byKey(RaceKeys.filterRow),
      200,
      scrollable: list,
    );
    expect(
      tester.widget<Text>(find.byKey(RaceKeys.filterSummary)).data,
      'Win · All endings',
    );
    // O recorde fica no fim da lista, que rola.
    await tester.scrollUntilVisible(
      find.text('No record yet. Your first race sets it.'),
      200,
      scrollable: find.descendant(
        of: find.byKey(RaceKeys.introView),
        matching: find.byType(Scrollable),
      ),
    );
    expect(find.text('No record yet. Your first race sets it.'), findsOne);
    expect(find.byKey(RaceKeys.start), findsOneWidget);
  });

  testWidgets('filtros: desmarcar uma categoria e aplicar muda o resumo', (
    tester,
  ) async {
    final cubit = await pumpRace(tester);
    final list = find.descendant(
      of: find.byKey(RaceKeys.introView),
      matching: find.byType(Scrollable),
    );
    await tester.scrollUntilVisible(
      find.byKey(RaceKeys.filterRow),
      200,
      scrollable: list,
    );
    await tester.ensureVisible(find.byKey(RaceKeys.filterRow));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(RaceKeys.filterRow));
    await tester.pumpAndSettle();
    expect(find.byKey(RaceKeys.filterScreen), findsOneWidget);
    // Limpar começa desligado: o filtro já é o padrão.
    expect(
      tester.widget<TextButton>(find.byKey(RaceKeys.filterClear)).onPressed,
      isNull,
    );

    // Abre a categoria básica e desmarca tudo dela.
    await tester.tap(find.byKey(RaceKeys.filterCategory('basic')));
    await tester.pumpAndSettle();
    expect(find.byKey(RaceKeys.filterType('queen')), findsOneWidget);
    expect(find.byKey(RaceKeys.filterType('rook')), findsOneWidget);
    await tester.tap(find.byKey(RaceKeys.filterCategoryCheck('basic')));
    await tester.pump();
    expect(find.text('0 of 2'), findsOneWidget);

    await tester.tap(find.byKey(RaceKeys.filterApply));
    await tester.pumpAndSettle();
    expect(find.byKey(RaceKeys.filterScreen), findsNothing);
    expect(cubit.state.filter.excluded, {'queen', 'rook'});
    expect(
      tester.widget<Text>(find.byKey(RaceKeys.filterSummary)).data,
      'Win · 2 ending types',
    );
  });

  testWidgets('filtros: sem nenhum final marcado, Aplicar fica desligado', (
    tester,
  ) async {
    await pumpRace(tester);
    final list = find.descendant(
      of: find.byKey(RaceKeys.introView),
      matching: find.byType(Scrollable),
    );
    await tester.scrollUntilVisible(
      find.byKey(RaceKeys.filterRow),
      200,
      scrollable: list,
    );
    await tester.ensureVisible(find.byKey(RaceKeys.filterRow));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(RaceKeys.filterRow));
    await tester.pumpAndSettle();
    for (final category in ['basic', 'pawn', 'knightBishop']) {
      await tester.tap(find.byKey(RaceKeys.filterCategoryCheck(category)));
      await tester.pump();
    }
    expect(find.byKey(RaceKeys.filterNone), findsOneWidget);
    expect(
      tester
          .widget<ButtonStyleButton>(find.byKey(RaceKeys.filterApply))
          .onPressed,
      isNull,
    );
    // Limpar volta ao padrão e libera o Aplicar.
    await tester.tap(find.byKey(RaceKeys.filterClear));
    await tester.pump();
    expect(find.byKey(RaceKeys.filterNone), findsNothing);
    // O X fecha sem mudar nada.
    await tester.tap(find.byKey(RaceKeys.filterClose));
    await tester.pumpAndSettle();
    expect(find.byKey(RaceKeys.filterScreen), findsNothing);
  });

  testWidgets('duração: 5 min troca a regra e fica guardada', (tester) async {
    final cubit = await pumpRace(tester);

    // A seção Duração vem acima das regras (E1.33, opção B).
    expect(
      tester.getTopLeft(find.byKey(RaceKeys.duration)).dy,
      lessThan(tester.getTopLeft(find.text('3 minutes')).dy),
    );
    await tester.tap(
      find.byKey(RaceKeys.durationOption(RaceDuration.fiveMinutes)),
    );
    await tester.pumpAndSettle();

    expect(cubit.state.duration, RaceDuration.fiveMinutes);
    expect(find.text('5 minutes'), findsOneWidget);
    expect(await repository.duration(), RaceDuration.fiveMinutes);
  });

  testWidgets('acerto: o ícone aparece no lugar do contador e o número sobe', (
    tester,
  ) async {
    final cubit = await pumpRace(tester);
    await start(tester);
    expect(find.byKey(RaceKeys.gameView), findsOneWidget);
    expect(tester.widget<Text>(find.byKey(RaceKeys.count)).data, '0');

    await move(tester, 'a1', 'g7');
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.byKey(RaceKeys.feedbackCorrect), findsOneWidget);

    await tester.pumpAndSettle();
    expect(find.byKey(RaceKeys.feedbackCorrect), findsNothing);
    expect(tester.widget<Text>(find.byKey(RaceKeys.count)).data, '1');
    // O segundo problema entrou no tabuleiro.
    expect(cubit.state.problem?.id, 'race.350.01');
    expect(find.byType(Chessboard), findsOneWidget);
  });

  // H-ANI-10/11: o tabuleiro é o do kit, e o lance que fecha o problema
  // ganha o retorno (casa, selo e respiro ou tremida) antes da troca.
  Finder seloDa(IconData icone) => find.descendant(
    of: find.byKey(MotionKeys.seloNaPeca),
    matching: find.byIcon(icone),
  );

  testWidgets('H-ANI-10: o tabuleiro da Corrida é o TabuleiroAnimado', (
    tester,
  ) async {
    await pumpRace(tester);
    await start(tester);
    final board = find.descendant(
      of: find.byKey(RaceKeys.board),
      matching: find.byType(Chessboard),
    );
    expect(
      find.ancestor(of: board, matching: find.byType(TabuleiroAnimado)),
      findsOneWidget,
    );
    expect(
      tester.widget<Chessboard>(board).settings.animationDuration,
      TabuleiroAnimado.duracaoDoLance(tester.element(board)),
    );
  });

  testWidgets('H-ANI-11: o acerto pinta a casa e põe o ✓ na peça', (
    tester,
  ) async {
    await pumpRace(tester);
    await start(tester);
    expect(find.byKey(MotionKeys.tabuleiroDoRetorno), findsNothing);
    await move(tester, 'a1', 'g7');
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byKey(MotionKeys.tabuleiroDoRetorno), findsOneWidget);
    expect(find.byKey(MotionKeys.corDaCasa), findsOneWidget);
    expect(seloDa(Icons.check), findsOneWidget);
    expect(seloDa(Icons.close), findsNothing);
    await tester.pumpAndSettle();
    // O problema novo entra limpo.
    expect(find.byKey(MotionKeys.tabuleiroDoRetorno), findsNothing);
  });

  testWidgets('H-ANI-11: o erro pinta a casa e põe o ✗ na peça', (
    tester,
  ) async {
    await pumpRace(tester);
    await start(tester);
    await move(tester, 'a1', 'b1');
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byKey(MotionKeys.tabuleiroDoRetorno), findsOneWidget);
    expect(seloDa(Icons.close), findsOneWidget);
    expect(seloDa(Icons.check), findsNothing);
    await tester.pumpAndSettle();
    expect(find.byKey(MotionKeys.tabuleiroDoRetorno), findsNothing);
  });

  testWidgets('erro: o ícone de erro aparece e uma chance se perde', (
    tester,
  ) async {
    await pumpRace(tester);
    await start(tester);
    expect(find.byKey(RaceKeys.chance(0, lost: false)), findsOneWidget);

    await move(tester, 'a1', 'b1');
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.byKey(RaceKeys.feedbackWrong), findsOneWidget);

    await tester.pumpAndSettle();
    expect(find.byKey(RaceKeys.chance(0, lost: true)), findsOneWidget);
    expect(tester.widget<Text>(find.byKey(RaceKeys.count)).data, '0');
  });

  testWidgets('três erros: o resultado, a revisão dos erros e jogar de novo', (
    tester,
  ) async {
    await pumpRace(tester);
    await start(tester);
    for (final (from, to) in [('a1', 'a2'), ('a1', 'b1'), ('h1', 'g1')]) {
      await move(tester, from, to);
      await tester.pumpAndSettle();
    }

    expect(find.byKey(RaceKeys.resultView), findsOneWidget);
    expect(find.text('3-min race · 3 mistakes'), findsOneWidget);
    // Só 3 problemas: nada de "Ver os N".
    expect(find.byKey(RaceKeys.seeAllProblems), findsNothing);
    expect(acertos(tester), '0');
    expect(find.byKey(RaceKeys.problemTile(2)), findsOneWidget);
    expect(find.text('Review the 3 mistakes'), findsOneWidget);
    // Antes de 3 Corridas: quantas faltam para o desempenho por final (L5).
    expect(find.byKey(RaceKeys.diagnosisProgress), findsOneWidget);
    expect(find.text('1 of 3'), findsOneWidget);
    expect(find.byKey(RaceKeys.performance), findsNothing);

    await tester.tap(find.byKey(RaceKeys.reviewMistakes));
    await tester.pumpAndSettle();
    expect(find.text('Mistake 1 of 3'), findsOneWidget);
    // Lance que também ganhava, só que devagar, tem o texto próprio.
    expect(
      find.text(
        'Your move also won, but it took more moves. '
        'The fastest was Qa8#, mate in 1.',
      ),
      findsOneWidget,
    );
    await tester.tap(find.byKey(RaceKeys.reviewNext));
    await tester.pumpAndSettle();
    expect(find.text('Mistake 2 of 3'), findsOneWidget);
    await tester.tap(find.byKey(RaceKeys.reviewNext));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(RaceKeys.reviewNext));
    await tester.pumpAndSettle();
    expect(find.byKey(RaceKeys.resultView), findsOneWidget);

    await tester.tap(find.byKey(RaceKeys.again));
    await tester.pumpAndSettle();
    expect(find.byKey(RaceKeys.gameView), findsOneWidget);
    expect(tester.widget<Text>(find.byKey(RaceKeys.count)).data, '0');
  });

  // H-ANI-25: o resultado se monta em ordem; os acertos contam antes de os
  // botões entrarem, e em 1,3 s tudo está parado.
  for (final reduzido in [false, true]) {
    testWidgets('H-ANI-25: o resultado se monta em ordem (reduzido: '
        '$reduzido)', (tester) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          FakeAccessibilityFeatures(disableAnimations: reduzido);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      await pumpRace(tester);
      await start(tester);
      for (final (from, to) in [('a1', 'a2'), ('a1', 'b1')]) {
        await move(tester, from, to);
        await tester.pumpAndSettle();
      }
      await move(tester, 'h1', 'g1');
      for (var i = 0; i < 300; i++) {
        if (find.byKey(RaceKeys.resultView).evaluate().isNotEmpty) break;
        await tester.pump(const Duration(milliseconds: 16));
      }
      expect(find.byKey(RaceKeys.resultView), findsOneWidget);
      expectEntradaDeResultado(
        tester,
        partes: const ['titulo', 'placar', 'viktor', 'botoes'],
        animando: !reduzido,
      );
      expect(
        find.descendant(
          of: find.byKey(MotionKeys.parteDoResultado('placar')),
          matching: find.byKey(RaceKeys.resultCorrects),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(MotionKeys.parteDoResultado('botoes')),
          matching: find.byKey(RaceKeys.again),
        ),
        findsOneWidget,
      );
      await tester.pump(const Duration(milliseconds: 1300));
      await tester.pump();
      expect(
        opacidadeDaParte(
          tester,
          find.byKey(MotionKeys.parteDoResultado('botoes')),
        ),
        1,
      );
      expect(acertos(tester), '0');
      await tester.pumpAndSettle();
    });
  }

  testWidgets('com 3 Corridas, o resultado mostra a linha do desempenho e '
      'a dos dados, sem ponto fraco', (tester) async {
    for (var i = 0; i < 3; i++) {
      var run = RaceRun(startedAt: now());
      for (var j = 0; j < 4; j++) {
        run = run.withAnswer(
          RaceAnswer(
            problemId: 'p$j',
            level: 400,
            move: 'a1a2',
            correct: j > 0,
            subcategory: 'queen',
          ),
        );
      }
      await repository.finish(run, RaceEnd.errors);
    }
    await pumpRace(tester);
    await start(tester);
    for (final (from, to) in [('a1', 'a2'), ('a1', 'b1'), ('h1', 'g1')]) {
      await move(tester, from, to);
      await tester.pumpAndSettle();
    }
    expect(find.byKey(RaceKeys.resultView), findsOneWidget);
    expect(find.byKey(RaceKeys.diagnosisProgress), findsNothing);
    expect(find.byKey(RaceKeys.performance), findsOneWidget);
    expect(find.text('Your performance by endgame'), findsOneWidget);
    expect(find.byKey(NextStepsKeys.resultsInfo), findsOneWidget);
  });

  testWidgets('resultado com 9 problemas: 8 na grade e Ver os 9 abre a lista '
      'inteira (H-DES-11)', (tester) async {
    repository = FakeRaceRepository(
      now: now,
      ongoing: RaceRun(
        startedAt: now(),
        answers: [
          for (var i = 0; i < 9; i++)
            RaceAnswer(
              problemId: 'race.001',
              level: 600 + i,
              move: 'a1a2',
              correct: i != 4,
            ),
        ],
      ),
    );
    now.advance(const Duration(minutes: 10));
    await pumpRace(tester);

    expect(find.byKey(RaceKeys.resultView), findsOneWidget);
    expect(find.text('3-min race · time is up'), findsOneWidget);
    expect(find.byKey(RaceKeys.problemTile(7)), findsOneWidget);
    expect(find.byKey(RaceKeys.problemTile(8)), findsNothing);
    expect(find.text('See all 9'), findsOneWidget);

    await tester.ensureVisible(find.byKey(RaceKeys.seeAllProblems));
    await tester.tap(find.byKey(RaceKeys.seeAllProblems));
    await tester.pumpAndSettle();
    expect(find.byKey(RaceKeys.problemsScreen), findsOneWidget);
    expect(find.byKey(RaceKeys.problemTile(8)), findsOneWidget);
  });

  testWidgets('num celular de 384 de largura, as miniaturas têm vão entre si', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(384, 860);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await pumpRace(tester);
    await start(tester);
    for (final (from, to) in [('a1', 'b1'), ('a1', 'b1'), ('h1', 'g1')]) {
      await move(tester, from, to);
      await tester.pumpAndSettle();
    }

    final first = tester.getRect(find.byKey(RaceKeys.problemTile(0)));
    final second = tester.getRect(find.byKey(RaceKeys.problemTile(1)));
    expect(second.left - first.right, greaterThanOrEqualTo(AppSpacing.md));
  });

  testWidgets('acabou o tempo: o relógio do aparelho fecha a Corrida', (
    tester,
  ) async {
    await pumpRace(tester);
    await start(tester);
    await move(tester, 'a1', 'g7');
    await tester.pumpAndSettle();

    now.advance(RaceRules.limit);
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();

    expect(find.byKey(RaceKeys.resultView), findsOneWidget);
    expect(find.text('3-min race · time is up'), findsOneWidget);
    expect(acertos(tester), '1');
    // Sem erros: não há o que revisar.
    expect(find.byKey(RaceKeys.reviewMistakes), findsNothing);
  });

  testWidgets('sair no meio descarta a Corrida e volta à abertura', (
    tester,
  ) async {
    await pumpRace(tester);
    await start(tester);
    await move(tester, 'a1', 'g7');
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(RaceKeys.exit));
    await tester.pumpAndSettle();

    expect(find.byKey(RaceKeys.resultView), findsNothing);
    expect(find.byKey(RaceKeys.gameView), findsNothing);
    expect((await repository.record()).isEmpty, isTrue);
    expect(await repository.history(), isEmpty);
    expect(await repository.ongoing(), isNull);
  });

  testWidgets('aquecimento: problemas fáceis, o fim e a partida', (
    tester,
  ) async {
    phone(tester);
    var played = 0;
    final cubit = RaceWarmUpCubit(repository);
    addTearDown(cubit.close);
    await cubit.load();
    await tester.pumpWidget(
      TestApp(
        settingsCubit: await settings(),
        child: BlocProvider.value(
          value: cubit,
          child: RaceWarmUpScreen(
            args: RaceWarmUpArgs(opponent: 'Rafa', onPlay: (_) => played++),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Problem 1 of 5'), findsOneWidget);

    Future<void> play(String from, String to) async {
      await move(tester, from, to);
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();
    }

    await play('a1', 'g7');
    expect(find.text('Problem 2 of 5'), findsOneWidget);
    await play('f6', 'f7');
    await play('a1', 'h1');
    await play('h1', 'g1');
    await play('c1', 'e2');
    await play('b1', 'a1');

    expect(find.byKey(RaceKeys.warmUpDone), findsOneWidget);
    expect(find.text('4 of 5 right. Rafa is waiting.'), findsOneWidget);
    // O aquecimento não guarda nada.
    expect((await repository.record()).isEmpty, isTrue);
    await tester.tap(find.byKey(RaceKeys.warmUpPlay));
    expect(played, 1);
  });

  testWidgets('aquecimento: pular chama a partida', (tester) async {
    phone(tester);
    var played = 0;
    final cubit = RaceWarmUpCubit(repository);
    addTearDown(cubit.close);
    await cubit.load();
    await tester.pumpWidget(
      TestApp(
        settingsCubit: await settings(),
        child: BlocProvider.value(
          value: cubit,
          child: RaceWarmUpScreen(
            args: RaceWarmUpArgs(opponent: 'Rafa', onPlay: (_) => played++),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(RaceKeys.warmUpSkip));
    expect(played, 1);
  });
}

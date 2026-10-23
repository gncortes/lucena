import 'package:chessground/chessground.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/ui/core/theme/app_spacing.dart';
import 'package:lucena/domain/models/app_language.dart';
import 'package:lucena/domain/models/app_settings.dart';
import 'package:lucena/domain/models/race.dart';
import 'package:lucena/domain/use_cases/race_rules.dart';
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
    expect(find.text('Three mistakes and it is over'), findsOneWidget);
    expect(find.text('The shortest path counts'), findsOneWidget);
    final list = find.descendant(
      of: find.byKey(RaceKeys.introView),
      matching: find.byType(Scrollable),
    );
    // Só os temas que o banco tem, mais "todos".
    await tester.scrollUntilVisible(
      find.byKey(RaceKeys.themeChip(null)),
      200,
      scrollable: list,
    );
    expect(find.byKey(RaceKeys.themeChip(null)), findsOneWidget);
    expect(find.byKey(RaceKeys.themeChip(RaceTheme.rook)), findsOneWidget);
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
    expect(find.text('Three mistakes'), findsOneWidget);
    expect(tester.widget<Text>(find.byKey(RaceKeys.resultCorrects)).data, '0');
    expect(find.byKey(RaceKeys.problemTile(2)), findsOneWidget);
    expect(find.text('Review the 3 mistakes'), findsOneWidget);

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
    expect(find.text('Time is up'), findsOneWidget);
    expect(tester.widget<Text>(find.byKey(RaceKeys.resultCorrects)).data, '1');
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

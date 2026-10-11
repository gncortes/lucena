import 'package:dartchess/dartchess.dart';
import 'package:chessground/chessground.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/app_language.dart';
import 'package:lucena/domain/models/clock.dart';
import 'package:lucena/domain/models/endgame_position.dart';
import 'package:lucena/domain/models/maia_level.dart';
import 'package:lucena/domain/models/game_setup.dart';
import 'package:lucena/domain/use_cases/game_rules.dart';
import 'package:lucena/ui/core/keys/game_setup_keys.dart';
import 'package:lucena/ui/game_setup/view_models/game_setup_cubit.dart';
import 'package:lucena/ui/game_setup/widgets/custom_pace_sheet.dart';
import 'package:lucena/ui/game_setup/widgets/game_setup_screen.dart';
import 'package:lucena/ui/settings/view_models/settings_cubit.dart';

import '../../../../testing/fakes/fake_settings_repository.dart';
import '../../../../testing/fakes/fake_profile_repository.dart';
import '../../../../testing/fakes/fake_progress_repository.dart';
import '../../../../testing/fakes/fake_training_repository.dart';
import '../../../../testing/test_app.dart';

import 'package:lucena/ui/core/keys/blind_keys.dart';

void main() {
  late GameSetupCubit cubit;

  Future<void> pump(
    WidgetTester tester, {
    Locale locale = const Locale('en'),
    GameSetup setup = const GameSetup(),
    Size screen = const Size(1080, 2400),
    double textScale = 1,
  }) async {
    tester.view.physicalSize = screen;
    tester.view.devicePixelRatio = 2.625;
    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    addTearDown(tester.view.reset);
    cubit = GameSetupCubit(
      FakeTrainingRepository(setup: setup),
      progress: FakeProgressRepository(),
      profile: FakeProfileRepository(),
      position: GameRules.fromFen('8/3k4/8/8/8/8/2K5/2Q5 w - - 0 1')!,
      goal: PositionGoal.win,
    );
    addTearDown(cubit.close);
    await cubit.load();
    final settings = SettingsCubit(
      FakeSettingsRepository(),
      languages: AppLanguage.selectable,
    );
    addTearDown(settings.close);
    await settings.load();
    await tester.pumpWidget(
      TestApp(
        locale: locale,
        settingsCubit: settings,
        child: BlocProvider.value(value: cubit, child: const GameSetupScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  for (final (screen, scale) in [
    (const Size(1080, 2400), 1.0),
    (const Size(945, 1680), 1.0),
    (const Size(945, 1680), 1.6),
  ]) {
    testWidgets('T64, $screen × $scale: o tabuleiro no centro do espaço '
        'entre a barra do app e o painel das opções, que rola', (tester) async {
      await pump(tester, screen: screen, textScale: scale);
      final appBar = tester.getRect(find.byType(AppBar));
      final panel = tester.getRect(find.byKey(GameSetupKeys.panel));
      final board = tester.getRect(find.byKey(GameSetupKeys.preview));
      expect(board.center.dy, closeTo((appBar.bottom + panel.top) / 2, 1));
      expect(
        tester.getRect(find.byKey(GameSetupKeys.goal)).bottom,
        lessThanOrEqualTo(panel.top),
      );
      // As opções e o botão de começar ficam ao alcance.
      expect(find.byKey(GameSetupKeys.startButton).hitTestable(), findsOne);
      await tester.scrollUntilVisible(
        find.byKey(GameSetupKeys.customPace),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.ensureVisible(find.byKey(GameSetupKeys.customPace));
      await tester.pumpAndSettle();
      expect(find.byKey(GameSetupKeys.customPace).hitTestable(), findsOne);
      expect(tester.takeException(), isNull);
    });
  }

  Future<void> tap(WidgetTester tester, Key key, {int times = 1}) async {
    // A lista só monta o que está perto da tela: rola até o botão.
    await tester.scrollUntilVisible(
      find.byKey(key),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    for (var i = 0; i < times; i++) {
      await tester.tap(find.byKey(key));
      await tester.pump();
    }
    await tester.pumpAndSettle();
  }

  String textOf(WidgetTester tester, Key key) =>
      tester.widget<Text>(find.byKey(key)).data!;

  // A lista só monta o que está perto da tela: rola até o que o teste olha.
  Future<void> show(WidgetTester tester, Key key) async {
    await tester.scrollUntilVisible(
      find.byKey(key),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
  }

  // O texto do chip "Personalizar".
  String customChip(WidgetTester tester) => tester
      .widget<Text>(
        find.descendant(
          of: find.byKey(GameSetupKeys.customPace),
          matching: find.byType(Text),
        ),
      )
      .data!;

  testWidgets('mostra o objetivo da posição', (tester) async {
    await pump(tester, locale: const Locale('pt'));

    expect(
      find.descendant(
        of: find.byKey(GameSetupKeys.goal),
        matching: find.text('Ganhar'),
      ),
      findsOneWidget,
    );
  });

  // O controle deslizante anda por passos: o teste pede o valor direto.
  Future<void> slide(
    WidgetTester tester,
    String who,
    String field,
    int value,
  ) async {
    final steps = field == 'minutes'
        ? CustomPaceSteps.minutes
        : CustomPaceSteps.increments;
    final slider = tester.widget<Slider>(
      find.byKey(GameSetupKeys.customSlider(who, field)),
    );
    slider.onChanged!(steps.indexOf(value).toDouble());
    await tester.pumpAndSettle();
  }

  testWidgets('"Personalizar" abre o painel: os controles mudam os minutos e '
      'o incremento dos dois lados', (tester) async {
    await pump(tester);
    await show(tester, GameSetupKeys.customPace);
    // Sem ritmos nomeados neste teste, o 5+0 de fábrica já conta como
    // personalizado.
    expect(customChip(tester), 'Custom · 5+0');

    await tap(tester, GameSetupKeys.customPace);
    expect(textOf(tester, GameSetupKeys.customValue('user')), '5+0 · Blitz');
    await slide(tester, 'user', 'minutes', 3);
    await slide(tester, 'user', 'increment', 2);
    expect(textOf(tester, GameSetupKeys.customValue('user')), '3+2 · Blitz');
    expect(find.text('3 minutes'), findsOneWidget);
    expect(find.text('+2 seconds per move'), findsOneWidget);
    // Nada muda antes de confirmar.
    expect(cubit.state.clockCodes.white, '300+0');

    await tester.tap(find.byKey(GameSetupKeys.customConfirm));
    await tester.pumpAndSettle();

    expect(cubit.state.clockCodes, (white: '180+2', black: '180+2'));
    await show(tester, GameSetupKeys.customPace);
    expect(customChip(tester), 'Custom · 3+2');
  });

  testWidgets('no painel, um tempo para cada lado', (tester) async {
    await pump(tester);

    await tap(tester, GameSetupKeys.customPace);
    expect(find.byKey(GameSetupKeys.customValue('opponent')), findsNothing);
    await tester.tap(find.byKey(GameSetupKeys.customSame));
    await tester.pumpAndSettle();
    await slide(tester, 'opponent', 'minutes', 1);
    await tester.tap(find.byKey(GameSetupKeys.customConfirm));
    await tester.pumpAndSettle();

    expect(cubit.state.clockCodes, (white: '300+0', black: '60+0'));
    await show(tester, GameSetupKeys.customPace);
    expect(customChip(tester), 'Custom · 5+0 / 1+0');
  });

  testWidgets('fechar o painel sem confirmar não muda o ritmo', (tester) async {
    await pump(tester);

    await tap(tester, GameSetupKeys.customPace);
    await slide(tester, 'user', 'minutes', 10);
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    expect(find.byKey(GameSetupKeys.customSheet), findsNothing);
    expect(cubit.state.clockCodes.white, '300+0');
  });

  testWidgets('tempo zero gravado de antes: aparece o erro e o botão de '
      'começar trava', (tester) async {
    await pump(
      tester,
      setup: const GameSetup(opponentTime: TimeControl(initial: Duration.zero)),
    );

    await show(tester, GameSetupKeys.timeError);
    expect(find.byKey(GameSetupKeys.timeError), findsOneWidget);
    final start = tester.widget<FilledButton>(
      find.byKey(GameSetupKeys.startButton),
    );
    expect(start.onPressed, isNull);
  });

  testWidgets('trocar o lado vira a amostra para o jogador', (tester) async {
    await pump(tester);
    StaticChessboard preview() =>
        tester.widget<StaticChessboard>(find.byKey(GameSetupKeys.preview));
    expect(preview().orientation, Side.white);

    await tap(tester, GameSetupKeys.side(Side.black));
    // A lista só monta o que está perto da tela: volta para a amostra.
    await tester.scrollUntilVisible(
      find.byKey(GameSetupKeys.preview),
      -200,
      scrollable: find.byType(Scrollable).first,
    );

    expect(preview().orientation, Side.black);
    expect(cubit.state.userSide, Side.black);
  });

  testWidgets('com o Maia escolhido, aparecem os níveis e o sugerido', (
    tester,
  ) async {
    await pump(tester);
    await tester.scrollUntilVisible(
      find.byKey(GameSetupKeys.suggestedLevel),
      200,
      scrollable: find.byType(Scrollable).first,
    );

    // Perfil padrão (rating 1150): o nível mais próximo é 1200.
    expect(find.text('Suggested for your rating: 1200'), findsOneWidget);
    for (final level in MaiaLevels.all) {
      expect(find.byKey(GameSetupKeys.level(level)), findsOneWidget);
    }
    ChoiceChip chip(int level) =>
        tester.widget<ChoiceChip>(find.byKey(GameSetupKeys.level(level)));
    expect(chip(1200).selected, isTrue);

    await tap(tester, GameSetupKeys.level(1600));

    expect(chip(1600).selected, isTrue);
    expect(chip(1200).selected, isFalse);
    expect(cubit.state.maiaLevel, 1600);
  });

  testWidgets('os adversários são o Maia e o Stockfish, sem "dois jogadores"', (
    tester,
  ) async {
    await pump(tester);

    expect(
      find.byKey(GameSetupKeys.opponent(OpponentKind.maia)),
      findsOneWidget,
    );
    expect(
      find.byKey(GameSetupKeys.opponent(OpponentKind.stockfish)),
      findsOneWidget,
    );
    expect(
      find.byKey(GameSetupKeys.opponent(OpponentKind.twoPlayers)),
      findsNothing,
    );
  });

  testWidgets('contra o Stockfish, os níveis somem', (tester) async {
    await pump(tester);

    await tap(tester, GameSetupKeys.opponent(OpponentKind.stockfish));

    expect(find.byKey(GameSetupKeys.levels), findsNothing);
    expect(cubit.state.setup.opponent, OpponentKind.stockfish);
  });

  testWidgets('o modo às cegas fica na configuração, é gravado e leva a '
      'partida às cegas com o adversário e o relógio escolhidos', (
    tester,
  ) async {
    await pump(tester);
    await tap(tester, BlindKeys.playButton);
    expect(cubit.state.setup.blind, isTrue);
    final route = Uri.parse(cubit.state.gameRoute);
    expect(route.path, '/blind');
    expect(route.queryParameters['opponent'], 'maia');
    expect(route.queryParameters['white'], isNotNull);
  });
}

import 'package:dartchess/dartchess.dart';
import 'package:chessground/chessground.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/app_language.dart';
import 'package:lucena/domain/models/endgame_position.dart';
import 'package:lucena/domain/models/maia_level.dart';
import 'package:lucena/domain/models/game_setup.dart';
import 'package:lucena/domain/use_cases/game_rules.dart';
import 'package:lucena/ui/core/keys/game_setup_keys.dart';
import 'package:lucena/ui/game_setup/view_models/game_setup_cubit.dart';
import 'package:lucena/ui/game_setup/widgets/game_setup_screen.dart';
import 'package:lucena/ui/settings/view_models/settings_cubit.dart';

import '../../../../testing/fakes/fake_settings_repository.dart';
import '../../../../testing/fakes/fake_profile_repository.dart';
import '../../../../testing/fakes/fake_progress_repository.dart';
import '../../../../testing/fakes/fake_training_repository.dart';
import '../../../../testing/test_app.dart';

void main() {
  late GameSetupCubit cubit;

  Future<void> pump(
    WidgetTester tester, {
    Locale locale = const Locale('en'),
  }) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);
    cubit = GameSetupCubit(
      FakeTrainingRepository(),
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

  testWidgets('os botões de menos e mais mudam os minutos e o incremento', (
    tester,
  ) async {
    await pump(tester);

    await tap(tester, GameSetupKeys.decrease('user', 'minutes'), times: 2);
    await tap(tester, GameSetupKeys.increase('user', 'increment'), times: 2);

    expect(textOf(tester, GameSetupKeys.value('user', 'minutes')), '3');
    expect(textOf(tester, GameSetupKeys.value('user', 'increment')), '2');
    expect(cubit.state.clockCodes.white, '180+2');
  });

  testWidgets('tempo zero: aparece o erro e o botão de começar trava', (
    tester,
  ) async {
    await pump(tester);

    await tap(tester, GameSetupKeys.decrease('opponent', 'minutes'), times: 5);

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

  testWidgets('contra o Stockfish, os níveis somem', (tester) async {
    await pump(tester);

    await tap(tester, GameSetupKeys.opponent(OpponentKind.stockfish));

    expect(find.byKey(GameSetupKeys.levels), findsNothing);
    expect(cubit.state.setup.opponent, OpponentKind.stockfish);
  });
}

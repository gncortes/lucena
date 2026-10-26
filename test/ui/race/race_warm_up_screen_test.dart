import 'package:chessground/chessground.dart' show Chessboard;
import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/app_language.dart';
import 'package:lucena/domain/models/app_settings.dart';
import 'package:lucena/domain/models/race.dart';
import 'package:lucena/ui/core/keys/race_keys.dart';
import 'package:lucena/ui/core/widgets/info_chip.dart';
import 'package:lucena/ui/race/view_models/race_warm_up_cubit.dart';
import 'package:lucena/ui/race/widgets/race_warm_up_screen.dart';
import 'package:lucena/ui/settings/view_models/settings_cubit.dart';

import '../../../testing/fakes/fake_now.dart';
import '../../../testing/fakes/fake_race_repository.dart';
import '../../../testing/fakes/fake_settings_repository.dart';
import '../../../testing/goldens/golden_harness.dart';
import '../../../testing/test_app.dart';

void main() {
  for (final size in const [
    Size(360, 740),
    Size(360, 800),
    Size(384, 832),
    Size(393, 873),
    Size(412, 915),
    Size(414, 896),
  ]) {
    testWidgets(
      'objetivo e lado acima do tabuleiro; Pular preservado em $size',
      (tester) async {
        await Goldens.loadFonts();
        tester.view.physicalSize = size * 3;
        tester.view.devicePixelRatio = 3;
        tester.view.padding = const FakeViewPadding(top: 72, bottom: 96);
        tester.view.viewPadding = const FakeViewPadding(top: 72, bottom: 96);
        addTearDown(tester.view.reset);
        const black = RaceProblem(
          id: 'black',
          fen: '8/8/8/8/8/k7/1q6/7K b - - 0 1',
          tree: RaceNode(distance: 1, moves: {'b2g2': RaceBranch()}),
          category: 'basic',
          subcategory: 'queen',
          level: 900,
        );
        final repository = FakeRaceRepository(
          now: FakeNow(DateTime.utc(2026)),
          problems: [raceTestProblems.first, black],
        );
        final cubit = RaceWarmUpCubit(repository);
        final settings = SettingsCubit(
          FakeSettingsRepository(const AppSettings()),
          languages: AppLanguage.selectable,
        );
        addTearDown(cubit.close);
        addTearDown(settings.close);
        await cubit.load();
        await settings.load();
        var played = 0;
        await tester.pumpWidget(
          TestApp(
            locale: const Locale('pt'),
            settingsCubit: settings,
            child: BlocProvider.value(
              value: cubit,
              child: RaceWarmUpScreen(
                args: RaceWarmUpArgs(opponent: 'Rafa', onPlay: (_) => played++),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        for (final side in [Side.white, Side.black]) {
          expect(cubit.state.problem?.side, side);
          expect(
            find.text('Jogue o lance que mantém a vitória'),
            findsOneWidget,
          );
          expect(find.byKey(RaceWarmUpScreen.objectiveKey), findsOneWidget);
          expect(
            tester.widget(find.byKey(RaceWarmUpScreen.objectiveKey)),
            isA<InfoChip>(),
          );
          final label = tester.widget<Text>(
            find.byKey(RaceWarmUpScreen.sideKey),
          );
          expect(label.data, side == Side.white ? 'Brancas' : 'Pretas');
          final board = tester.getRect(find.byType(Chessboard));
          expect(
            tester.getRect(find.byKey(RaceWarmUpScreen.objectiveKey)).bottom,
            lessThanOrEqualTo(board.top),
          );
          expect(
            tester.getRect(find.byKey(RaceWarmUpScreen.sideKey)).bottom,
            lessThanOrEqualTo(board.top),
          );
          expect(tester.takeException(), isNull);
          if (side == Side.white) {
            cubit.answer(cubit.state.problem!.tree.moves.keys.first);
            await tester.pumpAndSettle();
          }
        }
        await tester.tap(find.byKey(RaceKeys.warmUpSkip));
        await tester.pumpAndSettle();
        expect(played, 1);
        expect(cubit.state.results.length, 1);
        expect((await repository.record()).isEmpty, isTrue);
      },
    );
  }
}

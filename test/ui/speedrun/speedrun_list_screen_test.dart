import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/app_language.dart';
import 'package:lucena/domain/models/app_settings.dart';
import 'package:lucena/domain/models/clock.dart';
import 'package:lucena/domain/models/pace.dart';
import 'package:lucena/ui/core/keys/speedrun_keys.dart';
import 'package:lucena/ui/settings/view_models/settings_cubit.dart';
import 'package:lucena/ui/speedrun/view_models/speedrun_cubit.dart';
import 'package:lucena/ui/speedrun/widgets/speedrun_list_screen.dart';

import '../../../testing/fakes/fake_character_repository.dart';
import '../../../testing/fakes/fake_journey_repository.dart';
import '../../../testing/fakes/fake_now.dart';
import '../../../testing/fakes/fake_ongoing_game_repository.dart';
import '../../../testing/fakes/fake_progress_repository.dart';
import '../../../testing/fakes/fake_settings_repository.dart';
import '../../../testing/fakes/fake_speedrun_repository.dart';
import '../../../testing/test_app.dart';

/// A lista dos speedruns, com o ritmo escolhido no alto.
void main() {
  late FakeSettingsRepository settings;
  late SpeedrunCubit cubit;

  setUp(() {
    settings = FakeSettingsRepository(const AppSettings());
    cubit = SpeedrunCubit(
      journey: FakeJourneyRepository(),
      speedruns: FakeSpeedrunRepository(FakeProgressRepository()),
      games: FakeOngoingGameRepository(),
      now: FakeNow(DateTime.utc(2026, 10, 4, 12)),
      settings: settings,
      characters: FakeCharacterRepository(),
    );
  });
  tearDown(() => cubit.close());

  Future<void> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 4000);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);
    await cubit.load();
    final settingsCubit = SettingsCubit(
      FakeSettingsRepository(const AppSettings()),
      languages: AppLanguage.selectable,
    );
    addTearDown(settingsCubit.close);
    await settingsCubit.load();
    await tester.pumpWidget(
      TestApp(
        settingsCubit: settingsCubit,
        child: BlocProvider.value(
          value: cubit,
          child: const SpeedrunListScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  bool chipSelected(WidgetTester tester, String code) => tester
      .widget<ChoiceChip>(find.byKey(SpeedrunKeys.paceOption(code)))
      .selected;

  testWidgets('o ritmo fica no alto: a categoria e o tempo dela, sem '
      'painel', (tester) async {
    await pump(tester);

    // Abre no 5+3, da categoria dele.
    expect(find.byKey(SpeedrunKeys.pace), findsOneWidget);
    expect(chipSelected(tester, '300+3'), isTrue);
    expect(find.byKey(SpeedrunKeys.item('rung.1000')), findsOneWidget);
    // Sem seção de tentativas em andamento.
    expect(find.byKey(SpeedrunKeys.inProgress('rung.1000')), findsNothing);
  });

  testWidgets('trocar o ritmo troca os speedruns e grava a escolha', (
    tester,
  ) async {
    await pump(tester);
    const threeTwo = TimeControl(
      initial: Duration(minutes: 3),
      increment: Duration(seconds: 2),
    );

    await tester.tap(
      find.byKey(SpeedrunKeys.paceCategory(PaceCategory.of(threeTwo).name)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(SpeedrunKeys.paceOption(threeTwo.code)));
    await tester.pumpAndSettle();

    expect(cubit.state.pace, threeTwo);
    expect(chipSelected(tester, threeTwo.code), isTrue);
    expect(
      find.byKey(SpeedrunKeys.item('rung.1000@${threeTwo.code}')),
      findsOneWidget,
    );
    expect((await settings.load()).clock.speedrunTime, threeTwo);
  });
}

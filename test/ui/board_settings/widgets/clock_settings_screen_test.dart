import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/app_language.dart';
import 'package:lucena/domain/models/app_settings.dart';
import 'package:lucena/domain/models/clock_settings.dart';
import 'package:lucena/ui/board_settings/widgets/clock_settings_screen.dart';
import 'package:lucena/ui/core/keys/board_settings_keys.dart';
import 'package:lucena/ui/settings/view_models/settings_cubit.dart';

import '../../../../testing/fakes/fake_settings_repository.dart';
import '../../../../testing/test_app.dart';

void main() {
  late FakeSettingsRepository repository;

  Future<void> pumpScreen(
    WidgetTester tester, {
    ClockSettings clock = const ClockSettings(),
    Locale locale = const Locale('en'),
  }) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);
    repository = FakeSettingsRepository(AppSettings(clock: clock));
    final cubit = SettingsCubit(repository, languages: AppLanguage.selectable);
    addTearDown(cubit.close);
    await cubit.load();
    await tester.pumpWidget(
      TestApp(
        locale: locale,
        settingsCubit: cubit,
        child: const ClockSettingsScreen(),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tap(WidgetTester tester, Key key) async {
    await tester.tap(find.byKey(key));
    await tester.pumpAndSettle();
  }

  String textOf(WidgetTester tester, Key key) =>
      tester.widget<Text>(find.byKey(key)).data!;

  testWidgets('abre com as preferências gravadas', (tester) async {
    await pumpScreen(
      tester,
      clock: const ClockSettings(
        position: ClockPosition.top,
        lowTimeVibration: false,
      ),
    );

    expect(
      textOf(tester, BoardSettingsKeys.clockPositionValue),
      'Both above the board',
    );
    expect(
      tester
          .widget<SwitchListTile>(
            find.byKey(BoardSettingsKeys.clockVibrationSwitch),
          )
          .value,
      isFalse,
    );
  });

  testWidgets('a posição só muda depois de confirmar no painel', (
    tester,
  ) async {
    await pumpScreen(tester, locale: const Locale('pt'));

    await tap(tester, BoardSettingsKeys.clockPositionTile);
    await tap(
      tester,
      BoardSettingsKeys.clockPositionOption(ClockPosition.bottom),
    );
    expect(repository.saved, isEmpty);

    await tap(tester, BoardSettingsKeys.choiceConfirmButton);

    expect(
      textOf(tester, BoardSettingsKeys.clockPositionValue),
      'Os dois abaixo do tabuleiro',
    );
    expect(repository.saved.last.clock.position, ClockPosition.bottom);
  });

  testWidgets('desligar a vibração grava a escolha', (tester) async {
    await pumpScreen(tester);

    await tap(tester, BoardSettingsKeys.clockVibrationSwitch);

    expect(repository.saved.last.clock.lowTimeVibration, isFalse);
  });
}

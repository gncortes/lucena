import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/app_language.dart';
import 'package:lucena/domain/models/app_settings.dart';
import 'package:lucena/ui/core/keys/journey_keys.dart';
import 'package:lucena/ui/journey/view_models/journey_cubit.dart';
import 'package:lucena/ui/journey/widgets/challenge_screen.dart';
import 'package:lucena/ui/settings/view_models/settings_cubit.dart';

import '../../../testing/fakes/fake_character_repository.dart';
import '../../../testing/fakes/fake_journey_repository.dart';
import '../../../testing/fakes/fake_progress_repository.dart';
import '../../../testing/fakes/fake_settings_repository.dart';
import '../../../testing/test_app.dart';

/// T64: o desafio da Jornada com o tabuleiro no centro do espaço entre a
/// barra do app e o painel do adversário e das partidas.
void main() {
  final rung = sampleLadder.first;
  final challenge = rung.challenges.first;

  Future<void> pump(WidgetTester tester, Size screen, double scale) async {
    tester.view
      ..devicePixelRatio = 1
      ..physicalSize = screen;
    addTearDown(tester.view.reset);
    tester.platformDispatcher.textScaleFactorTestValue = scale;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final cubit = JourneyCubit(
      FakeJourneyRepository(),
      FakeProgressRepository(),
      characters: FakeCharacterRepository(),
    );
    addTearDown(cubit.close);
    await cubit.load(rungId: rung.id, positionId: challenge.position.id);
    final settings = SettingsCubit(
      FakeSettingsRepository(const AppSettings()),
      languages: AppLanguage.selectable,
    );
    addTearDown(settings.close);
    await settings.load();
    await tester.pumpWidget(
      TestApp(
        settingsCubit: settings,
        child: BlocProvider.value(
          value: cubit,
          child: ChallengeScreen(rungId: rung.id),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  for (final (screen, scale) in [
    (const Size(360, 640), 1.0),
    (const Size(412, 915), 1.0),
    (const Size(360, 640), 1.6),
  ]) {
    testWidgets('$screen × $scale: tabuleiro no centro, o painel rola e o '
        'botão de jogar fica à vista', (tester) async {
      await pump(tester, screen, scale);
      final appBar = tester.getRect(find.byType(AppBar));
      final panel = tester.getRect(find.byKey(JourneyKeys.challengePanel));
      final board = tester.getRect(find.byKey(JourneyKeys.challengeBoard));
      expect(board.center.dy, closeTo((appBar.bottom + panel.top) / 2, 1));
      expect(board.bottom, lessThanOrEqualTo(panel.top));
      expect(find.byKey(JourneyKeys.play).hitTestable(), findsOne);
      await tester.scrollUntilVisible(
        find.byKey(JourneyKeys.emptyHistory),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.ensureVisible(find.byKey(JourneyKeys.emptyHistory));
      await tester.pumpAndSettle();
      expect(find.byKey(JourneyKeys.emptyHistory).hitTestable(), findsOne);
      expect(tester.takeException(), isNull);
    });
  }
}

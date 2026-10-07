import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/app_language.dart';
import 'package:lucena/domain/models/app_settings.dart';
import 'package:lucena/ui/core/keys/tour_keys.dart';
import 'package:lucena/ui/settings/view_models/settings_cubit.dart';
import 'package:lucena/ui/tour/view_models/tour_cubit.dart';
import 'package:lucena/ui/tour/widgets/tour_demos.dart';

import '../../../testing/fakes/fake_character_repository.dart';
import '../../../testing/fakes/fake_settings_repository.dart';
import '../../../testing/test_app.dart';

void main() {
  Future<void> pump(WidgetTester tester, TourStep step) async {
    final settings = SettingsCubit(
      FakeSettingsRepository(const AppSettings()),
      languages: AppLanguage.selectable,
    );
    addTearDown(settings.close);
    await settings.load();
    await tester.pumpWidget(
      TestApp(
        locale: const Locale('pt'),
        settingsCubit: settings,
        child: Scaffold(
          body: TourDemo(
            step: step,
            characters: FakeCharacterRepository.sampleCharacters,
          ),
        ),
      ),
    );
  }

  testWidgets('o speedrun: três mates em um, um depois do outro, e o '
      'relógio somando', (tester) async {
    await pump(tester, TourStep.speedrun);
    expect(find.text('Etapa 1 de 3'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 2800));
    expect(find.text('Etapa 2 de 3'), findsOneWidget);
    await tester.pumpAndSettle();
    // No fim, a terceira etapa com o mate e o tempo total.
    expect(find.text('Etapa 3 de 3'), findsOneWidget);
    expect(find.text('Mate!'), findsOneWidget);
    expect(find.text('0:12.9'), findsOneWidget);

    // Um toque repete.
    await tester.tap(find.byKey(TourKeys.demo));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Etapa 1 de 3'), findsOneWidget);
    await tester.pumpAndSettle();
  });

  testWidgets('cada passo com demonstração monta sem erro', (tester) async {
    for (final step in TourStep.values.where(TourDemo.covers)) {
      await pump(tester, step);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: step.name);
    }
  });

  test('as posições do speedrun são válidas', () {
    // A dama em h1 daria xeque em a8 pela diagonal: o demo usa h2.
    expect(
      () => Position.setupPosition(
        Rule.chess,
        Setup.parseFen('k7/8/1K6/8/8/8/7Q/8 w - - 0 1'),
      ),
      returnsNormally,
    );
  });
}

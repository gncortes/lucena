import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/data/repositories/race/race_repository.dart';
import 'package:lucena/domain/models/app_language.dart';
import 'package:lucena/domain/models/app_settings.dart';
import 'package:lucena/ui/core/keys/race_keys.dart';
import 'package:lucena/ui/race/widgets/race_warm_up_sheet.dart';
import 'package:lucena/ui/settings/view_models/settings_cubit.dart';

import '../../../testing/fakes/fake_now.dart';
import '../../../testing/fakes/fake_race_repository.dart';
import '../../../testing/fakes/fake_settings_repository.dart';
import '../../../testing/test_app.dart';

void main() {
  late FakeRaceRepository repository;
  RaceOfferChoice? choice;

  setUp(() {
    repository = FakeRaceRepository(now: FakeNow(DateTime.utc(2026, 1, 1)))
      ..offers = true;
    choice = null;
  });

  Future<void> pump(WidgetTester tester) async {
    final settings = SettingsCubit(
      FakeSettingsRepository(const AppSettings()),
      languages: AppLanguage.selectable,
    );
    addTearDown(settings.close);
    await settings.load();
    await tester.pumpWidget(
      TestApp(
        settingsCubit: settings,
        child: RepositoryProvider<RaceRepository>.value(
          value: repository,
          child: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () async => choice = await offerRaceWarmUp(
                  context,
                  opponent: 'Rafa',
                  endgame: 'Rook endgame',
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('a folha oferece o aquecimento e devolve a escolha', (
    tester,
  ) async {
    await pump(tester);
    expect(find.byKey(RaceKeys.offerSheet), findsOneWidget);
    expect(find.text('Rook endgame · Rafa'), findsOneWidget);
    expect(find.byKey(RaceKeys.offerBoard(0)), findsOneWidget);

    await tester.tap(find.byKey(RaceKeys.offerWarm));
    await tester.pumpAndSettle();
    expect(choice, RaceOfferChoice.warm);
    expect(await repository.offersWarmUp(), isTrue);
  });

  testWidgets('"Não perguntar de novo" vale para as próximas partidas', (
    tester,
  ) async {
    await pump(tester);
    await tester.tap(find.byKey(RaceKeys.offerNever));
    await tester.pump();
    await tester.tap(find.byKey(RaceKeys.offerSkip));
    await tester.pumpAndSettle();
    expect(choice, RaceOfferChoice.skip);
    expect(await repository.offersWarmUp(), isFalse);

    // Sem oferta, a folha nem abre.
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.byKey(RaceKeys.offerSheet), findsNothing);
    expect(choice, RaceOfferChoice.skip);
  });
}

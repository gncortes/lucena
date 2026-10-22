import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/data/repositories/race/race_repository.dart';
import 'package:lucena/ui/core/keys/settings_keys.dart';
import 'package:lucena/ui/race/widgets/warm_up_offer_switch.dart';

import '../../../testing/fakes/fake_now.dart';
import '../../../testing/fakes/fake_race_repository.dart';
import '../../../testing/test_app.dart';

void main() {
  testWidgets('a chave liga e desliga a oferta de aquecimento', (tester) async {
    final repository = FakeRaceRepository(
      now: FakeNow(DateTime.utc(2026, 1, 1)),
    )..offers = false;
    await tester.pumpWidget(
      TestApp(
        child: RepositoryProvider<RaceRepository>.value(
          value: repository,
          child: const Scaffold(body: WarmUpOfferSwitch()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<SwitchListTile>(find.byKey(SettingsKeys.warmUpSwitch))
          .value,
      isFalse,
    );
    await tester.tap(find.byKey(SettingsKeys.warmUpSwitch));
    await tester.pumpAndSettle();
    expect(await repository.offersWarmUp(), isTrue);
  });
}

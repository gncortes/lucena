import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/ui/alerts/view_models/alerts_cubit.dart';
import 'package:lucena/ui/alerts/widgets/alerts_ask_sheet.dart';
import 'package:lucena/ui/core/keys/alerts_keys.dart';

import '../../../testing/fakes/fake_alerts_repository.dart';
import '../../../testing/fakes/fake_profile_repository.dart';
import '../../../testing/fakes/fake_push_repository.dart';
import '../../../testing/test_app.dart';

void main() {
  Future<AlertsCubit> pumpGate(
    WidgetTester tester,
    FakePushRepository push,
  ) async {
    final alerts = AlertsCubit(
      alerts: FakeAlertsRepository(),
      push: push,
      profile: FakeProfileRepository(),
    );
    addTearDown(alerts.close);
    await alerts.load();
    await tester.pumpWidget(
      TestApp(
        pushRepository: push,
        alertsCubit: alerts,
        child: const AlertsAskGate(child: Scaffold(body: SizedBox.expand())),
      ),
    );
    await tester.pumpAndSettle();
    return alerts;
  }

  testWidgets('primeiro final: a folha aparece; "Quero receber" pede ao '
      'Android e relê a permissão', (tester) async {
    final push = FakePushRepository(granted: true);
    final alerts = await pumpGate(tester, push);
    expect(find.byKey(AlertsKeys.askSheet), findsOneWidget);
    expect(alerts.state.permitted, isFalse);

    await tester.tap(find.byKey(AlertsKeys.askYes));
    await tester.pumpAndSettle();

    expect(find.byKey(AlertsKeys.askSheet), findsNothing);
    expect(push.permissionRequests, 1);
    expect(push.asked, isTrue);
    expect(alerts.state.permitted, isTrue);
  });

  testWidgets('"Agora não" fecha sem pedir e não pergunta de novo', (
    tester,
  ) async {
    final push = FakePushRepository();
    await pumpGate(tester, push);

    await tester.tap(find.byKey(AlertsKeys.askLater));
    await tester.pumpAndSettle();

    expect(find.byKey(AlertsKeys.askSheet), findsNothing);
    expect(push.permissionRequests, 0);
    expect(push.asked, isTrue);

    // O segundo final: nada.
    await tester.pumpWidget(const SizedBox());
    await pumpGate(tester, push);
    expect(find.byKey(AlertsKeys.askSheet), findsNothing);
  });

  testWidgets('com a permissão já dada ou sem Firebase, não aparece', (
    tester,
  ) async {
    await pumpGate(tester, FakePushRepository(allowed: true));
    expect(find.byKey(AlertsKeys.askSheet), findsNothing);

    await tester.pumpWidget(const SizedBox());
    await pumpGate(tester, FakePushRepository(available: false));
    expect(find.byKey(AlertsKeys.askSheet), findsNothing);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/alert_settings.dart';
import 'package:lucena/domain/models/user_profile.dart';
import 'package:lucena/ui/alerts/view_models/alerts_cubit.dart';
import 'package:lucena/ui/alerts/widgets/alerts_screen.dart';
import 'package:lucena/ui/core/keys/alerts_keys.dart';

import '../../../testing/fakes/fake_alerts_repository.dart';
import '../../../testing/fakes/fake_profile_repository.dart';
import '../../../testing/fakes/fake_push_repository.dart';
import '../../../testing/test_app.dart';

void main() {
  late FakeAlertsRepository alerts;
  late FakePushRepository push;

  Future<AlertsCubit> pump(WidgetTester tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(412, 915);
    addTearDown(tester.view.reset);
    final cubit = AlertsCubit(
      alerts: alerts,
      push: push,
      profile: FakeProfileRepository(const UserProfile(country: 'BR')),
    );
    addTearDown(cubit.close);
    await cubit.load();
    await tester.pumpWidget(
      TestApp(
        locale: const Locale('pt'),
        alertsCubit: cubit,
        child: const AlertsScreen(),
      ),
    );
    await tester.pumpAndSettle();
    return cubit;
  }

  setUp(() {
    alerts = FakeAlertsRepository();
    push = FakePushRepository(allowed: true);
  });

  bool on(WidgetTester tester, Key key) => tester
      .widget<SwitchListTile>(
        find.descendant(
          of: find.byKey(key),
          matching: find.byType(SwitchListTile),
        ),
      )
      .value;

  testWidgets('permitido: a linha do Android, as 4 chaves e as 19:00', (
    tester,
  ) async {
    await pump(tester);

    expect(find.byKey(AlertsKeys.allowed), findsOneWidget);
    expect(find.text('Android: avisos permitidos para o Lucena'), findsOne);
    expect(find.byKey(AlertsKeys.offBanner), findsNothing);
    expect(on(tester, AlertsKeys.tournaments), isTrue);
    expect(on(tester, AlertsKeys.daily), isTrue);
    expect(on(tester, AlertsKeys.news), isFalse);
    expect(on(tester, AlertsKeys.lessons), isTrue);
    expect(find.text('19:00'), findsOneWidget);

    await tester.tap(find.byKey(AlertsKeys.allowedSettings));
    expect(push.settingsOpened, 1);
  });

  testWidgets('negado: a faixa vermelha abre os ajustes, sem pedir', (
    tester,
  ) async {
    push.allowed = false;
    await pump(tester);

    expect(find.byKey(AlertsKeys.offBanner), findsOneWidget);
    expect(find.text('Os avisos estão desligados no Android'), findsOne);
    expect(find.byKey(AlertsKeys.allowed), findsNothing);

    await tester.tap(find.byKey(AlertsKeys.offOpen));
    await tester.pump();

    expect(push.settingsOpened, 1);
    expect(push.permissionRequests, 0);
  });

  testWidgets('voltar dos ajustes relê a permissão', (tester) async {
    push.allowed = false;
    await pump(tester);

    push.allowed = true;
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();

    expect(find.byKey(AlertsKeys.allowed), findsOneWidget);
    expect(find.byKey(AlertsKeys.offBanner), findsNothing);
  });

  testWidgets('a chave grava na hora', (tester) async {
    await pump(tester);

    await tester.tap(find.byKey(AlertsKeys.news));
    await tester.pumpAndSettle();

    expect(alerts.settings.news, isTrue);
    expect(on(tester, AlertsKeys.news), isTrue);
    expect(push.followed, contains('novidades'));
  });

  testWidgets('sem push só fica a chave local, sem o estado do Android', (
    tester,
  ) async {
    push.available = false;
    alerts.settings = const AlertSettings(reminderMinutes: 8 * 60 + 5);
    await pump(tester);

    expect(find.byKey(AlertsKeys.daily), findsOneWidget);
    expect(find.byKey(AlertsKeys.tournaments), findsNothing);
    expect(find.byKey(AlertsKeys.news), findsNothing);
    expect(find.byKey(AlertsKeys.lessons), findsNothing);
    expect(find.byKey(AlertsKeys.allowed), findsNothing);
    expect(find.byKey(AlertsKeys.offBanner), findsNothing);
    expect(find.text('08:05'), findsOneWidget);
  });
}

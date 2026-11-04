import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/alert_settings.dart';
import 'package:lucena/domain/models/user_profile.dart';
import 'package:lucena/ui/alerts/view_models/alerts_cubit.dart';
import 'package:lucena/ui/alerts/widgets/alerts_screen.dart';
import 'package:lucena/ui/core/keys/alerts_keys.dart';
import 'package:lucena/ui/core/widgets/skeleton.dart';

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

  testWidgets('permitido: a linha do Android e as 4 chaves', (tester) async {
    await pump(tester);

    expect(find.byKey(AlertsKeys.allowed), findsOneWidget);
    expect(
      find.text('Android: notificações permitidas para o Lucena'),
      findsOne,
    );
    expect(find.byKey(AlertsKeys.offBanner), findsNothing);
    expect(on(tester, AlertsKeys.tournaments), isTrue);
    expect(on(tester, AlertsKeys.daily), isTrue);
    expect(on(tester, AlertsKeys.news), isFalse);
    expect(on(tester, AlertsKeys.lessons), isTrue);

    await tester.tap(find.byKey(AlertsKeys.allowedSettings));
    expect(push.settingsOpened, 1);
  });

  testWidgets('negado: a faixa vermelha abre os ajustes, sem pedir', (
    tester,
  ) async {
    push.allowed = false;
    await pump(tester);

    expect(find.byKey(AlertsKeys.offBanner), findsOneWidget);
    expect(find.text('As notificações estão desligadas no Android'), findsOne);
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

  testWidgets('sem push a chave local ainda informa o bloqueio Android', (
    tester,
  ) async {
    push.available = false;
    push.allowed = false;
    alerts.settings = const AlertSettings(reminderMinutes: 8 * 60 + 5);
    await pump(tester);

    expect(find.byKey(AlertsKeys.daily), findsOneWidget);
    expect(find.byKey(AlertsKeys.tournaments), findsNothing);
    expect(find.byKey(AlertsKeys.news), findsNothing);
    expect(find.byKey(AlertsKeys.lessons), findsNothing);
    expect(find.byKey(AlertsKeys.allowed), findsNothing);
    expect(find.byKey(AlertsKeys.offBanner), findsOneWidget);
    expect(find.text('08:05'), findsNothing);
  });

  testWidgets('a linha da região mostra o país e o estado', (tester) async {
    await pump(tester);

    expect(
      find.descendant(
        of: find.byKey(AlertsKeys.region),
        matching: find.textContaining('Brasil'),
      ),
      findsOneWidget,
    );
    expect(find.text('Mudar'), findsOneWidget);
  });

  group('H-AJU-09', () {
    testWidgets('textos do canvas e sem "Horário dos lembretes"', (
      tester,
    ) async {
      await pump(tester);

      for (final text in [
        'Escolha quais notificações o Lucena pode enviar. Dá para mudar '
            'quando quiser.',
        'Um final novo na sua região, no máximo um por dia',
        'Sequência, continue a lição e resumo da semana',
        'Recursos novos do Lucena, poucos por mês',
        'Lições novas',
        'Quando sair uma lição de finais nova',
      ]) {
        expect(find.text(text), findsOneWidget, reason: text);
      }
      expect(find.text('Horário dos lembretes'), findsNothing);
    });

    testWidgets('negado: textos da faixa do canvas', (tester) async {
      push.allowed = false;
      await pump(tester);

      expect(
        find.text(
          'Mesmo com as opções ligadas abaixo, nenhuma notificação chega '
          'neste celular.',
        ),
        findsOneWidget,
      );
      expect(find.text('Abrir configurações'), findsOneWidget);
    });

    testWidgets('carregando: shimmer, sem faixa nem chaves', (tester) async {
      final cubit = AlertsCubit(
        alerts: alerts,
        push: push,
        profile: FakeProfileRepository(const UserProfile(country: 'BR')),
      );
      addTearDown(cubit.close);
      await tester.pumpWidget(
        TestApp(
          locale: const Locale('pt'),
          alertsCubit: cubit,
          child: const AlertsScreen(),
        ),
      );
      await tester.pump();

      expect(find.byType(SkeletonList), findsOneWidget);
      expect(find.byKey(AlertsKeys.allowed), findsNothing);
      expect(find.byKey(AlertsKeys.daily), findsNothing);
    });

    testWidgets('Gap 4: leitura falha mostra o erro, sem faixa verde', (
      tester,
    ) async {
      alerts.loadError = StateError('disco');
      await pump(tester);

      expect(find.byKey(AlertsKeys.error), findsOneWidget);
      expect(find.text('Ocorreu um erro inesperado'), findsOneWidget);
      expect(find.byKey(AlertsKeys.allowed), findsNothing);
    });

    testWidgets('Gap 7: "Permitir" pede a permissão uma vez', (tester) async {
      push.allowed = false;
      push.granted = false;
      await pump(tester);

      expect(find.text('Permitir'), findsOneWidget);
      await tester.tap(find.byKey(AlertsKeys.offAllow));
      await tester.pumpAndSettle();

      expect(push.permissionRequests, 1);
      expect(find.byKey(AlertsKeys.offAllow), findsNothing);
      expect(find.byKey(AlertsKeys.offOpen), findsOneWidget);
    });

    testWidgets('Gap 7: permitido no pedido, a faixa vira verde', (
      tester,
    ) async {
      push.allowed = false;
      push.granted = true;
      await pump(tester);

      await tester.tap(find.byKey(AlertsKeys.offAllow));
      await tester.pumpAndSettle();

      expect(find.byKey(AlertsKeys.allowed), findsOneWidget);
    });

    testWidgets('Gap 1: chave não gravada volta e avisa', (tester) async {
      await pump(tester);

      alerts.saveError = Exception('disco cheio');
      await tester.tap(find.byKey(AlertsKeys.news));
      await tester.pumpAndSettle();

      expect(on(tester, AlertsKeys.news), isFalse);
      expect(find.byKey(AlertsKeys.saveFailure), findsOneWidget);
      expect(find.text('Ocorreu um erro inesperado'), findsOneWidget);
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lucena/data/repositories/account/account_repository.dart';
import 'package:lucena/data/repositories/analytics/analytics_repository.dart';
import 'package:lucena/data/repositories/sync/sync_scheduler.dart';
import 'package:lucena/routing/routes.dart';
import 'package:lucena/ui/account/widgets/account_invite_card.dart';
import 'package:lucena/ui/core/keys/account_keys.dart';

import '../../../testing/fakes/fake_account_repository.dart';
import '../../../testing/fakes/fake_analytics_repository.dart';
import '../../../testing/fakes/fake_sync_repository.dart';
import '../../../testing/test_app.dart';

/// O cartão de convite dentro da tela (PropV2UxConclusaoConta e
/// PropV2UxProgresso, H-CON-02/03): a Partida e "Seu progresso" o colocam.
void main() {
  late FakeAccountRepository accounts;
  late FakeAnalyticsRepository analytics;
  var closed = 0;

  Future<void> pumpCard(WidgetTester tester, {required String title}) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(412, 1400);
    addTearDown(tester.view.reset);
    accounts = FakeAccountRepository();
    analytics = FakeAnalyticsRepository();
    closed = 0;
    final sync = SyncScheduler(accounts, FakeSyncRepository());
    addTearDown(sync.dispose);
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => MultiRepositoryProvider(
            providers: [
              RepositoryProvider<AccountRepository>.value(value: accounts),
              RepositoryProvider<SyncScheduler>.value(value: sync),
              RepositoryProvider<AnalyticsRepository>.value(value: analytics),
            ],
            child: Scaffold(
              body: ListView(
                children: [
                  AccountInviteCard(title: title, onClose: () => closed++),
                ],
              ),
            ),
          ),
        ),
        GoRoute(
          path: Routes.accountEmail,
          builder: (_, state) => Scaffold(body: Text('rota ${state.uri}')),
        ),
        GoRoute(
          path: Routes.accountData,
          builder: (_, state) => Scaffold(body: Text('rota ${state.uri}')),
        ),
      ],
    );
    await tester.pumpWidget(
      TestApp(
        router: router,
        locale: const Locale('pt'),
        child: const SizedBox(),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('"Salve suas conquistas": ícone, texto, os 3 benefícios, '
      'Google, e-mail e entrar, sem "Agora não"', (tester) async {
    await pumpCard(tester, title: 'Salve suas conquistas');
    final card = find.byKey(AccountKeys.inviteCard);
    expect(card, findsOneWidget);
    Finder inCard(Finder f) => find.descendant(of: card, matching: f);
    expect(inCard(find.text('Salve suas conquistas')), findsOneWidget);
    expect(
      inCard(find.text('É de graça e leva menos de um minuto.')),
      findsOneWidget,
    );
    expect(inCard(find.byIcon(Icons.cloud_sync)), findsOneWidget);
    expect(inCard(find.text('Partidas, rating e conquistas')), findsOneWidget);
    expect(inCard(find.text('Lições e Jornada')), findsOneWidget);
    expect(inCard(find.text('Tudo em qualquer celular')), findsOneWidget);
    expect(inCard(find.text('Criar conta com Google')), findsOneWidget);
    expect(inCard(find.text('Criar conta com e-mail')), findsOneWidget);
    expect(inCard(find.byKey(AccountKeys.toSignIn)), findsOneWidget);
    expect(inCard(find.byKey(AccountKeys.later)), findsNothing);
    final close = tester.getSize(find.byKey(AccountKeys.inviteCardClose));
    expect(close, const Size(40, 40));
  });

  testWidgets('o X chama quem colocou o cartão (que suspende o convite)', (
    tester,
  ) async {
    await pumpCard(tester, title: 'Salve seu progresso');
    await tester.tap(find.byKey(AccountKeys.inviteCardClose));
    await tester.pump();
    expect(closed, 1);
  });

  testWidgets('Google entra e segue para "Seu perfil"', (tester) async {
    await pumpCard(tester, title: 'Salve suas conquistas');
    await tester.tap(find.byKey(AccountKeys.google));
    await tester.pumpAndSettle();
    expect(accounts.current, isNotNull);
    expect(find.textContaining('rota /conta/dados'), findsOneWidget);
  });

  testWidgets('"Já tem conta? Entrar" abre o Entrar', (tester) async {
    await pumpCard(tester, title: 'Salve suas conquistas');
    await tester.tap(find.byKey(AccountKeys.toSignIn));
    await tester.pumpAndSettle();
    expect(find.text('rota /conta/email?from=game&entrar=1'), findsOneWidget);
  });
}

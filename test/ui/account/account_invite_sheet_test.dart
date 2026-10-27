import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/data/repositories/account/account_repository.dart';
import 'package:lucena/data/repositories/analytics/analytics_repository.dart';
import 'package:lucena/data/repositories/sync/sync_scheduler.dart';
import 'package:lucena/ui/account/widgets/account_invite_sheet.dart';
import 'package:lucena/ui/core/keys/account_keys.dart';
import 'package:lucena/ui/core/keys/sheet_keys.dart';
import 'package:lucena/ui/core/l10n/l10n.dart';
import 'package:lucena/ui/core/theme/app_spacing.dart';
import 'package:lucena/ui/core/widgets/actions_footer.dart';

import '../../../testing/fakes/fake_account_repository.dart';
import '../../../testing/fakes/fake_analytics_repository.dart';
import '../../../testing/fakes/fake_sync_repository.dart';
import '../../../testing/test_app.dart';

void main() {
  testWidgets('rodapé da folha alinha a 24; Agora não e X só fecham', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(412, 915);
    addTearDown(tester.view.reset);
    final account = FakeAccountRepository();
    final analytics = FakeAnalyticsRepository();
    final sync = SyncScheduler(account, FakeSyncRepository());
    addTearDown(sync.dispose);
    await tester.pumpWidget(
      TestApp(
        locale: const Locale('pt'),
        child: MultiRepositoryProvider(
          providers: [
            RepositoryProvider<AccountRepository>.value(value: account),
            RepositoryProvider<SyncScheduler>.value(value: sync),
            RepositoryProvider<AnalyticsRepository>.value(value: analytics),
          ],
          child: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                key: AccountKeys.later,
                onPressed: () => showAccountInviteSheet(context),
                child: const Icon(Icons.account_circle_outlined),
              ),
            ),
          ),
        ),
      ),
    );

    for (final dismiss in [AccountKeys.notNow, SheetKeys.close]) {
      await tester.tap(find.byKey(AccountKeys.later));
      await tester.pumpAndSettle();
      final sheet = find.byKey(AccountKeys.inviteSheet);
      final footer = find.descendant(
        of: sheet,
        matching: find.byType(ActionsFooter),
      );
      expect(tester.widget<ActionsFooter>(footer).margin, AppSpacing.xl);
      // Só o benefício: nada de vender o "sem conta".
      expect(
        find.text(
          'Com uma conta, a partida, o rating e os cursos ficam salvos e você '
          'recupera tudo em outro aparelho.',
        ),
        findsOneWidget,
      );
      final surface = tester.getRect(sheet);
      final button = tester.getRect(find.byKey(AccountKeys.google));
      expect(button.left - surface.left, AppSpacing.xl);
      expect(surface.right - button.right, AppSpacing.xl);
      await tester.tap(find.byKey(dismiss));
      await tester.pumpAndSettle();
      expect(sheet, findsNothing);
      expect(account.current, isNull);
      expect(find.byKey(AccountKeys.later), findsOneWidget);
    }
    // Só o "Agora não" responde ao convite; o X fecha sem evento.
    final answers = analytics.eventsNamed('conta_convite');
    expect(answers, hasLength(1));
    expect(answers.single.params, {
      'resposta': 'agora_nao',
      'momento': 'pos_vitoria',
    });
  });

  testWidgets('depois do Lichess: o mesmo convite, com o texto do vínculo', (
    tester,
  ) async {
    final account = FakeAccountRepository();
    final analytics = FakeAnalyticsRepository();
    final sync = SyncScheduler(account, FakeSyncRepository());
    addTearDown(sync.dispose);
    bool? accepted;
    await tester.pumpWidget(
      TestApp(
        locale: const Locale('pt'),
        child: MultiRepositoryProvider(
          providers: [
            RepositoryProvider<AccountRepository>.value(value: account),
            RepositoryProvider<SyncScheduler>.value(value: sync),
            RepositoryProvider<AnalyticsRepository>.value(value: analytics),
          ],
          child: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                key: AccountKeys.later,
                onPressed: () async => accepted = await showAccountInviteSheet(
                  context,
                  moment: accountInviteAfterLichess,
                  text: context.l10n.accountInviteTextLichess,
                  from: 'level',
                ),
                child: const Icon(Icons.account_circle_outlined),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(AccountKeys.later));
    await tester.pumpAndSettle();
    final sheet = find.byKey(AccountKeys.inviteSheet);
    expect(
      find.descendant(
        of: sheet,
        matching: find.text(
          'Guarde o seu progresso e o vínculo com o Lichess numa conta do '
          'Lucena. É opcional: sem conta, tudo continua funcionando.',
        ),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(of: sheet, matching: find.byKey(AccountKeys.google)),
      findsOneWidget,
    );
    await tester.tap(find.byKey(AccountKeys.notNow));
    await tester.pumpAndSettle();
    expect(sheet, findsNothing);
    expect(accepted, isFalse);
    expect(analytics.eventsNamed('conta_convite').single.params, {
      'resposta': 'agora_nao',
      'momento': 'pos_lichess',
    });
  });
}

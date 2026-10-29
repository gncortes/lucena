import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lucena/data/repositories/account/account_repository.dart';
import 'package:lucena/data/repositories/campaign/campaign_repository.dart';
import 'package:lucena/data/repositories/campaign/linked_lesson_catalog.dart';
import 'package:lucena/data/repositories/sync/sync_scheduler.dart';
import 'package:lucena/domain/models/campaign.dart';
import 'package:lucena/domain/models/linked_lesson.dart';
import 'package:lucena/routing/routes.dart';
import 'package:lucena/ui/account/widgets/account_screen.dart';
import 'package:lucena/ui/campaign/widgets/linked_lesson_gate.dart';
import 'package:lucena/ui/core/keys/account_keys.dart';
import 'package:lucena/ui/core/keys/challenge_keys.dart';
import 'package:lucena/ui/free_board/view_models/link_lesson_cubit.dart';

import '../../../../testing/fakes/fake_account_repository.dart';
import '../../../../testing/fakes/fake_analytics_repository.dart';
import '../../../../testing/fakes/fake_sync_repository.dart';
import '../../../../testing/test_app.dart';

class _Catalog implements LinkedLessonCatalog {
  @override
  Future<LinkedLessonInfo?> info(LinkedLesson lesson, String language) async =>
      const LinkedLessonInfo(
        kind: LinkedLessonKind.endgame,
        title: 'A posição de Lucena',
      );

  @override
  Future<bool> available(LinkedLesson lesson) async => true;
}

void main() {
  const lesson = LinkedLesson(LinkedLessonKind.endgame, 'rook.lucena');

  late FakeAccountRepository accounts;
  late MemoryCampaignRepository campaigns;
  late FakeAnalyticsRepository analytics;

  Future<void> pumpGate(WidgetTester tester, {String? returnEntry}) async {
    accounts = FakeAccountRepository();
    campaigns = MemoryCampaignRepository();
    analytics = FakeAnalyticsRepository();
    final router = GoRouter(
      initialLocation: '/aula/rook.lucena',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const Scaffold(body: Text('home')),
        ),
        GoRoute(
          path: '/aula/:id',
          builder: (context, state) => BlocProvider(
            create: (_) => LinkLessonCubit(
              campaign: const Campaign(lesson: lesson),
              accounts: accounts,
              catalog: _Catalog(),
              campaigns: campaigns,
              analytics: analytics,
            ),
            child: LinkedLessonGate(returnEntry: returnEntry),
          ),
        ),
        GoRoute(
          path: Routes.accountEnter,
          builder: (context, state) =>
              AccountScreen(from: state.uri.queryParameters['from']!),
        ),
        GoRoute(
          path: Routes.accountEmail,
          builder: (context, state) =>
              Scaffold(body: Text('account ${state.uri}')),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      MultiRepositoryProvider(
        providers: [
          RepositoryProvider<AccountRepository>.value(value: accounts),
          RepositoryProvider<SyncScheduler>.value(
            value: SyncScheduler(accounts, FakeSyncRepository()),
          ),
        ],
        child: TestApp(
          router: router,
          locale: const Locale('pt'),
          child: const SizedBox.shrink(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  List<Object?> answers() => analytics
      .eventsNamed('campanha_cadastro')
      .map((event) => event.params['resposta'])
      .toList();

  testWidgets(
    'normal lesson invitation carries the destination through email login',
    (tester) async {
      const entry =
          '/aula/rook.lucena?retorno=%2Fendgames%2Frook.lucena%2Froteiro%3Fpart%3Dponte';
      await pumpGate(tester, returnEntry: entry);
      await tester.tap(find.byKey(ChallengeKeys.leadHaveAccount));
      await tester.pumpAndSettle();
      expect(
        find.text('account ${Routes.accountEmailFrom(entry, signIn: true)}'),
        findsOneWidget,
      );
    },
  );

  testWidgets('link só de aula sem conta: a folha da aula gratuita, neutra '
      'e só com aprender e praticar; "Agora não" vai ao início', (
    tester,
  ) async {
    await pumpGate(tester);

    expect(find.byKey(ChallengeKeys.lessonGate), findsOneWidget);
    expect(find.byKey(ChallengeKeys.leadSheet), findsOneWidget);
    expect(find.byKey(AccountKeys.inviteSheet), findsNothing);
    expect(
      tester.widget<Text>(find.byKey(ChallengeKeys.leadText)).data,
      'Quer ver esta aula gratuita?',
    );
    expect(find.byKey(ChallengeKeys.leadStep(0)), findsOneWidget);
    expect(find.byKey(ChallengeKeys.leadStep(1)), findsOneWidget);
    expect(find.byKey(ChallengeKeys.leadStep(2)), findsNothing);
    expect(find.text('Refazer este desafio'), findsNothing);
    expect(find.byKey(ChallengeKeys.leadCreate), findsOneWidget);
    expect(find.byKey(ChallengeKeys.leadHaveAccount), findsOneWidget);
    // Atrás da folha, o título da aula, não um fundo vazio.
    expect(
      tester.widget<Text>(find.byKey(ChallengeKeys.lessonGateTitle)).data,
      'A posição de Lucena',
    );
    expect((await campaigns.active())?.lesson, lesson);

    await tester.tap(find.byKey(ChallengeKeys.leadNotNow));
    await tester.pumpAndSettle();

    expect(find.text('home'), findsOneWidget);
    expect(find.byKey(ChallengeKeys.lessonGate), findsNothing);
    expect(analytics.eventsNamed('campanha_aula_aberta'), isEmpty);
    expect(answers(), ['agora_nao']);
  });

  testWidgets('"Criar conta e ver a aula": o cadastro com o título da aula, '
      'sem o "sem conta, tudo continua"', (tester) async {
    await pumpGate(tester);
    await tester.tap(find.byKey(ChallengeKeys.leadCreate));
    await tester.pumpAndSettle();

    expect(find.byKey(AccountKeys.enterScreen), findsOneWidget);
    expect(
      tester.widget<Text>(find.byKey(AccountKeys.enterTitle)).data,
      'Crie sua conta para ter acesso à aula gratuita',
    );
    expect(
      tester.widget<Text>(find.byKey(AccountKeys.enterText)).data,
      'Leva menos de um minuto.',
    );
    expect(find.byIcon(Icons.cloud_done), findsOneWidget);
    expect(find.byIcon(Icons.devices_other), findsOneWidget);
    expect(find.byIcon(Icons.wifi_off), findsNothing);
    expect(answers(), ['aceitou']);
  });

  testWidgets('"Já tenho conta": o entrar por e-mail, que termina na aula', (
    tester,
  ) async {
    await pumpGate(tester);
    await tester.tap(find.byKey(ChallengeKeys.leadHaveAccount));
    await tester.pumpAndSettle();
    expect(
      find.text('account /conta/email?from=%2Faula%2Frook.lucena&entrar=1'),
      findsOneWidget,
    );
    expect(answers(), ['aceitou']);
  });
}

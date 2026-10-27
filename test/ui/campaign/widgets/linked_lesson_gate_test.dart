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
  Future<bool> available(LinkedLesson lesson) async => true;
}

void main() {
  const lesson = LinkedLesson(LinkedLessonKind.endgame, 'rook.lucena');

  testWidgets('link só de aula sem conta: convite antes; "Agora não" vai ao '
      'início, sem abrir a aula', (tester) async {
    final accounts = FakeAccountRepository();
    final campaigns = MemoryCampaignRepository();
    final analytics = FakeAnalyticsRepository();
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
            child: const LinkedLessonGate(),
          ),
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
        child: TestApp(router: router, child: const SizedBox.shrink()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(ChallengeKeys.lessonGate), findsOneWidget);
    expect(find.byKey(AccountKeys.notNow), findsOneWidget);
    expect((await campaigns.active())?.lesson, lesson);

    await tester.tap(find.byKey(AccountKeys.notNow));
    await tester.pumpAndSettle();

    expect(find.text('home'), findsOneWidget);
    expect(find.byKey(ChallengeKeys.lessonGate), findsNothing);
    expect(analytics.eventsNamed('campanha_aula_aberta'), isEmpty);
    expect(
      analytics
          .eventsNamed('campanha_cadastro')
          .map((event) => event.params['resposta']),
      ['agora_nao'],
    );
  });
}

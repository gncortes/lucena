import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lucena/domain/models/training/training_course.dart';
import 'package:lucena/domain/models/user_profile.dart';
import 'package:lucena/domain/models/week_summary.dart';
import 'package:lucena/l10n/app_localizations.dart';
import 'package:lucena/routing/routes.dart';
import 'package:lucena/ui/alerts/view_models/alerts_cubit.dart';
import 'package:lucena/ui/core/keys/training_goal_keys.dart';
import 'package:lucena/ui/reminders/view_models/reminders_cubit.dart';
import 'package:lucena/ui/reminders/widgets/reminders_bridge.dart';

import '../../../testing/fakes/fake_activity_repository.dart';
import '../../../testing/fakes/fake_alerts_repository.dart';
import '../../../testing/fakes/fake_analytics_repository.dart';
import '../../../testing/fakes/fake_profile_repository.dart';
import '../../../testing/fakes/fake_push_repository.dart';
import '../../../testing/fakes/fake_reminders_repository.dart';
import '../../../testing/training/training_scenario_builder.dart';

/// Caso 34 do roteiro do Treino (H-TRE-14), abertura a frio: o app estava
/// FECHADO quando a pessoa tocou a notificação do torneio. O Patrol 4.x não
/// mata o processo do app, então o teste de widget simula o que o plugin faz
/// na partida: `launchRoute()` devolve a rota do torneio na inicialização e o
/// [RemindersBridge] de produção a abre sozinho, sem nenhum toque.
void main() {
  final route =
      '${Routes.training(TrainingCourse.pilares.name)}/tournaments/register';

  Future<GoRouter> open(
    WidgetTester tester, {
    required FakeRemindersRepository reminders,
  }) async {
    final scenario = TrainingScenarioBuilder(TrainingCourse.pilares);
    final alerts = AlertsCubit(
      alerts: FakeAlertsRepository(),
      push: FakePushRepository(allowed: true),
      profile: FakeProfileRepository(const UserProfile(country: 'BR')),
      reminders: reminders,
      analytics: FakeAnalyticsRepository(),
    );
    final cubit = RemindersCubit(
      reminders: reminders,
      activity: FakeActivityRepository(now: scenario.now),
      week: FakeWeekRepository(
        WeekSummary(
          monday: DateTime(2026, 10, 26),
          finals: 0,
          perDay: const [0, 0, 0, 0, 0, 0, 0],
          ratingFrom: 1200,
          ratingTo: 1200,
          streakDays: 0,
          firstTry: 0,
        ),
      ),
      now: scenario.now,
    );
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const Scaffold(key: Key('test.home')),
        ),
        GoRoute(
          path: '/training/:course/tournaments/register',
          builder: (_, _) =>
              const Scaffold(key: TrainingGoalKeys.registerScreen),
        ),
      ],
    );
    addTearDown(router.dispose);
    addTearDown(alerts.close);
    addTearDown(cubit.close);
    addTearDown(reminders.tapsController.close);
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<AlertsCubit>.value(value: alerts),
          BlocProvider<RemindersCubit>.value(value: cubit),
        ],
        child: MaterialApp.router(
          routerConfig: router,
          locale: const Locale('pt', 'BR'),
          localizationsDelegates: const [
            ...AppLocalizations.localizationsDelegates,
            GlobalMaterialLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) => RemindersBridge(
            onOpen: (route) => unawaited(router.push(route)),
            child: child ?? const SizedBox.shrink(),
          ),
        ),
      ),
    );
    await tester.pump();
    await alerts.load();
    await tester.pumpAndSettle();
    return router;
  }

  testWidgets('app fechado: a notificação do torneio abre o Registrar', (
    tester,
  ) async {
    await open(tester, reminders: FakeRemindersRepository(launch: route));
    expect(find.byKey(TrainingGoalKeys.registerScreen), findsOneWidget);
  });

  testWidgets('abertura normal, sem notificação: fica no início', (
    tester,
  ) async {
    await open(tester, reminders: FakeRemindersRepository());
    expect(find.byKey(const Key('test.home')), findsOneWidget);
    expect(find.byKey(TrainingGoalKeys.registerScreen), findsNothing);
  });
}

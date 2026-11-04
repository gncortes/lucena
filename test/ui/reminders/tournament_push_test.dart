import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/alert_settings.dart';
import 'package:lucena/domain/models/training/goal/tournament_record.dart';
import 'package:lucena/domain/models/training/goal/training_objective.dart';
import 'package:lucena/domain/models/training/training_course.dart';
import 'package:lucena/domain/models/training/training_course_config.dart';
import 'package:lucena/domain/models/week_summary.dart';
import 'package:lucena/ui/core/l10n/l10n.dart';
import 'package:lucena/ui/reminders/view_models/reminders_cubit.dart';
import 'package:lucena/ui/reminders/widgets/l10n_reminder_texts.dart';

import '../../../testing/fakes/fake_activity_repository.dart';
import '../../../testing/fakes/fake_analytics_repository.dart';
import '../../../testing/fakes/fake_reminders_repository.dart';
import '../../../testing/training/training_scenario_builder.dart';

void main() {
  final texts = L10nReminderTexts(lookupAppLocalizations(const Locale('pt')));
  const pushId = RemindersCubit.tournamentPushFirstId;

  Future<
    ({
      FakeRemindersRepository reminders,
      FakeAnalyticsRepository analytics,
      dynamic training,
      RemindersCubit cubit,
      TrainingScenarioBuilder scenario,
    })
  >
  setup({
    required String? date,
    bool allowed = true,
    List<TournamentRecord> tournaments = const [],
  }) async {
    final scenario = TrainingScenarioBuilder(TrainingCourse.pilares);
    final state = scenario.large().copyWith(
      objective: date == null
          ? null
          : TrainingObjective(
              kind: ObjectiveKind.tournament,
              setOn: '2026-10-26',
              tournamentDate: date,
              tournamentName: 'Aberto',
            ),
      tournaments: tournaments,
    );
    final training = scenario.repository(state);
    addTearDown(training.dispose);
    final reminders = FakeRemindersRepository(allowed: allowed);
    addTearDown(reminders.tapsController.close);
    final analytics = FakeAnalyticsRepository();
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
      training: training,
      analytics: analytics,
    );
    addTearDown(cubit.close);
    await cubit.update(settings: const AlertSettings(), texts: texts);
    return (
      reminders: reminders,
      analytics: analytics,
      training: training,
      cubit: cubit,
      scenario: scenario,
    );
  }

  test(
    'agenda às 9h do dia seguinte ao torneio, com o texto e a rota',
    () async {
      final s = await setup(date: '2026-10-30');
      final push = s.reminders.scheduled.singleWhere((n) => n.id == pushId);
      expect(push.at, DateTime(2026, 10, 31, 9));
      expect(push.title, 'Como foi o Aberto?');
      expect(push.body, 'Registre seu desempenho.');
      expect(push.payload, '/training/pilares/tournaments/register');
      expect(s.analytics.eventsNamed('torneio_push_agendado'), hasLength(1));
      await s.cubit.refresh();
      expect(
        s.analytics.eventsNamed('torneio_push_agendado'),
        hasLength(1),
        reason: 'uma vez só por torneio',
      );
    },
  );

  test(
    'sem torneio, desempenho já registrado ou sem permissão: nada',
    () async {
      final none = await setup(date: null);
      expect(none.reminders.scheduled.where((n) => n.id == pushId), isEmpty);

      final denied = await setup(date: '2026-10-30', allowed: false);
      expect(denied.reminders.scheduled.where((n) => n.id == pushId), isEmpty);
      expect(denied.analytics.eventsNamed('torneio_push_agendado'), isEmpty);

      final done = await setup(
        date: '2026-10-30',
        tournaments: const [
          TournamentRecord(
            id: '1',
            name: 'Aberto',
            date: '2026-10-30',
            tenthsPoints: 35,
            rounds: 5,
          ),
        ],
      );
      expect(done.reminders.scheduled.where((n) => n.id == pushId), isEmpty);
    },
  );

  test(
    'passada a hora, o aviso sai da lista e vira "mostrado" uma vez',
    () async {
      final s = await setup(date: '2026-10-30');
      s.scenario.now.value = DateTime(2026, 10, 31, 10);
      await s.cubit.refresh();
      expect(s.reminders.scheduled.where((n) => n.id == pushId), isEmpty);
      expect(s.analytics.eventsNamed('torneio_push_mostrado'), hasLength(1));
      await s.cubit.refresh();
      expect(s.analytics.eventsNamed('torneio_push_mostrado'), hasLength(1));
    },
  );
}

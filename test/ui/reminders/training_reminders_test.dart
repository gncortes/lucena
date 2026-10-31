import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/alert_settings.dart';
import 'package:lucena/domain/models/training/day_goals.dart';
import 'package:lucena/domain/models/training/training_course.dart';
import 'package:lucena/domain/models/training/training_course_config.dart';
import 'package:lucena/domain/models/training/training_plan.dart';
import 'package:lucena/domain/models/training/training_state.dart';
import 'package:lucena/domain/models/week_summary.dart';
import 'package:lucena/domain/use_cases/training/reminder_text.dart';
import 'package:lucena/domain/use_cases/training/training_reminder.dart';
import 'package:lucena/ui/core/l10n/l10n.dart';
import 'package:lucena/ui/reminders/view_models/reminders_cubit.dart';
import 'package:lucena/ui/reminders/widgets/l10n_reminder_texts.dart';

import '../../../testing/fakes/fake_activity_repository.dart';
import '../../../testing/fakes/fake_reminders_repository.dart';
import '../../../testing/fakes/fake_course_training_repository.dart';
import '../../../testing/fakes/fake_analytics_repository.dart';
import '../../../testing/training/training_scenario_builder.dart';

void main() {
  final texts = L10nReminderTexts(lookupAppLocalizations(const Locale('pt')));
  test('notificações do treino usam plurais com e sem aula', () {
    for (final n in [1, 3]) {
      expect(
        texts.trainingBody(
          TrainingReminderText('trainingNotifGoals', {'n': n}),
          null,
        ),
        n == 1 ? '1 meta para concluir.' : '3 metas para concluir.',
      );
      expect(
        texts.trainingBody(
          TrainingReminderText('trainingNotifLesson', {'n': n, 'aula': 'id'}),
          'Cravada',
        ),
        n == 1
            ? 'Falta a aula Cravada e 1 meta para concluir.'
            : 'Falta a aula Cravada e 3 metas para concluir.',
      );
    }
  });

  test(
    'agendamento usa plano congelado; horário passado e folga não agendam',
    () {
      final scenario = TrainingScenarioBuilder(TrainingCourse.pilares);
      final state = scenario.large().copyWith(
        plan: const TrainingPlan(reminderHour: 14),
      );
      expect(trainingReminder(state, scenario.now)!.at.hour, 19);
      scenario.now.value = DateTime(2026, 10, 26, 20);
      expect(trainingReminder(state, scenario.now), isNull);
      expect(
        trainingReminder(scenario.large(dayOff: true), scenario.now),
        isNull,
      );
    },
  );

  for (final sample in ['pending', 'done', 'dayOff', 'denied', 'dailyOff']) {
    test(
      'treino $sample preserva lembretes antigos e usa o mesmo replace',
      () async {
        final scenario = TrainingScenarioBuilder(TrainingCourse.pilares);
        final TrainingState state = switch (sample) {
          'done' => scenario.allDone(),
          'dayOff' => scenario.large(dayOff: true),
          _ => scenario.large(),
        };
        final training = scenario.repository(state);
        addTearDown(training.dispose);
        final reminders = FakeRemindersRepository(allowed: sample != 'denied');
        addTearDown(reminders.tapsController.close);
        final activity = FakeActivityRepository(
          days: {DateTime(2026, 10, 24), DateTime(2026, 10, 25)},
          now: scenario.now,
        );
        final cubit = RemindersCubit(
          reminders: reminders,
          activity: activity,
          week: FakeWeekRepository(
            WeekSummary(
              monday: DateTime(2026, 10, 26),
              finals: 0,
              perDay: const [0, 0, 0, 0, 0, 0, 0],
              ratingFrom: 1200,
              ratingTo: 1200,
              streakDays: 1,
              firstTry: 0,
            ),
          ),
          now: scenario.now,
          training: training,
        );
        addTearDown(cubit.close);
        await cubit.update(
          settings: AlertSettings(daily: sample != 'dailyOff'),
          texts: texts,
        );
        final course = reminders.scheduled.where(
          (n) => n.id >= RemindersCubit.trainingFirstId,
        );
        expect(
          course.length,
          {
            'pending': 8,
            'done': 7,
            'dayOff': 0,
            'denied': 0,
            'dailyOff': 8,
          }[sample],
        );
        final other = reminders.scheduled.where(
          (n) => n.id < RemindersCubit.trainingFirstId,
        );
        if (sample == 'pending' || sample == 'done' || sample == 'dayOff') {
          expect(other, isNotEmpty);
        }
        if (sample == 'dailyOff' || sample == 'denied') expect(other, isEmpty);
        final today = course.where(
          (n) => n.id < RemindersCubit.trainingWeeklyFirstId,
        );
        if (sample == 'pending' || sample == 'dailyOff') {
          expect(
            today.single.body,
            'Falta a aula Tema 9 e 12 metas para concluir.',
          );
          expect(today.single.title, 'Hora do xadrez');
          expect(today.single.payload, '/');
          expect(today.single.repeatWeekly, isFalse);
        } else {
          expect(today, isEmpty);
        }
        expect(
          course.where((n) => n.repeatWeekly).length,
          {
            'pending': 7,
            'done': 7,
            'dayOff': 0,
            'denied': 0,
            'dailyOff': 7,
          }[sample],
        );
        expect(reminders.replaces, 1);
      },
    );
  }

  test(
    'two course IDs, snapshot, off and changed plan remain independent',
    () async {
      final scenario = TrainingScenarioBuilder(TrainingCourse.pilares);
      final original = scenario.large();
      final training = FakeTrainingRepository(
        states: {
          TrainingCourse.pilares: original,
          TrainingCourse.escola: TrainingState(
            course: TrainingCourse.escola,
            installSeed: 'school',
            onboardingDone: true,
          ),
        },
        content: {
          for (final course in TrainingCourse.values) course: scenario.content,
        },
      );
      addTearDown(training.dispose);
      final reminders = FakeRemindersRepository();
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
        courses: TrainingCourseConfig.all,
      );
      addTearDown(cubit.close);
      await cubit.update(settings: const AlertSettings(), texts: texts);
      var schedules = reminders.scheduled;
      expect(schedules.map((n) => n.id).toSet().length, schedules.length);
      expect(schedules.where((n) => n.id == 600 || n.id == 601).length, 2);
      expect(schedules.where((n) => n.repeatWeekly).length, 12);
      final today = await training.load(TrainingCourse.pilares);
      expect(today.day!.toJson(), original.day!.toJson());
      expect(today.completedLessons, original.completedLessons);
      expect(today.lastLessonDate, original.lastLessonDate);
      expect(today.analyticsReminderAt, DateTime(2026, 10, 26, 19));
      expect(today.analyticsReminderShownAt, isNull);
      expect(analytics.eventsNamed('treino_lembrete_agendado').length, 2);
      expect(analytics.eventsNamed('treino_lembrete_mostrado'), isEmpty);
      final ids = schedules.map((n) => n.id).toList();
      await cubit.refresh();
      expect(reminders.scheduled.map((n) => n.id), ids);
      expect(analytics.eventsNamed('treino_lembrete_agendado').length, 2);
      expect(analytics.eventsNamed('treino_lembrete_mostrado'), isEmpty);
      await training.update(
        TrainingCourse.pilares,
        (s) => s.copyWith(plan: s.plan.copyWith(weekdays: 2, reminderHour: 0)),
      );
      await cubit.refresh();
      schedules = reminders.scheduled;
      final pillarsFuture = schedules.where((n) => n.id >= 700 && n.id < 732);
      expect(pillarsFuture.single.repeatWeekly, isTrue);
      expect(pillarsFuture.single.at.weekday, DateTime.monday);
      expect(pillarsFuture.single.at.hour, 0);
      // Today's frozen plan keeps its one-shot; future uses the new plan.
      expect(schedules.singleWhere((n) => n.id == 600).at.hour, 19);
      await training.update(
        TrainingCourse.pilares,
        (s) => s.copyWith(plan: s.plan.copyWith(reminderOn: false)),
      );
      await cubit.refresh();
      expect(
        reminders.scheduled.where(
          (n) => n.id == 600 || n.id >= 700 && n.id < 732,
        ),
        isEmpty,
      );
      expect(reminders.scheduled.where((n) => n.id >= 732), isNotEmpty);
      reminders.allowed = false;
      await cubit.refresh();
      expect(reminders.scheduled, isEmpty);
    },
  );

  test('uma meta sem aula usa seu total nas notificações', () {
    final day = DayGoals(
      date: '2026-10-26',
      studyDay: true,
      goals: [TrainingGoal(kind: GoalKind.exercise, ref: 'theme')],
    );
    expect(reminderText(day)!.arguments, {'n': 1});
  });
}

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/alert_settings.dart';
import 'package:lucena/domain/models/training/day_goals.dart';
import 'package:lucena/domain/models/training/training_course.dart';
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
            'pending': 1,
            'done': 0,
            'dayOff': 0,
            'denied': 0,
            'dailyOff': 1,
          }[sample],
        );
        final other = reminders.scheduled.where(
          (n) => n.id < RemindersCubit.trainingFirstId,
        );
        if (sample == 'pending' || sample == 'done' || sample == 'dayOff') {
          expect(other, isNotEmpty);
        }
        if (sample == 'dailyOff' || sample == 'denied') expect(other, isEmpty);
        if (course.isNotEmpty) {
          expect(
            course.single.body,
            'Falta a aula Tema 9 e 12 metas para concluir.',
          );
          expect(course.single.title, 'Hora do xadrez');
          expect(course.single.payload, '/');
        }
        expect(reminders.replaces, 1);
      },
    );
  }

  test('uma meta sem aula usa seu total nas notificações', () {
    final day = DayGoals(
      date: '2026-10-26',
      studyDay: true,
      goals: [TrainingGoal(kind: GoalKind.exercise, ref: 'theme')],
    );
    expect(reminderText(day)!.arguments, {'n': 1});
  });
}

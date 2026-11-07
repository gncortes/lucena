import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/alert_settings.dart';
import 'package:lucena/domain/models/training/training_course.dart';
import 'package:lucena/domain/models/week_summary.dart';
import 'package:lucena/ui/core/l10n/l10n.dart';
import 'package:lucena/ui/reminders/view_models/reminders_cubit.dart';
import 'package:lucena/ui/reminders/widgets/l10n_reminder_texts.dart';

import '../../../testing/fakes/fake_activity_repository.dart';
import '../../../testing/fakes/fake_course_training_repository.dart';
import '../../../testing/fakes/fake_reminders_repository.dart';
import '../../../testing/training/training_scenario_builder.dart';

void main() {
  final texts = L10nReminderTexts(lookupAppLocalizations(const Locale('pt')));
  RemindersCubit build(
    TrainingScenarioBuilder scenario,
    FakeRemindersRepository reminders,
    FakeTrainingRepository training,
  ) => RemindersCubit(
    reminders: reminders,
    activity: FakeActivityRepository(
      days: {DateTime(2026, 10, 24), DateTime(2026, 10, 25)},
      now: scenario.now,
    ),
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

  // H-TRE-17 gap 10: estado ilegível não derruba os outros lembretes.
  test('estado do treino ilegível não impede os outros lembretes', () async {
    final scenario = TrainingScenarioBuilder(TrainingCourse.pilares);
    final training = scenario.repository(scenario.large());
    training.readError = const FormatException('training.v1 ilegível');
    addTearDown(training.dispose);
    final reminders = FakeRemindersRepository();
    addTearDown(reminders.tapsController.close);
    final cubit = build(scenario, reminders, training);
    addTearDown(cubit.close);
    await cubit.update(settings: const AlertSettings(), texts: texts);
    final other = reminders.scheduled.where(
      (n) => n.id < RemindersCubit.trainingFirstId,
    );
    expect(other, isNotEmpty, reason: 'sequência/semana continuam agendadas');
    expect(
      reminders.scheduled.where((n) => n.id >= RemindersCubit.trainingFirstId),
      isEmpty,
      reason: 'sem ler o treino, não inventa lembrete dele',
    );
  });

  test('meta do dia feita não notifica hoje', () async {
    final scenario = TrainingScenarioBuilder(TrainingCourse.pilares);
    final training = scenario.repository(scenario.allDone());
    addTearDown(training.dispose);
    final reminders = FakeRemindersRepository();
    addTearDown(reminders.tapsController.close);
    final cubit = build(scenario, reminders, training);
    addTearDown(cubit.close);
    await cubit.update(settings: const AlertSettings(), texts: texts);
    final today = DateTime(2026, 10, 26);
    for (final n in reminders.scheduled.where(
      (n) => n.id >= RemindersCubit.trainingFirstId,
    )) {
      expect(
        n.repeatWeekly || n.at.day != today.day,
        isTrue,
        reason: 'lembrete avulso de hoje com meta feita: ${n.at}',
      );
    }
    expect(
      reminders.scheduled.where(
        (n) => n.id == RemindersCubit.trainingFirstId && n.at.day == today.day,
      ),
      isEmpty,
    );
  });
}

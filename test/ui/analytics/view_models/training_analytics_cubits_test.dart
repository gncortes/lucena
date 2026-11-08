import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/alert_settings.dart';
import 'package:lucena/domain/models/training/training_course.dart';
import 'package:lucena/domain/models/week_summary.dart';
import 'package:lucena/ui/course_guide/view_models/course_guide_cubit.dart';
import 'package:lucena/ui/course_guide/view_models/training_plan_cubit.dart';
import 'package:lucena/ui/core/l10n/l10n.dart';
import 'package:lucena/ui/reminders/view_models/reminders_cubit.dart';
import 'package:lucena/ui/reminders/widgets/l10n_reminder_texts.dart';

import '../../../../testing/fakes/fake_analytics_repository.dart';
import '../../../../testing/fakes/fake_activity_repository.dart';
import '../../../../testing/fakes/fake_push_repository.dart';
import '../../../../testing/fakes/fake_reminders_repository.dart';
import '../../../../testing/training/training_scenario_builder.dart';

void main() {
  for (final course in TrainingCourse.values) {
    test('$course plan and guide emit only after successful saves', () async {
      final fixture = TrainingScenarioBuilder(TrainingCourse.pilares);
      final scenario = TrainingScenarioBuilder(
        course,
        resources: fixture.content,
      );
      final repository = scenario.repository(scenario.large());
      final analytics = FakeAnalyticsRepository();
      final plan = TrainingPlanCubit(
        repository: repository,
        config: scenario.config,
        now: scenario.now,
        push: FakePushRepository(allowed: true),
        analytics: analytics,
      );
      final guide = CourseGuideCubit(
        repository: repository,
        config: scenario.config,
        now: scenario.now,
        analytics: analytics,
      );
      addTearDown(plan.close);
      addTearDown(guide.close);
      addTearDown(repository.dispose);
      await plan.load();
      expect(await plan.save(), true);
      expect(
        analytics.eventsNamed('treino_plano_alterado').single.params['curso'],
        course.name,
      );
      expect(
        analytics.eventsNamed('aviso_chave').single.params['tipo'],
        'treino',
      );
      await guide.load();
      expect(await guide.selectTab(CourseGuideTab.goals, origin: 'home'), true);
      expect(analytics.eventsNamed('curso_guia_aba').single.params, {
        'curso': course.name,
        'aba': 'metas',
        'origem': 'home',
      });
      repository.writeError = StateError('disk');
      expect(await plan.save(), false);
      expect(analytics.eventsNamed('treino_plano_alterado'), hasLength(1));
      expect(await guide.selectTab(CourseGuideTab.catalog), false);
      expect(analytics.eventsNamed('curso_guia_aba'), hasLength(1));
    });
  }

  test('reminders persist schedule, infer once after reopening, cancel before time', () async {
    final scenario = TrainingScenarioBuilder(TrainingCourse.pilares);
    final repository = scenario.repository(scenario.large());
    final reminders = FakeRemindersRepository();
    final analytics = FakeAnalyticsRepository();
    addTearDown(repository.dispose);
    addTearDown(reminders.tapsController.close);
    final texts = L10nReminderTexts(lookupAppLocalizations(const Locale('pt')));
    RemindersCubit build() => RemindersCubit(
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
      training: repository,
      analytics: analytics,
    );
    var cubit = build();
    await cubit.update(settings: const AlertSettings(), texts: texts);
    await cubit.refresh();
    expect(analytics.eventsNamed('treino_lembrete_agendado'), hasLength(1));
    expect(
      (await repository.load(TrainingCourse.pilares)).analyticsReminderAt,
      isNotNull,
    );
    await cubit.close();
    scenario.now.value = DateTime(2026, 10, 26, 19, 7);
    cubit = build();
    await cubit.update(settings: const AlertSettings(), texts: texts);
    await cubit.refresh();
    expect(
      analytics
          .eventsNamed('treino_lembrete_mostrado')
          .single
          .params['atraso_min'],
      7,
    );
    await cubit.close();
    // Reopening after the inferred delivery does not duplicate it.
    cubit = build();
    await cubit.update(settings: const AlertSettings(), texts: texts);
    expect(analytics.eventsNamed('treino_lembrete_mostrado'), hasLength(1));
    await cubit.close();
    // A future schedule removed while permission is off never counts as shown.
    scenario.now.value = DateTime(2026, 10, 27, 12);
    cubit = build();
    await cubit.update(settings: const AlertSettings(), texts: texts);
    reminders.allowed = false;
    await cubit.refresh();
    expect(
      (await repository.load(TrainingCourse.pilares)).analyticsReminderAt,
      isNull,
    );
    scenario.now.value = DateTime(2026, 10, 27, 20);
    await cubit.refresh();
    expect(analytics.eventsNamed('treino_lembrete_mostrado'), hasLength(1));
    await cubit.close();
  });
}

import '../../../data/repositories/analytics/analytics_repository.dart';
import '../../../domain/models/analytics_event.dart';

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/activity/activity_repository.dart';
import '../../../data/repositories/reminders/reminders_repository.dart';
import '../../../data/repositories/week/week_repository.dart';
import '../../../data/repositories/training/course_training_repository.dart';
import '../../../domain/models/training/training_course_config.dart';
import '../../../domain/models/training/training_course.dart';
import '../../../domain/models/training/training_state.dart';
import '../../../domain/use_cases/training/build_day_goals.dart';
import '../../../domain/use_cases/training/training_reminder.dart';
import '../../../data/services/notification_service.dart';
import '../../../domain/models/alert_settings.dart';
import '../../../domain/models/reminder.dart';
import '../../../domain/use_cases/now.dart';
import '../../../domain/use_cases/reminder_planner.dart';
import '../../../domain/use_cases/streak_rules.dart';
import '../../../routing/routes.dart';
import 'reminder_texts.dart';

/// Os lembretes locais (E1.23). Vive no app inteiro: replaneja a cada
/// partida ou aula ([changes]), a cada mudança em Avisos ([update]) e ao
/// abrir, voltar ou ir para segundo plano ([refresh]). O estado é o que está
/// agendado.
class RemindersCubit extends Cubit<List<PlannedReminder>> {
  RemindersCubit({
    required this._reminders,
    required this._activity,
    required this._week,
    required this._now,
    Stream<void>? changes,
    TrainingRepository? training,
    this.analytics = const NoAnalyticsRepository(),
    this.courses = const [TrainingCourseConfig.pilares],
  }) : _training = training,
       super(const []) {
    _changes = changes?.listen((_) => unawaited(refresh()));
    _trainingChanges = training?.changes.listen((_) => unawaited(refresh()));
  }

  final AnalyticsRepository analytics;
  Future<void> _log(AnalyticsEvent event) {
    unawaited(
      Future<void>.sync(() => analytics.log(event)).catchError((Object _) {}),
    );
    return Future<void>.value();
  }

  final RemindersRepository _reminders;
  final ActivityRepository _activity;
  final WeekRepository _week;
  final Now _now;
  StreamSubscription<void>? _changes;
  final TrainingRepository? _training;
  final List<TrainingCourseConfig> courses;
  StreamSubscription<TrainingState>? _trainingChanges;

  AlertSettings? _settings;
  ReminderTexts? _texts;

  // Um replanejamento por vez; o que chega no meio roda de novo no fim.
  Future<void>? _running;
  bool _again = false;

  /// As rotas das notificações tocadas com o app aberto.
  Stream<String> get taps => _reminders.taps;

  /// A rota da notificação que abriu o app (depois do primeiro [update]).
  Future<String?> launchRoute() => _reminders.launchRoute();

  /// As chaves de Avisos ou o idioma mudaram.
  Future<void> update({
    required AlertSettings settings,
    required ReminderTexts texts,
  }) {
    _settings = settings;
    _texts = texts;
    return refresh();
  }

  /// Reconfere o que está agendado.
  Future<void> refresh() async {
    if (_settings == null || isClosed) return;
    if (_running != null) {
      _again = true;
      return _running;
    }
    final running = _replan();
    _running = running;
    try {
      await running;
    } finally {
      _running = null;
    }
    if (_again) {
      _again = false;
      await refresh();
    }
  }

  Future<void> _replan() async {
    final settings = _settings!;
    final texts = _texts!;
    final courseTexts = switch (texts) {
      CourseReminderTexts value => value,
      _ => null,
    };
    // O nome dos canais vai junto: outro idioma renomeia.
    await _reminders.start([
      texts.reminders,
      texts.week,
      if (_training != null && courseTexts != null) courseTexts.trainingChannel,
    ]);
    final permitted = await _reminders.permitted();
    final enabled = settings.daily && permitted;
    final now = _now();
    final plan = enabled
        ? ReminderPlanner.plan(
            now: now,
            enabled: true,
            minutes: settings.reminderMinutes,
            streak: StreakRules.of(await _activity.days(), now),
            lesson: await _reminders.pausedLesson(texts.language),
            week: await _week.summary(),
          )
        : const <PlannedReminder>[];
    final trainingNotifications = permitted && courseTexts != null
        ? await _courseNotifications(courseTexts)
        : <ScheduledNotification>[];
    await _reminders.replace([
      for (final reminder in plan) _notification(reminder, now, texts),
      ...trainingNotifications,
    ]);
    await _recordTrainingSchedules(trainingNotifications);
    if (!isClosed && !listEquals(plan, state)) emit(plan);
  }

  /// Course and existing reminders share the same replace operation, so neither
  /// flow erases notifications belonging to the other.
  Future<List<ScheduledNotification>> _courseNotifications(
    CourseReminderTexts texts,
  ) async {
    final repository = _training;
    if (repository == null) return [];
    final notifications = <ScheduledNotification>[];
    for (final config in courses) {
      final before = await repository.load(config.course);
      if (!before.onboardingDone) continue;
      final resources = await repository.resources(config.course);
      final training = await repository.update(
        config.course,
        (s) => BuildDayGoals(_now, config)(s, resources),
      );
      final request = trainingReminder(training, _now);
      if (request == null) continue;
      final lessonId = request.text.arguments['aula'];
      final lesson = resources.lessons
          .where((l) => l.id == lessonId)
          .firstOrNull;
      notifications.add(
        ScheduledNotification(
          id: trainingFirstId + config.course.index,
          channel: texts.trainingChannel,
          title: texts.trainingTitle,
          body: texts.trainingBody(request.text, lesson?.title),
          at: request.at,
          payload: Routes.home,
        ),
      );
    }
    return notifications;
  }

  /// Called only after replace succeeds. Persist inference before logging, so
  /// a restart or overlapping refresh cannot count the same delivery twice.
  Future<void> _recordTrainingSchedules(
    List<ScheduledNotification> notifications,
  ) async {
    final repository = _training;
    if (repository == null) return;
    for (final config in courses) {
      final notification = notifications
          .where((n) => n.id == trainingFirstId + config.course.index)
          .firstOrNull;
      AnalyticsEvent? scheduled, shown;
      await repository.transact(config.course, (current) {
        final old = current.analyticsReminderAt;
        final at = notification?.at;
        var next = current;
        if (old != null &&
            !old.isAfter(_now()) &&
            current.analyticsReminderShownAt != old) {
          next = next.copyWith(analyticsReminderShownAt: old);
          shown = AnalyticsEvents.treinoLembreteMostrado(
            curso: config.course.name,
            atrasoMin: _now().difference(old).inMinutes.clamp(0, 2147483647),
          );
        }
        if (old != at) {
          next = next.copyWith(analyticsReminderAt: at);
          if (at != null) {
            scheduled = AnalyticsEvents.treinoLembreteAgendado(
              curso: config.course.name,
              hora: at.hour,
              metas: current.day?.remaining ?? 0,
              aulaPendente:
                  current.day?.goals.any(
                    (g) =>
                        !g.done &&
                        (g.kind == GoalKind.lesson ||
                            g.kind == GoalKind.redo ||
                            g.kind == GoalKind.extraLesson),
                  ) ??
                  false,
            );
          }
        }
        return next;
      });
      if (shown != null) unawaited(_log(shown!));
      if (scheduled != null) unawaited(_log(scheduled!));
    }
  }

  static const trainingFirstId = 600;

  ScheduledNotification _notification(
    PlannedReminder reminder,
    DateTime now,
    ReminderTexts texts,
  ) {
    final today = StreakRules.day(now);
    final day = StreakRules.day(reminder.at);
    // Um id por dia da semana que vem: agendar de novo troca o do mesmo dia.
    final offset = DateTime.utc(
      day.year,
      day.month,
      day.day,
    ).difference(DateTime.utc(today.year, today.month, today.day)).inDays;
    return ScheduledNotification(
      id: firstId + offset,
      channel: reminder.kind == ReminderKind.week
          ? texts.week
          : texts.reminders,
      title: texts.title(reminder),
      body: texts.body(reminder),
      at: reminder.at,
      payload: route(reminder),
      action: texts.action(reminder),
    );
  }

  /// O id do lembrete de hoje; os seguintes somam o dia.
  static const firstId = 100;

  /// Para onde o toque leva.
  static String route(PlannedReminder reminder) => switch (reminder.kind) {
    ReminderKind.streak => Routes.dailyFrom('lembrete'),
    ReminderKind.lesson => Routes.endgameLessonScript(
      reminder.lesson!.lessonId,
      part: reminder.lesson!.partId,
      stage: reminder.lesson!.stage,
      origin: 'aviso',
    ),
    ReminderKind.week => Routes.week,
  };

  @override
  Future<void> close() async {
    await _changes?.cancel();
    await _trainingChanges?.cancel();
    return super.close();
  }
}

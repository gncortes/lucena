import '../../../data/services/notification_service.dart';
import '../../../domain/models/reminder.dart';
import '../../../domain/use_cases/training/reminder_text.dart';
import '../../core/l10n/l10n.dart';
import '../../week/widgets/week_texts.dart';
import '../view_models/reminder_texts.dart';

/// Os textos dos lembretes nas traduções do app.
class L10nReminderTexts implements ReminderTexts, CourseReminderTexts {
  L10nReminderTexts(this._l10n);

  final AppLocalizations _l10n;

  @override
  String get language => _l10n.localeName.split('_').first;

  @override
  NotificationChannelSpec get reminders => NotificationChannelSpec(
    id: 'lembretes_quieto',
    name: _l10n.reminderChannel,
  );

  @override
  NotificationChannelSpec get week => NotificationChannelSpec(
    id: 'resumo_semana_quieto',
    name: _l10n.weekChannel,
  );

  @override
  NotificationChannelSpec get trainingChannel => NotificationChannelSpec(
    id: 'treino_quieto',
    name: _l10n.trainingReminderTitle,
  );
  @override
  String get trainingTitle => _l10n.trainingNotifTitle;
  @override
  String trainingBody(TrainingReminderText request, String? lessonTitle) {
    final count = request.arguments['n']! as int;
    if (request.key == 'trainingNotifLesson') {
      return lessonTitle == null
          ? _l10n.trainingNotifGoals(count + 1)
          : _l10n.trainingNotifLesson(lessonTitle, count);
    }
    return _l10n.trainingNotifGoals(count);
  }

  @override
  String title(PlannedReminder reminder) => switch (reminder.kind) {
    ReminderKind.streak => _l10n.reminderStreakTitle(reminder.streakDays),
    ReminderKind.lesson => _l10n.reminderLessonTitle,
    ReminderKind.week => _l10n.weekNotifTitle,
  };

  @override
  String body(PlannedReminder reminder) => switch (reminder.kind) {
    ReminderKind.streak => _l10n.reminderStreakText,
    ReminderKind.lesson => _l10n.reminderLessonText(
      reminder.lesson!.title,
      reminder.lesson!.chapter,
      reminder.lesson!.total,
    ),
    ReminderKind.week => weekNotification(_l10n, reminder.week!),
  };

  @override
  String? action(PlannedReminder reminder) => switch (reminder.kind) {
    ReminderKind.streak => _l10n.reminderStreakAction,
    ReminderKind.lesson => _l10n.reminderLessonAction,
    ReminderKind.week => null,
  };

  @override
  bool operator ==(Object other) =>
      other is L10nReminderTexts && other._l10n.localeName == _l10n.localeName;

  @override
  int get hashCode => _l10n.localeName.hashCode;
}

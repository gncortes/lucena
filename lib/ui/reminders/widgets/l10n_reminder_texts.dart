import '../../../data/services/notification_service.dart';
import '../../../domain/models/reminder.dart';
import '../../core/l10n/l10n.dart';
import '../../week/widgets/week_texts.dart';
import '../view_models/reminder_texts.dart';

/// Os textos dos lembretes nas traduções do app.
class L10nReminderTexts implements ReminderTexts {
  L10nReminderTexts(this._l10n);

  final AppLocalizations _l10n;

  @override
  String get language => _l10n.localeName.split('_').first;

  @override
  NotificationChannelSpec get reminders =>
      NotificationChannelSpec(id: 'lembretes', name: _l10n.reminderChannel);

  @override
  NotificationChannelSpec get week =>
      NotificationChannelSpec(id: 'resumo_semana', name: _l10n.weekChannel);

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

import '../../../data/services/notification_service.dart';
import '../../../domain/models/reminder.dart';
import '../../../domain/use_cases/training/reminder_text.dart';

abstract interface class CourseReminderTexts {
  NotificationChannelSpec get trainingChannel;
  String get trainingTitle;
  String trainingBody(TrainingReminderText request, String? lessonTitle);
}

/// Os textos dos lembretes no idioma do app, montados pela UI (o view model
/// não lê as traduções).
abstract class ReminderTexts {
  /// O código do idioma, para o título da aula.
  String get language;

  /// O canal "Lembretes" (sequência e lição).
  NotificationChannelSpec get reminders;

  /// O canal "Resumo da semana".
  NotificationChannelSpec get week;

  String title(PlannedReminder reminder);
  String body(PlannedReminder reminder);

  /// O botão da notificação; nulo sem botão.
  String? action(PlannedReminder reminder);
}

import '../../../domain/models/reminder.dart';
import '../../../domain/use_cases/endgame_lesson_rules.dart';
import '../../services/notification_service.dart';
import '../endgames/endgame_lesson_repository.dart';
import '../endgames/endgame_progress_repository.dart';

/// Os lembretes locais (E1.23): o agendamento no aparelho e a aula em que a
/// pessoa parou.
abstract class RemindersRepository {
  /// Prepara as notificações e cria os [channels] do Android.
  Future<void> start(List<NotificationChannelSpec> channels);

  /// Se o Android deixa o Lucena mostrar avisos agora.
  Future<bool> permitted();

  /// Troca o que estava agendado por [notifications].
  Future<void> replace(List<ScheduledNotification> notifications);

  /// A rota da notificação que abriu o app.
  Future<String?> launchRoute();

  /// As rotas das notificações tocadas com o app já aberto.
  Stream<String> get taps;

  /// A aula de final começada e não concluída, com o título em [language].
  Future<PausedLesson?> pausedLesson(String language);
}

class LocalRemindersRepository implements RemindersRepository {
  const LocalRemindersRepository(
    this._service, {
    required this._progress,
    required this._lessons,
  });

  final NotificationService _service;
  final EndgameProgressRepository _progress;
  final EndgameLessonRepository _lessons;

  @override
  Future<void> start(List<NotificationChannelSpec> channels) =>
      _service.start(channels);

  @override
  Future<bool> permitted() => _service.permitted();

  @override
  Future<void> replace(List<ScheduledNotification> notifications) =>
      _service.replace(notifications);

  @override
  Future<String?> launchRoute() => _service.launchPayload();

  @override
  Stream<String> get taps => _service.taps;

  @override
  Future<PausedLesson?> pausedLesson(String language) async {
    final progress = await _progress.load();
    final ongoing = progress.ongoing;
    if (ongoing == null) return null;
    final lesson = (await _lessons.trail()).lesson(ongoing.lessonId);
    if (lesson == null || progress.of(lesson.id).lessonDone) return null;
    final parts = lesson.lesson.parts;
    final checkpoint = EndgameLessonRules.migrate(lesson, ongoing);
    final part = parts.isEmpty || checkpoint?.part == null
        ? null
        : lesson.lesson.part(checkpoint!.part!);
    final texts = await _lessons.texts(language);
    return PausedLesson(
      lessonId: lesson.id,
      title: texts.lessonTitle(lesson.id),
      chapter: part == null ? 1 : parts.indexOf(part) + 1,
      total: parts.isEmpty ? 1 : parts.length,
      partId: part?.id,
      stage: part == null ? 0 : checkpoint!.step,
    );
  }
}

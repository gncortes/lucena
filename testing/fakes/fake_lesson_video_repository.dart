import 'package:lucena/data/repositories/lesson_video/lesson_video_repository.dart';
import 'package:lucena/domain/models/lesson_video_progress.dart';

/// Progresso e ajustes da aula em vídeo em memória.
class FakeLessonVideoRepository implements LessonVideoRepository {
  FakeLessonVideoRepository({
    Map<String, VideoProgress>? progress,
    this.current = const VideoSettings(),
  }) : saved = progress ?? {};

  /// O progresso por `lição.parte.etapa`.
  final Map<String, VideoProgress> saved;
  VideoSettings current;

  static String keyOf(String lessonId, String partId, String stage) =>
      '$lessonId.$partId.$stage';

  @override
  Future<VideoProgress?> progress(
    String lessonId,
    String partId,
    String stage,
  ) async => saved[keyOf(lessonId, partId, stage)];

  @override
  Future<void> saveProgress(
    String lessonId,
    String partId,
    String stage,
    VideoProgress progress,
  ) async => saved[keyOf(lessonId, partId, stage)] = progress;

  @override
  Future<void> clearProgress(
    String lessonId,
    String partId,
    String stage,
  ) async => saved.remove(keyOf(lessonId, partId, stage));

  @override
  Future<VideoSettings> settings() async => current;

  @override
  Future<void> saveSettings(VideoSettings settings) async => current = settings;
}

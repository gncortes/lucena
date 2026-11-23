import '../../../domain/models/lesson_video_progress.dart';

/// O ponto em que o aluno parou em cada aula em vídeo e os ajustes do
/// player. A aula em si não vem daqui: o view model a monta com o
/// `LessonScriptRepository` e o `LessonVideoConverter`.
///
/// O progresso é por etapa ([stage]: `ideia` ou `demos`), porque cada etapa
/// toca como um vídeo próprio.
abstract interface class LessonVideoRepository {
  /// Onde o aluno parou; nulo se nunca abriu ou se o salvo não se lê.
  Future<VideoProgress?> progress(String lessonId, String partId, String stage);

  Future<void> saveProgress(
    String lessonId,
    String partId,
    String stage,
    VideoProgress progress,
  );

  /// Esquece onde parou (rever do começo, etapa concluída).
  Future<void> clearProgress(String lessonId, String partId, String stage);

  /// Os ajustes; os padrões se nunca mudaram ou se o salvo não se lê.
  Future<VideoSettings> settings();

  Future<void> saveSettings(VideoSettings settings);
}

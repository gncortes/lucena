import 'dart:convert';

import '../../../domain/models/lesson_video_progress.dart';
import '../../services/preferences_service.dart';
import 'lesson_video_repository.dart';

/// Guarda o progresso e os ajustes da aula em vídeo nas preferências, em JSON.
class LocalLessonVideoRepository implements LessonVideoRepository {
  const LocalLessonVideoRepository(this._preferences);

  final PreferencesService _preferences;

  static const settingsKey = 'lessonVideo.settings';

  static String progressKeyOf(String lessonId, String partId, String stage) =>
      'lessonVideo.$lessonId.$partId.$stage';

  @override
  Future<VideoProgress?> progress(
    String lessonId,
    String partId,
    String stage,
  ) async {
    final raw = await _preferences.getString(
      progressKeyOf(lessonId, partId, stage),
    );
    if (raw == null) return null;
    try {
      return VideoProgress.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } on Object {
      return null;
    }
  }

  @override
  Future<void> saveProgress(
    String lessonId,
    String partId,
    String stage,
    VideoProgress progress,
  ) => _preferences.setString(
    progressKeyOf(lessonId, partId, stage),
    jsonEncode(progress.toJson()),
  );

  @override
  Future<void> clearProgress(String lessonId, String partId, String stage) =>
      _preferences.remove(progressKeyOf(lessonId, partId, stage));

  @override
  Future<VideoSettings> settings() async {
    final raw = await _preferences.getString(settingsKey);
    if (raw == null) return const VideoSettings();
    try {
      return VideoSettings.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } on Object {
      return const VideoSettings();
    }
  }

  @override
  Future<void> saveSettings(VideoSettings settings) =>
      _preferences.setString(settingsKey, jsonEncode(settings.toJson()));
}

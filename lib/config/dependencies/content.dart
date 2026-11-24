import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../../data/repositories/endgames/endgame_lesson_repository_asset.dart';
import '../../data/repositories/lesson_voice/lesson_voice_repository.dart';
import '../../data/repositories/lesson_voice/lesson_voice_repository_downloaded.dart';
import '../../data/repositories/endgames/visible_endgame_lesson_repository.dart';
import '../../data/repositories/positions/positions_repository_asset.dart';
import '../../data/repositories/school/lesson_repository_asset.dart';
import '../../data/repositories/training/training_school_content.dart';
import '../../data/services/lesson_content_service.dart';
import '../../data/services/lesson_package_service.dart';
import '../../data/services/voice_pack_service.dart';
import '../build_flags.dart';
import 'core.dart';

/// O conteúdo das aulas (no APK ou baixado em pacotes) e as posições.
class ContentDependencies {
  ContentDependencies._({
    required this.source,
    required this.packages,
    required this.lessonContent,
    required this.positions,
    required this.lessons,
    required this.trainingSchoolContent,
    required this.endgameLessons,
    required this.lessonVoice,
  });

  factory ContentDependencies.create(CoreDependencies core) {
    final source = createLessonContentAssets(
      releaseBuild: kReleaseMode,
      firebase: core.firebase,
      localUrl: const String.fromEnvironment('CONTENT_URL'),
      publishedRelease: const String.fromEnvironment('CONTENT_RELEASE'),
    );
    final packages = source.reader == null
        ? null
        : LessonPackageService(
            source: source.reader!,
            directory: getApplicationSupportDirectory,
            identity: core.uid,
          );
    final lessonContent = packages == null
        ? source
        : LessonContentAssets(reader: packages);
    final lessons = AssetLessonRepository(lessonContent);
    // A voz dos capítulos vem da mesma versão publicada do conteúdo.
    const release = String.fromEnvironment('CONTENT_RELEASE');
    final lessonVoice = DownloadedLessonVoiceRepository(
      core.firebase && release.isNotEmpty
          ? VoicePackService(
              release: release,
              download: firebaseLessonObjectDownload,
              directory: getApplicationSupportDirectory,
            )
          : null,
      core.preferences,
      language: () async => (await core.settings.load()).languageCode ?? 'pt',
    );
    return ContentDependencies._(
      source: source,
      packages: packages,
      lessonContent: lessonContent,
      positions: AssetPositionsRepository(core.assets),
      lessons: lessons,
      trainingSchoolContent: TrainingSchoolContent(
        lessons,
        includeAll: kDebugMode || isE2E,
      ),
      // Só as aulas liberadas (VisibleLessons); as falas comuns vêm todas.
      endgameLessons: VisibleEndgameLessonRepository(
        AssetEndgameLessonRepository(lessonContent, school: lessons),
      ),
      lessonVoice: lessonVoice,
    );
  }

  /// O índice dos pacotes publicados no Firestore (vazio: sem índice).
  static const packageIndexPath = String.fromEnvironment(
    'CONTENT_PACKAGE_INDEX',
  );

  /// De onde vem o conteúdo: o APK, um servidor local ou a versão publicada.
  final LessonContentAssets source;

  /// Os pacotes baixados; nenhum quando o conteúdo vem só do APK.
  final LessonPackageService? packages;
  final LessonContentAssets lessonContent;
  final AssetPositionsRepository positions;
  final AssetLessonRepository lessons;
  final TrainingSchoolContent trainingSchoolContent;
  final VisibleEndgameLessonRepository endgameLessons;

  /// A voz gravada dos capítulos da aula em vídeo e a preferência de voz.
  final LessonVoiceRepository lessonVoice;
}

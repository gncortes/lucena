import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../../data/repositories/endgames/endgame_lesson_repository_asset.dart';
import '../../data/repositories/endgames/visible_endgame_lesson_repository.dart';
import '../../data/repositories/positions/positions_repository_asset.dart';
import '../../data/repositories/school/lesson_repository_asset.dart';
import '../../data/repositories/training/training_school_content.dart';
import '../../data/services/lesson_content_service.dart';
import '../../data/services/lesson_package_service.dart';
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
}

import '../../data/repositories/training/course_access_training_repository.dart'
    as course_training;
import '../../data/repositories/training/course_download_repository.dart';
import '../../data/repositories/training/course_training_repository.dart'
    as course_training;
import '../../data/repositories/training/course_training_repository_local.dart'
    as course_training;
import '../../data/repositories/training/observed_training_repository.dart';
import '../../data/repositories/training/school_training_observation_source.dart';
import '../../data/repositories/training/school_training_observer.dart';
import '../../data/repositories/training/training_endgame_content.dart';
import '../../data/repositories/training/training_learning_bridge.dart';
import '../../data/services/lesson_content_service.dart';
import '../../data/services/lesson_package_index.dart';
import '../../domain/models/training/school_training_resources.dart';
import '../../domain/models/training/training_course_config.dart';
import '../../domain/use_cases/training/training_analytics.dart';
import '../build_flags.dart';
import 'content.dart';
import 'core.dart';
import 'progress.dart';
import 'store.dart';

/// Os cursos com treino do dia (Pilares e Escola) e o download deles.
class TrainingDependencies {
  TrainingDependencies._({
    required this.analytics,
    required this.courseTraining,
    required this.learningBridge,
    required this.courseDownloads,
    required this.endgameContent,
  });

  /// Sem [trainingInstallSeed], o treino não grava nada.
  factory TrainingDependencies.create(
    CoreDependencies core,
    ContentDependencies content,
    ProgressDependencies progress,
    StoreDependencies store, {
    String? trainingInstallSeed,
  }) {
    final now = core.now;
    final lessonContent = content.lessonContent;
    late final course_training.TrainingRepository storage;
    final analytics = TrainingAnalytics(
      now: now,
      log: core.analytics.log,
      read: (course) => storage.load(course),
      write: (course, change) => storage.update(course, change),
    );
    storage = trainingInstallSeed == null
        ? const course_training.NoTrainingRepository()
        : course_training.TrainingRepositoryLocal(
            core.preferences,
            lessonContent,
            installSeed: trainingInstallSeed,
            onSaved: analytics.onSaved,
            configs: {
              for (final config in TrainingCourseConfig.all)
                config.course: config,
            },
            contentSources: {
              TrainingCourseConfig.escola.indexSource: () async {
                final school = content.trainingSchoolContent;
                return schoolTrainingResources(
                  await school.course(),
                  await school.texts('pt'),
                );
              },
            },
          );
    final schoolObservations = SchoolTrainingObservationSource(
      now: now,
      stars: progress.stars,
      progress: progress.progress,
      speedruns: progress.speedruns,
      journey: progress.journey,
    );
    final courseTraining = ObservedTrainingRepository(
      // A meta do dia só oferece o que o acesso abre (demo: Capítulo 1).
      course_training.CourseAccessTrainingRepository(
        storage,
        store.courseAccess,
      ),
      observers: {
        TrainingCourseConfig.escola.course: SchoolTrainingObserver(
          now: now,
          source: schoolObservations,
          analytics: analytics,
        ).call,
      },
    );
    return TrainingDependencies._(
      analytics: analytics,
      courseTraining: courseTraining,
      learningBridge: TrainingLearningBridge(
        courseTraining,
        courses: TrainingCourseConfig.all,
        activity: progress.activity,
      ),
      courseDownloads: CourseDownloadRepository(
        content.packages,
        openingProfile: () async =>
            (await courseTraining.load(TrainingCourseConfig.pilares.course))
                .openingProfile,
        indexSource:
            core.firebase &&
                content.source.reader is PublishedLessonContentReader &&
                ContentDependencies.packageIndexPath.isNotEmpty
            ? LessonPackageIndexSource.firestore(
                ContentDependencies.packageIndexPath,
              )
            : null,
      ),
      endgameContent: showsDevTools
          ? TrainingEndgameContent.fromConfigs(
              lessonContent,
              school: content.lessons,
              configs: activeTrainingCourses,
            )
          : null,
    );
  }

  final TrainingAnalytics analytics;
  final ObservedTrainingRepository courseTraining;

  /// Leva a unidade terminada na aula ao treino do dia.
  final TrainingLearningBridge learningBridge;
  final CourseDownloadRepository courseDownloads;
  final TrainingEndgameContent? endgameContent;
}

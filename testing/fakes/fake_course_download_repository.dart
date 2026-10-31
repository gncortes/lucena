import 'package:lucena/data/repositories/training/course_download_repository.dart';
import 'package:lucena/domain/models/training/training_course_config.dart';

/// A preinstalled test course. Entry/auth behavior has its own dedicated tests.
class FakeCourseDownloadRepository extends CourseDownloadRepository {
  const FakeCourseDownloadRepository() : super.unconfigured();
  @override
  Future<bool> isDownloaded(
    TrainingCourseConfig config, {
    String? chapterId,
  }) async => true;
  @override
  Future<void> prepare(
    TrainingCourseConfig config, {
    String? chapterId,
  }) async {}
}

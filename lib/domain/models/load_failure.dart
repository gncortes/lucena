import 'lesson_content.dart';

/// The cause safe to describe to a user; never contains exception messages.
enum LoadFailure {
  generic,
  offline,
  noSpace,
  unavailable,
  notFound,
  engine;

  static LoadFailure of(Object error) => switch (error) {
    LessonContentNetworkUnavailable() => offline,
    LessonContentStorageUnavailable() => noSpace,
    LessonContentUnavailable() => unavailable,
    _ => generic,
  };
}

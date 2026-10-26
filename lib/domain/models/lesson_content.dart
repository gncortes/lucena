/// No authorized, published or locally configured lesson file is available.
class LessonContentUnavailable implements Exception {
  const LessonContentUnavailable();
}

/// An optional path does not exist in this source/release. Unlike a transient
/// transport failure, parsers may legitimately omit this optional file.
class LessonContentNotFound extends LessonContentUnavailable {
  const LessonContentNotFound();
}

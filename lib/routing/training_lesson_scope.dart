import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/repositories/endgames/endgame_lesson_repository.dart';
import '../data/repositories/training/training_endgame_content.dart';
import '../ui/course_entry/widgets/course_content_session.dart';

TrainingEndgameContent? _privateContent(BuildContext context) {
  try {
    return context.read<TrainingEndgameContent?>();
  } on ProviderNotFoundException {
    return null;
  }
}

EndgameLessonRepository trainingLessonRepository(
  BuildContext context,
  String? lessonId,
) =>
    _privateContent(context)?.forId(lessonId) ??
    context.read<EndgameLessonRepository>();

/// An unconfigured index has no private tests; do not read another course's trail.
EndgameLessonRepository? trainingTestRepository(
  BuildContext context,
  String index,
) {
  final private = _privateContent(context);
  return private == null
      ? context.read<EndgameLessonRepository>()
      : private.forIndex(index);
}

Widget scopeTrainingLesson(
  BuildContext context,
  String? lessonId,
  WidgetBuilder builder,
) {
  final private = _privateContent(context)?.forId(lessonId);
  if (private == null) {
    final child = builder(context);
    return lessonId == null ? child : CourseContentSession(child: child);
  }
  return CourseContentSession(
    child: RepositoryProvider<EndgameLessonRepository>.value(
      value: private,
      child: Builder(builder: builder),
    ),
  );
}

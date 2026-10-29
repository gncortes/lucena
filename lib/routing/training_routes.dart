import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../config/dependencies.dart';
import '../data/repositories/characters/character_repository.dart';
import '../data/repositories/endgames/endgame_lesson_repository.dart';
import '../data/repositories/endgames/endgame_progress_repository.dart';
import '../data/repositories/training/course_training_repository.dart';
import '../data/repositories/training/training_history_source.dart';
import '../domain/models/training/training_content.dart';
import '../domain/models/training/training_course.dart';
import '../domain/models/training/training_course_config.dart';
import '../domain/use_cases/now.dart';
import '../ui/core/widgets/reload_on_return.dart';
import '../ui/course_guide/view_models/course_guide_cubit.dart';
import '../ui/course_guide/widgets/course_chapter_screen.dart';
import '../ui/course_guide/widgets/course_guide_screen.dart';
import 'routes.dart';

GoRoute trainingRoute() => GoRoute(
  path: '/training/:course',
  redirect: (context, state) =>
      activeTrainingCourses.any(
        (config) => config.course.name == state.pathParameters['course'],
      )
      ? null
      : Routes.settings,
  builder: (context, state) => _guide(context, state, const _Guide()),
  routes: [
    GoRoute(
      path: 'chapter/:chapter',
      builder: (context, state) => _guide(
        context,
        state,
        Builder(
          builder: (context) => ReloadOnReturn(
            onReturn: () => context.read<CourseGuideCubit>().load(),
            child: CourseChapterScreen(
              chapter: state.pathParameters['chapter']!,
              onBack: () => _back(context),
              onLesson: (lesson) => _lesson(context, lesson),
            ),
          ),
        ),
      ),
    ),
  ],
);

Widget _guide(BuildContext context, GoRouterState state, Widget child) {
  final config = activeTrainingCourses.firstWhere(
    (config) => config.course.name == state.pathParameters['course'],
    orElse: () => TrainingCourseConfig.pilares,
  );
  return BlocProvider(
    create: (context) => CourseGuideCubit(
      repository: context.read<TrainingRepository>(),
      config: config,
      now: context.read<Now>(),
      characters: context.read<CharacterRepository>(),
      testLessons: context.read<EndgameLessonRepository>(),
      testProgress: context.read<EndgameProgressRepository>(),
      beforeLoad: () => context.read<TrainingHistorySource>().bootstrap(config),
    )..load(),
    child: child,
  );
}

void _back(BuildContext context) => context.canPop()
    ? context.pop()
    : context.go(
        Routes.training(GoRouterState.of(context).pathParameters['course']!),
      );

void _lesson(BuildContext context, TrainingLesson lesson) => context.push(
  lesson.kind == TrainingLessonKind.test
      ? Routes.endgameExercisesIntro(lesson.id)
      : Routes.trainingLesson(lesson.id),
  extra: lesson,
);

class _Guide extends StatelessWidget {
  const _Guide();
  @override
  Widget build(BuildContext context) => ReloadOnReturn(
    onReturn: () => context.read<CourseGuideCubit>().load(),
    child: CourseGuideScreen(
      onLevelTest: () => context.push(Routes.placement),
      onBack: () =>
          context.canPop() ? context.pop() : context.go(Routes.settings),
      onPlan: () {},
      onHelp: () {},
      onWelcomeContinue: () {},
      onLesson: (lesson) => _lesson(context, lesson),
      onChapter: (chapter) => context.push(
        Routes.trainingChapter(
          context.read<CourseGuideCubit>().config.course.name,
          chapter,
        ),
      ),
      goalsBuilder: (_) => const SizedBox.shrink(),
      progressBuilder: (_) => const SizedBox.shrink(),
    ),
  );
}

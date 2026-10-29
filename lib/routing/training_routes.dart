import '../domain/models/character.dart';
import '../domain/models/training/day_goals.dart';
import '../ui/training_exercise/widgets/training_exercise_screen.dart';
import '../ui/core/l10n/l10n.dart';
import '../ui/course_guide/widgets/training_goals_tab.dart';
import '../data/repositories/push/push_repository.dart';
import '../ui/course_guide/view_models/training_plan_cubit.dart';
import '../ui/course_guide/widgets/training_plan_screen.dart';
import '../ui/reminders/view_models/reminders_cubit.dart';

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

TrainingCourseConfig _config(GoRouterState state) =>
    activeTrainingCourses.firstWhere(
      (config) => config.course.name == state.pathParameters['course'],
      orElse: () => TrainingCourseConfig.pilares,
    );

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
      path: 'exercise/:theme',
      builder: (context, state) => _ExerciseDestination(
        config: _config(state),
        theme: state.pathParameters['theme']!,
        goalKey: state.uri.queryParameters['goal'],
      ),
    ),
    GoRoute(
      path: 'plan',
      builder: (context, state) => BlocProvider(
        create: (_) => TrainingPlanCubit(
          repository: context.read<TrainingRepository>(),
          config: _config(state),
          now: context.read<Now>(),
          push: context.read<PushRepository>(),
          afterSave: (_) => context.read<RemindersCubit>().refresh(),
          beforeLoad: () =>
              context.read<TrainingHistorySource>().bootstrap(_config(state)),
        )..load(),
        child: TrainingPlanScreen(
          onBack: () => _back(context),
          onSaved: () => _back(context),
        ),
      ),
    ),
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
      onPlan: () => context.push(
        Routes.trainingPlan(
          context.read<CourseGuideCubit>().config.course.name,
        ),
      ),
      onHelp: () {},
      onWelcomeContinue: () => context.push(
        Routes.trainingPlan(
          context.read<CourseGuideCubit>().config.course.name,
        ),
      ),
      onLesson: (lesson) => _lesson(context, lesson),
      onChapter: (chapter) => context.push(
        Routes.trainingChapter(
          context.read<CourseGuideCubit>().config.course.name,
          chapter,
        ),
      ),
      goalsBuilder: (_) => TrainingGoalsTab(
        onPlan: () => context.push(
          Routes.trainingPlan(
            context.read<CourseGuideCubit>().config.course.name,
          ),
        ),
        onGoal: (goal) {
          if (goal.kind == GoalKind.lesson ||
              goal.kind == GoalKind.extraLesson ||
              goal.kind == GoalKind.redo) {
            final lesson = context
                .read<CourseGuideCubit>()
                .state
                .resources
                ?.lessons
                .where((l) => l.id == goal.ref)
                .firstOrNull;
            if (lesson != null) _lesson(context, lesson);
          } else if (goal.kind == GoalKind.exercise ||
              goal.kind == GoalKind.reinforce) {
            context.push(
              Uri.parse(
                Routes.trainingExercise(
                  context.read<CourseGuideCubit>().config.course.name,
                  goal.ref,
                ),
              ).replace(queryParameters: {'goal': goal.key}).toString(),
            );
          }
        },
      ),
      progressBuilder: (_) => const SizedBox.shrink(),
    ),
  );
}

class _ExerciseDestination extends StatefulWidget {
  const _ExerciseDestination({
    required this.config,
    required this.theme,
    this.goalKey,
  });
  final TrainingCourseConfig config;
  final String theme;
  final String? goalKey;
  @override
  State<_ExerciseDestination> createState() => _ExerciseDestinationState();
}

class _ExerciseDestinationState extends State<_ExerciseDestination> {
  bool _finishing = false;
  late Future<({TrainingGoal goal, String title, Character teacher})?> _data;
  @override
  void initState() {
    super.initState();
    _data = _load();
  }

  Future<({TrainingGoal goal, String title, Character teacher})?>
  _load() async {
    final repository = context.read<TrainingRepository>();
    final characters = context.read<CharacterRepository>();
    final saved = await repository.load(widget.config.course);
    final resources = await repository.resources(widget.config.course);
    final teachers = await characters.characters();
    final goal = saved.day?.goals
        .where(
          (g) =>
              (g.kind == GoalKind.exercise || g.kind == GoalKind.reinforce) &&
              g.ref == widget.theme &&
              (widget.goalKey == null ? !g.done : g.key == widget.goalKey),
        )
        .firstOrNull;
    final lesson = resources.lessons
        .where((l) => l.id == widget.theme)
        .firstOrNull;
    final teacher = teachers
        .where((c) => c.id == Character.masterId)
        .firstOrNull;
    if (goal == null || lesson == null || teacher == null) return null;
    return (goal: goal, title: lesson.title, teacher: teacher);
  }

  Future<void> _finish() async {
    if (_finishing) return;
    _finishing = true;
    final router = GoRouter.of(context);
    try {
      await context.read<TrainingRepository>().update(
        widget.config.course,
        (s) => s.copyWith(tab: CourseGuideTab.goals),
      );
      if (!mounted) return;
      if (router.canPop()) {
        router.pop();
      } else {
        router.go(Routes.training(widget.config.course.name));
      }
    } catch (_) {
      if (mounted) {
        _finishing = false;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.trainingExerciseSaveError)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder(
    future: _data,
    builder: (context, snapshot) {
      final data = snapshot.data;
      if (snapshot.connectionState != ConnectionState.done && data == null) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      if (snapshot.hasError || data == null) {
        return Scaffold(
          appBar: AppBar(),
          body: Center(
            child: TextButton(
              onPressed: () => setState(() => _data = _load()),
              child: Text(context.l10n.lessonRetry),
            ),
          ),
        );
      }
      return TrainingExerciseScreen(
        repository: context.read<TrainingRepository>(),
        config: widget.config,
        now: context.read<Now>(),
        goalKey: data.goal.key,
        title: data.title,
        teacher: data.teacher,
        onNextGoal: _finish,
        onRedoLesson: (id) => context.push(Routes.trainingLesson(id)),
      );
    },
  );
}

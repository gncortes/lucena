import 'training_lesson_scope.dart';

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../config/dependencies.dart';
import '../data/repositories/characters/character_repository.dart';
import '../data/repositories/endgames/endgame_progress_repository.dart';
import '../data/repositories/training/training_history_source.dart';
import '../data/repositories/push/push_repository.dart';
import '../data/repositories/training/course_training_repository.dart'
    as course_training;
import '../domain/models/training/day_goals.dart';
import '../domain/models/character.dart';
import '../domain/models/training/training_content.dart';
import '../domain/models/training/training_course.dart';
import '../domain/models/training/training_course_config.dart';
import '../domain/use_cases/now.dart';
import '../ui/core/widgets/reload_on_return.dart';
import '../ui/core/l10n/l10n.dart';
import '../ui/core/theme/app_motion.dart';
import '../ui/course_guide/view_models/course_guide_cubit.dart';
import '../ui/course_guide/view_models/training_plan_cubit.dart';
import '../ui/course_guide/widgets/course_chapter_screen.dart';
import '../ui/course_guide/widgets/course_guide_screen.dart';
import '../ui/course_guide/widgets/training_goals_tab.dart';
import '../ui/course_guide/widgets/training_plan_screen.dart';
import '../ui/course_guide/widgets/training_progress_tab.dart';
import '../ui/reminders/view_models/reminders_cubit.dart';
import '../ui/training_exercise/widgets/training_exercise_screen.dart';
import '../ui/training_opening/widgets/training_openings_screen.dart';
import '../ui/training_opening/widgets/training_opening_screen.dart';
import '../ui/training_progress/widgets/training_theme_screen.dart';
import '../ui/training_help/widgets/training_help_screen.dart';
import '../ui/training_help/widgets/training_tour.dart';
import 'routes.dart';
import 'training_launch.dart';
import 'training_goal_destination.dart';

TrainingCourseConfig _config(GoRouterState state) =>
    TrainingCourseConfig.fromName(state.pathParameters['course']!)!;

/// Both variants share this route tree and all guide screens.
GoRoute trainingRoute() => GoRoute(
  path: '/training/:course',
  redirect: (context, state) =>
      activeTrainingCourses.any(
        (c) => c.course.name == state.pathParameters['course'],
      )
      ? null
      : Routes.settings,
  builder: (context, state) => _guide(const _Guide(), config: _config(state)),
  routes: [
    GoRoute(
      path: 'help',
      builder: (context, state) => TrainingHelpScreen(
        onBack: () => _back(context),
        onTour: () => context.push(
          '${Routes.training(_config(state).course.name)}/tour?help=1',
        ),
      ),
    ),
    GoRoute(
      path: 'tour',
      builder: (context, state) => _guide(
        _Guide(tour: true, fromHelp: state.uri.queryParameters['help'] == '1'),
        config: _config(state),
      ),
    ),
    GoRoute(
      path: 'theme/:theme',
      builder: (context, state) => _guide(
        _Guide(theme: state.pathParameters['theme']),
        config: _config(state),
      ),
    ),
    GoRoute(
      path: 'openings',
      builder: (context, state) => _guide(
        const _Guide(openings: true),
        config: _config(state),
        initialTab: CourseGuideTab.goals,
      ),
    ),
    GoRoute(
      path: 'opening/:theme',
      pageBuilder: (context, state) => _destinationPage(
        context,
        state,
        _ExerciseDestination(
          config: _config(state),
          theme: state.pathParameters['theme']!,
          opening: true,
          fromList:
              state.uri.queryParameters['list'] == '1' ||
              state.uri.queryParameters['home'] == '1',
          launch: state.extra is TrainingLaunch
              ? state.extra as TrainingLaunch
              : null,
        ),
      ),
    ),
    GoRoute(
      path: 'exercise/:theme',
      pageBuilder: (context, state) => _destinationPage(
        context,
        state,
        _ExerciseDestination(
          config: _config(state),
          theme: state.pathParameters['theme']!,
          goalKey: state.uri.queryParameters['goal'],
          launch: state.extra is TrainingLaunch
              ? state.extra as TrainingLaunch
              : null,
        ),
      ),
    ),
    GoRoute(
      path: 'plan',
      builder: (context, state) => BlocProvider(
        create: (_) => TrainingPlanCubit(
          repository: context.read<course_training.TrainingRepository>(),
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
        config: _config(state),
      ),
    ),
  ],
);

Widget _guide(
  Widget child, {
  required TrainingCourseConfig config,
  CourseGuideTab? initialTab,
}) => BlocProvider(
  create: (context) {
    final cubit = CourseGuideCubit(
      repository: context.read<course_training.TrainingRepository>(),
      characters: context.read<CharacterRepository>(),
      testLessons: trainingTestRepository(context, config.indexSource),
      testProgress: context.read<EndgameProgressRepository>(),
      beforeLoad: () async {
        final history = context.read<TrainingHistorySource>();
        final repository = context.read<course_training.TrainingRepository>();
        await history.bootstrap(config);
        if (initialTab != null) {
          await repository.update(
            config.course,
            (s) => s.copyWith(tab: initialTab),
          );
        }
      },
      config: config,
      now: context.read<Now>(),
    );
    unawaited(cubit.load());
    return cubit;
  },
  child: child,
);

void _back(BuildContext context) {
  if (context.canPop()) {
    context.pop();
  } else {
    context.go(
      Routes.training(GoRouterState.of(context).pathParameters['course']!),
    );
  }
}

Future<void> _closeOpenings(BuildContext context) async {
  final saved = await context.read<CourseGuideCubit>().selectTab(
    CourseGuideTab.goals,
  );
  if (saved && context.mounted) _back(context);
}

void _lesson(
  BuildContext context,
  TrainingLesson lesson, {
  String origin = 'treino_guia',
}) => context.push(
  trainingLessonDestination(lesson, origin: origin),
  extra: lesson,
);

class _Guide extends StatelessWidget {
  const _Guide({
    this.theme,
    this.tour = false,
    this.fromHelp = false,
    this.openings = false,
  });
  final String? theme;
  final bool tour, fromHelp, openings;
  @override
  Widget build(BuildContext context) {
    final course = context.read<CourseGuideCubit>().config.course.name;
    void plan() => context.push(Routes.trainingPlan(course));
    Future<void> goal(TrainingGoal goal) async {
      final challenge = trainingChallengeDestination(goal, course: course);
      if (challenge != null) {
        await context.push(challenge);
        return;
      }
      if ([
        GoalKind.lesson,
        GoalKind.extraLesson,
        GoalKind.redo,
      ].contains(goal.kind)) {
        final lesson = context
            .read<CourseGuideCubit>()
            .state
            .resources
            ?.lessons
            .where((l) => l.id == goal.ref)
            .firstOrNull;
        if (lesson != null) _lesson(context, lesson, origin: 'treino_metas');
      }
      if (goal.kind == GoalKind.exercise || goal.kind == GoalKind.reinforce) {
        context.push(
          Uri.parse(Routes.trainingExercise(course, goal.ref))
              .replace(queryParameters: {'goal': goal.key})
              .toString(),
        );
      }
      if (goal.kind == GoalKind.openings) {
        context.push('${Routes.training(course)}/openings');
      }
    }

    final guide = ReloadOnReturn(
      onReturn: () async {
        final cubit = context.read<CourseGuideCubit>();
        await cubit.load();
      },
      child: CourseGuideScreen(
        centerTitle: theme != null,
        showHeaderActions: theme == null,
        onLevelTest: () => context.push(Routes.placement),
        onBack: openings
            ? () => _closeOpenings(context)
            : () => context.canPop()
                  ? context.pop()
                  : context.go(Routes.settings),
        onPlan: plan,
        onWelcomeContinue: plan,
        onHelp: () => context.push('${Routes.training(course)}/help'),
        onLesson: (lesson) => _lesson(context, lesson),
        onChapter: (chapter) =>
            context.push(Routes.trainingChapter(course, chapter)),
        goalsBuilder: (_) => TrainingGoalsTab(onGoal: goal, onPlan: plan),
        progressBuilder: (_) => TrainingProgressTab(
          testScores: context.read<CourseGuideCubit>().state.testScores,
          testProgress: context.read<CourseGuideCubit>().state.testProgress,
          onTest: (id) => context.push(Routes.endgameExercisesIntro(id)),
          onLevelTest: () => context.push(Routes.placement),
          onTheme: (id) => context.push(Routes.trainingTheme(course, id)),
        ),
        bodyOverride: openings
            ? TrainingOpeningsScreen(
                repository: context.read<course_training.TrainingRepository>(),
                config: context.read<CourseGuideCubit>().config,
                now: context.read<Now>(),
                embedded: true,
                onTrain: (id) => context.push(
                  '${Routes.trainingOpening(course, id)}?list=1',
                ),
              )
            : theme == null
            ? null
            : TrainingThemeScreen(
                lessonId: theme!,
                onBack: () => _back(context),
                embedded: true,
              ),
        titleOverride: openings
            ? context.l10n.trainingOpeningsTitle
            : theme == null
            ? null
            : context.l10n.trainingThemeTitle,
        onTabChanged: openings || theme != null ? (_) => _back(context) : null,
      ),
    );
    if (!tour) return guide;
    return TrainingTour(
      child: guide,
      onTab: (tab) => context.read<CourseGuideCubit>().selectTab(tab),
      onClose: () {
        final router = GoRouter.of(context);
        if (router.canPop()) {
          router.pop();
          if (fromHelp && router.canPop()) router.pop();
        } else {
          router.go(Routes.training(course));
        }
      },
    );
  }
}

class _ExerciseDestination extends StatefulWidget {
  const _ExerciseDestination({
    required this.config,
    required this.theme,
    this.goalKey,
    this.opening = false,
    this.fromList = false,
    this.launch,
  });
  final String theme;
  final TrainingCourseConfig config;
  final String? goalKey;
  final bool opening, fromList;
  final TrainingLaunch? launch;
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
    final repository = context.read<course_training.TrainingRepository>();
    final characterRepository = context.read<CharacterRepository>();
    final config = widget.config;
    final state = await repository.load(config.course);
    final resources = await repository.resources(config.course);
    final characters = await characterRepository.characters();
    final goal = state.day?.goals
        .where(
          (g) => widget.opening
              ? g.kind == GoalKind.openings && g.items.containsKey(widget.theme)
              : (g.kind == GoalKind.exercise || g.kind == GoalKind.reinforce) &&
                    g.ref == widget.theme &&
                    (widget.goalKey == null
                        ? !g.done
                        : g.key == widget.goalKey),
        )
        .firstOrNull;
    final lesson = resources.lessons
        .where((l) => l.id == widget.theme)
        .firstOrNull;
    final teacher = characters
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
      await context.read<course_training.TrainingRepository>().update(
        widget.config.course,
        (s) => s.copyWith(tab: CourseGuideTab.goals),
      );
      if (!mounted) return;
      if (router.canPop()) {
        router.pop();
        if (widget.fromList && router.canPop()) router.pop();
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
    initialData: _previewData,
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
      if (widget.opening) {
        return TrainingOpeningScreen(
          repository: context.read<course_training.TrainingRepository>(),
          config: widget.config,
          now: context.read<Now>(),
          lessonId: widget.theme,
          teacher: data.teacher,
          onNextGoal: _finish,
          preview: widget.launch?.openingPreview,
          homeHero: widget.launch?.openingPreview != null,
        );
      }
      return TrainingExerciseScreen(
        repository: context.read<course_training.TrainingRepository>(),
        config: widget.config,
        now: context.read<Now>(),
        goalKey: data.goal.key,
        title: data.title,
        teacher: data.teacher,
        onNextGoal: _finish,
        onRedoLesson: (id) => context.push(Routes.trainingLesson(id)),
        preview: widget.launch?.exercisePreview,
        homeHero: widget.launch?.exercisePreview != null,
      );
    },
  );

  ({TrainingGoal goal, String title, Character teacher})? get _previewData {
    final launch = widget.launch;
    final goal = launch?.exercisePreview?.goal ?? launch?.openingPreview?.goal;
    return launch == null || goal == null
        ? null
        : (goal: goal, title: launch.title, teacher: launch.teacher);
  }
}

Page<void> _destinationPage(
  BuildContext context,
  GoRouterState state,
  Widget child,
) {
  if (state.extra is! TrainingLaunch) {
    return MaterialPage<void>(key: state.pageKey, child: child);
  }
  final duration = AppMotion.of(context).screen;
  return CustomTransitionPage<void>(
    key: state.pageKey,
    transitionDuration: duration,
    reverseTransitionDuration: duration,
    transitionsBuilder: (context, animation, secondaryAnimation, child) =>
        FadeTransition(
          opacity: animation.drive(CurveTween(curve: AppMotion.enter)),
          child: child,
        ),
    child: child,
  );
}

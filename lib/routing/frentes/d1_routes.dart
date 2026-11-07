import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../data/repositories/characters/character_repository.dart';
import '../../data/repositories/diagnostics/failure_report_repository.dart';
import '../../data/repositories/lesson_ad/course_access_repository.dart';
import '../../data/repositories/lesson_ad/demo_ad_repository.dart';
import '../../data/repositories/training/course_training_repository.dart';
import '../../data/repositories/training/demo_offer_repository.dart';
import '../../domain/models/character.dart';
import '../../domain/models/course_access.dart';
import '../../domain/use_cases/now.dart';
import '../../domain/models/survey.dart';
import '../../domain/models/training/lesson_end.dart';
import '../../domain/models/training/training_course.dart';
import '../../domain/models/training/training_state.dart';
import '../../domain/use_cases/training/goal/goal_dates.dart';
import '../../domain/use_cases/training/goal/goal_view.dart';
import '../../domain/use_cases/training/lesson_end_steps.dart';
import '../../ui/core/l10n/l10n.dart';
import '../../ui/lesson_end/view_models/demo_offer_cubit.dart';
import '../../ui/lesson_end/widgets/day_goal_screen.dart';
import '../../ui/lesson_end/widgets/demo_offer_screen.dart';
import '../../ui/core/widgets/load_skeleton.dart';
import '../../ui/lesson_end/widgets/course_completed_screen.dart';
import '../../ui/lesson_end/widgets/lesson_soon_screen.dart';
import '../../ui/lesson_end/widgets/week_review_screen.dart';
import '../../ui/feedback/widgets/feedback_sent_screen.dart';
import '../../ui/lesson_ad/view_models/lesson_ad_cubit.dart';
import '../../ui/lesson_ad/widgets/lesson_ad_screen.dart';
import '../../ui/lesson_ad/widgets/lesson_entry.dart';
import '../../ui/survey/view_models/viktor_thanks_cubit.dart';
import '../../ui/survey/widgets/survey_thanks_screen.dart';
import '../route_names.dart';
import '../routes.dart';
import '../router.dart';

/// Telas novas da frente D1 (Lição + Opinião, T85). A frente registra as rotas na
/// lista [d1Routes] com `appRoute(name: RouteNames.x, path: D1Paths.x, ...)`,
/// do `router.dart`, e navega por nome. Só esta frente mexe neste arquivo.
abstract final class D1Paths {
  /// Revisão da semana / Dia do torneio (H-LIC-45).
  static const trainingReview = '/training/:course/review/:week';

  /// Curso concluído, o diploma (H-LIC-46).
  static const trainingCompleted = '/training/:course/completed';

  /// Meta do dia cumprida, no fim do último exercício do dia (H-LIC-50).
  static const trainingDayGoal = '/training/:course/day-goal';

  /// Oferta da demonstração no fim da lição (H-LIC-51).
  static const trainingDemoOffer = '/training/:course/demo-offer';

  /// Anúncio da demonstração em tela cheia (H-LIC-47).
  static const lessonAd = '/lesson/ad';

  /// Lição em breve, com X (H-LIC-48).
  static const lessonSoon = '/lesson/soon';

  /// Obrigado da pesquisa (H-OPI-09).
  static const surveyThanks = '/survey/:kind/thanks';

  /// Feedback enviado (H-OPI-12).
  static const feedbackSent = '/settings/feedback/sent';
}

/// A meta do dia e se o botão "Fazer o teste agora" aparece.
typedef DayGoalArgs = ({DayGoalSummary summary, bool canTest});

/// O resultado da lição que a oferta mostra.
typedef DemoOfferArgs = ({DemoOfferFacts facts, String title});

/// O que vem depois do último exercício, antes de voltar ao Treino
/// (H-LIC-50/51): a meta do dia, se foi cumprida, e a oferta da demonstração,
/// se o [DemoOfferCubit] deixar. Devolve aonde ir depois de voltar ao Treino
/// (o teste do capítulo ou a oferta do Pilares) ou nulo para ficar no Treino.
Future<String?> showLessonEndSteps(
  BuildContext context, {
  required TrainingCourse course,
  required TrainingState saved,
  required String lessonId,
  required String lessonTitle,
}) async {
  // Falha aqui não pode virar "não foi possível salvar": o treino já gravou.
  try {
    return await _lessonEndSteps(
      context,
      course: course,
      saved: saved,
      lessonId: lessonId,
      lessonTitle: lessonTitle,
    );
  } on Object catch (error, stack) {
    reportHandledError(error, stack);
    return null;
  }
}

Future<String?> _lessonEndSteps(
  BuildContext context, {
  required TrainingCourse course,
  required TrainingState saved,
  required String lessonId,
  required String lessonTitle,
}) async {
  final router = GoRouter.of(context);
  final l = context.l10n;
  final now = context.read<Now>();
  final training = context.read<TrainingRepository>();
  final access = context.read<CourseAccessRepository>().access;
  final offers = context.read<DemoOfferRepository>();
  final resources = await training.resources(course);
  final today = trainingGoalToday(now());
  final pathParameters = {'course': course.name};
  String? next;
  final summary = dayGoalSummary(
    saved,
    resources,
    today,
    chapterLabel: (n, title) => l.trainingProgressChapterTitle(n, title),
  );
  final testId = GoalView.of(saved, resources, today).current?.testId;
  if (summary != null) {
    final canTest = summary.testPending && testId != null;
    final test = await router.pushNamed<bool>(
      RouteNames.trainingDayGoal,
      pathParameters: pathParameters,
      extra: (summary: summary, canTest: canTest),
    );
    if (test == true && canTest) next = Routes.endgameExercisesIntro(testId);
  }
  final facts = demoOfferFacts(saved, resources, lessonId);
  if (facts == null || access != CourseAccess.demo) return next;
  final cubit = DemoOfferCubit(
    course: course,
    repository: offers,
    demo: true,
    now: now,
  );
  await cubit.decide();
  final show = cubit.state == true;
  await cubit.close();
  if (!show) return next;
  final buy = await router.pushNamed<bool>(
    RouteNames.trainingDemoOffer,
    pathParameters: pathParameters,
    extra: (facts: facts, title: lessonTitle),
  );
  return buy == true
      ? router.namedLocation(
          RouteNames.pilaresOffer,
          queryParameters: const {'origem': 'fim_demo'},
        )
      : next;
}

/// Carrega o Viktor e só então monta a tela (esqueleto enquanto carrega).
Widget _withViktor(Widget Function(Character teacher) build) => BlocProvider(
  create: (context) =>
      ViktorThanksCubit(characters: context.read<CharacterRepository>())
        ..load(),
  child: BlocBuilder<ViktorThanksCubit, Character?>(
    builder: (context, teacher) =>
        teacher == null ? const LoadSkeletonScreen() : build(teacher),
  ),
);

String _courseHome(GoRouterState state) =>
    Routes.training(state.pathParameters['course'] ?? 'pilares');

final List<RouteBase> d1Routes = [
  // O anúncio só abre pela entrada da lição (extra); aberto sem ela
  // (link, fechar à força) volta ao início, sem lição aberta (H-LIC-10).
  appRoute(
    name: RouteNames.lessonAd,
    path: D1Paths.lessonAd,
    redirect: (context, state) =>
        state.extra is LessonAdArgs ? null : Routes.home,
    builder: (context, state) => BlocProvider(
      create: (_) => LessonAdCubit(
        ads: context.read<DemoAdRepository>(),
        now: context.read<Now>(),
      )..load(),
      child: LessonAdScreen(
        lessonTitle: (state.extra! as LessonAdArgs).lessonTitle,
      ),
    ),
  ),
  appRoute(
    name: RouteNames.trainingReview,
    path: D1Paths.trainingReview,
    // Sem os dados da semana (por exemplo, link solto), volta ao treino.
    redirect: (context, state) =>
        state.extra is WeekReview ? null : _courseHome(state),
    builder: (context, state) {
      final review = state.extra! as WeekReview;
      return _withViktor(
        (teacher) => WeekReviewScreen(
          review: review,
          teacher: teacher,
          onOpen: context.push<void>,
          onStart: () => context.push<void>(
            review.isTournamentDay
                ? review.warmups.first.path
                : review.items.first.path,
          ),
          onBack: () =>
              context.canPop() ? context.pop() : context.go(_courseHome(state)),
        ),
      );
    },
  ),
  appRoute(
    name: RouteNames.trainingDayGoal,
    path: D1Paths.trainingDayGoal,
    // Sem os dados do dia (link solto, fechar à força), volta ao treino.
    redirect: (context, state) =>
        state.extra is DayGoalArgs ? null : _courseHome(state),
    builder: (context, state) {
      final args = state.extra! as DayGoalArgs;
      return DayGoalScreen(
        summary: args.summary,
        onBack: () => context.canPop()
            ? context.pop(false)
            : context.go(_courseHome(state)),
        onTest: args.canTest ? () => context.pop(true) : null,
      );
    },
  ),
  appRoute(
    name: RouteNames.trainingDemoOffer,
    path: D1Paths.trainingDemoOffer,
    redirect: (context, state) =>
        state.extra is DemoOfferArgs ? null : _courseHome(state),
    builder: (context, state) {
      final args = state.extra! as DemoOfferArgs;
      return _withViktor(
        (teacher) => DemoOfferScreen(
          chapterNumber: args.facts.chapter,
          exerciseTitle: args.title,
          correct: args.facts.correct,
          total: args.facts.total,
          teacher: teacher,
          onSeeCourse: () => context.canPop()
              ? context.pop(true)
              : context.go(_courseHome(state)),
          onNotNow: () => context.canPop()
              ? context.pop(false)
              : context.go(_courseHome(state)),
        ),
      );
    },
  ),
  appRoute(
    name: RouteNames.trainingCompleted,
    path: D1Paths.trainingCompleted,
    redirect: (context, state) =>
        state.extra is CourseCompletion ? null : _courseHome(state),
    builder: (context, state) {
      final completion = state.extra! as CourseCompletion;
      return _withViktor(
        (teacher) => CourseCompletedScreen(
          completion: completion,
          teacher: teacher,
          onGoals: () => context.go(_courseHome(state)),
          onCatalog: () => context.go(Routes.catalog),
          onClose: () => context.go(_courseHome(state)),
        ),
      );
    },
  ),
  appRoute(
    name: RouteNames.lessonSoon,
    path: D1Paths.lessonSoon,
    builder: (context, state) => LessonSoonScreen(
      onBack: () => context.canPop() ? context.pop() : context.go(Routes.home),
    ),
  ),
  appRoute(
    name: RouteNames.surveyThanks,
    path: D1Paths.surveyThanks,
    redirect: (context, state) =>
        SurveyKind.byCode(state.pathParameters['kind'] ?? '') == null
        ? Routes.home
        : null,
    builder: (context, state) => BlocProvider(
      create: (_) =>
          ViktorThanksCubit(characters: context.read<CharacterRepository>())
            ..load(),
      child: SurveyThanksScreen(
        kind: SurveyKind.byCode(state.pathParameters['kind']!)!,
      ),
    ),
  ),
  appRoute(
    name: RouteNames.feedbackSent,
    path: D1Paths.feedbackSent,
    builder: (context, state) => BlocProvider(
      create: (_) =>
          ViktorThanksCubit(characters: context.read<CharacterRepository>())
            ..load(),
      child: const FeedbackSentScreen(),
    ),
  ),
];

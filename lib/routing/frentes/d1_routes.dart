import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../data/repositories/characters/character_repository.dart';
import '../../domain/models/character.dart';
import '../../domain/models/survey.dart';
import '../../domain/models/training/lesson_end.dart';
import '../../ui/core/widgets/load_skeleton.dart';
import '../../ui/lesson_end/widgets/course_completed_screen.dart';
import '../../ui/lesson_end/widgets/lesson_soon_screen.dart';
import '../../ui/lesson_end/widgets/week_review_screen.dart';
import '../../ui/feedback/widgets/feedback_sent_screen.dart';
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

  /// Anúncio da demonstração em tela cheia (H-LIC-47).
  static const lessonAd = '/lesson/ad';

  /// Lição em breve, com X (H-LIC-48).
  static const lessonSoon = '/lesson/soon';

  /// Obrigado da pesquisa (H-OPI-09).
  static const surveyThanks = '/survey/:kind/thanks';

  /// Feedback enviado (H-OPI-12).
  static const feedbackSent = '/settings/feedback/sent';
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

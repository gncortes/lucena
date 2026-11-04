import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../data/repositories/characters/character_repository.dart';
import '../../domain/models/survey.dart';
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

final List<RouteBase> d1Routes = [
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

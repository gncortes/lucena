import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../data/repositories/training/course_training_repository.dart';
import '../../domain/models/training/training_course_config.dart';
import '../../domain/use_cases/now.dart';
import '../../ui/core/analytics/analytics_context.dart';
import '../../ui/reminders/view_models/reminders_cubit.dart';
import '../../ui/training_goal/view_models/training_goal_cubit.dart';
import '../../ui/training_goal/widgets/training_diagnostic_screen.dart';
import '../../ui/training_goal/widgets/training_goal_screen.dart';
import '../../ui/training_goal/widgets/training_next_goal_screen.dart';
import '../../ui/training_goal/widgets/training_plan_presentation_screen.dart';
import '../../ui/training_goal/widgets/training_questionnaire_screen.dart';
import '../../ui/training_goal/widgets/training_register_screen.dart';
import '../../ui/training_goal/widgets/training_test_screen.dart';
import '../../ui/training_goal/widgets/training_tournaments_screen.dart';
import '../../ui/training_goal/widgets/training_week_screen.dart';
import '../route_names.dart';
import '../router.dart';
import '../routes.dart';
import 'd4_routes.dart';

TrainingCourseConfig _config(GoRouterState state) =>
    TrainingCourseConfig.fromName(state.pathParameters['course']!)!;

String _course(GoRouterState state) => state.pathParameters['course']!;

/// Um cubit do objetivo por tela: todo o estado vive no repositório.
Widget _goal(GoRouterState state, Widget child) => BlocProvider(
  create: (context) => TrainingGoalCubit(
    repository: context.read<TrainingRepository>(),
    config: _config(state),
    now: context.read<Now>(),
    analytics: context.analytics,
    afterSave: (_) => context.read<RemindersCubit>().refresh(),
  )..load(),
  child: child,
);

void _back(BuildContext context, GoRouterState state) {
  if (context.canPop()) {
    context.pop();
  } else {
    context.go(Routes.training(_course(state)));
  }
}

Map<String, String> _params(GoRouterState state) => {'course': _course(state)};

/// Rotas do objetivo, diagnóstico, plano, semana e torneios (T85, Treino B).
List<RouteBase> treinoBRoutes() => [
  appRoute(
    name: RouteNames.trainingGoal,
    eixoX: true,
    path: D4Paths.trainingGoal,
    builder: (context, state) => _goal(
      state,
      TrainingGoalScreen(
        onBack: () => _back(context, state),
        onContinue: (date) => context.pushNamed(
          RouteNames.trainingPlan,
          pathParameters: _params(state),
          queryParameters: {'flow': '1', 'date': ?date},
        ),
      ),
    ),
  ),
  appRoute(
    name: RouteNames.trainingDiagnostic,
    eixoX: true,
    path: D4Paths.trainingDiagnostic,
    builder: (context, state) => _goal(
      state,
      TrainingDiagnosticScreen(
        onBack: () => _back(context, state),
        onTest: () => context.pushNamed(
          RouteNames.trainingDiagnosticTest,
          pathParameters: _params(state),
        ),
        onQuestionnaire: () => context.pushNamed(
          RouteNames.trainingQuestionnaire,
          pathParameters: _params(state),
        ),
      ),
    ),
  ),
  appRoute(
    name: RouteNames.trainingDiagnosticTest,
    eixoX: true,
    path: D4Paths.trainingDiagnosticTest,
    builder: (context, state) => _goal(
      state,
      TrainingTestScreen(
        onBack: () => _back(context, state),
        onSeePlan: () => context.pushNamed(
          RouteNames.trainingPlanPresentation,
          pathParameters: _params(state),
        ),
      ),
    ),
  ),
  appRoute(
    name: RouteNames.trainingQuestionnaire,
    eixoX: true,
    path: D4Paths.trainingQuestionnaire,
    builder: (context, state) => _goal(
      state,
      TrainingQuestionnaireScreen(
        onBack: () => _back(context, state),
        onBuilt: () => context.pushNamed(
          RouteNames.trainingPlanPresentation,
          pathParameters: _params(state),
        ),
      ),
    ),
  ),
  appRoute(
    name: RouteNames.trainingPlanPresentation,
    eixoX: true,
    path: D4Paths.trainingPlanPresentation,
    builder: (context, state) => _goal(
      state,
      TrainingPlanPresentationScreen(
        onBack: () => _back(context, state),
        onStart: () => context.go(Routes.training(_course(state))),
        onAdjust: () => context.pushNamed(
          RouteNames.trainingPlan,
          pathParameters: _params(state),
          queryParameters: const {'replan': '1'},
        ),
        onWeek: (i) => context.pushNamed(
          RouteNames.trainingWeek,
          pathParameters: {..._params(state), 'week': '${i + 1}'},
        ),
      ),
    ),
  ),
  appRoute(
    name: RouteNames.trainingWeek,
    path: D4Paths.trainingWeek,
    builder: (context, state) => _goal(
      state,
      TrainingWeekScreen(
        week: (int.tryParse(state.pathParameters['week'] ?? '') ?? 1) - 1,
        onBack: () => _back(context, state),
        onChapter: (id) =>
            context.push(Routes.trainingChapter(_course(state), id)),
      ),
    ),
  ),
  appRoute(
    name: RouteNames.trainingTournaments,
    path: D4Paths.trainingTournaments,
    builder: (context, state) => _goal(
      state,
      TrainingTournamentsScreen(
        onBack: () => _back(context, state),
        onRegister: () => context.pushNamed(
          RouteNames.trainingTournamentRegister,
          pathParameters: _params(state),
        ),
      ),
    ),
  ),
  appRoute(
    name: RouteNames.trainingTournamentRegister,
    path: D4Paths.trainingTournamentRegister,
    builder: (context, state) => _goal(
      state,
      TrainingRegisterScreen(
        onBack: () => _back(context, state),
        onRegistered: () => context.pushReplacementNamed(
          RouteNames.trainingNextGoal,
          pathParameters: _params(state),
        ),
      ),
    ),
  ),
  appRoute(
    name: RouteNames.trainingNextGoal,
    path: D4Paths.trainingNextGoal,
    builder: (context, state) => _goal(
      state,
      TrainingNextGoalScreen(
        onBack: () => context.go(Routes.training(_course(state))),
        onTournament: () => context.pushReplacementNamed(
          RouteNames.trainingGoal,
          pathParameters: _params(state),
        ),
        onImprove: () => context.go(Routes.training(_course(state))),
      ),
    ),
  ),
];

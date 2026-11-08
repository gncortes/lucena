import 'package:go_router/go_router.dart';

import '../../ui/daily/widgets/daily_start_screen.dart';
import '../route_names.dart';
import '../router.dart';
import 'treino_b_routes.dart';

/// Telas novas da frente D4 (Treino + Desafios + Partida, T85). A frente registra as rotas na
/// lista [d4Routes] com `appRoute(name: RouteNames.x, path: D4Paths.x, ...)`,
/// do `router.dart`, e navega por nome. Só esta frente mexe neste arquivo.
abstract final class D4Paths {
  /// Seu objetivo (H-TRE-06).
  static const trainingGoal = '/training/:course/goal';

  /// Como montar o plano (H-TRE-07).
  static const trainingDiagnostic = '/training/:course/diagnostic';

  /// Teste de nível do curso, 15 posições (H-TRE-08).
  static const trainingDiagnosticTest = '/training/:course/diagnostic/test';

  /// Questionário (H-TRE-09).
  static const trainingQuestionnaire =
      '/training/:course/diagnostic/questionnaire';

  /// Apresentação do plano (H-TRE-10).
  static const trainingPlanPresentation = '/training/:course/plan-presentation';

  /// Semana (H-TRE-13).
  static const trainingWeek = '/training/:course/week/:week';

  /// Torneios (H-TRE-16).
  static const trainingTournaments = '/training/:course/tournaments';

  /// Cadastro de torneio (H-TRE-14).
  static const trainingTournamentRegister =
      '/training/:course/tournaments/register';

  /// Próxima meta (H-TRE-15).
  static const trainingNextGoal = '/training/:course/next-goal';

  /// Sem final hoje (H-DES-03).
  static const dailyEmpty = '/daily/empty';
}

final List<RouteBase> d4Routes = [
  ...treinoBRoutes(),
  // Desafios (H-DES-03): sem final hoje.
  appRoute(
    name: RouteNames.dailyEmpty,
    path: D4Paths.dailyEmpty,
    builder: (context, state) => const DailyEmptyScreen(),
  ),
];

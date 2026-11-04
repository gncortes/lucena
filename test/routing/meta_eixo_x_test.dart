import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lucena/routing/frentes/treino_b_routes.dart';
import 'package:lucena/routing/route_names.dart';
import 'package:lucena/routing/training_routes.dart';
import 'package:lucena/ui/core/motion/transicao_eixo_x.dart';

/// H-ANI-03: os passos da Meta (objetivo, diagnóstico, teste, questionário,
/// apresentação do plano e o plano em si) deslizam no eixo X.
void main() {
  GoRoute? acha(List<RouteBase> rotas, String nome) {
    for (final rota in rotas) {
      if (rota is GoRoute && rota.name == nome) return rota;
      final dentro = acha(rota.routes, nome);
      if (dentro != null) return dentro;
    }
    return null;
  }

  final rotas = [...treinoBRoutes(), trainingRoute()];
  const passos = [
    RouteNames.trainingGoal,
    RouteNames.trainingDiagnostic,
    RouteNames.trainingDiagnosticTest,
    RouteNames.trainingQuestionnaire,
    RouteNames.trainingPlanPresentation,
    RouteNames.trainingPlan,
  ];

  for (final nome in passos) {
    testWidgets('$nome entra no eixo X', (tester) async {
      final rota = acha(rotas, nome);
      expect(rota, isNotNull, reason: 'rota $nome');
      final router = GoRouter(
        routes: [GoRoute(path: '/', builder: (_, _) => const SizedBox())],
      );
      addTearDown(router.dispose);
      late BuildContext contexto;
      await tester.pumpWidget(
        Builder(
          builder: (context) {
            contexto = context;
            return const SizedBox();
          },
        ),
      );
      final estado = GoRouterState(
        router.configuration,
        uri: Uri.parse('/training/pilares/x'),
        matchedLocation: '/training/pilares/x',
        fullPath: '/training/:course/x',
        pathParameters: const {'course': 'pilares'},
        pageKey: const ValueKey('x'),
      );
      expect(rota!.pageBuilder, isNotNull, reason: '$nome sem pageBuilder');
      expect(rota.pageBuilder!(contexto, estado), isA<PaginaEixoX<void>>());
    });
  }
}

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lucena/routing/route_names.dart';
import 'package:lucena/routing/router.dart';
import 'package:lucena/ui/core/motion/transicao_eixo_x.dart';

/// H-ANI-03: os passos da Conta (entrar, e-mail, dados, aceite, recuperada e
/// o país) deslizam no eixo X. Foto e senha são folhas (H-ANI-06).
void main() {
  GoRoute? acha(List<RouteBase> rotas, String nome) {
    for (final rota in rotas) {
      if (rota is GoRoute && rota.name == nome) return rota;
      final dentro = acha(rota.routes, nome);
      if (dentro != null) return dentro;
    }
    return null;
  }

  const passos = [
    RouteNames.accountEnter,
    RouteNames.accountEmail,
    RouteNames.accountData,
    RouteNames.accountConsent,
    RouteNames.country,
  ];

  for (final nome in passos) {
    testWidgets('$nome entra no eixo X', (tester) async {
      final router = buildRouter();
      addTearDown(router.dispose);
      final rota = acha(router.configuration.routes, nome);
      expect(rota, isNotNull, reason: 'rota $nome');
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
        uri: Uri.parse('/x'),
        matchedLocation: '/x',
        fullPath: '/x',
        pathParameters: const {},
        pageKey: const ValueKey('x'),
      );
      expect(rota!.pageBuilder!(contexto, estado), isA<PaginaEixoX<void>>());
    });
  }
}

import 'package:go_router/go_router.dart';

import 'd1_routes.dart';
import 'd2_routes.dart';
import 'd3_routes.dart';
import 'd4_routes.dart';
import 'treinador_routes.dart';

/// As rotas novas das quatro frentes do T85, no nível de cima do roteador.
final List<RouteBase> frentesRoutes = [
  ...d1Routes,
  ...d2Routes,
  ...d3Routes,
  ...d4Routes,
  ...treinadorRoutes,
];

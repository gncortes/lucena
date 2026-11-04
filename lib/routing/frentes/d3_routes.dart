import 'package:go_router/go_router.dart';

/// Telas novas da frente D3 (Abertura + Início + Iniciante, T85). A frente registra as rotas na
/// lista [d3Routes] com `appRoute(name: RouteNames.x, path: D3Paths.x, ...)`,
/// do `router.dart`, e navega por nome. Só esta frente mexe neste arquivo.
abstract final class D3Paths {
  /// Entrar sem conta, o portão da Escola (H-ESC-18).
  static const schoolGate = '/school/gate';

  /// Formatura da Escola (H-ESC-22).
  static const schoolGraduation = '/school/graduation';
}

final List<RouteBase> d3Routes = [];

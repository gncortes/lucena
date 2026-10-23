import 'dart:async';

import 'package:go_router/go_router.dart';

import '../data/repositories/analytics/analytics_repository.dart';

/// O `screen_view` de cada tela (E1.03, escolha 11): o nome da rota com os
/// parâmetros (`/featured/:id`), nunca o id, a FEN nem a busca.
///
/// Ouve o [GoRouter] e não um `NavigatorObserver`: o observador só vê o
/// navegador de cima e não dá o molde da rota.
class ScreenTracker {
  ScreenTracker(this._router, this._analytics) {
    _router.routerDelegate.addListener(_changed);
    _changed();
  }

  final GoRouter _router;
  final AnalyticsRepository _analytics;
  String? _last;

  void _changed() {
    final route = _router.routerDelegate.currentConfiguration.fullPath;
    if (route.isEmpty || route == _last) return;
    _last = route;
    unawaited(_analytics.screen(route));
  }

  void dispose() => _router.routerDelegate.removeListener(_changed);
}

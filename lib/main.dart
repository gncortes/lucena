import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'config/dependencies.dart';
import 'domain/use_cases/now.dart';
import 'routing/router.dart';
import 'ui/core/l10n/l10n.dart';
import 'ui/core/theme/app_theme.dart';

void main() {
  runApp(const LucenaApp(dependencies: Dependencies.normal()));
}

class LucenaApp extends StatefulWidget {
  const LucenaApp({required this.dependencies, this.locale, super.key});

  final Dependencies dependencies;

  /// Força um idioma (testes). Nulo segue o idioma do sistema.
  final Locale? locale;

  @override
  State<LucenaApp> createState() => _LucenaAppState();
}

class _LucenaAppState extends State<LucenaApp> {
  late final GoRouter _router = buildRouter();

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider<Now>.value(
      value: widget.dependencies.now,
      child: MaterialApp.router(
        onGenerateTitle: (context) => context.l10n.appTitle,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        locale: widget.locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: _router,
      ),
    );
  }
}

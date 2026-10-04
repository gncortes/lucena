import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'config/dependencies.dart';
import 'domain/models/app_settings.dart';
import 'domain/use_cases/now.dart';
import 'routing/router.dart';
import 'ui/core/l10n/l10n.dart';
import 'ui/core/theme/app_theme.dart';
import 'ui/core/theme/app_theme_mode_ui.dart';
import 'ui/settings/view_models/settings_cubit.dart';

void main() {
  runApp(LucenaApp(dependencies: Dependencies.normal()));
}

class LucenaApp extends StatefulWidget {
  const LucenaApp({required this.dependencies, super.key});

  final Dependencies dependencies;

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
    final dependencies = widget.dependencies;
    return RepositoryProvider<Now>.value(
      value: dependencies.now,
      child: BlocProvider(
        create: (context) => SettingsCubit(
          dependencies.settingsRepository,
          languages: dependencies.languages,
        )..load(),
        child: BlocBuilder<SettingsCubit, AppSettings?>(
          builder: (context, settings) {
            // Até as preferências chegarem, só o fundo: o app nunca aparece
            // no idioma errado.
            if (settings == null) return const _LaunchBackground();
            return MaterialApp.router(
              onGenerateTitle: (context) => context.l10n.appTitle,
              debugShowCheckedModeBanner: false,
              theme: AppTheme.light,
              darkTheme: AppTheme.dark,
              themeMode: settings.themeMode.material,
              locale: localeFromCode(settings.languageCode),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: appSupportedLocales,
              routerConfig: _router,
            );
          },
        ),
      ),
    );
  }
}

/// O mesmo fundo da abertura nativa e da tela inicial.
class _LaunchBackground extends StatelessWidget {
  const _LaunchBackground();

  @override
  Widget build(BuildContext context) {
    final isDark = MediaQuery.platformBrightnessOf(context) == Brightness.dark;
    final theme = isDark ? AppTheme.dark : AppTheme.light;
    return ColoredBox(color: theme.scaffoldBackgroundColor);
  }
}

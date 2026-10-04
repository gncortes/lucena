import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucena/ui/core/l10n/l10n.dart';
import 'package:lucena/ui/core/theme/app_theme.dart';
import 'package:lucena/ui/settings/view_models/settings_cubit.dart';

/// Envolve um widget com tema e idiomas do app, para testes de widget.
class TestApp extends StatelessWidget {
  const TestApp({
    required this.child,
    this.locale = const Locale('en'),
    this.themeMode = ThemeMode.light,
    this.settingsCubit,
    super.key,
  });

  final Widget child;
  final Locale locale;
  final ThemeMode themeMode;

  /// View model das telas de Configurações, quando a tela testada precisa dele.
  final SettingsCubit? settingsCubit;

  @override
  Widget build(BuildContext context) {
    final app = MaterialApp(
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: appSupportedLocales,
      home: child,
    );
    final cubit = settingsCubit;
    if (cubit == null) return app;
    return BlocProvider.value(value: cubit, child: app);
  }
}

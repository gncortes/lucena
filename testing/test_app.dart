import 'package:flutter/material.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucena/domain/models/app_accent.dart';
import 'package:lucena/domain/models/app_settings.dart';
import 'package:lucena/ui/core/l10n/l10n.dart';
import 'package:lucena/ui/core/theme/app_theme.dart';
import 'package:lucena/ui/profile/view_models/profile_cubit.dart';
import 'package:lucena/ui/settings/view_models/settings_cubit.dart';

import 'fakes/fake_profile_repository.dart';

/// Envolve um widget com tema e idiomas do app, para testes de widget.
class TestApp extends StatelessWidget {
  const TestApp({
    required this.child,
    this.locale = const Locale('en'),
    this.themeMode = ThemeMode.light,
    this.settingsCubit,
    this.profileCubit,
    super.key,
  });

  final Widget child;
  final Locale locale;
  final ThemeMode themeMode;

  /// View model das telas de Configurações, quando a tela testada precisa dele.
  final SettingsCubit? settingsCubit;

  /// View model do perfil, quando a tela testada precisa dele.
  final ProfileCubit? profileCubit;

  @override
  Widget build(BuildContext context) {
    final settingsCubit = this.settingsCubit;
    Widget build(AppAccent? accent) => MaterialApp(
      theme: AppTheme.of(Brightness.light, accent: accent),
      darkTheme: AppTheme.of(Brightness.dark, accent: accent),
      themeMode: themeMode,
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: appSupportedLocales,
      home: child,
    );
    // Com as preferências, a cor do app escolhida vale na hora, como no app.
    final app = settingsCubit == null
        ? build(null)
        : BlocBuilder<SettingsCubit, AppSettings?>(
            bloc: settingsCubit,
            builder: (context, settings) => build(settings?.accent),
          );
    final profileCubit = this.profileCubit;
    final providers = [
      if (settingsCubit != null)
        BlocProvider<SettingsCubit>.value(value: settingsCubit),
      // Toda tela pode mostrar o apelido: sem perfil dado, o de fábrica.
      if (profileCubit != null)
        BlocProvider<ProfileCubit>.value(value: profileCubit)
      else
        BlocProvider<ProfileCubit>(
          create: (_) => ProfileCubit(FakeProfileRepository())..load(),
        ),
    ];
    return MultiBlocProvider(providers: providers, child: app);
  }
}

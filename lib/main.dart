import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'config/app_providers.dart';
import 'config/dependencies.dart';
import 'config/launch_inputs.dart';
import 'config/launch_navigation.dart';
import 'config/launch_shell.dart';
import 'config/push_alerts.dart';
import 'config/startup_tasks.dart';
import 'data/repositories/sync/sync_scheduler.dart';
import 'data/services/firebase/crash_report_service.dart';
import 'domain/models/app_settings.dart';
import 'domain/models/app_version.dart';
import 'routing/launch_location.dart';
import 'routing/router.dart';
import 'routing/screen_tracker.dart';
import 'routing/stream_refresh.dart';
import 'ui/core/l10n/l10n.dart';
import 'ui/core/motion/abertura_animada.dart';
import 'ui/core/motion/entradas_vistas.dart';
import 'ui/core/theme/app_theme.dart';
import 'ui/core/theme/app_theme_mode_ui.dart';
import 'ui/settings/view_models/settings_cubit.dart';
import 'ui/update/view_models/update_cubit.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final firebase = await startPlatform();
  final version = await launchValue(
    Dependencies.installedVersion,
    const AppVersion('0.0.0'),
  );
  // O push que chega com o app fechado: o app monta a notificação.
  if (firebase) listenPushInBackground();
  // H-ANI-44: a abertura animada cobre o app até a primeira tela (ou o erro
  // de carga) estar desenhada.
  final abriu = Completer<void>();
  runApp(
    AberturaAnimada(
      carga: abriu.future,
      child: LucenaBootstrap(
        aoAbrir: () {
          if (!abriu.isCompleted) abriu.complete();
        },
        initialize: () async => Dependencies.normal(
          version: version,
          firebase: firebase,
          trainingInstallSeed: await Dependencies.trainingInstallSeed(),
        ),
      ),
    ),
  );
}

/// Required installation data must be readable before creating production
/// repositories. A recoverable seed failure cannot silently disable training.
class LucenaBootstrap extends StatefulWidget {
  const LucenaBootstrap({required this.initialize, this.aoAbrir, super.key});
  final Future<Dependencies> Function() initialize;

  /// A primeira tela (ou o erro de carga) está na tela: a abertura pode sair.
  final VoidCallback? aoAbrir;
  @override
  State<LucenaBootstrap> createState() => _LucenaBootstrapState();
}

class _LucenaBootstrapState extends State<LucenaBootstrap> {
  Dependencies? _dependencies;
  int _failures = 0;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    unawaited(_initialize());
  }

  Future<void> _initialize() async {
    if (_loading) return;
    _loading = true;
    try {
      final dependencies = await widget.initialize();
      if (mounted) setState(() => _dependencies = dependencies);
    } on Object catch (error, stack) {
      reportHandledError(error, stack);
      if (mounted) setState(() => _failures++);
    } finally {
      _loading = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dependencies = _dependencies;
    if (dependencies != null) {
      return LucenaApp(dependencies: dependencies, aoAbrir: widget.aoAbrir);
    }
    return LaunchShell(
      theme: AppTheme.light,
      failures: _failures,
      onRetry: _initialize,
      aoAbrir: widget.aoAbrir,
    );
  }
}

class LucenaApp extends StatefulWidget {
  const LucenaApp({required this.dependencies, this.aoAbrir, super.key});

  final Dependencies dependencies;

  /// Ver [LucenaBootstrap.aoAbrir].
  final VoidCallback? aoAbrir;

  @override
  State<LucenaApp> createState() => _LucenaAppState();
}

class _LucenaAppState extends State<LucenaApp> {
  // Nulo até saber em que tela o app abre.
  GoRouter? _router;
  int _launchFailures = 0;
  bool _opening = false;
  // As telas que já fizeram a entrada animada nesta sessão (H-ANI-01).
  final _entradasVistas = EntradasVistas();
  Dependencies get _dependencies => widget.dependencies;
  late final SettingsCubit _settings = SettingsCubit(
    _dependencies.settingsRepository,
    languages: _dependencies.languages,
    sound: _dependencies.soundRepository,
  );

  // O screen_view de cada tela (E1.03).
  ScreenTracker? _screens;

  late final _analytics = openingAnalytics(_dependencies);
  late final _reader = LaunchReader(
    _dependencies,
    tasks: StartupTasks(_dependencies, analytics: _analytics),
  );
  late final _navigation = LaunchNavigation(
    _dependencies,
    analytics: _analytics,
    router: () => _router,
    mounted: () => mounted,
  );

  // O progresso indo para a conta (E1.13).
  late final SyncScheduler _sync = SyncScheduler(
    _dependencies.accountRepository,
    _dependencies.syncRepository,
    changes: _dependencies.localChanges,
  );

  // A versão contra o Remote Config e a Play (E1.32).
  late final UpdateCubit _update = UpdateCubit(
    flags: _dependencies.remoteFlagsRepository,
    updates: _dependencies.appUpdateRepository,
    analytics: _dependencies.analyticsRepository,
  );

  // Refaz o redirect da atualização obrigatória quando ela muda.
  late final StreamRefresh _updateRefresh = StreamRefresh(
    _update.stream.map((state) => state.required).distinct(),
  );
  late final StreamRefresh? _accountRefresh = _dependencies.requireLessonAccount
      ? StreamRefresh(_dependencies.accountRepository.changes)
      : null;

  @override
  void initState() {
    super.initState();
    _sync.start();
    unawaited(_update.start());
    _openRouter();
  }

  // O app reabre na partida ou aula que estava na tela ao ser fechado.
  Future<void> _openRouter() async {
    if (_opening) return;
    _opening = true;
    try {
      await _settings.load();
      await _loadRouter();
    } on Object catch (error, stack) {
      // Report the original failure, without exposing its message in the UI.
      debugPrint('App launch failed: $error\n$stack');
      reportHandledError(error, stack);
      if (mounted) {
        _screens?.dispose();
        _screens = null;
        _router?.dispose();
        setState(() {
          _router = null;
          _launchFailures++;
        });
      }
    } finally {
      _opening = false;
    }
  }

  Future<void> _loadRouter() async {
    final destination = await _reader.read();
    final facts = destination.facts;
    if (!mounted) return;
    setState(() {
      _router = buildRouter(
        requireLessonAccount: _dependencies.requireLessonAccount,
        initialLocation: launchLocation(
          conclusion: facts.conclusion,
          resumeGame: facts.resumeGame,
          resumeBlind: facts.resumeBlind,
          school: facts.school,
          endgames: facts.endgames,
          stars: facts.stars,
          boardControlsOpen: facts.boardControlsOpen,
          consentPending: destination.consentPending,
          link: destination.link,
          // Erro frio é empilhado sobre a retomada, para Voltar recuperá-la.
          uri: destination.uri,
          showSchool: destination.showSchool,
          visibleEndgameLessons: destination.visibleEndgameLessons,
        ),
        updateRequired: () => _update.state.required,
        refresh: Listenable.merge([_updateRefresh, _accountRefresh]),
      );
      _screens = ScreenTracker(_router!, _dependencies.analyticsRepository);
    });
    await _navigation.opened(destination);
  }

  @override
  void dispose() {
    _navigation.dispose();
    unawaited(_sync.dispose());
    _screens?.dispose();
    _router?.dispose();
    _updateRefresh.dispose();
    _accountRefresh?.dispose();
    unawaited(_update.close());
    unawaited(_settings.close());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final router = _router;
    return AppProviders(
      dependencies: _dependencies,
      sync: _sync,
      update: _update,
      settings: _settings,
      child: BlocBuilder<SettingsCubit, AppSettings?>(
        builder: (context, settings) {
          // Before preferences and routing are ready, use the localized
          // loading/error shell, without guessing an application route.
          if (settings == null || router == null) {
            final defaults = settings ?? const AppSettings();
            return LaunchShell(
              theme: AppTheme.of(Brightness.light, accent: defaults.accent),
              locale: localeFromCode(defaults.languageCode),
              failures: _launchFailures,
              onRetry: _openRouter,
              aoAbrir: widget.aoAbrir,
            );
          }
          avisaQueAbriu(widget.aoAbrir);
          return QuietInBackground(
            child: MaterialApp.router(
              onGenerateTitle: (context) => context.l10n.appTitle,
              debugShowCheckedModeBanner: false,
              theme: AppTheme.of(Brightness.light, accent: settings.accent),
              darkTheme: AppTheme.of(Brightness.dark, accent: settings.accent),
              themeMode: settings.themeMode.material,
              locale: localeFromCode(settings.languageCode),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: appSupportedLocales,
              routerConfig: router,
              builder: (context, child) => AppBridges(
                router: router,
                onReminder: (route) {
                  unawaited(_analytics.alertOpened(route, channel: 'local'));
                  _router?.push(route);
                },
                vistas: _entradasVistas,
                child: child,
              ),
            ),
          );
        },
      ),
    );
  }
}

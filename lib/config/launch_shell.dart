import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../data/repositories/ads/ads_repository.dart';
import '../ui/core/l10n/l10n.dart';
import '../ui/core/motion/entradas_vistas.dart';
import '../ui/core/widgets/load_error.dart';
import '../ui/core/widgets/load_skeleton.dart';
import '../ui/pilares_sale/widgets/pilares_purchase_bridge.dart';
import '../ui/reminders/widgets/reminders_bridge.dart';
import '../ui/settings/widgets/settings_save_failure_listener.dart';
import '../ui/update/widgets/update_bridge.dart';
import '../ui/voice/view_models/speech_cubit.dart';

/// Avisa a abertura (H-ANI-44) depois do quadro em que a primeira tela de
/// verdade foi desenhada.
void avisaQueAbriu(VoidCallback? aoAbrir) {
  if (aoAbrir == null) return;
  WidgetsBinding.instance.addPostFrameCallback((_) => aoAbrir());
}

/// O app antes da primeira tela: o esqueleto de carga e, depois de
/// [failures] falhas, o erro com "Tentar de novo" ([onRetry]). Sem adivinhar
/// rota nenhuma do app.
class LaunchShell extends StatelessWidget {
  const LaunchShell({
    required this.theme,
    required this.failures,
    required this.onRetry,
    this.locale,
    this.aoAbrir,
    super.key,
  });

  final ThemeData theme;
  final Locale? locale;
  final int failures;
  final FutureOr<void> Function() onRetry;

  /// O erro de carga está na tela: a abertura pode sair.
  final VoidCallback? aoAbrir;

  @override
  Widget build(BuildContext context) {
    if (failures > 0) avisaQueAbriu(aoAbrir);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: theme,
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: appSupportedLocales,
      home: failures == 0
          ? const LoadSkeletonScreen()
          : LoadErrorScreen(
              kind: failures == 1
                  ? LoadErrorKind.launch
                  : LoadErrorKind.launchAgain,
              onAction: onRetry,
            ),
    );
  }
}

/// O que vale em toda tela do app, abaixo das traduções (os textos dos
/// lembretes vêm delas): a atualização obrigatória, a compra vigiada, os
/// lembretes locais ([onReminder] abre a rota de um), o aviso de preferência
/// não gravada e as entradas animadas já vistas ([vistas]).
class AppBridges extends StatelessWidget {
  const AppBridges({
    required this.router,
    required this.onReminder,
    required this.vistas,
    required this.child,
    super.key,
  });

  final GoRouter router;
  final ValueChanged<String> onReminder;
  final EntradasVistas vistas;
  final Widget? child;

  @override
  Widget build(BuildContext context) => UpdateBridge(
    router: router,
    child: PilaresPurchaseBridge(
      router: router,
      child: RemindersBridge(
        onOpen: onReminder,
        child: SettingsSaveFailureListener(
          child: EntradasVistasEscopo(
            vistas: vistas,
            child: child ?? const SizedBox.shrink(),
          ),
        ),
      ),
    ),
  );
}

/// O app foi para segundo plano (ou foi fechado): a voz para.
class QuietInBackground extends StatefulWidget {
  const QuietInBackground({required this.child, super.key});

  final Widget child;

  @override
  State<QuietInBackground> createState() => _QuietInBackgroundState();
}

class _QuietInBackgroundState extends State<QuietInBackground> {
  late final AppLifecycleListener _listener = AppLifecycleListener(
    onHide: () {
      context.read<SpeechCubit>().stop();
      context.read<AdsRepository>().hidden();
    },
    // Mais de 30 minutos fora: sessão nova do anúncio (E1.25).
    onShow: () => context.read<AdsRepository>().visible(),
    // De volta (talvez das configurações de voz do aparelho): uma voz nova
    // pode ter sido baixada.
    onResume: () => context.read<SpeechCubit>().reloadVoices(),
  );

  @override
  void initState() {
    super.initState();
    _listener;
  }

  @override
  void dispose() {
    _listener.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/models/alert_settings.dart';
import '../../../routing/routes.dart';
import '../../core/keys/alerts_keys.dart';
import '../../core/l10n/countries.dart';
import '../../core/l10n/l10n.dart';
import '../../core/motion/entrada_em_cascata.dart';
import '../../core/motion/entradas_vistas.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_icon_size.dart';
import '../../core/theme/app_shape.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/lucena_app_bar.dart';
import '../../core/widgets/load_error.dart';
import '../../core/widgets/lucena_snack_bar.dart';
import '../../core/widgets/skeleton.dart';
import '../../profile/widgets/profile_rows.dart';
import '../../region/widgets/region_sheet.dart';
import '../view_models/alerts_cubit.dart';

/// Configurações > Notificações (canvas `PropV1RetencaoAvisos` e
/// `AvisosOff`, H-AJU-09): o estado do Android em cima e uma chave por tipo.
/// Sem a permissão, explica e abre os ajustes do sistema; enquanto a tela não
/// pediu nesta sessão, oferece "Permitir" (Gap 7).
class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  // Ao voltar dos ajustes do Android, relê a permissão.
  late final AppLifecycleListener _lifecycle = AppLifecycleListener(
    onResume: () => unawaited(context.read<AlertsCubit>().refresh()),
  );

  // Chave não gravada: a tela já voltou; o aviso só conta (Gap 1).
  late final StreamSubscription<void> _failures = context
      .read<AlertsCubit>()
      .saveFailures
      .listen((_) {
        if (!mounted) return;
        showLucenaSnackBar(
          context,
          context.l10n.ajuSaveError,
          icon: Icons.error_outline,
          key: AlertsKeys.saveFailure,
        );
      });

  @override
  void initState() {
    super.initState();
    _lifecycle;
    _failures;
    unawaited(context.read<AlertsCubit>().refresh());
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    unawaited(_failures.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = context.watch<AlertsCubit>().state;
    final cubit = context.read<AlertsCubit>();
    if (state.failure case final failure?) {
      return KeyedSubtree(
        key: AlertsKeys.error,
        child: LoadErrorScreen(
          kind: LoadErrorKind.fromFailure(failure),
          onAction: cubit.load,
          onBack: () =>
              context.canPop() ? context.pop() : context.go(Routes.home),
        ),
      );
    }
    if (!state.ready) {
      return Scaffold(
        key: AlertsKeys.screen,
        appBar: LucenaAppBar(title: Text(l10n.alertsTitle)),
        body: const SkeletonList(),
      );
    }
    final settings = state.settings;
    void change(AlertSettings next) => unawaited(cubit.change(next));
    final switches = [
      if (state.push)
        _AlertSwitch(
          key: AlertsKeys.tournaments,
          icon: Icons.stadium,
          title: l10n.alertsTournaments,
          subtitle: l10n.alertsTournamentsBody,
          value: settings.tournaments,
          onChanged: (on) => change(settings.copyWith(tournaments: on)),
        ),
      _AlertSwitch(
        key: AlertsKeys.daily,
        icon: Icons.today,
        title: l10n.alertsDaily,
        subtitle: l10n.alertsDailyBody,
        value: settings.daily,
        onChanged: (on) => change(settings.copyWith(daily: on)),
      ),
      if (state.push) ...[
        _AlertSwitch(
          key: AlertsKeys.news,
          icon: Icons.new_releases,
          title: l10n.alertsNews,
          subtitle: l10n.alertsNewsBody,
          value: settings.news,
          onChanged: (on) => change(settings.copyWith(news: on)),
        ),
        _AlertSwitch(
          key: AlertsKeys.lessons,
          icon: Icons.auto_stories,
          title: l10n.alertsLessons,
          subtitle: l10n.alertsLessonsBody,
          value: settings.lessons,
          onChanged: (on) => change(settings.copyWith(lessons: on)),
        ),
      ],
    ];
    // H-ANI-16: a faixa, o texto, as chaves e a região entram em cascata,
    // só na primeira entrada da tela.
    return EntradaDaTela(
      id: 'PropV1TreinoNotificacao',
      child: Scaffold(
        key: AlertsKeys.screen,
        appBar: LucenaAppBar(title: Text(l10n.alertsTitle)),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screen,
            AppSpacing.sm,
            AppSpacing.screen,
            AppSpacing.xl,
          ),
          children: [
            EntradaEmCascata(
              montar: (itens) => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: itens,
              ),
              itens: [
                // A permissão Android também vale para os lembretes sem
                // Firebase.
                ItemDaCascata.texto(
                  state.permitted
                      ? _Allowed(onSettings: cubit.openSystemSettings)
                      : _Denied(
                          onSettings: cubit.openSystemSettings,
                          onAllow: state.canAsk
                              ? cubit.requestPermission
                              : null,
                        ),
                ),
                ItemDaCascata.texto(const _AlertsIntro()),
                // Sem a permissão, as chaves ficam esmaecidas, mas mudam.
                ItemDaCascata.texto(
                  Opacity(
                    opacity: !state.permitted ? _muted : 1,
                    child: ProfileRowGroup(children: switches),
                  ),
                ),
                if (state.push && state.country != null)
                  ItemDaCascata.texto(
                    _RegionRow(country: state.country!, state: state.state),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static const _muted = 0.5;
}

/// O texto de abertura, entre a permissão e as chaves.
class _AlertsIntro extends StatelessWidget {
  const _AlertsIntro();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
      ),
      child: Text(
        l10n.alertsIntro,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

/// "Torneios da região: Brasil · Paraná" e "Mudar" (abre "Seu país").
class _RegionRow extends StatelessWidget {
  const _RegionRow({required this.country, required this.state});

  final String country;
  final String? state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final name = stateName(country: country, state: state);
    final place = [Countries.name(l10n, country), ?name].join(' · ');
    return InkWell(
      key: AlertsKeys.region,
      onTap: () => context.push(Routes.country),
      borderRadius: BorderRadius.circular(AppShape.small),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.sm,
          AppSpacing.md,
          AppSpacing.sm,
          0,
        ),
        child: Row(
          children: [
            Icon(
              Icons.location_on,
              size: AppIconSize.button,
              color: colors.onSurfaceVariant,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text.rich(
                TextSpan(
                  text: '${l10n.alertsRegionLabel} ',
                  children: [
                    TextSpan(
                      text: place,
                      style: TextStyle(
                        color: colors.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ),
            Text(
              l10n.alertsRegionChange,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AlertSwitch extends StatelessWidget {
  const _AlertSwitch({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    super.key,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => SwitchListTile(
    secondary: Icon(icon),
    title: Text(title),
    subtitle: Text(subtitle),
    value: value,
    onChanged: onChanged,
  );
}

/// "Android: avisos permitidos para o Lucena", com o atalho "Ajustes".
class _Allowed extends StatelessWidget {
  const _Allowed({required this.onSettings});

  final Future<bool> Function() onSettings;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Padding(
      key: AlertsKeys.allowed,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      child: Row(
        spacing: AppSpacing.sm,
        children: [
          const Icon(
            Icons.check_circle,
            size: AppIconSize.button,
            color: AppColors.successColor,
          ),
          Expanded(
            child: Text(
              l10n.alertsAllowed,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          TextButton(
            key: AlertsKeys.allowedSettings,
            onPressed: () => unawaited(onSettings()),
            child: Text(l10n.alertsAllowedSettings),
          ),
        ],
      ),
    );
  }
}

/// A faixa vermelha: os avisos estão desligados no Android.
class _Denied extends StatelessWidget {
  const _Denied({required this.onSettings, this.onAllow});

  final Future<bool> Function() onSettings;

  /// "Permitir": só enquanto a tela não pediu nesta sessão.
  final Future<void> Function()? onAllow;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return DecoratedBox(
      key: AlertsKeys.offBanner,
      decoration: BoxDecoration(
        color: colors.errorContainer,
        borderRadius: BorderRadius.circular(AppShape.large),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: AppSpacing.md,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: AppSpacing.md,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: colors.error,
                    borderRadius: BorderRadius.circular(AppShape.medium),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    child: Icon(
                      Icons.notifications_off,
                      size: AppIconSize.standard,
                      color: colors.onError,
                    ),
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: AppSpacing.xs,
                    children: [
                      Text(
                        l10n.alertsOffTitle,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: colors.onErrorContainer,
                        ),
                      ),
                      Text(
                        l10n.alertsOffBody,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colors.onErrorContainer,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (onAllow case final allow?)
              FilledButton(
                key: AlertsKeys.offAllow,
                onPressed: () => unawaited(allow()),
                child: Text(l10n.ajuAlertsAllow),
              ),
            OutlinedButton.icon(
              key: AlertsKeys.offOpen,
              onPressed: () => unawaited(onSettings()),
              icon: const Icon(Icons.settings),
              label: Text(l10n.alertsOffOpen),
            ),
          ],
        ),
      ),
    );
  }
}

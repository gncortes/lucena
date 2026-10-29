import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/models/alert_settings.dart';
import '../../../routing/routes.dart';
import '../../core/keys/alerts_keys.dart';
import '../../core/l10n/countries.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_icon_size.dart';
import '../../core/theme/app_shape.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/lucena_app_bar.dart';
import '../../profile/widgets/profile_rows.dart';
import '../../region/widgets/region_sheet.dart';
import '../view_models/alerts_cubit.dart';

/// Perfil > Avisos (canvas `PropV1RetencaoAvisos` e `AvisosOff`): o estado
/// do Android em cima, uma chave por tipo e a hora dos lembretes. Nunca pede
/// a permissão: sem ela, explica e abre os ajustes do sistema.
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

  @override
  void initState() {
    super.initState();
    _lifecycle;
    unawaited(context.read<AlertsCubit>().refresh());
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final state = context.watch<AlertsCubit>().state;
    final cubit = context.read<AlertsCubit>();
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
    final reminder = TimeOfDay(
      hour: settings.reminderMinutes ~/ 60,
      minute: settings.reminderMinutes % 60,
    );
    return Scaffold(
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
          // A permissão Android também vale para os lembretes sem Firebase.
          state.permitted
              ? _Allowed(onSettings: cubit.openSystemSettings)
              : _Denied(onSettings: cubit.openSystemSettings),
          const SizedBox(height: AppSpacing.lg),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            child: Text(
              l10n.alertsIntro,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          // Sem a permissão, as chaves ficam esmaecidas, mas mudam.
          Opacity(
            opacity: !state.permitted ? _muted : 1,
            child: ProfileRowGroup(children: switches),
          ),
          if (state.push && state.country != null)
            _RegionRow(country: state.country!, state: state.state),
          const SizedBox(height: AppSpacing.lg),
          ProfileRowGroup(
            children: [
              ProfileRow(
                key: AlertsKeys.reminder,
                icon: Icons.schedule,
                title: l10n.alertsReminder,
                value: MaterialLocalizations.of(context)
                    .formatTimeOfDay(reminder, alwaysUse24HourFormat: true),
                onTap: () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: reminder,
                    helpText: l10n.alertsReminder,
                  );
                  if (picked == null) return;
                  await cubit.setReminder(picked.hour * 60 + picked.minute);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  static const _muted = 0.5;
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
  const _Denied({required this.onSettings});

  final Future<bool> Function() onSettings;

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

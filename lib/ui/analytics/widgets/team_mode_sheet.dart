import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucena_ui/lucena_ui.dart';

import '../../core/keys/analytics_keys.dart';
import '../../core/l10n/l10n.dart';
import '../view_models/team_mode_cubit.dart';

/// A folha do Modo equipe (quadro `PropV1EventosEquipe`). Abrir já liga a
/// chave "Não contar meu uso"; dá para desligar ali mesmo.
Future<void> showTeamModeSheet(BuildContext context) {
  final cubit = context.read<TeamModeCubit>();
  cubit.setTeamMode(true);
  return showLucenaSheet<void>(
    context,
    sheetKey: AnalyticsKeys.teamSheet,
    builder: (sheet) => BlocProvider.value(
      value: cubit,
      child: const SafeArea(top: false, child: _TeamSheet()),
    ),
  );
}

class _TeamSheet extends StatelessWidget {
  const _TeamSheet();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final team = context.watch<TeamModeCubit>().state.team;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.lg,
        AppSpacing.xl,
        AppSpacing.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: colors.primaryContainer,
              borderRadius: BorderRadius.circular(AppShape.large),
            ),
            child: SizedBox.square(
              dimension: 56,
              child: Icon(
                Icons.engineering,
                size: AppIconSize.large,
                color: colors.primary,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            l10n.teamModeTitle,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          SwitchListTile(
            key: AnalyticsKeys.teamSwitch,
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.teamModeSwitch),
            subtitle: Text(l10n.teamModeBody),
            value: team,
            onChanged: (value) =>
                context.read<TeamModeCubit>().setTeamMode(value),
          ),
        ],
      ),
    );
  }
}

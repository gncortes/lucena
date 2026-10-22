import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/analytics/analytics_context.dart';
import '../../core/keys/settings_keys.dart';
import '../../core/l10n/l10n.dart';
import '../view_models/team_mode_cubit.dart';
import 'team_mode_sheet.dart';

/// A versão no fim das Configurações. Sete toques abrem o Modo equipe; com
/// ele ligado, "Versão 1.2.3 · modo equipe".
class VersionFooter extends StatelessWidget {
  const VersionFooter({super.key, required this.version});

  final String version;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (context) => TeamModeCubit(context.analytics)..load(),
    child: _Footer(version: version),
  );
}

class _Footer extends StatelessWidget {
  const _Footer({required this.version});

  final String version;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final team = context.select((TeamModeCubit cubit) => cubit.state.team);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        if (context.read<TeamModeCubit>().tapVersion()) {
          showTeamModeSheet(context);
        }
      },
      child: Text(
        team ? l10n.versionTeamMode(version) : l10n.homeVersion(version),
        key: SettingsKeys.version,
        textAlign: TextAlign.center,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

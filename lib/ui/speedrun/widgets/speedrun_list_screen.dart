import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/models/speedrun.dart';
import '../../../domain/use_cases/clock_format.dart';
import '../../../routing/routes.dart';
import '../../core/keys/speedrun_keys.dart';
import '../../core/l10n/l10n.dart';
import '../view_models/speedrun_cubit.dart';
import 'speedrun_ui.dart';
import '../../core/widgets/scroll_padding.dart';

/// Os speedruns, de degrau e de final, com o recorde de cada um.
class SpeedrunListScreen extends StatelessWidget {
  const SpeedrunListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final all = context.select((SpeedrunCubit cubit) => cubit.state.all);
    Widget section(String title, SpeedrunKind kind) => Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(16, 16, 16, 4),
      child: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(
          color: theme.colorScheme.primary,
        ),
      ),
    );
    return Scaffold(
      key: SpeedrunKeys.listScreen,
      appBar: AppBar(title: Text(l10n.speedrunTitle)),
      body: all == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: scrollPadding(context),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Text(
                    l10n.speedrunIntro,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                for (final kind in SpeedrunKind.values)
                  // Modalidade sem speedrun não ganha título.
                  if (all.any((summary) => summary.speedrun.kind == kind)) ...[
                    section(switch (kind) {
                      SpeedrunKind.rung => l10n.speedrunRungSection,
                      SpeedrunKind.ending => l10n.speedrunEndingSection,
                      SpeedrunKind.exercises => l10n.speedrunExercisesSection,
                      SpeedrunKind.full => l10n.speedrunFullSection,
                    }, kind),
                    for (final summary in all)
                      if (summary.speedrun.kind == kind)
                        _Item(summary: summary),
                  ],
              ],
            ),
    );
  }
}

class _Item extends StatelessWidget {
  const _Item({required this.summary});

  final SpeedrunSummary summary;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final speedrun = summary.speedrun;
    final best = summary.records.best;
    return ListTile(
      key: SpeedrunKeys.item(speedrun.id),
      leading: Icon(
        summary.ongoing != null ? Icons.timelapse : Icons.timer_outlined,
        color: theme.colorScheme.primary,
      ),
      title: SpeedrunTitle(speedrun, style: theme.textTheme.titleMedium),
      subtitle: Text(speedrunDescription(l10n, speedrun)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            best == null ? l10n.speedrunNoRecord : RunTimeFormat.format(best),
            key: SpeedrunKeys.itemBest(speedrun.id),
            style: theme.textTheme.titleSmall?.copyWith(
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const Icon(Icons.chevron_right),
        ],
      ),
      onTap: () async {
        await context.push(Routes.speedrun(speedrun.id));
        if (context.mounted) await context.read<SpeedrunCubit>().load();
      },
    );
  }
}

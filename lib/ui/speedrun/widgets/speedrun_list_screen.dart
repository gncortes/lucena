import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/models/speedrun.dart';
import '../../../domain/use_cases/clock_format.dart';
import '../../../routing/routes.dart';
import '../../core/keys/speedrun_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/pace/pace_ui.dart';
import '../../core/widgets/scroll_padding.dart';
import '../view_models/speedrun_cubit.dart';
import 'speedrun_ui.dart';

/// Os speedruns no ritmo escolhido, com o melhor tempo de cada um. As
/// tentativas em andamento (de qualquer ritmo) ficam no alto.
class SpeedrunListScreen extends StatelessWidget {
  const SpeedrunListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final state = context.watch<SpeedrunCubit>().state;
    final all = state.all;
    Widget section(String title) => Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(16, 20, 16, 8),
      child: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
    );
    return Scaffold(
      key: SpeedrunKeys.listScreen,
      appBar: AppBar(
        title: Text(l10n.speedrunTitle),
        actions: [
          IconButton(
            key: SpeedrunKeys.help,
            icon: const Icon(Icons.info_outline),
            tooltip: l10n.speedrunHelp,
            onPressed: () => _showHelp(context),
          ),
        ],
      ),
      body: all == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: scrollPadding(context),
              children: [
                // O ritmo da lista: cada ritmo tem os seus recordes.
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: ActionChip(
                      key: SpeedrunKeys.pace,
                      avatar: const Icon(Icons.timer_outlined, size: 18),
                      label: Text(paceLabel(l10n, state.pace)),
                      onPressed: () async {
                        final cubit = context.read<SpeedrunCubit>();
                        final choice = await showPaceSheet(
                          context,
                          current: state.pace,
                        );
                        final time = choice?.time;
                        if (time != null) await cubit.choosePace(time);
                      },
                    ),
                  ),
                ),
                if (state.inProgress.isNotEmpty) ...[
                  section(l10n.speedrunContinue),
                  for (final summary in state.inProgress)
                    _Card(summary: summary, ongoing: true),
                ],
                for (final kind in SpeedrunKind.values)
                  // Modalidade sem speedrun não ganha título.
                  if (all.any((summary) => summary.speedrun.kind == kind)) ...[
                    section(switch (kind) {
                      SpeedrunKind.rung => l10n.speedrunRungSection,
                      SpeedrunKind.ending => l10n.speedrunEndingSection,
                      SpeedrunKind.exercises => l10n.speedrunExercisesSection,
                      SpeedrunKind.full => l10n.speedrunFullSection,
                    }),
                    for (final summary in all)
                      if (summary.speedrun.kind == kind)
                        _Card(summary: summary),
                  ],
              ],
            ),
    );
  }

  void _showHelp(BuildContext context) {
    final theme = Theme.of(context);
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                context.l10n.speedrunTitle,
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                context.l10n.speedrunIntro,
                key: SpeedrunKeys.helpText,
                style: theme.textTheme.bodyLarge,
              ),
              const SizedBox(height: 8),
              Text(
                context.l10n.speedrunPauseHint,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Um speedrun num cartão: a imagem, o nome, as etapas e o melhor tempo (ou,
/// em andamento, em que etapa está e o ritmo).
class _Card extends StatelessWidget {
  const _Card({required this.summary, this.ongoing = false});

  final SpeedrunSummary summary;
  final bool ongoing;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final characters = context.select(
      (SpeedrunCubit cubit) => cubit.state.characters,
    );
    final speedrun = summary.speedrun;
    final best = summary.records.best;
    final run = summary.ongoing;
    return Card(
      key: ongoing
          ? SpeedrunKeys.inProgress(speedrun.id)
          : SpeedrunKeys.item(speedrun.id),
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      color: ongoing ? colors.primaryContainer : colors.surfaceContainerLow,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () async {
          final cubit = context.read<SpeedrunCubit>();
          await context.push(
            ongoing && run != null
                ? Routes.speedrunAttempt(speedrun.id, run.attempt.id)
                : Routes.speedrun(speedrun.id),
          );
          if (context.mounted) await cubit.load();
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              SpeedrunPicture(speedrun, characters: characters),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      speedrunName(l10n, characters, speedrun),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      ongoing && run != null
                          ? '${l10n.speedrunStageOf(run.currentStage + 1, speedrun.stages.length)}'
                                ' · ${paceShort(l10n, speedrun.time)}'
                          : l10n.speedrunStagesCount(speedrun.stages.length),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (ongoing)
                Icon(Icons.play_circle_fill, size: 32, color: colors.primary)
              else
                Text(
                  best == null
                      ? l10n.speedrunNoRecord
                      : RunTimeFormat.format(best),
                  key: SpeedrunKeys.itemBest(speedrun.id),
                  style:
                      (best == null
                              ? theme.textTheme.bodySmall
                              : theme.textTheme.titleMedium)
                          ?.copyWith(
                            fontWeight: best == null ? null : FontWeight.w800,
                            color: best == null
                                ? colors.onSurfaceVariant
                                : colors.primary,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

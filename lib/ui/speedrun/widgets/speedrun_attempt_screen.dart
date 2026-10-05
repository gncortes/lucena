import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/models/speedrun.dart';
import '../../../domain/use_cases/clock_format.dart';
import '../../../routing/routes.dart';
import '../../core/keys/speedrun_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../journey/widgets/journey_ui.dart';
import '../view_models/speedrun_cubit.dart';
import 'speedrun_ui.dart';
import '../../core/widgets/scroll_padding.dart';

/// Uma tentativa: as etapas com o tempo e as derrotas de cada uma, o total e
/// o botão da próxima etapa. No fim, a diferença para o recorde.
class SpeedrunAttemptScreen extends StatelessWidget {
  const SpeedrunAttemptScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final state = context.watch<SpeedrunCubit>().state;
    final summary = state.selected;
    final run = state.run;
    if (summary == null || run == null) {
      return Scaffold(
        key: SpeedrunKeys.attemptScreen,
        appBar: AppBar(title: Text(l10n.speedrunTitle)),
        body: state.all != null
            ? null
            : const Center(child: CircularProgressIndicator()),
      );
    }
    final speedrun = summary.speedrun;
    final tabular = theme.textTheme.titleMedium?.copyWith(
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    return Scaffold(
      key: SpeedrunKeys.attemptScreen,
      appBar: AppBar(
        title: SpeedrunTitle(speedrun, style: theme.textTheme.titleLarge),
      ),
      body: ListView(
        padding: scrollPadding(context),
        children: [
          if (run.completed)
            _Finish(run: run, previousBest: state.previousBest),
          if (run.abandoned)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                l10n.speedrunAbandoned,
                key: SpeedrunKeys.abandoned,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ),
          for (var index = 0; index < speedrun.stages.length; index++)
            _stageTile(context, speedrun, run, index, tabular),
          const Divider(),
          ListTile(
            title: Text(l10n.speedrunTotal, style: theme.textTheme.titleMedium),
            trailing: Text(
              RunTimeFormat.format(run.total),
              key: SpeedrunKeys.total,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          if (run.inProgress) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: FilledButton.icon(
                key: SpeedrunKeys.play,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
                icon: const Icon(Icons.play_arrow_rounded),
                label: Text(
                  state.gameOngoing
                      ? l10n.speedrunContinueGame
                      : run.stages[run.currentStage].losses > 0
                      ? l10n.speedrunRetryStage(run.currentStage + 1)
                      : l10n.speedrunPlayStage(run.currentStage + 1),
                ),
                onPressed: () => _play(context, speedrun, run, state),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Text(
                l10n.speedrunPauseHint,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: TextButton.icon(
                key: SpeedrunKeys.abandon,
                icon: const Icon(Icons.close),
                label: Text(l10n.speedrunAbandon),
                onPressed: () => _confirmAbandon(context),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _stageTile(
    BuildContext context,
    Speedrun speedrun,
    SpeedrunRun run,
    int index,
    TextStyle? style,
  ) {
    final l10n = context.l10n;
    final colors = Theme.of(context).colorScheme;
    final stage = run.stages[index];
    final current = run.inProgress && index == run.currentStage;
    final played = stage.done || stage.losses > 0;
    return ListTile(
      key: SpeedrunKeys.stage(index),
      dense: true,
      selected: current,
      leading: stage.done
          ? Icon(Icons.check_circle, color: colors.primary)
          : current
          ? Icon(Icons.play_circle_outline, color: colors.primary)
          : Icon(Icons.radio_button_unchecked, color: colors.outline),
      title: Text(opponentRefLabel(l10n, speedrun.stages[index].opponent)),
      subtitle: stage.losses == 0
          ? null
          : Text(
              l10n.speedrunLosses(stage.losses),
              key: SpeedrunKeys.stageLosses(index),
              style: TextStyle(color: colors.error),
            ),
      trailing: Text(
        played ? RunTimeFormat.format(stage.time) : '',
        key: SpeedrunKeys.stageTime(index),
        style: style,
      ),
    );
  }

  Future<void> _play(
    BuildContext context,
    Speedrun speedrun,
    SpeedrunRun run,
    SpeedrunState state,
  ) async {
    final cubit = context.read<SpeedrunCubit>();
    // A etapa que ficou no tabuleiro continua de onde parou.
    final route = state.gameOngoing
        ? Routes.freeBoard
        : Routes.challengeGame(
            speedrun.stages[run.currentStage],
            speedrunId: speedrun.id,
            attemptId: run.attempt.id,
            stage: run.currentStage,
          );
    await context.push(route);
    if (context.mounted) {
      await cubit.load(speedrunId: speedrun.id, attemptId: run.attempt.id);
    }
  }

  Future<void> _confirmAbandon(BuildContext context) async {
    final l10n = context.l10n;
    final cubit = context.read<SpeedrunCubit>();
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 12,
            children: [
              Text(
                l10n.speedrunAbandonQuestion,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              FilledButton(
                key: SpeedrunKeys.abandonConfirm,
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                  foregroundColor: Theme.of(context).colorScheme.onError,
                ),
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(l10n.speedrunAbandon),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(l10n.speedrunKeepGoing),
              ),
            ],
          ),
        ),
      ),
    );
    if (confirmed ?? false) await cubit.abandon();
  }
}

/// O fim da tentativa: novo recorde ou a diferença para o recorde.
class _Finish extends StatelessWidget {
  const _Finish({required this.run, required this.previousBest});

  final SpeedrunRun run;
  final Duration? previousBest;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final previous = previousBest;
    final record = previous == null || run.total < previous;
    return Card(
      margin: const EdgeInsets.all(16),
      color: record ? colors.primaryContainer : colors.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              record ? Icons.emoji_events : Icons.flag,
              size: 32,
              color: record
                  ? colors.onPrimaryContainer
                  : colors.onSecondaryContainer,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 4,
                children: [
                  Text(
                    record ? l10n.speedrunNewRecord : l10n.speedrunFinished,
                    key: record ? SpeedrunKeys.newRecord : null,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (previous != null)
                    Text(
                      l10n.speedrunVersusRecord(
                        RunTimeFormat.difference(run.total - previous),
                        RunTimeFormat.format(previous),
                      ),
                      key: SpeedrunKeys.recordDifference,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

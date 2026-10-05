import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/models/speedrun.dart';
import '../../../domain/use_cases/clock_format.dart';
import '../../../routing/routes.dart';
import '../../core/keys/speedrun_keys.dart';
import '../../catalog/widgets/catalog_ui.dart';
import '../../core/l10n/l10n.dart';
import '../../core/widgets/character_avatar.dart';
import '../../core/widgets/goal_style.dart';
import '../../core/widgets/position_board.dart';
import '../../journey/widgets/journey_ui.dart';
import '../view_models/speedrun_cubit.dart';
import 'speedrun_ui.dart';
import '../../core/widgets/scroll_padding.dart';

/// Uma tentativa: o total e o progresso no alto, a etapa da vez em destaque
/// (com o tabuleiro, o final e o adversário), as etapas com o tempo de cada
/// uma e, no fim, a diferença para o recorde. "Desistir" fica no menu.
class SpeedrunAttemptScreen extends StatelessWidget {
  const SpeedrunAttemptScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
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
    final characters = state.characters;
    final total = speedrun.stages.length;
    final done = run.stages.where((stage) => stage.done).length;
    return Scaffold(
      key: SpeedrunKeys.attemptScreen,
      appBar: AppBar(
        title: Text(speedrunName(l10n, characters, speedrun)),
        actions: [
          if (run.inProgress)
            PopupMenuButton<void>(
              key: SpeedrunKeys.menu,
              itemBuilder: (context) => [
                PopupMenuItem(
                  key: SpeedrunKeys.abandon,
                  onTap: () => _confirmAbandon(context),
                  child: Text(l10n.speedrunAbandon),
                ),
              ],
            ),
        ],
      ),
      body: ListView(
        padding: scrollPadding(context),
        children: [
          // O total grande e quanto falta.
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.speedrunTotal,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
                Text(
                  RunTimeFormat.format(run.total),
                  key: SpeedrunKeys.total,
                  style: theme.textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: total == 0 ? 0 : done / total,
                    minHeight: 8,
                    backgroundColor: colors.surfaceContainerHighest,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.speedrunStageOf(
                    run.inProgress ? run.currentStage + 1 : done,
                    total,
                  ),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (run.completed)
            _Finish(run: run, previousBest: state.previousBest),
          if (run.abandoned)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                l10n.speedrunAbandoned,
                key: SpeedrunKeys.abandoned,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: colors.error,
                ),
              ),
            ),
          if (run.inProgress)
            _Current(
              speedrun: speedrun,
              run: run,
              state: state,
              onPlay: () => _play(context, speedrun, run, state),
            ),
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(16, 20, 16, 4),
            child: Text(
              l10n.speedrunStages,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          for (var index = 0; index < speedrun.stages.length; index++)
            _stageTile(context, speedrun, run, index),
          if (run.inProgress)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Text(
                l10n.speedrunPauseHint,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _stageTile(
    BuildContext context,
    Speedrun speedrun,
    SpeedrunRun run,
    int index,
  ) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final characters = context.read<SpeedrunCubit>().state.characters;
    final stage = run.stages[index];
    final challenge = speedrun.stages[index];
    final current = run.inProgress && index == run.currentStage;
    final played = stage.done || stage.losses > 0;
    return ListTile(
      key: SpeedrunKeys.stage(index),
      dense: true,
      selected: current,
      leading: stage.done
          ? Icon(Icons.check_circle, color: ChangeColors.of(context, up: true))
          : CircleAvatar(
              radius: 13,
              backgroundColor: current
                  ? colors.primary
                  : colors.surfaceContainerHighest,
              child: Text(
                (index + 1).toString(),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: current ? colors.onPrimary : colors.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
      title: Text(
        endgameName(l10n, challenge.position.subcategory),
        style: TextStyle(color: played || current ? null : colors.outline),
      ),
      subtitle: Text(opponentName(l10n, characters, challenge.opponent)),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            played ? RunTimeFormat.format(stage.time) : '',
            key: SpeedrunKeys.stageTime(index),
            style: theme.textTheme.titleMedium?.copyWith(
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          if (stage.losses > 0)
            Text(
              l10n.speedrunLosses(stage.losses),
              key: SpeedrunKeys.stageLosses(index),
              style: theme.textTheme.labelSmall?.copyWith(color: colors.error),
            ),
        ],
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

/// A etapa da vez em destaque: a posição, o nome do final, o adversário e o
/// botão de jogar (ou continuar a partida).
class _Current extends StatelessWidget {
  const _Current({
    required this.speedrun,
    required this.run,
    required this.state,
    required this.onPlay,
  });

  final Speedrun speedrun;
  final SpeedrunRun run;
  final SpeedrunState state;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final index = run.currentStage;
    final challenge = speedrun.stages[index];
    final character = opponentCharacter(state.characters, challenge.opponent);
    return Card(
      key: SpeedrunKeys.current,
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      color: colors.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.speedrunNow,
              style: theme.textTheme.labelLarge?.copyWith(
                color: colors.onSecondaryContainer,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                PositionBoard(fen: challenge.position.fen, size: 112),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        endgameName(l10n, challenge.position.subcategory),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: colors.onSecondaryContainer,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          if (character != null) ...[
                            CharacterAvatar(character: character, size: 28),
                            const SizedBox(width: 8),
                          ],
                          Flexible(
                            child: Text(
                              opponentName(
                                l10n,
                                state.characters,
                                challenge.opponent,
                              ),
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colors.onSecondaryContainer,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              key: SpeedrunKeys.play,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
              icon: const Icon(Icons.play_arrow_rounded),
              label: Text(
                state.gameOngoing
                    ? l10n.speedrunContinueGame
                    : run.stages[index].losses > 0
                    ? l10n.speedrunRetryStage(index + 1)
                    : l10n.speedrunPlayStage(index + 1),
              ),
              onPressed: onPlay,
            ),
          ],
        ),
      ),
    );
  }
}

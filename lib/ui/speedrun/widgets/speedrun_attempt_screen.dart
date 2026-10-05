import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../../../domain/models/speedrun.dart';
import '../../core/keys/speedrun_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/l10n/run_time.dart';
import '../../core/pace/pace_ui.dart';
import '../../core/widgets/goal_style.dart';
import '../../core/widgets/run_clock.dart';
import '../../core/widgets/scroll_padding.dart';
import '../../core/widgets/step_progress.dart';
import '../view_models/speedrun_cubit.dart';
import 'speedrun_ui.dart';

/// O resumo de uma tentativa terminada (concluída ou abandonada): como ela
/// acabou, o tempo total e, etapa por etapa, o adversário, o tempo e as
/// derrotas. É onde o speedrun termina e o que o histórico abre.
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
    final locale = Localizations.localeOf(context).toString();
    final endedAt = run.finishedAt ?? run.attempt.abandonedAt;
    return Scaffold(
      key: SpeedrunKeys.attemptScreen,
      appBar: AppBar(title: Text(speedrunName(l10n, characters, speedrun))),
      body: ListView(
        padding: scrollPadding(context),
        children: [
          if (run.completed)
            _Finish(run: run, previousBest: state.previousBest)
          else
            _Stopped(run: run, total: total),
          // O total grande, com o ritmo, as derrotas e quando foi.
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.speedrunTotal,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 6),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: RunClock(
                    run.total,
                    large: true,
                    textKey: SpeedrunKeys.total,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  [
                    paceLabel(l10n, speedrun.time),
                    l10n.speedrunLosses(run.losses),
                    if (endedAt != null)
                      DateFormat.MMMd(locale)
                          .add_Hm()
                          .format(endedAt.toLocal()),
                  ].join(' · '),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                StepProgress(total: total, value: done.toDouble()),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(16, 24, 16, 8),
            child: Text(
              l10n.speedrunStages,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          for (final (index, stage) in run.stages.indexed)
            SpeedrunStageRow(
              key: SpeedrunKeys.stage(index),
              index: index,
              stage: speedrun.stages[index],
              speedrun: speedrun,
              last: index == total - 1,
              losses: stage.losses,
              status: stage.done
                  ? SpeedrunStageStatus.done
                  : index == run.currentStage && stage.losses > 0
                  // A etapa em que a tentativa parou.
                  ? SpeedrunStageStatus.idle
                  : SpeedrunStageStatus.ahead,
              trailing: stage.done || stage.losses > 0
                  ? RunClock(stage.time, textKey: SpeedrunKeys.stageTime(index))
                  : null,
            ),
        ],
      ),
    );
  }
}

/// A tentativa parou no meio: abandonada, sem recorde.
class _Stopped extends StatelessWidget {
  const _Stopped({required this.run, required this.total});

  final SpeedrunRun run;
  final int total;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final stage = (run.currentStage + 1).clamp(1, total);
    return Card(
      margin: const EdgeInsets.all(16),
      color: colors.surfaceContainerHigh,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.flag_outlined, size: 32, color: colors.outline),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 4,
                children: [
                  Text(
                    l10n.speedrunStoppedAt(stage, total),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    l10n.speedrunAbandoned,
                    key: SpeedrunKeys.abandoned,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
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
    final color = record ? colors.onPrimaryContainer : colors.onSurface;
    return Card(
      margin: const EdgeInsets.all(16),
      color: record ? colors.primaryContainer : colors.surfaceContainerHigh,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // O troféu entra crescendo, para o recorde ter o seu momento.
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.4, end: 1),
              duration: MediaQuery.disableAnimationsOf(context)
                  ? Duration.zero
                  : const Duration(milliseconds: 500),
              curve: Curves.easeOutBack,
              builder: (context, value, child) =>
                  Transform.scale(scale: value, child: child),
              child: Icon(
                record ? Icons.emoji_events : Icons.flag_rounded,
                size: 36,
                color: record
                    ? colors.onPrimaryContainer
                    : ChangeColors.of(context, up: true),
              ),
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
                      color: color,
                    ),
                  ),
                  if (previous != null)
                    Text(
                      l10n.speedrunVersusRecord(
                        runTimeDifference(context, run.total - previous),
                        runTime(context, previous),
                      ),
                      key: SpeedrunKeys.recordDifference,
                      style: theme.textTheme.bodyMedium?.copyWith(color: color),
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

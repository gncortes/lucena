import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../../../domain/models/pace.dart';
import '../../../domain/models/speedrun.dart';
import '../../../routing/routes.dart';
import '../../core/keys/speedrun_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/l10n/run_time.dart';
import '../../core/pace/pace_ui.dart';
import '../../core/widgets/step_progress.dart';
import '../../core/widgets/run_clock.dart';
import '../../core/widgets/scroll_padding.dart';
import '../view_models/speedrun_cubit.dart';
import 'speedrun_ui.dart';

/// Um speedrun antes de começar: quem ou o que é, o ritmo, o melhor tempo (ou
/// o convite para o primeiro), a trilha das etapas com o melhor tempo de cada
/// uma e o histórico das tentativas. "Começar" fica fixo embaixo.
class SpeedrunScreen extends StatelessWidget {
  const SpeedrunScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final state = context.watch<SpeedrunCubit>().state;
    final summary = state.selected;
    if (summary == null) {
      return Scaffold(
        key: SpeedrunKeys.screen,
        appBar: AppBar(title: Text(l10n.speedrunTitle)),
        body: state.all != null
            ? null
            : const Center(child: CircularProgressIndicator()),
      );
    }
    final characters = state.characters;
    final speedrun = summary.speedrun;
    final records = summary.records;
    final ongoing = summary.ongoing;
    final best = records.best;
    return Scaffold(
      key: SpeedrunKeys.screen,
      appBar: AppBar(title: Text(speedrunName(l10n, characters, speedrun))),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: ongoing == null
              ? FilledButton.icon(
                  key: SpeedrunKeys.start,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                  ),
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: Text(l10n.speedrunStartStages(speedrun.stages.length)),
                  onPressed: () => _start(context, speedrun),
                )
              // O app fechou no meio de uma etapa: ela continua de onde
              // parou.
              : FilledButton.icon(
                  key: SpeedrunKeys.resume,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                  ),
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: Text(l10n.speedrunContinueGame),
                  onPressed: () async {
                    final cubit = context.read<SpeedrunCubit>();
                    await context.push(Routes.freeBoard);
                    if (context.mounted) {
                      await cubit.load(speedrunId: speedrun.id);
                    }
                  },
                ),
        ),
      ),
      body: ListView(
        padding: scrollPadding(context),
        children: [
          // Quem ou o que é, as etapas e o ritmo.
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Row(
              children: [
                SpeedrunPicture(speedrun, characters: characters, size: 72),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        speedrunName(l10n, characters, speedrun),
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        l10n.speedrunStagesCount(speedrun.stages.length),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        key: SpeedrunKeys.paceBadge,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: colors.secondaryContainer,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // O ícone da categoria: raio, chama, relógio.
                            Icon(
                              paceIcon(PaceCategory.of(speedrun.time)),
                              size: 16,
                              color: colors.onSecondaryContainer,
                            ),
                            const SizedBox(width: 4),
                            // Rótulo longo (outros idiomas) quebra a linha.
                            Flexible(
                              child: Text(
                                paceLabel(l10n, speedrun.time),
                                style: theme.textTheme.labelLarge?.copyWith(
                                  color: colors.onSecondaryContainer,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // O melhor tempo em destaque; sem ele, o convite.
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: best == null
                ? Row(
                    children: [
                      Icon(Icons.flag_outlined, color: colors.outline),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          l10n.speedrunFirstTimeInvite,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  )
                : Card(
                    margin: EdgeInsets.zero,
                    color: colors.primaryContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(
                            Icons.emoji_events,
                            color: colors.onPrimaryContainer,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              l10n.speedrunBest,
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: colors.onPrimaryContainer,
                              ),
                            ),
                          ),
                          RunClock(best, textKey: SpeedrunKeys.best),
                        ],
                      ),
                    ),
                  ),
          ),
          _header(context, l10n.speedrunStages),
          // Em andamento, o progresso por passos: uma barra por etapa.
          if (ongoing != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: StepProgress(
                key: SpeedrunKeys.progress,
                total: speedrun.stages.length,
                value: ongoing.currentStage.toDouble(),
              ),
            ),
          // A ordem das etapas, uma embaixo da outra: quem o jogador
          // enfrenta, até onde a tentativa em andamento chegou e o melhor
          // tempo de cada etapa.
          for (final (index, stage) in speedrun.stages.indexed)
            SpeedrunStageRow(
              key: SpeedrunKeys.stageCard(index),
              index: index,
              stage: stage,
              speedrun: speedrun,
              last: index == speedrun.stages.length - 1,
              status: ongoing == null
                  ? SpeedrunStageStatus.idle
                  : index < ongoing.currentStage
                  ? SpeedrunStageStatus.done
                  : index == ongoing.currentStage
                  ? SpeedrunStageStatus.current
                  : SpeedrunStageStatus.ahead,
              // O melhor tempo da etapa, em qualquer tentativa concluída.
              trailing: switch (records.bestStages[index]) {
                final best? => RunClock(
                  best,
                  textKey: SpeedrunKeys.stageRecord(index),
                ),
                null => null,
              },
            ),
          if (records.completed.isNotEmpty || summary.abandoned.isNotEmpty) ...[
            _header(context, l10n.speedrunHistory),
            ..._history(context, speedrun, [
              ...records.completed,
              ...summary.abandoned,
            ]),
          ],
        ],
      ),
    );
  }

  // "Começar": abre a primeira etapa, no ritmo escolhido na lista. Daí em
  // diante a partida segue sozinha de uma etapa para a outra.
  Future<void> _start(BuildContext context, Speedrun speedrun) async {
    final cubit = context.read<SpeedrunCubit>();
    final started = await cubit.startWith(speedrun.time);
    if (started == null || !context.mounted) return;
    final (paced, attempt) = started;
    await context.push(
      Routes.challengeGame(
        paced.stages.first,
        speedrunId: paced.id,
        attemptId: attempt,
        stage: 0,
      ),
    );
    if (context.mounted) await cubit.load(speedrunId: speedrun.id);
  }

  Widget _header(BuildContext context, String text) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(16, 24, 16, 8),
      child: Text(
        text,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  // As tentativas terminadas, da mais recente para a mais antiga, com o
  // título de cada mês: as concluídas com o tempo, as abandonadas com a
  // etapa em que pararam.
  List<Widget> _history(
    BuildContext context,
    Speedrun speedrun,
    List<SpeedrunRun> runs,
  ) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toString();
    final month = DateFormat.yMMMM(locale);
    final date = DateFormat.MMMd(locale).add_Hm();
    DateTime endOf(SpeedrunRun run) =>
        (run.finishedAt ?? run.attempt.abandonedAt!).toLocal();
    final sorted = [...runs]..sort((a, b) => endOf(b).compareTo(endOf(a)));
    final children = <Widget>[];
    String? current;
    var months = 0;
    for (final (index, run) in sorted.indexed) {
      final endedAt = endOf(run);
      final label = month.format(endedAt);
      if (label != current) {
        current = label;
        children.add(
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(16, 8, 16, 4),
            child: Text(
              label,
              key: SpeedrunKeys.month(months++),
              style: theme.textTheme.titleSmall?.copyWith(
                color: colors.primary,
              ),
            ),
          ),
        );
      }
      final total = speedrun.stages.length;
      children.add(
        Card(
          key: SpeedrunKeys.run(index),
          margin: const EdgeInsets.fromLTRB(16, 4, 16, 4),
          color: colors.surfaceContainerLow,
          clipBehavior: Clip.antiAlias,
          child: ListTile(
            // Os detalhes da tentativa: o tempo e as derrotas de cada etapa.
            onTap: () => context.push(
              Routes.speedrunAttempt(speedrun.id, run.attempt.id),
            ),
            trailing: Icon(
              Directionality.of(context) == TextDirection.rtl
                  ? Icons.chevron_left
                  : Icons.chevron_right,
              color: colors.onSurfaceVariant,
            ),
            leading: Icon(
              run.completed ? Icons.flag_rounded : Icons.flag_outlined,
              color: run.completed ? colors.primary : colors.outline,
            ),
            title: Text(
              run.completed
                  ? runTime(context, run.total)
                  : l10n.speedrunStoppedAt(
                      math.min(run.currentStage + 1, total),
                      total,
                    ),
              style: run.completed
                  ? theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    )
                  : theme.textTheme.titleSmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
            ),
            subtitle: Text(
              '${date.format(endedAt)} · ${l10n.speedrunLosses(run.losses)}',
            ),
          ),
        ),
      );
    }
    return children;
  }
}

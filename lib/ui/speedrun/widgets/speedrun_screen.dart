import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../../../domain/models/journey.dart';
import '../../../domain/models/speedrun.dart';
import '../../../domain/use_cases/clock_format.dart';
import '../../../routing/routes.dart';
import '../../catalog/widgets/catalog_ui.dart';
import '../../core/keys/speedrun_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/pace/pace_ui.dart';
import '../../core/widgets/goal_style.dart';
import '../../core/widgets/step_progress.dart';
import '../../core/widgets/scroll_padding.dart';
import '../../journey/widgets/journey_ui.dart';
import '../../journey/widgets/trail_widgets.dart';
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
              : FilledButton.icon(
                  key: SpeedrunKeys.resume,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                  ),
                  icon: const Icon(Icons.timelapse),
                  label: Text(
                    l10n.speedrunResume(
                      ongoing.currentStage + 1,
                      speedrun.stages.length,
                    ),
                  ),
                  onPressed: () async {
                    final cubit = context.read<SpeedrunCubit>();
                    await context.push(
                      Routes.speedrunAttempt(speedrun.id, ongoing.attempt.id),
                    );
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
                            Icon(
                              Icons.timer_outlined,
                              size: 16,
                              color: colors.onSecondaryContainer,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              paceLabel(l10n, speedrun.time),
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: colors.onSecondaryContainer,
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
                          Text(
                            RunTimeFormat.format(best),
                            key: SpeedrunKeys.best,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              color: colors.onPrimaryContainer,
                              fontWeight: FontWeight.w800,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
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
            _StageRow(
              index: index,
              stage: stage,
              speedrun: speedrun,
              best: records.bestStages[index],
              last: index == speedrun.stages.length - 1,
              status: ongoing == null
                  ? _StageStatus.idle
                  : index < ongoing.currentStage
                  ? _StageStatus.done
                  : index == ongoing.currentStage
                  ? _StageStatus.current
                  : _StageStatus.ahead,
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

  // "Começar": escolhe o ritmo e abre a tentativa nele.
  Future<void> _start(BuildContext context, Speedrun speedrun) async {
    final cubit = context.read<SpeedrunCubit>();
    final choice = await showPaceSheet(context, current: speedrun.time);
    final time = choice?.time;
    if (time == null || !context.mounted) return;
    final started = await cubit.startWith(time);
    if (started == null || !context.mounted) return;
    final (id, attempt) = started;
    await context.push(Routes.speedrunAttempt(id, attempt));
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
                  ? RunTimeFormat.format(run.total)
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

enum _StageStatus {
  /// Sem tentativa em andamento.
  idle,
  done,
  current,
  ahead,
}

/// Uma etapa na trilha, no formato da Jornada: o retrato do adversário num
/// círculo, ligado aos vizinhos por uma linha, com o nome, a etapa e o melhor
/// tempo dela. Com uma tentativa em andamento, as etapas vencidas levam o
/// selo de feito e a da vez fica maior e em destaque; a última é o chefe
/// final.
class _StageRow extends StatelessWidget {
  const _StageRow({
    required this.index,
    required this.stage,
    required this.speedrun,
    required this.best,
    required this.last,
    required this.status,
  });

  final int index;
  final Challenge stage;
  final Speedrun speedrun;
  final Duration? best;
  final bool last;
  final _StageStatus status;

  // O meio da coluna dos retratos, por onde passa a linha.
  static const _railX = 52.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final l10n = context.l10n;
    final characters = context.select(
      (SpeedrunCubit cubit) => cubit.state.characters,
    );
    final best = this.best;
    final current = status == _StageStatus.current;
    final done = status == _StageStatus.done;
    final ahead = status == _StageStatus.ahead;
    final size = current ? 72.0 : 56.0;
    final height = current ? 108.0 : 84.0;
    final doneColor = ChangeColors.of(context, up: true);
    final first = index == 0;
    return SizedBox(
      key: SpeedrunKeys.stageCard(index),
      height: height,
      child: Stack(
        children: [
          // A linha da trilha, atrás dos retratos: só a metade de baixo na
          // primeira etapa e só a de cima na última. Até a etapa da vez, ela
          // vem na cor de feito.
          PositionedDirectional(
            start: _railX - 2,
            width: 4,
            top: first ? height / 2 : 0,
            bottom: height / 2,
            child: ColoredBox(
              color: done || current ? doneColor : colors.outlineVariant,
            ),
          ),
          if (!last)
            PositionedDirectional(
              start: _railX - 2,
              width: 4,
              top: height / 2,
              bottom: 0,
              child: ColoredBox(
                color: done ? doneColor : colors.outlineVariant,
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                SizedBox(
                  width: 72,
                  child: Center(
                    child: TrailPortrait(
                      character: opponentCharacter(characters, stage.opponent),
                      size: size,
                      locked: false,
                      completed: done,
                      current: current,
                      doneColor: doneColor,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        opponentName(l10n, characters, stage.opponent),
                        style:
                            (current
                                    ? theme.textTheme.titleLarge
                                    : theme.textTheme.titleMedium)
                                ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: ahead ? colors.onSurfaceVariant : null,
                                ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        [
                          l10n.speedrunStageOf(
                            index + 1,
                            speedrun.stages.length,
                          ),
                          // Quando o final muda de etapa para etapa, o nome
                          // dele vem junto.
                          if (speedrun.kind != SpeedrunKind.ending)
                            endgameName(l10n, stage.position.subcategory),
                        ].join(' · '),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                      if (current || last) ...[
                        const SizedBox(height: 6),
                        TrailBadge(
                          text: current ? l10n.speedrunNow : l10n.journeyBoss,
                          color: current ? colors.primary : colors.tertiary,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  best == null ? '' : RunTimeFormat.format(best),
                  key: SpeedrunKeys.stageRecord(index),
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: colors.primary,
                    fontWeight: FontWeight.w800,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

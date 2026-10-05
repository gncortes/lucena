import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../domain/models/journey.dart';
import '../../../domain/models/speedrun.dart';
import '../../../domain/use_cases/clock_format.dart';
import '../../../routing/routes.dart';
import '../../catalog/widgets/catalog_ui.dart';
import '../../core/keys/speedrun_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/pace/pace_ui.dart';
import '../../core/widgets/position_board.dart';
import '../../core/widgets/scroll_padding.dart';
import '../../journey/widgets/journey_ui.dart';
import '../view_models/speedrun_cubit.dart';
import 'speedrun_ui.dart';

/// Um speedrun antes de começar: quem ou o que é, o ritmo, o melhor tempo (ou
/// o convite para o primeiro), as etapas em miniatura com o melhor tempo de
/// cada uma e o histórico. "Começar" fica fixo embaixo.
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Três por linha, cada uma com a altura do conteúdo.
                const gap = 10.0;
                final width = (constraints.maxWidth - gap * 2) / 3;
                return Wrap(
                  spacing: gap,
                  runSpacing: gap,
                  children: [
                    for (final (index, stage) in speedrun.stages.indexed)
                      SizedBox(
                        width: width,
                        child: _StageCard(
                          index: index,
                          stage: stage,
                          speedrun: speedrun,
                          best: records.bestStages[index],
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
          if (records.completed.isNotEmpty) ...[
            _header(context, l10n.speedrunHistory),
            ..._history(context, records.completed),
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

  // Os tempos das tentativas concluídas, da mais recente para a mais antiga,
  // com o título de cada mês.
  List<Widget> _history(BuildContext context, List<SpeedrunRun> runs) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toString();
    final month = DateFormat.yMMMM(locale);
    final date = DateFormat.MMMd(locale).add_Hm();
    final children = <Widget>[];
    String? current;
    var months = 0;
    for (final (index, run) in runs.indexed) {
      final finishedAt = run.finishedAt!.toLocal();
      final label = month.format(finishedAt);
      if (label != current) {
        current = label;
        children.add(
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(16, 8, 16, 4),
            child: Text(
              label,
              key: SpeedrunKeys.month(months++),
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
          ),
        );
      }
      children.add(
        Card(
          key: SpeedrunKeys.run(index),
          margin: const EdgeInsets.fromLTRB(16, 4, 16, 4),
          color: theme.colorScheme.surfaceContainerLow,
          child: ListTile(
            leading: const Icon(Icons.flag_outlined),
            title: Text(
              RunTimeFormat.format(run.total),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            subtitle: Text(
              '${date.format(finishedAt)} · ${l10n.speedrunLosses(run.losses)}',
            ),
          ),
        ),
      );
    }
    return children;
  }
}

/// Uma etapa na grade: o número, a posição em miniatura, o nome do final (e
/// o adversário, quando muda de etapa para etapa) e o melhor tempo dela.
class _StageCard extends StatelessWidget {
  const _StageCard({
    required this.index,
    required this.stage,
    required this.speedrun,
    required this.best,
  });

  final int index;
  final Challenge stage;
  final Speedrun speedrun;
  final Duration? best;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final l10n = context.l10n;
    final characters = context.select(
      (SpeedrunCubit cubit) => cubit.state.characters,
    );
    final best = this.best;
    return Card(
      key: SpeedrunKeys.stageCard(index),
      margin: EdgeInsets.zero,
      color: colors.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LayoutBuilder(
              builder: (context, constraints) => Stack(
                children: [
                  PositionBoard(
                    fen: stage.position.fen,
                    size: constraints.maxWidth,
                    radius: 4,
                  ),
                  PositionedDirectional(
                    top: 2,
                    start: 2,
                    child: CircleAvatar(
                      radius: 11,
                      backgroundColor: colors.primary,
                      child: Text(
                        (index + 1).toString(),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colors.onPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              speedrun.kind == SpeedrunKind.ending
                  ? opponentName(l10n, characters, stage.opponent)
                  : endgameName(l10n, stage.position.subcategory),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              best == null ? '' : RunTimeFormat.format(best),
              key: SpeedrunKeys.stageRecord(index),
              style: theme.textTheme.labelMedium?.copyWith(
                color: colors.primary,
                fontWeight: FontWeight.w700,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'dart:math' as math;

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
import '../../core/widgets/character_avatar.dart';
import '../../core/widgets/position_board.dart';
import '../../core/widgets/scroll_padding.dart';
import '../../journey/widgets/journey_ui.dart';
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
          child: ListTile(
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

/// Uma etapa na trilha: o número, quem o jogador enfrenta (ou o final, quando
/// o adversário é sempre o mesmo) e o melhor tempo dela. Com uma tentativa em
/// andamento, as etapas vencidas ganham o selo e a da vez fica em destaque.
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

  static const _avatar = 44.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final l10n = context.l10n;
    final characters = context.select(
      (SpeedrunCubit cubit) => cubit.state.characters,
    );
    final best = this.best;
    final byOpponent = speedrun.kind == SpeedrunKind.ending;
    final character = opponentCharacter(characters, stage.opponent);
    final current = status == _StageStatus.current;
    final done = status == _StageStatus.done;
    final line = done ? colors.primary : colors.outlineVariant;
    return Padding(
      key: SpeedrunKeys.stageCard(index),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // O retrato (ou a posição) e a linha que desce até a próxima.
            Column(
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    shape: byOpponent ? BoxShape.circle : BoxShape.rectangle,
                    borderRadius: byOpponent ? null : BorderRadius.circular(6),
                    border: Border.all(
                      color: current || done
                          ? colors.primary
                          : colors.outlineVariant,
                      width: current ? 3 : 2,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(2),
                    child: byOpponent && character != null
                        ? ClipOval(
                            child: CharacterAvatar(
                              character: character,
                              size: _avatar,
                            ),
                          )
                        : PositionBoard(
                            fen: stage.position.fen,
                            size: _avatar,
                            radius: 4,
                          ),
                  ),
                ),
                if (!last)
                  Expanded(
                    child: Container(
                      width: 2,
                      constraints: const BoxConstraints(minHeight: 14),
                      color: line,
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(top: 6, bottom: last ? 0 : 18),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            byOpponent
                                ? opponentName(l10n, characters, stage.opponent)
                                : endgameName(l10n, stage.position.subcategory),
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: status == _StageStatus.ahead
                                  ? colors.onSurfaceVariant
                                  : null,
                            ),
                          ),
                          Text(
                            current
                                ? l10n.speedrunNow
                                : l10n.speedrunStageOf(
                                    index + 1,
                                    speedrun.stages.length,
                                  ),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: current
                                  ? colors.primary
                                  : colors.onSurfaceVariant,
                              fontWeight: current ? FontWeight.w700 : null,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (done)
                      Padding(
                        padding: const EdgeInsetsDirectional.only(end: 8),
                        child: Icon(
                          Icons.check_circle,
                          size: 20,
                          color: colors.primary,
                        ),
                      ),
                    Text(
                      best == null ? '' : RunTimeFormat.format(best),
                      key: SpeedrunKeys.stageRecord(index),
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: colors.primary,
                        fontWeight: FontWeight.w700,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

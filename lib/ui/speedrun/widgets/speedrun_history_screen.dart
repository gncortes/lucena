import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' show DateFormat, toBeginningOfSentenceCase;

import '../../../domain/models/pace.dart';
import '../../../domain/models/speedrun.dart';
import '../../../domain/use_cases/speedrun_category.dart';
import '../../../routing/routes.dart';
import '../../core/keys/speedrun_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/l10n/run_time.dart';
import '../../core/pace/pace_ui.dart';
import '../../core/theme/app_shape.dart';
import '../../core/widgets/goal_style.dart';
import '../../core/widgets/scroll_padding.dart';
import '../../core/widgets/time_display.dart';
import '../view_models/speedrun_history_cubit.dart';
import 'speedrun_ui.dart';

/// O histórico de um speedrun (um final num ritmo): o recorde, as contagens e
/// as tentativas terminadas por mês. Cada uma abre o resumo dela.
class SpeedrunHistoryScreen extends StatelessWidget {
  const SpeedrunHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = context.watch<SpeedrunHistoryCubit>().state;
    final speedrun = state.speedrun;
    return Scaffold(
      key: SpeedrunKeys.historyScreen,
      appBar: AppBar(title: Text(l10n.historyTitle), centerTitle: true),
      body: speedrun == null
          ? (state.loaded
                ? null
                : const Center(child: CircularProgressIndicator()))
          : ListView(
              padding: scrollPadding(context),
              children: [
                _Header(speedrun: speedrun, state: state),
                _Numbers(speedrun: speedrun, state: state),
                ..._months(context, speedrun, state),
              ],
            ),
    );
  }

  // As tentativas agrupadas por mês, o mais novo primeiro.
  List<Widget> _months(
    BuildContext context,
    Speedrun speedrun,
    SpeedrunHistoryState state,
  ) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final locale = Localizations.localeOf(context).toString();
    final month = DateFormat.yMMMM(locale);
    final groups = <(String, List<(int, SpeedrunHistoryRun)>)>[];
    for (final (index, run) in state.runs.indexed) {
      final label = toBeginningOfSentenceCase(
        month.format(run.endedAt.toLocal()),
        locale,
      );
      if (groups.isEmpty || groups.last.$1 != label) groups.add((label, []));
      groups.last.$2.add((index, run));
    }
    return [
      for (final (index, (label, runs)) in groups.indexed) ...[
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(16, 16, 16, 8),
          child: Text(
            label,
            key: SpeedrunKeys.historyMonth(index),
            style: theme.textTheme.titleSmall?.copyWith(color: colors.primary),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Material(
            color: colors.surfaceContainerLow,
            clipBehavior: Clip.antiAlias,
            borderRadius: BorderRadius.circular(AppShape.large),
            child: Column(
              children: [
                for (final (position, (index, run)) in runs.indexed) ...[
                  if (position > 0)
                    Divider(height: 1, color: colors.outlineVariant),
                  _RunRow(
                    key: SpeedrunKeys.historyRun(index),
                    speedrun: speedrun,
                    entry: run,
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    ];
  }
}

/// A peça, o nome do final, o ritmo e o nível, como no detalhe.
class _Header extends StatelessWidget {
  const _Header({required this.speedrun, required this.state});

  final Speedrun speedrun;
  final SpeedrunHistoryState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final level = switch (SpeedrunCategories.of(speedrun)) {
      SpeedrunCategory.beginner => l10n.profileLevelBeginner,
      SpeedrunCategory.intermediate => l10n.profileLevelIntermediate,
      SpeedrunCategory.advanced => l10n.profileLevelAdvanced,
      null => null,
    };
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        children: [
          SpeedrunPicture(speedrun, characters: state.characters, size: 72),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  speedrunName(l10n, state.characters, speedrun),
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _Chip(
                      icon: paceIcon(PaceCategory.of(speedrun.time)),
                      label: paceLabel(l10n, speedrun.time),
                    ),
                    if (level != null)
                      _Chip(
                        icon: Icons.signal_cellular_alt,
                        label: level,
                        outlined: true,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.icon, required this.label, this.outlined = false});

  final IconData icon;
  final String label;

  /// O do nível: contornado, raio 8; o do ritmo, preenchido como no detalhe.
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final color = outlined
        ? colors.onSurfaceVariant
        : colors.onSecondaryContainer;
    return Container(
      constraints: const BoxConstraints(minHeight: 28),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: outlined ? null : colors.secondaryContainer,
        border: outlined ? Border.all(color: colors.outlineVariant) : null,
        borderRadius: BorderRadius.circular(
          outlined ? AppShape.small : AppShape.large,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              style: theme.textTheme.labelLarge?.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }
}

/// "Seu recorde" com a data e, ao lado, as tentativas e as concluídas.
class _Numbers extends StatelessWidget {
  const _Numbers({required this.speedrun, required this.state});

  final Speedrun speedrun;
  final SpeedrunHistoryState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final locale = Localizations.localeOf(context).toString();
    final best = state.best;
    final bestAt = state.bestAt?.toLocal();
    final muted = theme.textTheme.bodyMedium?.copyWith(
      color: colors.onSurfaceVariant,
    );
    final attempts = state.runs.length;
    final finished = state.finished;
    Widget count(Key key, int value, String label) => Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$value',
          textDirection: TextDirection.ltr,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(label, style: muted),
      ],
    );
    final counts = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        count(
          SpeedrunKeys.historyAttempts,
          attempts,
          l10n.historyStatAttempts(attempts),
        ),
        const SizedBox(height: 10),
        count(
          SpeedrunKeys.historyFinished,
          finished,
          l10n.historyStatFinishedAttempts(finished),
        ),
      ],
    );
    // Lado a lado até a fonte 1,5; acima, um embaixo do outro.
    final wide = MediaQuery.textScalerOf(context).scale(10) <= 15;
    final Widget record = best == null || bestAt == null
        ? const SizedBox.shrink()
        : Column(
            key: SpeedrunKeys.historyRecord,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.speedrunYourRecord, style: muted),
              const SizedBox(height: 4),
              TimeDisplay(
                value: runTime(context, recordTime(speedrun, best)),
                semanticsLabel:
                    '${l10n.speedrunYourRecord}: ${runTime(context, recordTime(speedrun, best))}',
                type: TimeDisplayType.record,
                size: TimeDisplaySize.pill,
                state: TimeDisplayState.highlight,
              ),
              const SizedBox(height: 4),
              Text(
                l10n.speedrunRecordAt(
                  (bestAt.year == state.year
                          ? DateFormat.MMMMd(locale)
                          : DateFormat.yMMMMd(locale))
                      .format(bestAt),
                  DateFormat.Hm(locale).format(bestAt),
                ),
                style: muted,
              ),
            ],
          );
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Material(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppShape.large),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          // Sem conclusão, só as contagens.
          child: best == null || bestAt == null
              ? Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: counts,
                )
              : wide
              ? IntrinsicHeight(
                  child: Row(
                    children: [
                      Expanded(child: record),
                      const SizedBox(width: 16),
                      VerticalDivider(width: 1, color: colors.outlineVariant),
                      const SizedBox(width: 16),
                      ConstrainedBox(
                        constraints: const BoxConstraints(minWidth: 104),
                        child: counts,
                      ),
                    ],
                  ),
                )
              // Fonte grande: as contagens embaixo do recorde.
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    record,
                    Divider(height: 24, color: colors.outlineVariant),
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: counts,
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

/// Uma tentativa: o tempo (troféu no recorde) ou onde parou, o dia e, na
/// primeira conclusão, o rating que ela deu.
class _RunRow extends StatelessWidget {
  const _RunRow({required this.speedrun, required this.entry, super.key});

  final Speedrun speedrun;
  final SpeedrunHistoryRun entry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final locale = Localizations.localeOf(context).toString();
    final endedAt = entry.endedAt.toLocal();
    final total = speedrun.stages.length;
    final stage = entry.stage.clamp(1, total);
    final muted = theme.textTheme.bodyMedium?.copyWith(
      color: colors.onSurfaceVariant,
    );
    final time = runTime(context, recordTime(speedrun, entry.run.total));
    final label = '${l10n.speedrunTotal}: $time';
    final (icon, stopped) = switch (entry.end) {
      SpeedrunRunEnd.completed => (null, null),
      SpeedrunRunEnd.lost => (
        Icons.remove,
        l10n.speedrunLostHero(stage, total),
      ),
      SpeedrunRunEnd.drawn => (
        Icons.drag_handle,
        l10n.speedrunDrawnHero(stage, total),
      ),
      SpeedrunRunEnd.abandoned => (
        Icons.do_not_disturb_on_outlined,
        l10n.speedrunStoppedAt(stage, total),
      ),
    };
    final bonus = entry.bonus;
    return InkWell(
      // O resumo da tentativa: o tempo e o fim de cada etapa.
      onTap: () => context.push(
        Routes.speedrunAttempt(speedrun.id, entry.run.attempt.id),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 56),
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(16, 8, 8, 8),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (stopped == null)
                      TimeDisplay(
                        value: time,
                        semanticsLabel: label,
                        type: entry.record
                            ? TimeDisplayType.record
                            : TimeDisplayType.stopwatch,
                        state: entry.record
                            ? TimeDisplayState.highlight
                            : TimeDisplayState.normal,
                        size: TimeDisplaySize.inline,
                      )
                    else
                      Row(
                        children: [
                          Icon(icon, size: 18, color: colors.onSurfaceVariant),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              stopped,
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: colors.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.historyDayAt(
                        DateFormat(
                          l10n.historyDayPattern,
                          locale,
                        ).format(endedAt),
                        DateFormat.Hm(locale).format(endedAt),
                      ),
                      style: muted,
                    ),
                    if (bonus != null && bonus > 0)
                      _Bonus(key: SpeedrunKeys.historyBonus, points: bonus),
                  ],
                ),
              ),
              // Espelha sozinha no RTL.
              Icon(Icons.chevron_right, color: colors.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

/// "+N de rating" em negrito e "na primeira conclusão" normal, em verde.
class _Bonus extends StatelessWidget {
  const _Bonus({required this.points, super.key});

  final int points;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final color = ChangeColors.of(context, up: true);
    final style = Theme.of(context).textTheme.bodySmall
        ?.copyWith(fontSize: 13, height: 18 / 13, color: color);
    final text = l10n.speedrunRatingBonusFirst(points);
    final short = l10n.speedrunRatingBonusShort(points);
    // O negrito só onde o idioma começa pelo "+N de rating".
    final bold = text.startsWith(short) ? short : '';
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: Icon(Icons.trending_up, size: 16, color: color),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: bold,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                TextSpan(text: text.substring(bold.length)),
              ],
            ),
            style: style,
          ),
        ),
      ],
    );
  }
}

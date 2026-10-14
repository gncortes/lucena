import 'package:flutter/material.dart';
import 'package:lucena/ui/core/widgets/lucena_app_bar.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' show DateFormat, toBeginningOfSentenceCase;

import '../../../domain/models/endgame_position.dart';
import '../../../domain/models/speedrun.dart';
import '../../../domain/use_cases/speedrun_category.dart';
import '../../../routing/routes.dart';
import '../../catalog/widgets/catalog_ui.dart';
import '../../core/keys/speedrun_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/l10n/run_time.dart';
import '../../core/theme/app_shape.dart';
import '../../core/widgets/goal_style.dart';
import '../../core/widgets/info_chip.dart';
import '../../core/widgets/scroll_padding.dart';
import '../../core/widgets/time_display.dart';
import '../view_models/speedrun_history_cubit.dart';
import 'speedrun_pace_chip.dart';
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
      appBar: LucenaAppBar(title: Text(l10n.historyTitle)),
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
                  speedrun.kind == SpeedrunKind.marathon
                      ? endgameName(
                          l10n,
                          speedrun.stages.first.position.subcategory,
                        )
                      : speedrunName(l10n, state.characters, speedrun),
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    SpeedrunPaceChip(speedrun.time),
                    if (speedrun.kind == SpeedrunKind.marathon)
                      InfoChip(
                        icon: Icons.all_inclusive,
                        label: l10n.marathonSection,
                      ),
                    if (level != null)
                      InfoChip(icon: Icons.signal_cellular_alt, label: level),
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

/// "Em {date}, às {time}" com a hora presa à palavra de antes: numa tela
/// estreita a linha quebra antes de "às", nunca entre "às" e a hora.
@visibleForTesting
String recordAtLabel(AppLocalizations l10n, String date, String time) =>
    l10n.speedrunRecordAt(date, time).replaceFirst(' $time', '\u00A0$time');

/// "Seu recorde" com a data e, embaixo, as tentativas e as concluídas.
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
    final muted = theme.textTheme.bodySmall?.copyWith(
      fontSize: 13,
      height: 18 / 13,
      color: colors.onSurfaceVariant,
    );
    final marathon = speedrun.kind == SpeedrunKind.marathon;
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
            fontSize: 20,
            height: 24 / 20,
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
    // Verde de sucesso do GoalStyle (T67d, variante B): troféu e tempo.
    final green = GoalStyle.of(context, PositionGoal.win).color;
    final Widget record = best == null || bestAt == null
        ? const SizedBox.shrink()
        : Column(
            key: SpeedrunKeys.historyRecord,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                marathon ? l10n.marathonBest : l10n.speedrunYourRecord,
                style: muted,
              ),
              const SizedBox(height: 4),
              Semantics(
                container: true,
                excludeSemantics: true,
                label: marathon
                    ? l10n.marathonBestValue(
                        runTime(context, recordTime(speedrun, best)),
                      )
                    : '${l10n.speedrunYourRecord}: ${runTime(context, recordTime(speedrun, best))}',
                child: Row(
                  children: [
                    Icon(Icons.emoji_events_rounded, size: 32, color: green),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        runTime(context, recordTime(speedrun, best)),
                        key: SpeedrunKeys.historyRecordTime,
                        textDirection: TextDirection.ltr,
                        style: theme.textTheme.displaySmall?.copyWith(
                          color: green,
                          fontSize: 36,
                          height: 44 / 36,
                          fontWeight: FontWeight.w800,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                recordAtLabel(
                  l10n,
                  (bestAt.year == state.year
                          ? DateFormat.MMMMd(locale)
                          : DateFormat.yMMMMd(locale))
                      .format(bestAt),
                  DateFormat.Hm(locale).format(bestAt),
                ),
                key: SpeedrunKeys.historyRecordAt,
                style: muted,
              ),
            ],
          );
    // As contagens lado a lado, centradas, com divisor vertical.
    Widget centered(Key key, int value, String label) => Expanded(
      child: Column(
        key: key,
        children: [
          Text(
            '$value',
            textDirection: TextDirection.ltr,
            style: theme.textTheme.titleLarge?.copyWith(
              fontSize: 20,
              height: 24 / 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(label, textAlign: TextAlign.center, style: muted),
        ],
      ),
    );
    final strip = IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          centered(
            SpeedrunKeys.historyAttempts,
            attempts,
            l10n.historyStatAttempts(attempts),
          ),
          VerticalDivider(width: 1, color: colors.outlineVariant),
          centered(
            SpeedrunKeys.historyFinished,
            finished,
            l10n.historyStatFinishedAttempts(finished),
          ),
        ],
      ),
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
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (marathon) ...[
                      Text(
                        l10n.marathonNotFinishedYet,
                        key: SpeedrunKeys.historyNotFinished,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                    counts,
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    record,
                    Divider(height: 24, color: colors.outlineVariant),
                    strip,
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
    final muted = theme.textTheme.bodySmall?.copyWith(
      fontSize: 13,
      height: 18 / 13,
      color: colors.onSurfaceVariant,
    );
    final marathon = speedrun.kind == SpeedrunKind.marathon;
    final time = runTime(context, recordTime(speedrun, entry.run.total));
    final label = marathon
        ? l10n.marathonLeftValue(time)
        : '${l10n.speedrunTotal}: $time';
    final (icon, stopped) = marathon
        ? switch (entry.end) {
            SpeedrunRunEnd.completed => (null, null),
            SpeedrunRunEnd.drawn => (
              Icons.drag_handle,
              l10n.marathonDrawnHero(stage, total),
            ),
            SpeedrunRunEnd.timeout => (
              Icons.hourglass_bottom,
              l10n.marathonTimeoutHero(stage, total),
            ),
            SpeedrunRunEnd.abandoned => (
              Icons.do_not_disturb_on_outlined,
              l10n.speedrunAbandonedHero(stage, total),
            ),
            SpeedrunRunEnd.lost => (
              Icons.remove,
              l10n.speedrunLostHero(stage, total),
            ),
          }
        : switch (entry.end) {
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
            SpeedrunRunEnd.timeout => (
              Icons.timer_off_outlined,
              l10n.marathonTimeoutHero(stage, total),
            ),
          };
    final day = l10n.historyDayAt(
      DateFormat(l10n.historyDayPattern, locale).format(endedAt),
      DateFormat.Hm(locale).format(endedAt),
    );
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
                            : marathon
                            ? TimeDisplayType.countdown
                            : TimeDisplayType.stopwatch,
                        state: entry.record
                            ? TimeDisplayState.highlight
                            : TimeDisplayState.normal,
                        size: TimeDisplaySize.inline,
                      )
                    else
                      // A altura da pílula do tempo: todas as linhas iguais.
                      ConstrainedBox(
                        constraints: const BoxConstraints(minHeight: 28),
                        child: Row(
                          children: [
                            Icon(
                              icon,
                              size: 18,
                              color: colors.onSurfaceVariant,
                            ),
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
                      ),
                    const SizedBox(height: 2),
                    Text(
                      marathon && stopped == null
                          ? l10n.marathonDayLeft(day)
                          : day,
                      style: muted,
                    ),
                    if (bonus != null && bonus > 0)
                      _Bonus(key: SpeedrunKeys.historyBonus, points: bonus),
                  ],
                ),
              ),
              const SizedBox(width: 12),
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

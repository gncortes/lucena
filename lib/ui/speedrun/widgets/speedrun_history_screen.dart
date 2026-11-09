import '../../journey/widgets/challenge_load_error.dart';

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
import '../../core/theme/app_icon_size.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/goal_style.dart';
import '../../core/widgets/info_chip.dart';
import '../../core/widgets/scroll_padding.dart';
import '../../core/widgets/time_display.dart';
import '../view_models/speedrun_history_cubit.dart';
import 'speedrun_pace_chip.dart';
import 'speedrun_ui.dart';
import '../../core/widgets/skeleton.dart';
import '../../core/motion/shimmer_conteudo.dart';

/// O histórico de um speedrun (um final num ritmo): o recorde, as contagens e
/// as tentativas terminadas por mês. Cada uma abre o resumo dela.
class SpeedrunHistoryScreen extends StatelessWidget {
  const SpeedrunHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = context.watch<SpeedrunHistoryCubit>().state;
    final speedrun = state.speedrun;
    final failure = state.failure;
    if (failure != null) {
      return challengeLoadError(
        context,
        failure,
        context.read<SpeedrunHistoryCubit>().retry,
      );
    }
    final locale = Localizations.localeOf(context).toString();
    // Um formato de dia e de hora para a lista toda, não um por tentativa.
    final dayFormat = DateFormat(l10n.historyDayPattern, locale);
    final timeFormat = DateFormat.Hm(locale);
    return Scaffold(
      key: SpeedrunKeys.historyScreen,
      appBar: LucenaAppBar(title: Text(l10n.historyTitle)),
      body: speedrun == null && state.loaded
          ? null
          : ShimmerConteudo(
              carregando: speedrun == null,
              esqueleto: const SkeletonList(),
              child: speedrun == null
                  ? const SizedBox.shrink()
                  : ListView(
                      padding: scrollPadding(context),
                      children: [
                        _Header(speedrun: speedrun, state: state),
                        _Numbers(speedrun: speedrun, state: state),
                        // As tentativas agrupadas por mês, o mais novo
                        // primeiro.
                        for (final (index, (label, runs)) in _monthGroups(
                          context,
                          state,
                        ).indexed) ...[
                          _MonthTitle(label: label, index: index),
                          _MonthCard(
                            speedrun: speedrun,
                            runs: runs,
                            dayFormat: dayFormat,
                            timeFormat: timeFormat,
                          ),
                        ],
                      ],
                    ),
            ),
    );
  }

  /// O rótulo de cada mês e as tentativas dele (com a posição na lista).
  static List<(String, List<(int, SpeedrunHistoryRun)>)> _monthGroups(
    BuildContext context,
    SpeedrunHistoryState state,
  ) {
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
    return groups;
  }
}

/// O nome de um mês do histórico.
class _MonthTitle extends StatelessWidget {
  const _MonthTitle({required this.label, required this.index});

  final String label;
  final int index;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: Text(
        label,
        key: SpeedrunKeys.historyMonth(index),
        style: theme.textTheme.titleSmall?.copyWith(
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }
}

/// O cartão com as tentativas de um mês, separadas por linha.
class _MonthCard extends StatelessWidget {
  const _MonthCard({
    required this.speedrun,
    required this.runs,
    required this.dayFormat,
    required this.timeFormat,
  });

  final Speedrun speedrun;

  /// Cada tentativa com a posição dela na lista toda (a key de teste).
  final List<(int, SpeedrunHistoryRun)> runs;
  final DateFormat dayFormat;
  final DateFormat timeFormat;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
    child: Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (final (position, (index, run)) in runs.indexed) ...[
            if (position > 0) const Divider(),
            _RunRow(
              key: SpeedrunKeys.historyRun(index),
              speedrun: speedrun,
              entry: run,
              dayFormat: dayFormat,
              timeFormat: timeFormat,
            ),
          ],
        ],
      ),
    ),
  );
}

/// A peça, o nome do final, o ritmo e o nível, como no detalhe.
class _Header extends StatelessWidget {
  const _Header({required this.speedrun, required this.state});

  final Speedrun speedrun;
  final SpeedrunHistoryState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final level = switch (SpeedrunCategories.of(speedrun)) {
      SpeedrunCategory.beginner => l10n.profileLevelBeginner,
      SpeedrunCategory.intermediate => l10n.profileLevelIntermediate,
      SpeedrunCategory.advanced => l10n.profileLevelAdvanced,
      null => null,
    };
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        0,
      ),
      child: Row(
        children: [
          SpeedrunPicture(speedrun, characters: state.characters, size: 72),
          const SizedBox(width: AppSpacing.lg),
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
                  style: Theme.of(context).textTheme.titleLarge
                      ?.copyWith(fontWeight: AppWeight.heavy),
                ),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    SpeedrunPaceChip(speedrun.time),
                    if (speedrun.kind == SpeedrunKind.marathon)
                      InfoChip(
                        icon: Icons.all_inclusive,
                        label: l10n.marathonSection,
                        outlined: true,
                      ),
                    if (level != null)
                      InfoChip(
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

/// "Em {date}, às {time}" com a hora presa à palavra de antes: numa tela
/// estreita a linha quebra antes de "às", nunca entre "às" e a hora.
@visibleForTesting
String recordAtLabel(AppLocalizations l10n, String date, String time) =>
    l10n.speedrunRecordAt(date, time).replaceFirst(' $time', '\u00A0$time');

/// Os números pequenos em cinza (data, rótulos das contagens).
TextStyle? _mutedStyle(ThemeData theme) => theme.textTheme.bodySmall?.copyWith(
  fontSize: 13,
  height: 18 / 13,
  color: theme.colorScheme.onSurfaceVariant,
);

/// "Seu recorde" com a data e, embaixo, as tentativas e as concluídas.
class _Numbers extends StatelessWidget {
  const _Numbers({required this.speedrun, required this.state});

  final Speedrun speedrun;
  final SpeedrunHistoryState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final best = state.best;
    final bestAt = state.bestAt?.toLocal();
    final marathon = speedrun.kind == SpeedrunKind.marathon;
    final attempts = state.runs.length;
    final finished = state.finished;
    final counts = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Count(
          countKey: SpeedrunKeys.historyAttempts,
          value: attempts,
          label: l10n.historyStatAttempts(attempts),
        ),
        const SizedBox(height: AppSpacing.md),
        _Count(
          countKey: SpeedrunKeys.historyFinished,
          value: finished,
          label: l10n.historyStatFinishedAttempts(finished),
        ),
      ],
    );
    final Widget record = best == null || bestAt == null
        ? const SizedBox.shrink()
        : _RecordBlock(
            speedrun: speedrun,
            best: best,
            bestAt: bestAt,
            year: state.year,
            marathon: marathon,
          );
    final strip = IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _CenteredCount(
            countKey: SpeedrunKeys.historyAttempts,
            value: attempts,
            label: l10n.historyStatAttempts(attempts),
          ),
          const VerticalDivider(),
          _CenteredCount(
            countKey: SpeedrunKeys.historyFinished,
            value: finished,
            label: l10n.historyStatFinishedAttempts(finished),
          ),
        ],
      ),
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        0,
      ),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.lg,
          ),
          // Sem conclusão, só as contagens.
          child: best == null || bestAt == null
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (marathon) ...[
                      Text(
                        l10n.marathonNotFinishedYet,
                        key: SpeedrunKeys.historyNotFinished,
                        style: theme.textTheme.titleSmall,
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],
                    counts,
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [record, const Divider(), strip],
                ),
        ),
      ),
    );
  }
}

/// Uma contagem à esquerda: o número grande e o rótulo embaixo.
class _Count extends StatelessWidget {
  const _Count({
    required this.countKey,
    required this.value,
    required this.label,
  });

  final Key countKey;
  final int value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      key: countKey,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$value',
          textDirection: TextDirection.ltr,
          style: theme.textTheme.titleLarge?.copyWith(
            fontSize: 20,
            height: 24 / 20,
            fontWeight: AppWeight.heavy,
          ),
        ),
        Text(label, style: _mutedStyle(theme)),
      ],
    );
  }
}

/// Uma contagem centrada, lado a lado com a outra.
class _CenteredCount extends StatelessWidget {
  const _CenteredCount({
    required this.countKey,
    required this.value,
    required this.label,
  });

  final Key countKey;
  final int value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Column(
        key: countKey,
        children: [
          Text(
            '$value',
            textDirection: TextDirection.ltr,
            style: theme.textTheme.titleLarge?.copyWith(
              fontSize: 20,
              height: 24 / 20,
            ),
          ),
          Text(label, textAlign: TextAlign.center, style: _mutedStyle(theme)),
        ],
      ),
    );
  }
}

/// O recorde: o troféu com o tempo e a data em que foi feito.
class _RecordBlock extends StatelessWidget {
  const _RecordBlock({
    required this.speedrun,
    required this.best,
    required this.bestAt,
    required this.year,
    required this.marathon,
  });

  final Speedrun speedrun;
  final Duration best;
  final DateTime bestAt;
  final int? year;
  final bool marathon;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toString();
    final muted = _mutedStyle(theme);
    // Verde de sucesso do GoalStyle (T67d, variante B): troféu e tempo.
    final green = GoalStyle.of(context, PositionGoal.win).color;
    return Column(
      key: SpeedrunKeys.historyRecord,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          marathon ? l10n.marathonBest : l10n.speedrunYourRecord,
          style: muted,
        ),
        const SizedBox(height: AppSpacing.xs),
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
              Icon(
                Icons.emoji_events_rounded,
                size: AppIconSize.large,
                color: green,
              ),
              const SizedBox(width: AppSpacing.sm),
              Flexible(
                child: Text(
                  runTime(context, recordTime(speedrun, best)),
                  key: SpeedrunKeys.historyRecordTime,
                  textDirection: TextDirection.ltr,
                  style: theme.textTheme.displaySmall?.copyWith(
                    color: green,
                    fontSize: 36,
                    height: 44 / 36,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          recordAtLabel(
            l10n,
            (bestAt.year == year
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
  }
}

/// O ícone e o texto de onde a tentativa parou (nulos se concluiu).
(IconData?, String?) _stopLabel(
  AppLocalizations l10n,
  bool marathon,
  SpeedrunRunEnd end,
  int stage,
  int total,
) => marathon
    ? switch (end) {
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
    : switch (end) {
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

/// Uma tentativa: o tempo (troféu no recorde) ou onde parou, o dia e, na
/// primeira conclusão, o rating que ela deu.
class _RunRow extends StatelessWidget {
  const _RunRow({
    required this.speedrun,
    required this.entry,
    required this.dayFormat,
    required this.timeFormat,
    super.key,
  });

  final Speedrun speedrun;
  final SpeedrunHistoryRun entry;
  final DateFormat dayFormat;
  final DateFormat timeFormat;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final endedAt = entry.endedAt.toLocal();
    final total = speedrun.stages.length;
    final stage = entry.stage.clamp(1, total);
    final muted = _mutedStyle(theme);
    final marathon = speedrun.kind == SpeedrunKind.marathon;
    final time = runTime(context, recordTime(speedrun, entry.run.total));
    final label = marathon
        ? l10n.marathonLeftValue(time)
        : '${l10n.speedrunTotal}: $time';
    final (icon, stopped) = _stopLabel(l10n, marathon, entry.end, stage, total);
    final day = l10n.historyDayAt(
      dayFormat.format(endedAt),
      timeFormat.format(endedAt),
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
          padding: const EdgeInsetsDirectional.fromSTEB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.sm,
            AppSpacing.sm,
          ),
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
                      _StoppedLabel(icon: icon, text: stopped),
                    const SizedBox(height: AppSpacing.xs),
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
              const SizedBox(width: AppSpacing.md),
              // Espelha sozinha no RTL.
              Icon(Icons.chevron_right, color: colors.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

/// Onde a tentativa parou: o ícone e o texto, na altura da pílula do tempo.
class _StoppedLabel extends StatelessWidget {
  const _StoppedLabel({required this.icon, required this.text});

  final IconData? icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    // A altura da pílula do tempo: todas as linhas iguais.
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 28),
      child: Row(
        children: [
          Icon(icon, size: AppIconSize.button, color: colors.onSurfaceVariant),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.titleSmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ),
        ],
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
          padding: const EdgeInsets.only(top: AppSpacing.xs),
          child: Icon(Icons.trending_up, size: AppIconSize.small, color: color),
        ),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: bold,
                  style: const TextStyle(fontWeight: AppWeight.strong),
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

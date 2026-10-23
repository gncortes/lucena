import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:lucena_ui/lucena_ui.dart';

import '../../../domain/models/week_summary.dart';
import '../../../routing/routes.dart';
import '../../core/keys/week_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/widgets/actions_footer.dart';
import '../../core/widgets/lucena_app_bar.dart';
import '../../core/widgets/scroll_padding.dart';
import '../view_models/week_cubit.dart';
import 'week_texts.dart';

/// Sua semana (canvas `PropV1RetencaoSemana`), aberta pelo resumo de domingo:
/// o título com os números, as datas, quatro números, as barras de finais por
/// dia e o rating.
class WeekScreen extends StatelessWidget {
  const WeekScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final week = context.watch<WeekCubit>().state;
    return Scaffold(
      key: WeekKeys.screen,
      appBar: LucenaAppBar(title: Text(l10n.weekTitle)),
      body: week == null ? const SizedBox.shrink() : _Body(week: week),
      bottomNavigationBar: ActionsFooter(
        stacked: true,
        children: [
          FilledButton.icon(
            key: WeekKeys.play,
            onPressed: () => context.push(Routes.daily),
            icon: const Icon(Icons.today),
            label: Text(l10n.weekPlay),
          ),
          TextButton(
            key: WeekKeys.seeStreak,
            onPressed: () => context.push(Routes.streak),
            child: Text(l10n.weekSeeStreak),
          ),
        ],
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.week});

  final WeekSummary week;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toString();
    final date = DateFormat.MMMMd(locale);
    final sunday = week.sunday;
    final points = week.points;
    return ListView(
      padding: scrollPadding(
        context,
        left: AppSpacing.screen,
        top: AppSpacing.sm,
        right: AppSpacing.screen,
      ),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                weekHeadline(l10n, week),
                key: WeekKeys.headline,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                l10n.weekRange(
                  date.format(week.monday),
                  // No mesmo mês, só o dia: "a domingo, 18".
                  sunday.month == week.monday.month
                      ? '${sunday.day}'
                      : date.format(sunday),
                ),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.betweenCards),
        Row(
          children: [
            _Number(
              code: 'finals',
              icon: Icons.grid_view,
              value: '${week.finals}',
              label: l10n.weekStatFinals,
            ),
            const SizedBox(width: AppSpacing.sm),
            _Number(
              code: 'points',
              icon: Icons.trending_up,
              value: points > 0 ? '+$points' : '$points',
              label: l10n.weekStatPoints,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            _Number(
              code: 'days',
              icon: Icons.event_repeat,
              value: '${week.streakDays}',
              label: l10n.weekStatDays,
            ),
            const SizedBox(width: AppSpacing.sm),
            _Number(
              code: 'firstTry',
              icon: Icons.check_circle_outline,
              value: '${week.firstTry}',
              label: l10n.weekStatFirstTry,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.betweenCards),
        _Bars(week: week),
        const SizedBox(height: AppSpacing.betweenCards),
        _Rating(week: week),
      ],
    );
  }
}

// Um número com ícone (canvas `CompNumero`).
class _Number extends StatelessWidget {
  const _Number({
    required this.code,
    required this.icon,
    required this.value,
    required this.label,
  });

  final String code;
  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Expanded(
      child: DecoratedBox(
        key: WeekKeys.stat(code),
        decoration: BoxDecoration(
          color: colors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(AppShape.large),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colors.primaryContainer,
                ),
                child: SizedBox.square(
                  dimension: 36,
                  child: Icon(
                    icon,
                    size: AppIconSize.button,
                    color: colors.onPrimaryContainer,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Finais por dia, de segunda a domingo.
class _Bars extends StatelessWidget {
  const _Bars({required this.week});

  final WeekSummary week;

  static const _height = 72.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final weekday = DateFormat.EEEEE(
      Localizations.localeOf(context).toString(),
    );
    final most = week.perDay.fold(0, (a, b) => a > b ? a : b);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.insideCard),
        child: Column(
          key: WeekKeys.bars,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              context.l10n.weekByDay,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var i = 0; i < week.perDay.length; i++)
                  Expanded(
                    child: Column(
                      children: [
                        SizedBox(
                          height: _height,
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: Container(
                              width: 24,
                              // Dia sem final: um traço, para a semana aparecer.
                              height: most == 0
                                  ? 4
                                  : (week.perDay[i] * _height / most).clamp(
                                      4,
                                      _height,
                                    ),
                              decoration: BoxDecoration(
                                color: week.perDay[i] > 0
                                    ? colors.primary
                                    : colors.surfaceContainerHighest,
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(AppShape.tiny),
                                  bottom: Radius.circular(AppShape.hairline),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          weekday.format(
                            DateTime(
                              week.monday.year,
                              week.monday.month,
                              week.monday.day + i,
                            ),
                          ),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// "Rating: 1152 para 1192" e o melhor dia.
class _Rating extends StatelessWidget {
  const _Rating({required this.week});

  final WeekSummary week;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final best = week.bestDay;
    return Card(
      key: WeekKeys.rating,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.insideCard),
        child: Row(
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: colors.primaryContainer,
                borderRadius: BorderRadius.circular(AppShape.medium),
              ),
              child: SizedBox.square(
                dimension: 40,
                child: Icon(
                  Icons.trending_up,
                  size: AppIconSize.standard,
                  color: colors.primary,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.weekRating(week.ratingFrom, week.ratingTo),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (best != null)
                    Text(
                      l10n.weekBestDay(weekdayKey(best)),
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

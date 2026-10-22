import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/models/daily_final.dart';
import '../../../routing/routes.dart';
import '../../core/keys/daily_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_icon_size.dart';
import '../../core/theme/app_shape.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/actions_footer.dart';
import '../../core/widgets/lucena_app_bar.dart';
import '../../core/widgets/scroll_padding.dart';
import '../../streak/view_models/streak_cubit.dart';
import '../../streak/widgets/streak_screen.dart';
import '../view_models/daily_result_cubit.dart';
import 'daily_crowd_card.dart';
import 'daily_squares.dart';

/// O resultado do final do dia (canvas `PropV1RetencaoResultado`): o título,
/// os quadradinhos da primeira tentativa, a sequência e o "quantos
/// acertaram", com Compartilhar e Continuar.
class DailyResultScreen extends StatelessWidget {
  const DailyResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final date = context.read<DailyResultCubit>().date;
    return BlocBuilder<DailyResultCubit, DailyResultState>(
      builder: (context, state) {
        final record = state.record;
        return Scaffold(
          key: DailyKeys.resultScreen,
          appBar: LucenaAppBar(
            title: Text(l10n.dailyTitle),
            actions: [
              if (record != null)
                IconButton(
                  tooltip: l10n.dailyShareTitle,
                  icon: const Icon(Icons.share_rounded),
                  onPressed: () =>
                      unawaited(context.push(Routes.dailyShareOf(date))),
                ),
            ],
          ),
          body: !state.ready
              ? const SizedBox.shrink()
              : ListView(
                  padding: scrollPadding(
                    context,
                    left: AppSpacing.screen,
                    top: AppSpacing.sm,
                    right: AppSpacing.screen,
                  ),
                  children: [
                    if (record != null) ...[
                      _ResultCard(record: record, state: state),
                      const SizedBox(height: AppSpacing.betweenCards),
                    ],
                    const _StreakCard(),
                    const SizedBox(height: AppSpacing.betweenCards),
                    const DailyCrowdCard(),
                  ],
                ),
          bottomNavigationBar: ActionsFooter(
            stacked: true,
            children: [
              if (record != null)
                FilledButton.icon(
                  key: DailyKeys.share,
                  onPressed: () =>
                      unawaited(context.push(Routes.dailyShareOf(date))),
                  icon: const Icon(Icons.share_rounded),
                  label: Text(l10n.dailyShareTitle),
                ),
              TextButton(
                key: DailyKeys.continueButton,
                onPressed: () => context.go(Routes.home),
                child: Text(l10n.dailyContinue),
              ),
            ],
          ),
        );
      },
    );
  }
}

// "Você ganhou", "22 de outubro · 5 lances", os quadradinhos e a legenda.
class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.record, required this.state});

  final DailyRecord record;
  final DailyResultState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.insideCard,
          vertical: AppSpacing.xl,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              dailyResultTitle(l10n, record, state.daily?.position.goal),
              key: DailyKeys.resultTitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.dailyMeta(dailyDate(context, record.date), record.moves),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            DailySquares(
              squares: record.squares,
              size: 28,
              gap: AppSpacing.xs,
              radius: AppShape.tiny,
            ),
            const SizedBox(height: AppSpacing.md),
            DailyLegend(squares: record.squares),
          ],
        ),
      ),
    );
  }
}

// Os dias seguidos, quanto falta para o recorde e a semana; abre a Sequência.
class _StreakCard extends StatelessWidget {
  const _StreakCard();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return BlocBuilder<StreakCubit, StreakState>(
      builder: (context, state) {
        if (!state.ready) return const SizedBox.shrink();
        final streak = state.streak;
        return Card(
          key: DailyKeys.streakCard,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => unawaited(context.push(Routes.streak)),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.insideCard),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: colors.primaryContainer,
                          borderRadius: BorderRadius.circular(AppShape.large),
                        ),
                        child: SizedBox.square(
                          dimension: 56,
                          child: Icon(
                            Icons.event_repeat,
                            size: AppIconSize.large,
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
                              l10n.streakDays(streak.current),
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              streak.toRecord > 0
                                  ? l10n.streakToRecord(
                                      streak.toRecord,
                                      streak.record,
                                    )
                                  : l10n.streakAtRecord,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right, color: colors.onSurfaceVariant),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  StreakWeek(state: state),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

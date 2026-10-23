import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucena_ui/lucena_ui.dart';

import '../../../domain/models/achievement.dart';
import '../../core/keys/achievements_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/widgets/one_line.dart';
import '../../core/widgets/scroll_padding.dart';
import '../../core/widgets/staggered_entrance.dart';
import '../view_models/achievements_cubit.dart';
import 'achievement_detail.dart';
import 'achievement_medal.dart';
import 'achievement_ui.dart';

/// As conquistas: a barra do progresso geral, o filtro (todas, conquistadas,
/// faltando e o histórico) e a lista por grupo, com as obtidas em cor e a
/// data relativa, e as que faltam em cinza, com o cadeado e o progresso.
/// Tocar numa abre o detalhe.
class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = context.watch<AchievementsCubit>().state;
    final all = state.all;
    return Scaffold(
      key: AchievementsKeys.screen,
      appBar: LucenaAppBar(title: Text(l10n.achievementsTitle)),
      body: all == null
          ? const SkeletonList()
          : ListView(
              padding: scrollPadding(context),
              children: [
                _Overall(done: state.unlockedCount, total: all.length),
                _Filter(selected: state.filter),
                ..._items(context, state),
              ],
            ),
    );
  }

  List<Widget> _items(BuildContext context, AchievementsState state) {
    final l10n = context.l10n;
    final visible = state.visible;
    if (visible.isEmpty) {
      return [
        EmptyState(
          key: AchievementsKeys.empty,
          style: EmptyStateStyle.text,
          message: state.filter == AchievementsFilter.locked
              ? l10n.achievementsEmptyLocked
              : l10n.achievementsEmptyUnlocked,
        ),
      ];
    }
    var index = 0;
    Widget row(Achievement achievement) => StaggeredEntrance(
      index: index++,
      child: _AchievementRow(achievement: achievement, state: state),
    );
    // O histórico é uma fileira só, pela data.
    if (state.filter == AchievementsFilter.history) {
      return [for (final achievement in visible) row(achievement)];
    }
    final all = state.all!;
    return [
      for (final category in AchievementCategory.values)
        if (visible.any((a) => a.category == category)) ...[
          SectionTitle(
            l10n.achievementsGroupHeader(
              category.label(l10n),
              all
                  .where(
                    (a) =>
                        a.category == category &&
                        state.unlocked.containsKey(a.id),
                  )
                  .length,
              all.where((a) => a.category == category).length,
            ),
            textKey: AchievementsKeys.group(category.name),
          ),
          for (final achievement in visible)
            if (achievement.category == category) row(achievement),
        ],
    ];
  }
}

/// "14 de 50 conquistadas" e a barra.
class _Overall extends StatelessWidget {
  const _Overall({required this.done, required this.total});

  final int done;
  final int total;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screen,
        AppSpacing.sm,
        AppSpacing.screen,
        AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            context.l10n.achievementsProgress(done, total),
            key: AchievementsKeys.progress,
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          AnimatedProgress(
            key: AchievementsKeys.progressBar,
            value: total == 0 ? 0 : done / total,
          ),
        ],
      ),
    );
  }
}

/// Todas, conquistadas, faltando e o histórico.
class _Filter extends StatelessWidget {
  const _Filter({required this.selected});

  final AchievementsFilter selected;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<AchievementsCubit>();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
      child: SizedBox(
        width: double.infinity,
        child: SegmentedButton<AchievementsFilter>(
          showSelectedIcon: false,
          segments: [
            for (final filter in AchievementsFilter.values)
              ButtonSegment(
                value: filter,
                label: OneLine(switch (filter) {
                  AchievementsFilter.all => l10n.achievementsFilterAll,
                  AchievementsFilter.unlocked =>
                    l10n.achievementsFilterUnlocked,
                  AchievementsFilter.locked => l10n.achievementsFilterLocked,
                  AchievementsFilter.history => l10n.achievementsFilterHistory,
                }, key: AchievementsKeys.filter(filter.name)),
              ),
          ],
          selected: {selected},
          onSelectionChanged: (selection) => cubit.filter(selection.single),
        ),
      ),
    );
  }
}

class _AchievementRow extends StatelessWidget {
  const _AchievementRow({required this.achievement, required this.state});

  final Achievement achievement;
  final AchievementsState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final locale = Localizations.localeOf(context).toString();
    final unlocked = state.unlocked[achievement.id];
    final progress = unlocked == null ? state.progress[achievement.id] : null;
    final now = state.now;
    return ListTile(
      key: AchievementsKeys.item(achievement.id),
      onTap: () => showAchievementDetail(
        context,
        achievement: achievement,
        unlocked: unlocked,
        characters: state.characters,
        progress: progress,
        speedrunId: state.speedrunOfAttempt[unlocked?.speedrunAttemptId],
      ),
      leading: AchievementMedal(
        icon: achievement.iconData,
        unlocked: unlocked != null,
        lockKey: AchievementsKeys.locked(achievement.id),
        lockLabel: l10n.achievementsLockedLabel,
      ),
      title: Text(
        achievement.title(l10n, state.characters),
        style: unlocked == null
            ? TextStyle(color: colors.onSurfaceVariant)
            : null,
      ),
      subtitle: unlocked != null
          ? Text(
              now == null
                  ? fullDateTime(l10n, locale, unlocked.at)
                  : relativeDay(l10n, locale, unlocked.at, now),
              key: AchievementsKeys.unlockedOn(achievement.id),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(achievement.description(l10n, state.characters)),
                if (progress != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  AnimatedProgress(value: progress.fraction),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    progress.label(l10n),
                    key: AchievementsKeys.itemProgress(achievement.id),
                    style: theme.textTheme.labelMedium,
                  ),
                ],
              ],
            ),
      trailing: Icon(Icons.chevron_right, color: colors.outline),
    );
  }
}

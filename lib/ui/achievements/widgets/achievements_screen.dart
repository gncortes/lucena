import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../../core/keys/achievements_keys.dart';
import '../../core/l10n/l10n.dart';
import '../view_models/achievements_cubit.dart';
import 'achievement_ui.dart';
import '../../core/widgets/scroll_padding.dart';
import '../../core/widgets/staggered_entrance.dart';

/// As conquistas: as obtidas primeiro, com a data, e as bloqueadas com o que
/// falta fazer.
class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final state = context.watch<AchievementsCubit>().state;
    final all = state.all;
    final date = DateFormat.yMd(Localizations.localeOf(context).toString());
    return Scaffold(
      key: AchievementsKeys.screen,
      appBar: AppBar(title: Text(l10n.achievementsTitle)),
      body: all == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: scrollPadding(context),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Text(
                    l10n.achievementsProgress(
                      state.unlocked.keys
                          .where((id) => all.any((a) => a.id == id))
                          .length,
                      all.length,
                    ),
                    key: AchievementsKeys.progress,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                for (final (index, achievement) in [
                  ...all.where((a) => state.unlocked.containsKey(a.id)),
                  ...all.where((a) => !state.unlocked.containsKey(a.id)),
                ].indexed)
                  StaggeredEntrance(
                    index: index,
                    child: Builder(
                      builder: (context) {
                        final at = state.unlocked[achievement.id];
                        final unlocked = at != null;
                        return ListTile(
                          key: AchievementsKeys.item(achievement.id),
                          leading: CircleAvatar(
                            backgroundColor: unlocked
                                ? colors.primaryContainer
                                : colors.surfaceContainerHighest,
                            child: Icon(
                              achievement.iconData,
                              color: unlocked
                                  ? colors.onPrimaryContainer
                                  : colors.outline,
                            ),
                          ),
                          title: Text(
                            achievement.title(l10n, state.characters),
                            style: unlocked
                                ? null
                                : TextStyle(color: colors.onSurfaceVariant),
                          ),
                          subtitle: Text(
                            unlocked
                                ? l10n.achievementsUnlockedOn(
                                    date.format(at.toLocal()),
                                  )
                                : achievement.description(
                                    l10n,
                                    state.characters,
                                  ),
                            key: unlocked
                                ? AchievementsKeys.unlockedOn(achievement.id)
                                : null,
                          ),
                          trailing: unlocked
                              ? null
                              : Icon(
                                  Icons.lock_outline,
                                  key: AchievementsKeys.locked(achievement.id),
                                  color: colors.outline,
                                  semanticLabel: l10n.achievementsLockedLabel,
                                ),
                        );
                      },
                    ),
                  ),
              ],
            ),
    );
  }
}

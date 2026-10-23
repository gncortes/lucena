import 'package:flutter/material.dart';
import 'package:lucena_ui/lucena_ui.dart';

import '../../../domain/models/streak.dart';
import '../../core/keys/streak_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/widgets/actions_footer.dart';
import '../../core/widgets/lucena_sheet.dart';
import 'streak_pill.dart';

/// A sequência que acabou (canvas `PropV1RetencaoPerdida`): sai uma vez, ao
/// abrir o app no dia seguinte ao que ficou sem jogar. Sem culpa: o recorde
/// continua e dá para começar outra hoje. [onPlay] abre o final do dia.
Future<void> showStreakLostSheet(
  BuildContext context, {
  required Streak streak,
  required VoidCallback onPlay,
}) => showLucenaSheet<void>(
  context,
  sheetKey: StreakKeys.lostSheet,
  builder: (sheet) => SafeArea(
    top: false,
    child: _LostSheet(
      streak: streak,
      onPlay: () {
        Navigator.of(sheet).pop();
        onPlay();
      },
    ),
  ),
);

class _LostSheet extends StatelessWidget {
  const _LostSheet({required this.streak, required this.onPlay});

  final Streak streak;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            AppSpacing.lg,
            AppSpacing.xl,
            0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(AppShape.large),
                ),
                child: SizedBox.square(
                  dimension: 56,
                  child: Icon(
                    Icons.event_repeat,
                    size: AppIconSize.large,
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                l10n.streakLostTitle(streak.lost),
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                l10n.streakLostText(streak.record),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(AppShape.large),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      StreakPill(days: streak.lost, muted: true),
                      const SizedBox(width: AppSpacing.md),
                      Icon(
                        Icons.arrow_forward,
                        size: AppIconSize.button,
                        color: colors.outline,
                      ),
                      const SizedBox(width: AppSpacing.md),
                      const StreakPill(days: 0),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        ActionsFooter(
          stacked: true,
          children: [
            FilledButton.icon(
              key: StreakKeys.lostPlay,
              onPressed: onPlay,
              icon: const Icon(Icons.today),
              label: Text(l10n.streakLostPlay),
            ),
            TextButton(
              key: StreakKeys.lostNo,
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.streakLostNo),
            ),
          ],
        ),
      ],
    );
  }
}

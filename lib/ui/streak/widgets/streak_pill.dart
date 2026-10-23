import 'package:flutter/material.dart';
import 'package:lucena_ui/lucena_ui.dart';

/// A pílula da sequência (ícone `event_repeat` e os dias): na home, no
/// resultado do final do dia e na folha da sequência perdida ([muted]).
class StreakPill extends StatelessWidget {
  const StreakPill({required this.days, this.muted = false, super.key});

  final int days;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final ink = muted ? colors.onSurfaceVariant : colors.primary;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: muted
            ? colors.surfaceContainerHighest
            : colors.primaryContainer.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(AppShape.full),
      ),
      child: SizedBox(
        height: 28,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.event_repeat, size: AppIconSize.small, color: ink),
              const SizedBox(width: AppSpacing.xs),
              Text(
                '$days',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: ink,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

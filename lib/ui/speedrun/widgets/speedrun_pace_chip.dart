import 'package:flutter/material.dart';

import '../../../domain/models/pace.dart';
import '../../../domain/models/clock.dart';
import '../../core/keys/speedrun_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/pace/pace_ui.dart';
import '../../core/theme/app_shape.dart';
import '../../history/widgets/history_labels.dart';

/// O chip do ritmo de um speedrun (`CompTempo` tipo ritmo, tamanho p): pílula
/// cinza cheia de 28, ícone da categoria do ritmo e texto de 14 em negrito.
class SpeedrunPaceChip extends StatelessWidget {
  const SpeedrunPaceChip(this.time, {super.key = SpeedrunKeys.paceChip});

  final TimeControl time;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final label = paceLabel(context.l10n, time);
    return Semantics(
      container: true,
      label: label,
      excludeSemantics: true,
      child: Container(
        // 28 no artboard; o texto maior (fonte 2,0) cresce a caixa.
        constraints: const BoxConstraints(minHeight: 28),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: colors.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppShape.full),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 6,
          children: [
            Icon(
              paceIcon(PaceCategory.of(time)),
              size: 16,
              color: colors.onSurfaceVariant,
            ),
            Flexible(
              child: Text(
                HistoryLabels.ltr(label),
                style: theme.textTheme.labelLarge?.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: colors.onSurface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

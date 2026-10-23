import 'package:flutter/material.dart';
import 'package:lucena_ui/lucena_ui.dart';

import '../../../domain/models/pace.dart';
import '../../../domain/models/clock.dart';
import '../../core/keys/speedrun_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/pace/pace_ui.dart';
import '../../history/widgets/history_labels.dart';

/// O chip do ritmo de um speedrun (`CompTempo` tipo ritmo, tamanho p): pílula
/// cinza cheia ([InfoChip] `filled`), com o ícone da categoria do ritmo.
class SpeedrunPaceChip extends StatelessWidget {
  const SpeedrunPaceChip(this.time, {super.key = SpeedrunKeys.paceChip});

  final TimeControl time;

  @override
  Widget build(BuildContext context) {
    final label = paceLabel(context.l10n, time);
    return Semantics(
      container: true,
      label: label,
      excludeSemantics: true,
      child: InfoChip(
        icon: paceIcon(PaceCategory.of(time)),
        label: HistoryLabels.ltr(label),
      ),
    );
  }
}

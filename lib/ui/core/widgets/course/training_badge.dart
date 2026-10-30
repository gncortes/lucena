import 'package:flutter/material.dart';

import '../../../endgames/widgets/stars_row.dart';
import '../../keys/training_keys.dart';
import '../../l10n/l10n.dart';
import '../../theme/app_icon_size.dart';

/// Selo do treino: ícone e rótulo, sem fundo ou contorno (canvas T85).
class TrainingBadge extends StatelessWidget {
  const TrainingBadge({required this.icon, required this.label, super.key});

  factory TrainingBadge.difficulty(BuildContext context, int difficulty) =>
      TrainingBadge(
        key: TrainingKeys.difficultyBadge,
        icon: ValueStar(points: difficulty, size: 18),
        label: difficultyLabel(context, difficulty),
      );

  factory TrainingBadge.withHint(BuildContext context) => TrainingBadge(
    key: TrainingKeys.hintBadge,
    icon: const Icon(Icons.lightbulb_outline, size: AppIconSize.button),
    label: context.l10n.trainingWithHint,
  );

  final Widget icon;
  final String label;

  static String difficultyLabel(BuildContext context, int difficulty) {
    assert(difficulty >= 1 && difficulty <= 3);
    return switch (difficulty) {
      1 => context.l10n.challengeLevelEasy,
      2 => context.l10n.challengeLevelMedium,
      _ => context.l10n.challengeLevelHard,
    };
  }

  static Widget difficultyIcon(
    BuildContext context,
    int difficulty, {
    Key? key,
    double size = 18,
  }) => Semantics(
    key: key,
    label: difficultyLabel(context, difficulty),
    excludeSemantics: true,
    child: ValueStar(points: difficulty, size: size),
  );

  @override
  Widget build(BuildContext context) => Semantics(
    label: label,
    excludeSemantics: true,
    child: Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 4,
      children: [
        icon,
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            height: 20 / 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    ),
  );
}

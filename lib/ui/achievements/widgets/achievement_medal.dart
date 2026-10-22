import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// A medalha de uma conquista: disco de ouro liso com o ícone quando obtida; cinza,
/// com um cadeado por cima, quando falta. O [shine] passa um brilho pelo
/// disco (o aviso e o detalhe usam).
class AchievementMedal extends StatelessWidget {
  const AchievementMedal({
    required this.icon,
    required this.unlocked,
    this.size = 40,
    this.shine,
    this.lockKey,
    this.lockLabel,
    super.key,
  });

  final IconData icon;
  final bool unlocked;
  final double size;
  final Animation<double>? shine;

  /// A key e o rótulo de acessibilidade do cadeado, quando falta.
  final Key? lockKey;
  final String? lockLabel;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final gold = AppColors.of(context).gold;
    final shine = this.shine;
    final disc = SizedBox.square(
      dimension: size,
      child: ClipOval(
        child: Stack(
          fit: StackFit.expand,
          children: [
            DecoratedBox(
              decoration: unlocked
                  ? BoxDecoration(color: gold)
                  : BoxDecoration(color: colors.surfaceContainerHighest),
            ),
            Icon(
              icon,
              size: size * 0.58,
              color: unlocked ? AppColors.goldInk : colors.outline,
            ),
            if (unlocked && shine != null)
              AnimatedBuilder(
                animation: shine,
                builder: (context, _) {
                  final t = shine.value;
                  // Parado no começo e no fim, o brilho fica fora do disco.
                  if (t == 0 || t == 1) return const SizedBox.shrink();
                  return FractionalTranslation(
                    translation: Offset(t * 2.4 - 1.2, 0),
                    child: Transform.rotate(
                      angle: 0.5,
                      child: const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.shineClear,
                              AppColors.shine,
                              AppColors.shineClear,
                            ],
                            stops: [0.35, 0.5, 0.65],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
    if (unlocked) return disc;
    final badge = size * 0.46;
    return SizedBox.square(
      dimension: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          disc,
          PositionedDirectional(
            end: -badge * 0.15,
            bottom: -badge * 0.15,
            child: Container(
              key: lockKey,
              width: badge,
              height: badge,
              decoration: BoxDecoration(
                color: colors.surface,
                shape: BoxShape.circle,
                border: Border.all(color: colors.outlineVariant),
              ),
              child: Icon(
                Icons.lock,
                size: badge * 0.62,
                color: colors.onSurfaceVariant,
                semanticLabel: lockLabel,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

/// O progresso por passos: um segmento por passo, os feitos cheios e o atual
/// enchendo com animação. Espelha sozinho nos idiomas da direita para a
/// esquerda.
class StepProgress extends StatelessWidget {
  const StepProgress({
    required this.total,
    required this.value,
    this.height = 8,
    super.key,
  });

  /// Quantos passos há.
  final int total;

  /// Quanto já foi feito, de 0 a [total] (fração enche o segmento em parte).
  final double value;
  final double height;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return TweenAnimationBuilder<double>(
      tween: Tween(end: value.clamp(0, total.toDouble())),
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) => Row(
        children: [
          for (var index = 0; index < total; index++) ...[
            if (index > 0) const SizedBox(width: 4),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(height / 2),
                child: SizedBox(
                  height: height,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ColoredBox(color: colors.surfaceContainerHighest),
                      FractionallySizedBox(
                        alignment: AlignmentDirectional.centerStart,
                        widthFactor: (value - index).clamp(0.0, 1.0),
                        child: ColoredBox(color: colors.primary),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

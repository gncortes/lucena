import 'package:flutter/material.dart';

import '../theme/app_motion.dart';
import '../theme/app_shape.dart';
import '../theme/app_spacing.dart';

/// Um bloco cinza no lugar do que ainda está carregando, com um brilho que
/// passa (T51, G5). Com "remover animações", fica parado.
class SkeletonBlock extends StatefulWidget {
  const SkeletonBlock({
    this.width = double.infinity,
    this.height = 16,
    this.radius = AppShape.small,
    super.key,
  });

  final double width;
  final double height;
  final double radius;

  /// Uma volta do brilho.
  static const sweep = Duration(milliseconds: 1400);

  @override
  State<SkeletonBlock> createState() => _SkeletonBlockState();
}

class _SkeletonBlockState extends State<SkeletonBlock>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: SkeletonBlock.sweep,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (AppMotion.of(context).disabled) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final base = colors.surfaceContainerHighest;
    final shine = Color.lerp(base, colors.surface, 0.6)!;
    final still = AppMotion.of(context).disabled;
    final block = DecoratedBox(
      decoration: BoxDecoration(
        color: base,
        borderRadius: BorderRadius.circular(widget.radius),
      ),
      child: SizedBox(width: widget.width, height: widget.height),
    );
    return ExcludeSemantics(
      child: still
          ? block
          : AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                // O brilho atravessa o bloco da esquerda para a direita.
                final t = _controller.value * 3 - 1;
                return ShaderMask(
                  blendMode: BlendMode.srcATop,
                  shaderCallback: (bounds) => LinearGradient(
                    colors: [base, shine, base],
                    stops: [
                      (t - 0.3).clamp(0, 1),
                      t.clamp(0, 1),
                      (t + 0.3).clamp(0, 1),
                    ],
                  ).createShader(bounds),
                  child: child,
                );
              },
              child: block,
            ),
    );
  }
}

/// Linhas de esqueleto no lugar de uma lista que carrega: um retrato redondo,
/// um título e uma linha menor.
class SkeletonList extends StatelessWidget {
  const SkeletonList({this.rows = 4, super.key});

  final int rows;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: MaterialLocalizations.of(context).refreshIndicatorSemanticLabel,
      child: Column(
        children: [
          for (var i = 0; i < rows; i++)
            const Padding(
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.screen,
                vertical: AppSpacing.md,
              ),
              child: Row(
                children: [
                  SkeletonBlock(width: 40, height: 40, radius: AppShape.full),
                  SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SkeletonBlock(height: 14),
                        SizedBox(height: AppSpacing.sm),
                        SkeletonBlock(width: 120, height: 12),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

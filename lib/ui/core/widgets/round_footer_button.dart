import 'package:flutter/material.dart';

/// O botão redondo só com ícone dos rodapés (lição, exercício, prática): o
/// mesmo da lâmpada da dica e dos outros ícones. O texto vai no tooltip, que
/// também é o rótulo de acessibilidade.
class RoundFooterButton extends StatelessWidget {
  const RoundFooterButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    super.key,
  });

  /// O diâmetro do botão (o do FAB padrão do Material).
  static const size = 56.0;

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return FloatingActionButton(
      heroTag: null,
      shape: const CircleBorder(),
      elevation: 2,
      backgroundColor: colors.surface,
      foregroundColor: colors.primary,
      tooltip: tooltip,
      onPressed: onPressed,
      child: Icon(icon),
    );
  }
}

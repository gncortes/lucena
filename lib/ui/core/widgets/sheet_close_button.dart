import 'package:flutter/material.dart';

/// O ✕ redondo que flutua acima de uma folha, fora dela, no canto direito:
/// o da fala do Viktor na lição e o da página da web. A mesma cor da folha
/// da fala, com uma sombra leve.
class SheetCloseButton extends StatelessWidget {
  const SheetCloseButton({required this.onPressed, this.tooltip, super.key});

  /// O espaço entre a folha e o botão.
  static const gap = 20.0;

  /// Da borda direita da tela até o botão.
  static const margin = 12.0;

  /// O botão e o espaço até a folha: quanto ele sobe acima dela.
  static const lift = 48 + gap;

  final VoidCallback onPressed;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return IconButton.filled(
      style: IconButton.styleFrom(
        backgroundColor: colors.surfaceContainerLow,
        foregroundColor: colors.onSurface,
        elevation: 2,
      ),
      tooltip: tooltip ?? MaterialLocalizations.of(context).closeButtonTooltip,
      icon: const Icon(Icons.close_rounded),
      onPressed: onPressed,
    );
  }
}

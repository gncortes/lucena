import 'package:flutter/material.dart';

import '../theme/app_icon_size.dart';
import '../theme/canvas_symbols.dart';

/// O cinza do botão sem uso (canvas `T70-etapa1-estados`, `.cb`).
const _off = Color(0xFFB9BDC7);

/// O botão redondo de navegação (lance anterior e próximo dos exercícios): 48 dp, ícone na cor primária,
/// sem fundo; o principal tem 56 dp, fundo primário. Sem ação, cinza.
class RoundNavButton extends StatelessWidget {
  const RoundNavButton({
    required this.buttonKey,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.main = false,
    super.key,
  });

  static const size = 48.0;
  static const mainSize = 56.0;

  final Key buttonKey;
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final bool main;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final side = main ? mainSize : size;
    return IconButton(
      key: buttonKey,
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(
        icon,
        size: AppIconSize.standard,
        fill: icon.fontFamily == CanvasSymbols.family ? 1 : null,
      ),
      style: IconButton.styleFrom(
        fixedSize: Size.square(side),
        minimumSize: Size.square(side),
        padding: EdgeInsets.zero,
        shape: const CircleBorder(),
        backgroundColor: main ? colors.primary : Colors.transparent,
        foregroundColor: main ? colors.onPrimary : colors.primary,
        disabledForegroundColor: _off,
      ),
    );
  }
}

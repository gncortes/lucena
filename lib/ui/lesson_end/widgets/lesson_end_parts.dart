import 'package:flutter/material.dart';

import '../../core/theme/app_icon_size.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/canvas_symbols.dart';

/// Peças comuns das telas de fim (T85-D1): o X do topo, o círculo do ícone
/// e os estilos de texto dos quadros do canvas.
class LessonEndClose extends StatelessWidget implements PreferredSizeWidget {
  const LessonEndClose({
    required this.buttonKey,
    required this.onClose,
    this.actions,
    super.key,
  });

  final Key buttonKey;
  final VoidCallback onClose;
  final List<Widget>? actions;

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) => AppBar(
    toolbarHeight: 64,
    automaticallyImplyLeading: false,
    leading: IconButton(
      key: buttonKey,
      icon: const Icon(CanvasSymbols.close),
      tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
      onPressed: onClose,
    ),
    actions: actions,
  );
}

/// Círculo de 80 com o ícone de 48 (canvas: #E2F0E4 / #2E6B45).
class LessonEndBadge extends StatelessWidget {
  const LessonEndBadge({required this.icon, super.key});
  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
    width: 80,
    height: 80,
    decoration: const BoxDecoration(
      shape: BoxShape.circle,
      color: AppColors.goalWinBg,
    ),
    child: Icon(
      icon,
      size: AppIconSize.illustration,
      color: AppColors.trainingDayCorrect,
    ),
  );
}

TextStyle? endTitleStyle(BuildContext context) => Theme.of(context)
    .textTheme
    .titleLarge
    ?.copyWith(
      fontSize: 22,
      height: 28 / 22,
      fontWeight: FontWeight.w800,
      letterSpacing: 0,
    );

TextStyle? endSubtitleStyle(BuildContext context) =>
    Theme.of(context).textTheme.titleMedium?.copyWith(
      fontSize: 16,
      height: 24 / 16,
      fontWeight: FontWeight.w500,
      letterSpacing: 0,
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );

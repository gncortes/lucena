import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../domain/models/app_accent.dart';
import '../l10n/l10n.dart';
import '../theme/app_accent_ui.dart';

/// As cores do app em bolinhas, numa linha: a escolhida ganha o anel e a
/// marca.
class AccentPicker extends StatelessWidget {
  const AccentPicker({
    required this.selected,
    required this.onSelected,
    required this.keyOf,
    super.key,
  });

  final AppAccent selected;
  final ValueChanged<AppAccent> onSelected;
  final Key Function(AppAccent accent) keyOf;

  static const _maxDot = 52.0;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return LayoutBuilder(
      builder: (context, constraints) {
        // Em tela estreita as bolinhas encolhem para caber todas.
        final dot = math.min(
          _maxDot,
          constraints.maxWidth / AppAccent.values.length - 4,
        );
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (final accent in AppAccent.values)
              _Dot(
                key: keyOf(accent),
                size: dot,
                color: accent.swatch,
                label: accent.label(l10n),
                selected: accent == selected,
                onTap: () => onSelected(accent),
              ),
          ],
        );
      },
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({
    required this.size,
    required this.color,
    required this.label,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final double size;
  final Color color;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: InkResponse(
        onTap: onTap,
        radius: size / 2 + 4,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: size,
          height: size,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              width: 3,
              color: selected ? color : Colors.transparent,
            ),
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: AnimatedScale(
              scale: selected ? 1 : 0,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutBack,
              child: Icon(
                Icons.check_rounded,
                size: size * 0.45,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

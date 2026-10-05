import 'package:flutter/material.dart';

import '../../../domain/models/character.dart';
import '../../core/l10n/l10n.dart';

/// O retrato redondo de um adversário numa trilha (a da Jornada e a das
/// etapas do speedrun).
class TrailPortrait extends StatelessWidget {
  const TrailPortrait({
    required this.character,
    required this.size,
    required this.locked,
    required this.completed,
    required this.current,
    required this.doneColor,
    this.lockKey,
    this.doneKey,
    super.key,
  });

  final Character? character;
  final double size;
  final bool locked;
  final bool completed;
  final bool current;
  final Key? lockKey;
  final Key? doneKey;
  final Color doneColor;

  // Tira a cor do retrato trancado.
  static const _grayscale = ColorFilter.matrix([
    0.2126, 0.7152, 0.0722, 0, 0, //
    0.2126, 0.7152, 0.0722, 0, 0, //
    0.2126, 0.7152, 0.0722, 0, 0, //
    0, 0, 0, 1, 0, //
  ]);

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final character = this.character;
    Widget image = character == null
        ? Icon(Icons.person, size: size * 0.6, color: colors.outline)
        : Image.asset(
            character.avatar,
            width: size,
            height: size,
            fit: BoxFit.cover,
            excludeFromSemantics: true,
          );
    if (locked) {
      image = Opacity(
        opacity: 0.6,
        child: ColorFiltered(colorFilter: _grayscale, child: image),
      );
    }
    final ring = current
        ? colors.primary
        : completed
        ? doneColor
        : colors.outlineVariant;
    return SizedBox.square(
      dimension: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colors.surfaceContainerHighest,
              border: Border.all(color: ring, width: current ? 4 : 3),
              boxShadow: current
                  ? [
                      BoxShadow(
                        color: colors.primary.withValues(alpha: 0.35),
                        blurRadius: 12,
                      ),
                    ]
                  : null,
            ),
            child: ClipOval(child: image),
          ),
          if (locked)
            Center(
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: colors.surface.withValues(alpha: 0.9),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.lock,
                  key: lockKey,
                  size: size * 0.3,
                  color: colors.outline,
                  semanticLabel: l10n.journeyLockedLabel,
                ),
              ),
            ),
          if (completed)
            PositionedDirectional(
              end: -2,
              bottom: -2,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.surface,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle,
                  key: doneKey,
                  size: 24,
                  color: doneColor,
                  semanticLabel: l10n.journeyCompletedLabel,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Um selo pequeno de texto colorido ("Concluído", "Chefe final").
class TrailBadge extends StatelessWidget {
  const TrailBadge({required this.text, required this.color, super.key});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelSmall
            ?.copyWith(color: color, fontWeight: FontWeight.w700),
      ),
    );
  }
}

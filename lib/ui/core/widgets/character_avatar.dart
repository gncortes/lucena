import 'package:flutter/material.dart';

import '../../../domain/models/character.dart';

/// O retrato do personagem, no quadrado de cantos arredondados do chess.com.
/// Com [emotion], a imagem é a da emoção (quando há) e um selo no canto mostra
/// como ele está.
class CharacterAvatar extends StatelessWidget {
  const CharacterAvatar({
    required this.character,
    this.size = 44,
    this.emotion,
    super.key,
  });

  final Character character;
  final double size;
  final Emotion? emotion;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final emotion = this.emotion;
    return SizedBox.square(
      dimension: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(size * 0.14),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: Image.asset(
                  character.imageFor(emotion),
                  key: ValueKey(character.imageFor(emotion)),
                  width: size,
                  height: size,
                  fit: BoxFit.cover,
                  // O retrato é decorativo: o nome vem ao lado.
                  excludeFromSemantics: true,
                ),
              ),
            ),
          ),
          if (emotion != null)
            PositionedDirectional(
              end: -size * 0.12,
              bottom: -size * 0.12,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                transitionBuilder: (child, animation) =>
                    ScaleTransition(scale: animation, child: child),
                child: Container(
                  key: ValueKey('emotion.${emotion.name}'),
                  padding: const EdgeInsets.all(1),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    emotionIcon(emotion),
                    size: size * 0.34,
                    color: colors.primary,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// O rosto de cada emoção, no selo do retrato.
IconData emotionIcon(Emotion emotion) => switch (emotion) {
  Emotion.calm => Icons.sentiment_neutral,
  Emotion.happy => Icons.sentiment_satisfied_alt,
  Emotion.confident => Icons.sentiment_very_satisfied,
  Emotion.playful => Icons.mood,
  Emotion.focused => Icons.psychology_outlined,
  Emotion.surprised => Icons.error_outline,
  Emotion.nervous => Icons.sentiment_dissatisfied,
  Emotion.frustrated => Icons.mood_bad,
  Emotion.sad => Icons.sentiment_very_dissatisfied,
};

import 'package:flutter/material.dart';

import '../../../domain/models/character.dart';

/// O retrato do personagem, no quadrado de cantos arredondados do chess.com.
/// Com [emotion], a imagem é a da emoção, quando o personagem tem uma.
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
    return SizedBox.square(
      dimension: size,
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
    );
  }
}

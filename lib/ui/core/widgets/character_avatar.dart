import 'package:flutter/material.dart';
import 'package:lucena_ui/lucena_ui.dart';

import '../../../domain/models/character.dart';

/// O retrato do personagem, no quadrado de cantos arredondados do chess.com.
/// Com [emotion], a imagem é a da emoção, quando o personagem tem uma.
class CharacterAvatar extends StatelessWidget {
  const CharacterAvatar({
    required this.character,
    this.size = player,
    this.radius,
    this.emotion,
    super.key,
  });

  /// Os tamanhos do retrato (T73, D9; canvas 96d710e): fala em cartão fora do
  /// tabuleiro, linha da lição, jogador em linha, tour e confronto (VS), mais o mini dos chips.
  static const speech = 56.0;
  static const lesson = 40.0;
  static const player = 44.0;
  static const tour = 64.0;
  static const versus = 72.0;

  /// O retrato pequeno dentro de chip e de linha compacta.
  static const mini = 28.0;

  final Character character;
  final double size;

  /// Raio dos cantos; nulo: 14% do tamanho.
  final double? radius;
  final Emotion? emotion;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius ?? size * 0.14),
        child: AnimatedSwitcher(
          duration: AppMotion.state,
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

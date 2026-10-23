import 'package:flutter/material.dart';
import 'package:lucena_ui/lucena_ui.dart';

import '../../../domain/models/character.dart';

/// O retrato de um [Character] do app (com a [emotion], quando ele tem uma
/// imagem para ela). O desenho em si é o `CharacterAvatar` do `lucena_ui`.
class CharacterPortrait extends StatelessWidget {
  const CharacterPortrait({
    required this.character,
    this.size = CharacterAvatar.player,
    this.radius,
    this.emotion,
    super.key,
  });

  final Character character;
  final double size;
  final double? radius;
  final Emotion? emotion;

  @override
  Widget build(BuildContext context) => CharacterAvatar(
    image: portraitImage(character, emotion),
    size: size,
    radius: radius,
  );
}

/// A imagem do personagem para a emoção pedida.
ImageProvider portraitImage(Character character, [Emotion? emotion]) =>
    AssetImage(character.imageFor(emotion));

/// Como [portraitImage], para quem pode não ter personagem.
ImageProvider? portraitImageOrNull(Character? character, [Emotion? emotion]) =>
    character == null ? null : portraitImage(character, emotion);

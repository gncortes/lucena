import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';

import '../../../domain/models/character.dart';
import '../../../domain/models/speedrun.dart';
import '../../../domain/use_cases/subcategory_material.dart';
import '../../catalog/widgets/catalog_ui.dart';
import '../../core/l10n/l10n.dart';
import '../../core/widgets/character_avatar.dart';
import '../../core/widgets/figurine.dart';
import '../../journey/widgets/journey_ui.dart';

/// O nome de um speedrun: contra quem (`Contra o Coco`), o nome do final
/// (`Dama contra torre`), a série de exercícios ou a Jornada completa.
String speedrunName(
  AppLocalizations l10n,
  List<Character> characters,
  Speedrun speedrun,
) => switch (speedrun.kind) {
  SpeedrunKind.rung => l10n.speedrunRungTitle(
    opponentName(l10n, characters, speedrun.stages.first.opponent),
  ),
  SpeedrunKind.ending => endgameName(
    l10n,
    speedrun.stages.first.position.subcategory,
  ),
  SpeedrunKind.exercises => categoryName(
    l10n,
    speedrun.stages.first.position.category,
  ),
  SpeedrunKind.full => l10n.speedrunFullTitle,
};

/// O nome de um speedrun como texto.
class SpeedrunTitle extends StatelessWidget {
  const SpeedrunTitle(
    this.speedrun, {
    required this.characters,
    this.style,
    super.key,
  });

  final Speedrun speedrun;
  final List<Character> characters;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) =>
      Text(speedrunName(context.l10n, characters, speedrun), style: style);
}

/// A imagem de um speedrun: o retrato do adversário, o material do final ou
/// um ícone.
class SpeedrunPicture extends StatelessWidget {
  const SpeedrunPicture(
    this.speedrun, {
    required this.characters,
    this.size = 56,
    super.key,
  });

  final Speedrun speedrun;
  final List<Character> characters;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final character = speedrun.kind == SpeedrunKind.rung
        ? opponentCharacter(characters, speedrun.stages.first.opponent)
        : null;
    if (character != null) {
      return CharacterAvatar(character: character, size: size);
    }
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: colors.secondaryContainer,
        borderRadius: BorderRadius.circular(size * 0.14),
      ),
      child: speedrun.kind == SpeedrunKind.ending
          ? _Material(
              subcategory: speedrun.stages.first.position.subcategory,
              size: size,
              color: colors.onSecondaryContainer,
            )
          : Icon(
              speedrun.kind == SpeedrunKind.full
                  ? Icons.emoji_events_outlined
                  : Icons.fitness_center,
              size: size * 0.5,
              color: colors.onSecondaryContainer,
            ),
    );
  }
}

/// O material do final em duas linhas: as peças das brancas em cima (em
/// contorno) e as das pretas embaixo (cheias), grandes o bastante para ler.
class _Material extends StatelessWidget {
  const _Material({
    required this.subcategory,
    required this.size,
    required this.color,
  });

  final String subcategory;
  final double size;
  final Color color;

  static const _outlined = {
    Role.king: '♔',
    Role.queen: '♕',
    Role.rook: '♖',
    Role.bishop: '♗',
    Role.knight: '♘',
    Role.pawn: '♙',
  };
  static const _filled = {
    Role.king: '♚',
    Role.queen: '♛',
    Role.rook: '♜',
    Role.bishop: '♝',
    Role.knight: '♞',
    Role.pawn: '♟',
  };

  @override
  Widget build(BuildContext context) {
    final (white, black) = SubcategoryMaterial.of(subcategory);
    final style = TextStyle(
      fontFamily: Figurine.fontFamily,
      fontSize: size * 0.34,
      height: 1.1,
      color: color,
    );
    return Padding(
      padding: const EdgeInsets.all(4),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              white.map((role) => _outlined[role]).join(),
              textDirection: TextDirection.ltr,
              style: style,
            ),
            Text(
              black.map((role) => _filled[role]).join(),
              textDirection: TextDirection.ltr,
              style: style,
            ),
          ],
        ),
      ),
    );
  }
}

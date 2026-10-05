import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/models/character.dart';
import '../../../domain/models/journey.dart';
import '../../../domain/models/speedrun.dart';
import '../../../domain/use_cases/subcategory_material.dart';
import '../../catalog/widgets/catalog_ui.dart';
import '../../core/l10n/l10n.dart';
import '../../core/widgets/character_avatar.dart';
import '../../core/widgets/figurine.dart';
import '../../core/widgets/goal_style.dart';
import '../../journey/widgets/journey_ui.dart';
import '../../journey/widgets/trail_widgets.dart';
import '../view_models/speedrun_cubit.dart';

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

/// Como uma etapa aparece na trilha.
enum SpeedrunStageStatus {
  /// Sem tentativa em andamento.
  idle,
  done,
  current,
  ahead,
}

/// Uma etapa na trilha, no formato da Jornada: o retrato do adversário num
/// círculo, ligado aos vizinhos por uma linha, com o nome, a etapa e o melhor
/// tempo dela. Com uma tentativa em andamento, as etapas vencidas levam o
/// selo de feito e a da vez fica maior e em destaque; a última é o chefe
/// final.
class SpeedrunStageRow extends StatelessWidget {
  const SpeedrunStageRow({
    required this.index,
    required this.stage,
    required this.speedrun,
    required this.last,
    required this.status,
    this.trailing,
    this.losses = 0,
    super.key,
  });

  final int index;
  final Challenge stage;
  final Speedrun speedrun;
  final bool last;
  final SpeedrunStageStatus status;

  /// O que vai na ponta da linha: o tempo da etapa.
  final Widget? trailing;

  /// As derrotas nesta etapa (a etapa perdida é jogada de novo).
  final int losses;

  // O meio da coluna dos retratos, por onde passa a linha.
  static const _railX = 52.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final l10n = context.l10n;
    final characters = context.select(
      (SpeedrunCubit cubit) => cubit.state.characters,
    );
    final current = status == SpeedrunStageStatus.current;
    final done = status == SpeedrunStageStatus.done;
    final ahead = status == SpeedrunStageStatus.ahead;
    final size = current ? 72.0 : 56.0;
    final height = current ? 108.0 : 84.0;
    final doneColor = ChangeColors.of(context, up: true);
    final first = index == 0;
    return SizedBox(
      height: height,
      child: Stack(
        children: [
          // A linha da trilha, atrás dos retratos: só a metade de baixo na
          // primeira etapa e só a de cima na última. Até a etapa da vez, ela
          // vem na cor de feito.
          PositionedDirectional(
            start: _railX - 2,
            width: 4,
            top: first ? height / 2 : 0,
            bottom: height / 2,
            child: ColoredBox(
              color: done || current ? doneColor : colors.outlineVariant,
            ),
          ),
          if (!last)
            PositionedDirectional(
              start: _railX - 2,
              width: 4,
              top: height / 2,
              bottom: 0,
              child: ColoredBox(
                color: done ? doneColor : colors.outlineVariant,
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                SizedBox(
                  width: 72,
                  child: Center(
                    child: TrailPortrait(
                      character: opponentCharacter(characters, stage.opponent),
                      size: size,
                      locked: false,
                      completed: done,
                      current: current,
                      doneColor: doneColor,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        opponentName(l10n, characters, stage.opponent),
                        style:
                            (current
                                    ? theme.textTheme.titleLarge
                                    : theme.textTheme.titleMedium)
                                ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: ahead ? colors.onSurfaceVariant : null,
                                ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        [
                          l10n.speedrunStageOf(
                            index + 1,
                            speedrun.stages.length,
                          ),
                          // Quando o final muda de etapa para etapa, o nome
                          // dele vem junto.
                          if (speedrun.kind != SpeedrunKind.ending)
                            endgameName(l10n, stage.position.subcategory),
                        ].join(' · '),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                      if (losses > 0)
                        Text(
                          l10n.speedrunLosses(losses),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colors.error,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      if (current || last) ...[
                        const SizedBox(height: 6),
                        TrailBadge(
                          text: current ? l10n.speedrunNow : l10n.journeyBoss,
                          color: current ? colors.primary : colors.tertiary,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                ?trailing,
              ],
            ),
          ),
        ],
      ),
    );
  }
}

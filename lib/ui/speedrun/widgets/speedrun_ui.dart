import 'dart:math' as math;

import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/models/character.dart';
import '../../../domain/models/journey.dart';
import '../../../domain/models/speedrun.dart';
import '../../../domain/use_cases/marathon.dart';
import '../../../domain/use_cases/subcategory_material.dart';
import '../../catalog/widgets/catalog_ui.dart';
import '../../core/keys/speedrun_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_button.dart';
import '../../core/widgets/character_avatar.dart';
import '../../core/widgets/figurine.dart';
import '../../core/widgets/goal_style.dart';
import '../../core/widgets/info_chip.dart';
import '../../journey/widgets/journey_ui.dart';
import '../../journey/widgets/trail_widgets.dart';
import '../../../domain/use_cases/speedrun_category.dart';
import '../../../routing/routes.dart';
import '../../core/theme/app_spacing.dart';
import '../../history/widgets/history_labels.dart';
import '../view_models/speedrun_cubit.dart';
import 'speedrun_pace_chip.dart';
import '../../core/theme/app_colors.dart';

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
  SpeedrunKind.marathon => l10n.speedrunMarathonTitle(
    endgameName(l10n, speedrun.stages.first.position.subcategory),
  ),
};

/// O tempo que um recorde de [speedrun] mostra: o total, ou, na Maratona, o
/// que sobrou no banco.
Duration recordTime(Speedrun speedrun, Duration total) =>
    speedrun.kind == SpeedrunKind.marathon
    ? Marathon.left(speedrun.time, total)
    : total;

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
      child:
          speedrun.kind == SpeedrunKind.ending ||
              speedrun.kind == SpeedrunKind.marathon
          ? _Material(
              subcategory: speedrun.stages.first.position.subcategory,
              size: size,
              color: colors.onSecondaryContainer,
            )
          : Icon(
              speedrun.kind == SpeedrunKind.full
                  ? Icons.timer_outlined
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
/// círculo, ligado aos vizinhos por uma linha, com o nome, a etapa e, na ponta,
/// o tempo dela. Com uma tentativa em andamento, as etapas vencidas levam o
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
    this.note,
    this.noteKey,
    super.key,
  });

  final int index;
  final Challenge stage;
  final Speedrun speedrun;
  final bool last;
  final SpeedrunStageStatus status;

  /// O que vai na ponta da linha: o tempo da etapa.
  final Widget? trailing;

  /// A nota depois de "Etapa N de M" ("perdeu aqui"): a etapa onde a
  /// tentativa parou.
  final String? note;
  final Key? noteKey;

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
    return ConstrainedBox(
      // 84/108 no artboard; o texto maior (fonte 2,0) cresce a linha.
      constraints: BoxConstraints(minHeight: height),
      child: Stack(
        fit: StackFit.passthrough,
        children: [
          // A linha da trilha, atrás dos retratos: só a metade de baixo na
          // primeira etapa e só a de cima na última. Até a etapa da vez, ela
          // vem na cor de feito.
          PositionedDirectional(
            start: _railX - 2,
            width: 4,
            top: 0,
            bottom: 0,
            child: Column(
              children: [
                Expanded(
                  child: first
                      ? const SizedBox.shrink()
                      : ColoredBox(
                          color: done || current
                              ? doneColor
                              : colors.outlineVariant,
                          child: const SizedBox.expand(),
                        ),
                ),
                Expanded(
                  child: last
                      ? const SizedBox.shrink()
                      : ColoredBox(
                          color: done ? doneColor : colors.outlineVariant,
                          child: const SizedBox.expand(),
                        ),
                ),
              ],
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
                  // A linha cresce com o texto (fonte grande, árabe); a
                  // trilha acompanha.
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
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
                                    color: ahead
                                        ? colors.onSurfaceVariant
                                        : null,
                                  ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          key: noteKey,
                          note != null
                              ? l10n.speedrunStageNote(
                                  index + 1,
                                  speedrun.stages.length,
                                  note!,
                                )
                              : [
                                  l10n.speedrunStageOf(
                                    index + 1,
                                    speedrun.stages.length,
                                  ),
                                  // Quando o final muda de etapa para etapa, o nome
                                  // dele vem junto.
                                  if (speedrun.kind != SpeedrunKind.ending &&
                                      speedrun.kind != SpeedrunKind.marathon)
                                    endgameName(
                                      l10n,
                                      stage.position.subcategory,
                                    ),
                                ].join(' · '),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                        if (last) ...[
                          const SizedBox(height: 6),
                          TrailBadge(
                            text: l10n.journeyBoss,
                            color: colors.tertiary,
                          ),
                        ],
                      ],
                    ),
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

/// A peça, o nome do final, o ritmo e o nível: o cabeçalho do detalhe, do
/// resumo e do histórico (artboards `SpeedrunDetalhe` e `SpeedrunHistorico`).
/// Na Maratona, o nome é só o do final (o título da tela já diz "Maratona").
class SpeedrunHeader extends StatelessWidget {
  const SpeedrunHeader({
    required this.speedrun,
    required this.characters,
    super.key,
  });

  final Speedrun speedrun;
  final List<Character> characters;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final level = switch (SpeedrunCategories.of(speedrun)) {
      SpeedrunCategory.beginner => l10n.profileLevelBeginner,
      SpeedrunCategory.intermediate => l10n.profileLevelIntermediate,
      SpeedrunCategory.advanced => l10n.profileLevelAdvanced,
      null => null,
    };
    final name = speedrun.kind == SpeedrunKind.marathon
        ? endgameName(l10n, speedrun.stages.first.position.subcategory)
        : speedrunName(l10n, characters, speedrun);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        children: [
          SpeedrunPicture(speedrun, characters: characters, size: 72),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    SpeedrunPaceChip(
                      speedrun.time,
                      key: SpeedrunKeys.paceBadge,
                    ),
                    if (level != null)
                      InfoChip(icon: Icons.signal_cellular_alt, label: level),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Começa uma tentativa nova de [speedrun], no ritmo dele, e abre a primeira
/// etapa. Com [replace], a tela de onde se chamou (o resumo) sai da pilha; sem
/// ele, ao voltar da partida o speedrun é lido de novo.
Future<void> startSpeedrun(
  BuildContext context,
  Speedrun speedrun, {
  bool replace = false,
}) async {
  final cubit = context.read<SpeedrunCubit>();
  final started = await cubit.startWith(speedrun.time);
  if (started == null || !context.mounted) return;
  final (paced, attempt) = started;
  final route = Routes.challengeGame(
    paced.stages.first,
    speedrunId: paced.id,
    attemptId: attempt,
    stage: 0,
  );
  if (replace) {
    context.pushReplacement(route);
    return;
  }
  await context.push(route);
  if (context.mounted) await cubit.load(speedrunId: speedrun.id);
}

/// O rodapé fixo das telas do speedrun: fundo da tela, borda de cima e um
/// botão de 52 (como o da conclusão da partida).
class SpeedrunActionBar extends StatelessWidget {
  const SpeedrunActionBar({
    required this.buttonKey,
    required this.icon,
    required this.label,
    required this.onPressed,
    super.key,
  });

  final Key buttonKey;
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screen,
            AppSpacing.sm,
            AppSpacing.screen,
            AppSpacing.sm,
          ),
          child: FilledButton.icon(
            key: buttonKey,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(kButtonHeight),
            ),
            icon: Icon(icon),
            label: Text(label),
            onPressed: onPressed,
          ),
        ),
      ),
    );
  }
}

/// "+N de rating ao concluir" sobre o aviso azul: o "+N de rating" em verde
/// com o ícone, o resto no [style]. (Mesma linha do aviso da Maratona.)
class SpeedrunOfferLine extends StatelessWidget {
  const SpeedrunOfferLine({
    required this.points,
    required this.style,
    super.key,
  });

  final int points;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final background = theme.colorScheme.secondaryContainer;
    final color = _legible(
      ChangeColors.of(context, up: true),
      background,
      theme.brightness,
    );
    final full = l10n.speedrunRatingBonusAtFinish(points);
    final short = l10n.speedrunRatingBonusShort(points);
    final at = full.indexOf(short);
    if (at < 0) return Text(full, style: style);
    final strong = style?.copyWith(fontWeight: FontWeight.w700, color: color);
    return Text.rich(
      TextSpan(
        style: style,
        children: [
          TextSpan(text: full.substring(0, at)),
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: ExcludeSemantics(
              child: Icon(Icons.trending_up, size: 16, color: color),
            ),
          ),
          const WidgetSpan(child: SizedBox(width: AppSpacing.xs)),
          TextSpan(text: HistoryLabels.ltr(short), style: strong),
          TextSpan(text: full.substring(at + short.length)),
        ],
      ),
    );
  }

  // O verde do "sobe" com o contraste de leitura (4,5:1) sobre o aviso.
  static Color _legible(Color color, Color background, Brightness brightness) {
    final target = brightness == Brightness.dark
        ? AppColors.white
        : AppColors.black;
    var result = color;
    for (var i = 0; i < 10 && _contrast(result, background) < 4.5; i++) {
      result = Color.lerp(result, target, 0.1)!;
    }
    return result;
  }

  static double _contrast(Color a, Color b) {
    final la = a.computeLuminance();
    final lb = b.computeLuminance();
    return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
  }
}

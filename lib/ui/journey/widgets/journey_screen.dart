import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/models/character.dart';
import '../../../domain/models/journey.dart';
import '../../../routing/routes.dart';
import '../../core/keys/journey_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/widgets/character_avatar.dart';
import '../../core/widgets/goal_style.dart';
import '../../core/widgets/scroll_padding.dart';
import '../view_models/journey_cubit.dart';
import '../../core/widgets/staggered_entrance.dart';
import 'journey_ui.dart';

/// A Jornada: o adversário atual em destaque e, embaixo, a trilha dos
/// personagens, do mais fraco ao mais forte, com o Stockfish no fim, como
/// chefe final.
class JourneyScreen extends StatelessWidget {
  const JourneyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final progress = context.select(
      (JourneyCubit cubit) => cubit.state.progress,
    );
    return Scaffold(
      key: JourneyKeys.screen,
      appBar: AppBar(title: Text(l10n.journeyTitle)),
      body: progress == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: scrollPadding(context),
              children: [
                _Summary(progress: progress),
                const SizedBox(height: 8),
                // A trilha vai do mais fraco ao mais forte: o Stockfish no
                // fim, como chefe final.
                for (final (index, rung) in progress.rungs.indexed)
                  StaggeredEntrance(
                    index: index,
                    child: _TrailNode(
                      rung: rung,
                      progress: progress,
                      first: index == 0,
                      last: index == progress.rungs.length - 1,
                    ),
                  ),
              ],
            ),
    );
  }
}

Future<void> _openRung(BuildContext context, String id) async {
  // A tela do adversário abre com o que esta já leu: sem espera, e o retrato
  // voa até ela.
  await context.push(
    Routes.journeyRung(id),
    extra: context.read<JourneyCubit>().state,
  );
  // Ao voltar, um degrau pode ter sido concluído.
  if (context.mounted) await context.read<JourneyCubit>().load();
}

/// O cartão do alto: o adversário atual, o progresso contra ele, quem vem
/// depois e o botão de continuar.
class _Summary extends StatelessWidget {
  const _Summary({required this.progress});

  final JourneyProgress progress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final l10n = context.l10n;
    final characters = context.select(
      (JourneyCubit cubit) => cubit.state.characters,
    );
    final current = progress.current;
    final next = progress.next;
    if (current == null) {
      return Card(
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        color: colors.primaryContainer,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Icon(Icons.emoji_events, size: 40, color: colors.primary),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  l10n.journeyFinished,
                  key: JourneyKeys.current,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colors.onPrimaryContainer,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
    final opponent = current.rung.opponent;
    final character = opponentCharacter(characters, opponent);
    final nextCharacter = next == null
        ? null
        : opponentCharacter(characters, next.rung.opponent);
    final total = current.rung.challenges.length;
    final done = current.completed.length;
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      color: colors.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                if (character != null) ...[
                  CharacterAvatar(character: character, size: 72),
                  const SizedBox(width: 16),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.journeyNowFacing,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: colors.onPrimaryContainer,
                        ),
                      ),
                      Text(
                        opponentName(l10n, characters, opponent),
                        key: JourneyKeys.current,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: colors.onPrimaryContainer,
                        ),
                      ),
                      if (opponent.level case final level?)
                        Text(
                          l10n.journeyOpponentLevel('$level'),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colors.onPrimaryContainer,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: total == 0 ? 0 : done / total,
                minHeight: 10,
                backgroundColor: colors.surface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              l10n.journeyRungProgress(done, total),
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                if (next != null) ...[
                  if (nextCharacter != null) ...[
                    CharacterAvatar(character: nextCharacter, size: 28),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: Text(
                      l10n.journeyThen(
                        opponentName(l10n, characters, next.rung.opponent),
                      ),
                      key: JourneyKeys.next,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colors.onPrimaryContainer,
                      ),
                    ),
                  ),
                ] else
                  const Spacer(),
                const SizedBox(width: 8),
                FilledButton(
                  key: JourneyKeys.continueButton,
                  onPressed: () => _openRung(context, current.rung.id),
                  child: Text(l10n.homeContinue),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Um adversário na trilha: o retrato num círculo, ligado aos vizinhos por
/// uma linha. O atual fica maior e destacado; os concluídos levam o selo de
/// feito; os trancados ficam em cinza, com o cadeado sobre o retrato.
class _TrailNode extends StatelessWidget {
  const _TrailNode({
    required this.rung,
    required this.progress,
    required this.first,
    required this.last,
  });

  final RungProgress rung;
  final JourneyProgress progress;

  /// O de cima (sem linha acima) e o de baixo (sem linha abaixo).
  final bool first;
  final bool last;

  // O meio da coluna dos retratos, por onde passa a linha.
  static const _railX = 52.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final l10n = context.l10n;
    final id = rung.rung.id;
    final opponent = rung.rung.opponent;
    final characters = context.select(
      (JourneyCubit cubit) => cubit.state.characters,
    );
    final character = opponentCharacter(characters, opponent);
    final locked = rung.status == RungStatus.locked;
    final completed = rung.status == RungStatus.completed;
    final current = progress.current?.rung.id == id;
    final size = current ? 76.0 : 60.0;
    final height = current ? 116.0 : 96.0;
    final done = ChangeColors.of(context, up: true);
    return InkWell(
      key: JourneyKeys.rung(id),
      onTap: () => locked ? _explainLock(context) : _openRung(context, id),
      child: SizedBox(
        height: height,
        child: Stack(
          children: [
            // A linha da trilha, atrás dos retratos: só a metade de baixo no
            // primeiro e só a de cima no último.
            PositionedDirectional(
              start: _railX - 2,
              width: 4,
              top: first ? height / 2 : 0,
              bottom: last ? height / 2 : 0,
              child: ColoredBox(color: colors.outlineVariant),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  SizedBox(
                    width: 72,
                    child: Center(
                      // O retrato voa para o cabeçalho da tela do adversário.
                      child: Hero(
                        tag: opponentHeroTag(id),
                        child: _Portrait(
                          character: character,
                          size: size,
                          locked: locked,
                          completed: completed,
                          current: current,
                          lockKey: JourneyKeys.rungLocked(id),
                          doneKey: JourneyKeys.rungCompleted(id),
                          doneColor: done,
                        ),
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
                          opponentName(l10n, characters, opponent),
                          style:
                              (current
                                      ? theme.textTheme.titleLarge
                                      : theme.textTheme.titleMedium)
                                  ?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: locked ? colors.outline : null,
                                  ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          [
                            if (opponent.level case final level?)
                              l10n.journeyOpponentLevel('$level'),
                            l10n.journeyRungProgress(
                              rung.completed.length,
                              rung.rung.challenges.length,
                            ),
                          ].join(' · '),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: locked
                                ? colors.outline
                                : colors.onSurfaceVariant,
                          ),
                        ),
                        // O último da trilha é o chefe final.
                        if (last || completed) ...[
                          const SizedBox(height: 6),
                          _Badge(
                            text: completed
                                ? l10n.journeyDone
                                : l10n.journeyBoss,
                            color: completed ? done : colors.tertiary,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Trancado: diz o que falta no adversário anterior.
  void _explainLock(BuildContext context) {
    final l10n = context.l10n;
    final before = progress.before(rung.rung.id);
    if (before == null) return;
    final characters = context.read<JourneyCubit>().state.characters;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            l10n.journeyLocked(
              before.remaining,
              opponentName(l10n, characters, before.rung.opponent),
            ),
            key: JourneyKeys.lockedMessage,
          ),
        ),
      );
  }
}

/// O retrato redondo de um adversário da trilha.
class _Portrait extends StatelessWidget {
  const _Portrait({
    required this.character,
    required this.size,
    required this.locked,
    required this.completed,
    required this.current,
    required this.lockKey,
    required this.doneKey,
    required this.doneColor,
  });

  final Character? character;
  final double size;
  final bool locked;
  final bool completed;
  final bool current;
  final Key lockKey;
  final Key doneKey;
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
class _Badge extends StatelessWidget {
  const _Badge({required this.text, required this.color});

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

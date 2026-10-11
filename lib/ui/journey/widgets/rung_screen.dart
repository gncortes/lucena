import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/models/endgame_position.dart';
import '../../../domain/models/journey.dart';
import '../../../routing/routes.dart';
import '../../catalog/widgets/catalog_ui.dart';
import '../../core/keys/journey_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/widgets/character_avatar.dart';
import '../../core/widgets/goal_style.dart';
import '../../core/widgets/position_board.dart';
import '../../core/widgets/position_card.dart';
import '../../core/widgets/scroll_padding.dart';
import '../../core/widgets/teacher_speech.dart';
import '../view_models/journey_cubit.dart';
import '../../core/widgets/staggered_entrance.dart';
import 'journey_ui.dart';
import '../../core/widgets/animated_progress.dart';
import '../../core/theme/app_shape.dart';

/// Os desafios contra um adversário: o personagem com a frase dele e o
/// progresso, o próximo desafio em destaque e todos os desafios em grade, com
/// o selo de feito.
class RungScreen extends StatelessWidget {
  const RungScreen({required this.rungId, super.key});

  final String rungId;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = Theme.of(context).colorScheme;
    final progress = context.select(
      (JourneyCubit cubit) => cubit.state.progress,
    );
    final rung = progress?.rung(rungId);
    final reunion = context.select((JourneyCubit cubit) => cubit.state.reunion);
    final characters = context.select(
      (JourneyCubit cubit) => cubit.state.characters,
    );
    final teacher = [
      for (final character in characters)
        if (character.id == 'master' &&
            character.level == rung?.rung.opponent.level)
          character,
    ].firstOrNull;
    final next = rung == null
        ? null
        : [
            for (final challenge in rung.rung.challenges)
              if (!rung.completed.contains(challenge.id)) challenge,
          ].firstOrNull;
    return Scaffold(
      key: JourneyKeys.rungScreen,
      appBar: AppBar(
        title: Text(
          rung == null
              ? ''
              : opponentName(l10n, characters, rung.rung.opponent),
        ),
      ),
      body: rung == null
          ? const Center(child: CircularProgressIndicator())
          : LayoutBuilder(
              builder: (context, constraints) => ListView(
                padding: scrollPadding(context),
                children: [
                  _Header(rung: rung),
                  if (teacher != null && reunion != null)
                    Card(
                      key: JourneyKeys.reunion,
                      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                      color: colors.primaryContainer,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.rungReunionTitle(teacher.name),
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: colors.onPrimaryContainer,
                                  ),
                            ),
                            const SizedBox(height: 12),
                            TeacherSpeech(
                              speechContext: SpeechContext.teaching,
                              teacher: teacher,
                              text: reunion,
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (next != null) ...[
                    _SectionTitle(l10n.journeyNextChallenge),
                    _NextChallenge(rungId: rungId, challenge: next),
                  ],
                  _SectionTitle(l10n.journeyAllChallenges),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Builder(
                      builder: (context) {
                        // Duas colunas no celular, três em tela larga; cada
                        // cartão com a altura do próprio conteúdo.
                        final columns = constraints.maxWidth >= 600 ? 3 : 2;
                        const gap = 12.0;
                        final width =
                            (constraints.maxWidth - 32 - gap * (columns - 1)) /
                            columns;
                        return Wrap(
                          spacing: gap,
                          runSpacing: gap,
                          children: [
                            for (final (index, challenge)
                                in rung.rung.challenges.indexed)
                              SizedBox(
                                width: width,
                                child: StaggeredEntrance(
                                  index: index,
                                  child: _ChallengeCell(
                                    rungId: rungId,
                                    challenge: challenge,
                                    done: rung.completed.contains(challenge.id),
                                    // O do próximo voa do destaque.
                                    flies: challenge.id != next?.id,
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ),
                  // O mesmo final de outro jeito: às cegas. Vale como extra.
                  if (rung.rung.specials.isNotEmpty) ...[
                    _SectionTitle(l10n.journeySpecialSection),
                    for (final special in rung.rung.specials)
                      _SpecialChallenge(
                        special: special,
                        open: rung.specialOpen(special),
                        done: rung.specialsDone.contains(special.id),
                      ),
                  ],
                ],
              ),
            ),
    );
  }
}

/// Um desafio especial do degrau: o mesmo final às cegas (liberado depois de
/// vencê-lo no modo normal), um speedrun curto ou uma Maratona curta.
class _SpecialChallenge extends StatelessWidget {
  const _SpecialChallenge({
    required this.special,
    required this.open,
    required this.done,
  });

  final Challenge special;
  final bool open;
  final bool done;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Card(
      key: JourneyKeys.special(special.id),
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      color: open ? colors.tertiaryContainer : colors.surfaceContainerLow,
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        enabled: open,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: Icon(
          !open
              ? Icons.lock_outline
              : switch (special.mode) {
                  ChallengeMode.speedrun => Icons.timer_outlined,
                  ChallengeMode.marathon => Icons.all_inclusive_rounded,
                  _ => Icons.record_voice_over_outlined,
                },
          color: open ? colors.onTertiaryContainer : colors.outline,
        ),
        title: Text(
          switch (special.mode) {
            ChallengeMode.speedrun => l10n.journeySpecialSpeedrunTitle,
            ChallengeMode.marathon => l10n.journeySpecialMarathonTitle,
            _ =>
              '${l10n.blindTitle} · ${endgameName(l10n, special.position.subcategory)}',
          },
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Text(switch (special.mode) {
          _ when !open && special.mode == ChallengeMode.blind =>
            l10n.journeySpecialLocked,
          _ when !open => l10n.journeySpecialLockedAny,
          ChallengeMode.speedrun => l10n.journeySpecialSpeedrunBody,
          ChallengeMode.marathon => l10n.journeySpecialMarathonBody,
          _ when special.hideBoard => l10n.journeySpecialNoBoard,
          _ => l10n.journeySpecialSquares,
        }),
        trailing: done
            ? Icon(Icons.check_circle, color: colors.primary)
            : const Icon(Icons.chevron_right),
        onTap: !open
            ? null
            : () async {
                final cubit = context.read<JourneyCubit>();
                final speedrunId = special.speedrunId;
                // O speedrun e a Maratona curtos abrem a tela do speedrun,
                // já no ritmo deles; o às cegas, a partida.
                await context.push(
                  speedrunId != null
                      ? Routes.speedrun(speedrunId)
                      : Routes.blindChallenge(special),
                );
                if (context.mounted) await cubit.load();
              },
      ),
    );
  }
}

Future<void> _openChallenge(
  BuildContext context,
  String rungId,
  Challenge challenge,
) async {
  final cubit = context.read<JourneyCubit>();
  // A tela do desafio abre com ele já pronto: o tabuleiro voa até ela.
  await context.push(
    Routes.journeyChallenge(rungId, challenge.position.id),
    extra: cubit.state.copyWith(challenge: challenge, attempts: const []),
  );
  // Ao voltar, o desafio pode ter sido concluído.
  if (context.mounted) await cubit.load();
}

/// O personagem do adversário, a frase dele e o progresso.
class _Header extends StatelessWidget {
  const _Header({required this.rung});

  final RungProgress rung;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final l10n = context.l10n;
    final characters = context.select(
      (JourneyCubit cubit) => cubit.state.characters,
    );
    final opponent = rung.rung.opponent;
    final character = opponentCharacter(characters, opponent);
    final language = Localizations.localeOf(context).languageCode;
    final tagline = character?.taglineIn(language) ?? '';
    final total = rung.rung.challenges.length;
    final done = rung.completed.length;
    return Padding(
      key: JourneyKeys.rungHeader,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              if (character != null) ...[
                Hero(
                  tag: opponentHeroTag(rung.rung.id),
                  child: CharacterAvatar(character: character, size: 80),
                ),
                const SizedBox(width: 16),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      opponentName(l10n, characters, opponent),
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (opponent.level case final level?)
                      Text(
                        l10n.journeyOpponentLevel('$level'),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    if (tagline.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        '“$tagline”',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppShape.small),
            child: AnimatedProgress(
              value: total == 0 ? 0 : done / total,
              minHeight: 10,
              color: ChangeColors.of(context, up: true),
              backgroundColor: colors.surfaceContainerHighest,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.journeyRungProgress(done, total),
            key: JourneyKeys.rungProgress,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(16, 16, 16, 8),
      child: Text(
        text,
        style: Theme.of(context).textTheme.titleMedium
            ?.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}

/// O próximo desafio por fazer, num cartão maior com o botão de jogar.
class _NextChallenge extends StatelessWidget {
  const _NextChallenge({required this.rungId, required this.challenge});

  final String rungId;
  final Challenge challenge;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final l10n = context.l10n;
    final position = challenge.position;
    return Card(
      key: JourneyKeys.nextChallenge,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      color: colors.secondaryContainer,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openChallenge(context, rungId, challenge),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              PositionBoard(
                fen: position.fen,
                size: 120,
                heroTag: challengeBoardTag(challenge.id),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      endgameName(l10n, position.subcategory),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colors.onSecondaryContainer,
                      ),
                    ),
                    _GoalIfSpecial(goal: position.goal),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      key: JourneyKeys.nextChallengePlay,
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: Text(l10n.journeyPlay),
                      onPressed: () async {
                        if (!await playChallenge(context, challenge)) return;
                        if (context.mounted) {
                          await context.read<JourneyCubit>().load();
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Um desafio na grade: o tabuleiro, o nome do final e o selo de feito.
class _ChallengeCell extends StatelessWidget {
  const _ChallengeCell({
    required this.rungId,
    required this.challenge,
    required this.done,
    required this.flies,
  });

  final String rungId;
  final Challenge challenge;
  final bool done;

  /// O tabuleiro voa até a tela do desafio.
  final bool flies;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final position = challenge.position;
    return PositionCard(
      key: JourneyKeys.challenge(position.id),
      fen: position.fen,
      heroTag: flies ? challengeBoardTag(challenge.id) : null,
      doneKey: done ? JourneyKeys.challengeDone(position.id) : null,
      doneLabel: done ? l10n.journeyCompletedLabel : null,
      onTap: () => _openChallenge(context, rungId, challenge),
      children: [
        Text(
          endgameName(l10n, position.subcategory),
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        _GoalIfSpecial(goal: position.goal),
      ],
    );
  }
}

/// O objetivo só aparece quando não é o comum (vencer): "Defender".
class _GoalIfSpecial extends StatelessWidget {
  const _GoalIfSpecial({required this.goal});

  final PositionGoal goal;

  @override
  Widget build(BuildContext context) {
    if (goal == PositionGoal.win) return const SizedBox.shrink();
    final style = GoalStyle.of(context, goal);
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(
        children: [
          Icon(style.icon, size: 14, color: style.color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              goalLabel(context.l10n, goal),
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: style.color, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

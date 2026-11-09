import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../data/repositories/characters/character_repository.dart';
import '../../../domain/models/attempt.dart';
import '../../../domain/models/character.dart';
import '../../../domain/models/game_setup.dart';
import '../../../domain/models/pace.dart';
import '../../../domain/use_cases/history_games.dart';
import '../../../routing/routes.dart';
import '../../core/keys/rating_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/opponent/opponent_ui.dart';
import '../../core/pace/pace_ui.dart';
import '../../core/review/move_quality_ui.dart';
import '../../core/theme/app_icon_size.dart';
import '../../core/theme/app_shape.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/character_avatar.dart';
import '../../core/widgets/container_navigation.dart';
import '../../core/widgets/goal_style.dart';
import '../../core/widgets/rating_value.dart';
import '../view_models/history_cubit.dart';

/// Uma partida do histórico, enxuta como no chess.com: o ícone do ritmo, o
/// retrato pequeno, o nome e o nível do adversário, a marca do resultado e
/// quanto o rating mudou. Tocar abre os detalhes.
class HistoryGameRow extends StatelessWidget {
  const HistoryGameRow({
    this.destinationBuilder,
    required this.index,
    required this.game,
    required this.characters,
    this.highlighted = false,
    super.key,
  });

  final Widget Function(BuildContext, int)? destinationBuilder;
  final int index;
  final HistoryGame game;
  final List<Character> characters;

  /// A partida que a conclusão abriu: o fundo tingido.
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final l10n = context.l10n;
    final attempt = game.attempt;
    final time = attempt.userTime;
    final category = time == null ? null : PaceCategory.of(time);
    final character = switch (attempt.opponent) {
      OpponentKind.stockfish => Character.stockfish,
      OpponentKind.maia => characters.forLevel(attempt.opponentLevel),
      OpponentKind.twoPlayers => null,
    };
    final change = game.change;
    void reload() {
      if (context.mounted) context.read<HistoryCubit>().load();
    }

    Future<void> canonical() async {
      await context.push<void>(Routes.game(game.id));
    }

    final builder = destinationBuilder;
    Widget content(VoidCallback open) => InkWell(
      key: RatingKeys.entry(index),
      onTap: open,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            // O ritmo pelo ícone de sempre: raio, chama, relógio.
            Icon(
              category == null ? Icons.timer_off_outlined : paceIcon(category),
              size: AppIconSize.standard,
              color: ChangeColors.of(context, up: true),
              semanticLabel: time == null
                  ? l10n.challengeNoClock
                  : paceLabel(l10n, time),
            ),
            const SizedBox(width: AppSpacing.md),
            if (character != null)
              CharacterAvatar(
                character: character,
                size: CharacterAvatar.lesson,
              )
            else
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: colors.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(AppShape.small),
                ),
                child: Icon(Icons.smart_toy_outlined, color: colors.outline),
              ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _OpponentName(
                index: index,
                attempt: attempt,
                character: character,
              ),
            ),
            // A precisão do jogador, nas partidas já revisadas (como no
            // histórico do chess.com).
            if (game.accuracy case final accuracy?) ...[
              const SizedBox(width: AppSpacing.sm),
              _AccuracyChip(index: index, accuracy: accuracy),
            ],
            const SizedBox(width: AppSpacing.md),
            _ResultBadge(index: index, outcome: attempt.outcome),
            _RatingChange(
              index: index,
              change: change,
              rating: game.entry.rating.rounded,
            ),
          ],
        ),
      ),
    );
    final row = builder == null
        ? content(() async {
            await canonical();
            reload();
          })
        : ContainerNavigation(
            color: highlighted
                ? colors.primaryContainer
                : Theme.of(context).scaffoldBackgroundColor,
            routeName: Routes.game(game.id),
            openBuilder: (context) => builder(context, game.id),
            onFallback: canonical,
            onClosed: reload,
            closedBuilder: (_, open) => content(open),
          );
    if (!highlighted) return row;
    return Material(
      key: RatingKeys.entryHighlighted,
      color: colors.primaryContainer,
      child: row,
    );
  }
}

/// O nome do adversário e, entre parênteses, o nível dele (no Maia).
class _OpponentName extends StatelessWidget {
  const _OpponentName({
    required this.index,
    required this.attempt,
    required this.character,
  });

  final int index;
  final Attempt attempt;
  final Character? character;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final l10n = context.l10n;
    final level = attempt.opponent == OpponentKind.maia
        ? attempt.opponentLevel
        : null;
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: character?.name ?? attempt.opponent.label(l10n, level: level),
            style: const TextStyle(fontWeight: AppWeight.strong),
          ),
          if (level != null && character != null)
            TextSpan(
              text: ' ($level)',
              style: TextStyle(
                color: colors.onSurfaceVariant,
                fontWeight: FontWeight.w400,
              ),
            ),
        ],
      ),
      key: RatingKeys.entryOpponent(index),
      style: theme.textTheme.titleMedium,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}

/// A precisão do jogador numa pílula, nas partidas já revisadas.
class _AccuracyChip extends StatelessWidget {
  const _AccuracyChip({required this.index, required this.accuracy});

  final int index;
  final double accuracy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final l10n = context.l10n;
    return Tooltip(
      message: l10n.reviewAccuracy,
      child: Container(
        key: RatingKeys.entryAccuracy(index),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: colors.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppShape.small),
        ),
        child: Text(
          formatAccuracy(accuracy, Localizations.localeOf(context).toString()),
          semanticsLabel:
              '${l10n.reviewAccuracy} ${formatAccuracy(accuracy, Localizations.localeOf(context).toString())}',
          style: theme.textTheme.labelLarge?.copyWith(
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ),
    );
  }
}

/// A marca do resultado: vitória, empate ou derrota.
class _ResultBadge extends StatelessWidget {
  const _ResultBadge({required this.index, required this.outcome});

  final int index;
  final AttemptOutcome outcome;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final (resultColor, resultIcon, resultLabel) = switch (outcome) {
      AttemptOutcome.win => (
        ChangeColors.of(context, up: true),
        Icons.add_rounded,
        l10n.attemptWin,
      ),
      AttemptOutcome.draw => (
        colors.outline,
        Icons.drag_handle_rounded,
        l10n.attemptDraw,
      ),
      AttemptOutcome.loss => (
        ChangeColors.of(context, up: false),
        Icons.remove_rounded,
        l10n.attemptLoss,
      ),
    };
    return Container(
      key: RatingKeys.entryResult(index),
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: resultColor,
        borderRadius: BorderRadius.circular(AppShape.small),
      ),
      child: Icon(
        resultIcon,
        size: AppIconSize.button,
        color: colors.surface,
        semanticLabel: resultLabel,
      ),
    );
  }
}

/// Quanto a partida mudou o rating e como ele ficou. Largura mínima de 64;
/// cresce com a fonte.
class _RatingChange extends StatelessWidget {
  const _RatingChange({
    required this.index,
    required this.change,
    required this.rating,
  });

  final int index;
  final int? change;
  final int rating;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final change = this.change;
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 64),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (change != null)
            Text(
              signedChange(change),
              key: RatingKeys.entryChange(index),
              textDirection: TextDirection.ltr,
              style: context.cardTitle?.copyWith(
                color: change == 0
                    ? colors.onSurfaceVariant
                    : ChangeColors.of(context, up: change > 0),
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          Text(
            '$rating',
            key: RatingKeys.entryRating(index),
            style:
                (change == null
                        ? context.cardTitle
                        : theme.textTheme.labelMedium?.copyWith(
                            color: colors.onSurfaceVariant,
                          ))
                    ?.copyWith(
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
          ),
        ],
      ),
    );
  }
}

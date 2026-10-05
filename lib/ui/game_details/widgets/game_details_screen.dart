import 'dart:math' as math;

import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart' show DateFormat, NumberFormat;

import '../../../data/repositories/characters/character_repository.dart';
import '../../../domain/models/attempt.dart';
import '../../../domain/models/character.dart';
import '../../../domain/models/game_end.dart';
import '../../../domain/models/game_setup.dart';
import '../../catalog/widgets/catalog_ui.dart';
import '../../core/keys/game_details_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/opponent/opponent_ui.dart';
import '../../core/pace/pace_ui.dart';
import '../../core/widgets/character_avatar.dart';
import '../../core/widgets/figurine.dart';
import '../../core/widgets/goal_style.dart';
import '../../core/widgets/position_board.dart';
import '../../core/widgets/rating_value.dart';
import '../../core/widgets/scroll_padding.dart';
import '../view_models/game_details_cubit.dart';

/// Os detalhes de uma partida: contra quem, o final, quando, o ritmo, o
/// resultado e o rating; o tabuleiro no lance escolhido e a tabela de lances
/// com o tempo que cada um levou. A análise vem depois.
class GameDetailsScreen extends StatelessWidget {
  const GameDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = context.watch<GameDetailsCubit>().state;
    final attempt = state.attempt;
    return Scaffold(
      key: GameDetailsKeys.screen,
      appBar: AppBar(title: Text(l10n.gameDetailsTitle)),
      body: !state.ready
          ? const Center(child: CircularProgressIndicator())
          : attempt == null
          ? Center(
              child: Text(
                l10n.gameDetailsNotFound,
                key: GameDetailsKeys.notFound,
              ),
            )
          : LayoutBuilder(
              builder: (context, constraints) {
                final board = math.min(constraints.maxWidth - 32, 480.0);
                return ListView(
                  padding: scrollPadding(context),
                  children: [
                    _Header(state: state, attempt: attempt),
                    if (state.shownPosition case final position?)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                        child: Center(
                          child: PositionBoard(
                            key: GameDetailsKeys.board,
                            fen: position.fen,
                            size: board,
                            radius: 10,
                            coordinates: true,
                            lastMove: state.shownMove,
                            orientation: attempt.userSide ?? Side.white,
                          ),
                        ),
                      ),
                    _MoveTable(state: state),
                  ],
                );
              },
            ),
    );
  }
}

/// Contra quem, o final, a data, o ritmo, o resultado e o rating.
class _Header extends StatelessWidget {
  const _Header({required this.state, required this.attempt});

  final GameDetailsState state;
  final Attempt attempt;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final locale = Localizations.localeOf(context).toString();
    final character = switch (attempt.opponent) {
      OpponentKind.stockfish => Character.stockfish,
      OpponentKind.maia => state.characters.forLevel(attempt.opponentLevel),
      OpponentKind.twoPlayers => null,
    };
    final level = attempt.opponent == OpponentKind.maia
        ? attempt.opponentLevel
        : null;
    final parts = attempt.positionId.split('.');
    final endgame = parts.length > 1 ? endgameName(l10n, parts[1]) : null;
    final time = attempt.userTime;
    final (color, label) = switch (attempt.outcome) {
      AttemptOutcome.win => (
        ChangeColors.of(context, up: true),
        l10n.attemptWin,
      ),
      AttemptOutcome.draw => (colors.outline, l10n.attemptDraw),
      AttemptOutcome.loss => (
        ChangeColors.of(context, up: false),
        l10n.attemptLoss,
      ),
    };
    final reason = switch (attempt.endReason) {
      GameEndReason.checkmate => l10n.freeBoardCheckmate,
      GameEndReason.stalemate => l10n.freeBoardStalemate,
      GameEndReason.insufficientMaterial => l10n.freeBoardInsufficientMaterial,
      GameEndReason.repetition => l10n.freeBoardRepetition,
      GameEndReason.fiftyMoves => l10n.freeBoardFiftyMoves,
      GameEndReason.timeout => l10n.freeBoardTimeout,
      GameEndReason.timeoutVsInsufficientMaterial =>
        l10n.freeBoardTimeoutVsInsufficientMaterial,
      GameEndReason.resign => l10n.gameResigned,
      GameEndReason.drawAgreed => l10n.freeBoardDrawAgreed,
      null => null,
    };
    final after = state.ratingAfter;
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      color: colors.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            if (character != null)
              CharacterAvatar(character: character, size: 56)
            else
              Icon(Icons.person_outline, size: 40, color: colors.outline),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text:
                              character?.name ??
                              attempt.opponent.label(l10n, level: level),
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        if (level != null && character != null)
                          TextSpan(
                            text: ' ($level)',
                            style: TextStyle(color: colors.onSurfaceVariant),
                          ),
                      ],
                    ),
                    key: GameDetailsKeys.opponent,
                    style: theme.textTheme.titleMedium,
                  ),
                  if (endgame != null)
                    Text(endgame, style: theme.textTheme.bodyMedium),
                  Text(
                    [
                      DateFormat.yMMMd(locale)
                          .add_Hm()
                          .format(attempt.playedAt.toLocal()),
                      if (time != null)
                        paceLabel(l10n, time)
                      else
                        l10n.challengeNoClock,
                    ].join(' · '),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    [label, ?reason].join(' · '),
                    key: GameDetailsKeys.result,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            if (after != null)
              RatingValue(rating: after, change: state.ratingChange),
          ],
        ),
      ),
    );
  }
}

/// Os lances em tabela (número, brancas, pretas), cada um com o tempo que
/// levou. Tocar num lance mostra a posição depois dele.
class _MoveTable extends StatelessWidget {
  const _MoveTable({required this.state});

  final GameDetailsState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final start = state.start;
    if (start == null || state.moves.isEmpty) return const SizedBox.shrink();
    final offset = start.turn == Side.black ? 1 : 0;
    final rows = (state.moves.length + offset + 1) ~/ 2;
    return Directionality(
      // A notação de xadrez é sempre da esquerda para a direita.
      textDirection: TextDirection.ltr,
      child: Card(
        margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        color: colors.surfaceContainerLow,
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            for (var row = 0; row < rows; row++)
              Container(
                color: row.isOdd
                    ? colors.onSurface.withValues(alpha: 0.04)
                    : null,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    SizedBox(
                      width: 40,
                      child: Text(
                        '${start.fullmoves + row}.',
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: colors.onSurfaceVariant,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                    Expanded(child: _cell(context, row * 2 - offset)),
                    Expanded(child: _cell(context, row * 2 + 1 - offset)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _cell(BuildContext context, int index) {
    if (index < 0 || index >= state.moves.length) {
      return const SizedBox(height: 44);
    }
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final move = state.moves[index];
    final selected = index == state.shownIndex;
    final time = move.time;
    return InkWell(
      key: GameDetailsKeys.move(index),
      borderRadius: BorderRadius.circular(8),
      onTap: () => context.read<GameDetailsCubit>().select(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 44,
        margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: selected ? colors.secondaryContainer : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text.rich(
                TextSpan(
                  children: [
                    for (final char in move.san.split(''))
                      if (Figurine.ofLetter[char] case final figurine?)
                        TextSpan(
                          text: figurine,
                          style: const TextStyle(
                            fontFamily: Figurine.fontFamily,
                            fontWeight: FontWeight.w400,
                          ),
                        )
                      else
                        TextSpan(text: char),
                  ],
                ),
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: selected ? colors.onSecondaryContainer : null,
                ),
                maxLines: 1,
              ),
            ),
            // Quanto o lance levou, discreto à direita.
            if (time != null)
              Text(
                _seconds(context, time),
                key: GameDetailsKeys.moveTime(index),
                style: theme.textTheme.labelMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
          ],
        ),
      ),
    );
  }

  // `3,4 s` ou `1:05` acima de um minuto.
  static String _seconds(BuildContext context, Duration time) {
    if (time.inSeconds >= 60) {
      final seconds = time.inSeconds.remainder(60).toString().padLeft(2, '0');
      return '${time.inMinutes}:$seconds';
    }
    final locale = Localizations.localeOf(context).toString();
    final format = NumberFormat('0.0', locale);
    return '${format.format(time.inMilliseconds / 1000)} s';
  }
}

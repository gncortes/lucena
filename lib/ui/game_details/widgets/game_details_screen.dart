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
import '../../core/board/centered_board_layout.dart';
import '../../core/keys/game_details_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/opponent/opponent_ui.dart';
import '../../core/pace/pace_ui.dart';
import '../../core/widgets/character_avatar.dart';
import '../../core/widgets/figurine.dart';
import '../../core/widgets/goal_style.dart';
import '../../core/review/move_quality_ui.dart';
import '../../core/widgets/rating_value.dart';
import '../../core/widgets/scroll_padding.dart';
import '../view_models/game_details_cubit.dart';
import 'review_widgets.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_shape.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/skeleton.dart';

/// Os detalhes de uma partida: o resultado e contra quem; a revisão pela
/// engine (precisão e qualidade de cada lance); o tabuleiro com a anotação
/// do lance, a barra de avaliação e a navegação lance a lance; a engine
/// ligável com as melhores linhas; e a tabela de lances, com a qualidade e o
/// tempo de cada um.
class GameDetailsScreen extends StatelessWidget {
  const GameDetailsScreen({super.key});

  /// O maior tabuleiro da revisão.
  static const _maxBoard = 480.0;

  /// O espaço da linha de botões de andar pelos lances, embaixo dele.
  static const _navigationHeight = 54.0;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = context.watch<GameDetailsCubit>().state;
    final attempt = state.attempt;
    return Scaffold(
      key: GameDetailsKeys.screen,
      appBar: AppBar(title: Text(l10n.gameDetailsTitle)),
      body: !state.ready
          // Carregando: o tabuleiro e os lances em esqueleto.
          ? ListView(
              key: GameDetailsKeys.loading,
              children: const [
                Padding(
                  padding: EdgeInsets.all(AppSpacing.screen),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: SkeletonBlock(height: double.infinity),
                  ),
                ),
                SkeletonList(rows: 3),
              ],
            )
          : attempt == null
          ? Center(
              child: ErrorState(
                message: l10n.gameDetailsNotFound,
                messageKey: GameDetailsKeys.notFound,
              ),
            )
          : LayoutBuilder(
              builder: (context, constraints) {
                final board = math.min(constraints.maxWidth - 32, _maxBoard);
                final user = attempt.userSide;
                final opponent = _opponentName(context, state, attempt);
                final you = l10n.reviewYou;
                final (whiteName, blackName) = switch (user) {
                  Side.white => (you, opponent),
                  Side.black => (opponent, you),
                  null => (l10n.sideWhite, l10n.sideBlack),
                };
                final header = [
                  _Header(state: state, attempt: attempt),
                  ReviewSummary(
                    state: state,
                    whiteName: whiteName,
                    blackName: blackName,
                  ),
                ];
                final footer = [
                  _MoveTable(state: state),
                  ReviewLegend(
                    state: state,
                    whiteName: whiteName,
                    blackName: blackName,
                  ),
                ];
                if (state.shownPosition == null) {
                  return ListView(
                    padding: scrollPadding(context),
                    children: [...header, ...footer],
                  );
                }
                // O tabuleiro e os botões de andar pelos lances no centro do
                // espaço entre a barra do app e o painel (T64); o painel
                // rola embaixo: a explicação do lance, a engine, o cartão
                // da partida, o resumo, a tabela e a legenda.
                return Column(
                  children: [
                    SizedBox(
                      height: BoardOptionsPanel.boardAreaFor(
                        constraints.maxHeight,
                        boardRoom:
                            board +
                            2 * (_navigationHeight + AppSpacing.sm) +
                            AppSpacing.md,
                        minPanel: 0.35,
                      ),
                      child: CenteredBoardLayout(
                        gutter: AppSpacing.lg,
                        maxBoard: _maxBoard,
                        reserveBottom: _navigationHeight,
                        board: LayoutBuilder(
                          builder: (context, box) => Center(
                            child: ReviewBoard(
                              state: state,
                              size: box.maxWidth,
                              orientation: user ?? Side.white,
                            ),
                          ),
                        ),
                        bottom: ReviewNavigation(
                          state: state,
                          attempt: attempt,
                        ),
                      ),
                    ),
                    Expanded(
                      child: BoardOptionsPanel(
                        key: GameDetailsKeys.panel,
                        child: ListView(
                          padding: scrollPadding(context),
                          children: [
                            MoveExplanation(state: state),
                            if (state.engine) EngineLinesPanel(state: state),
                            ...header,
                            ...footer,
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }

  static String _opponentName(
    BuildContext context,
    GameDetailsState state,
    Attempt attempt,
  ) {
    final level = attempt.opponent == OpponentKind.maia
        ? attempt.opponentLevel
        : null;
    final character = switch (attempt.opponent) {
      OpponentKind.stockfish => Character.stockfish,
      OpponentKind.maia => state.characters.forLevel(attempt.opponentLevel),
      OpponentKind.twoPlayers => null,
    };
    return character?.name ??
        attempt.opponent.label(context.l10n, level: level);
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
    final icon = switch (attempt.outcome) {
      AttemptOutcome.win => Icons.emoji_events,
      AttemptOutcome.draw => Icons.handshake_outlined,
      AttemptOutcome.loss => Icons.sentiment_dissatisfied_outlined,
    };
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      color: colors.surfaceContainerLow,
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // O resultado numa faixa da cor dele, com o rating à direita.
          Container(
            color: color.withValues(alpha: 0.14),
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
            child: Row(
              children: [
                Icon(icon, color: color, size: 26),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    [label, ?reason].join(' · '),
                    key: GameDetailsKeys.result,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (after != null) ...[
                  // Um respiro entre o resultado e o rating.
                  const SizedBox(width: 12),
                  RatingValue(rating: after, change: state.ratingChange),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Row(
              children: [
                if (character != null)
                  CharacterAvatar(character: character, size: 52)
                else
                  Icon(
                    Icons.smart_toy_outlined,
                    size: 40,
                    color: colors.outline,
                  ),
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
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            if (level != null && character != null)
                              TextSpan(
                                text: ' ($level)',
                                style: TextStyle(
                                  color: colors.onSurfaceVariant,
                                ),
                              ),
                          ],
                        ),
                        key: GameDetailsKeys.opponent,
                        style: theme.textTheme.titleMedium,
                      ),
                      if (endgame != null)
                        Text(endgame, style: theme.textTheme.bodyMedium),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            Icons.schedule,
                            size: 14,
                            color: colors.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
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
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Os lances em tabela (número, brancas, pretas), cada um com o tempo que
/// levou. Tocar num lance mostra a posição depois dele. A variante feita no
/// tabuleiro entra entre parênteses, menor e em itálico, logo abaixo da
/// linha do lance que ela troca.
class _MoveTable extends StatelessWidget {
  const _MoveTable({required this.state});

  final GameDetailsState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final start = state.start;
    if (start == null || (state.moves.isEmpty && state.variation.isEmpty)) {
      return const SizedBox.shrink();
    }
    final offset = start.turn == Side.black ? 1 : 0;
    final rows = (state.moves.length + offset + 1) ~/ 2;
    // A variante fica sob a linha do lance da partida que ela troca (ou da
    // última, se sai do fim).
    final replaced = math.min(state.variationFrom + 1, state.moves.length - 1);
    final variationRow = state.variation.isEmpty
        ? null
        : math.max(0, (replaced + offset) ~/ 2);
    final variation = _VariationLine(state: state);
    return Directionality(
      // A notação de xadrez é sempre da esquerda para a direita.
      textDirection: TextDirection.ltr,
      child: Card(
        margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        color: colors.surfaceContainerLow,
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            if (variationRow != null && rows == 0) variation,
            for (var row = 0; row < rows; row++) ...[
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
              if (row == variationRow) variation,
            ],
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
      borderRadius: BorderRadius.circular(AppShape.small),
      onTap: () => context.read<GameDetailsCubit>().select(index),
      child: AnimatedContainer(
        duration: AppMotion.state,
        height: 44,
        margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: selected ? colors.secondaryContainer : Colors.transparent,
          borderRadius: BorderRadius.circular(AppShape.small),
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
            if (state.reviewOf(index) case final reviewed?) ...[
              MoveQualityBadge(
                reviewed.quality,
                size: 18,
                key: GameDetailsKeys.moveQuality(index),
              ),
              const SizedBox(width: 6),
            ],
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

/// A variante feita no tabuleiro, entre parênteses: `(7... Rf7 8. Qg5)`.
/// Tocar num lance dela mostra a posição depois dele.
class _VariationLine extends StatelessWidget {
  const _VariationLine({required this.state});

  final GameDetailsState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final cubit = context.read<GameDetailsCubit>();
    final base = theme.textTheme.bodyMedium?.copyWith(
      fontStyle: FontStyle.italic,
      color: colors.onSurfaceVariant,
    );
    var position = state.variationStart!;
    final children = <Widget>[];
    for (final (ply, move) in state.variation.indexed) {
      final white = position.turn == Side.white;
      final number = white
          ? '${position.fullmoves}. '
          : ply == 0
          ? '${position.fullmoves}... '
          : '';
      final selected = ply == state.variationPly;
      children.add(
        InkWell(
          key: GameDetailsKeys.variationMove(ply),
          borderRadius: BorderRadius.circular(AppShape.small),
          onTap: () => cubit.selectVariation(ply),
          child: AnimatedContainer(
            duration: AppMotion.state,
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            decoration: BoxDecoration(
              color: selected ? colors.secondaryContainer : Colors.transparent,
              borderRadius: BorderRadius.circular(AppShape.small),
            ),
            child: Text.rich(
              TextSpan(
                children: [
                  if (ply == 0) const TextSpan(text: '('),
                  TextSpan(text: number),
                  for (final char in move.san.split(''))
                    if (Figurine.ofLetter[char] case final figurine?)
                      TextSpan(
                        text: figurine,
                        style: const TextStyle(
                          fontFamily: Figurine.fontFamily,
                          fontStyle: FontStyle.normal,
                        ),
                      )
                    else
                      TextSpan(text: char),
                  if (ply == state.variation.length - 1)
                    const TextSpan(text: ')'),
                ],
              ),
              style: base?.copyWith(
                fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                color: selected ? colors.onSecondaryContainer : null,
              ),
            ),
          ),
        ),
      );
      position = move.position;
    }
    return Padding(
      key: GameDetailsKeys.variation,
      // Recuada, como um comentário sob o lance.
      padding: const EdgeInsets.fromLTRB(48, 2, 8, 6),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Wrap(runSpacing: 2, children: children),
      ),
    );
  }
}

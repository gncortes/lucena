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
import '../../core/widgets/container_navigation.dart';
import '../../core/widgets/scroll_padding.dart';
import '../../core/widgets/viktor_sheet.dart';
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

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = context.watch<GameDetailsCubit>().state;
    final attempt = state.attempt;
    return Scaffold(
      key: GameDetailsKeys.screen,
      appBar: AppBar(
        leading: ContainerNavigation.canClose(context)
            ? BackButton(onPressed: () => ContainerNavigation.close(context))
            : null,
        title: Text(l10n.gameDetailsTitle),
      ),
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
          : _ReviewBody(
              state: state,
              attempt: attempt,
              opponent: _opponentName(context, state, attempt),
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

/// A revisão pronta: o tabuleiro e os botões de andar pelos lances fixos, no
/// centro do espaço acima de uma folha (como a da fala do Viktor nas
/// lições). Recolhida, a folha mostra o começo: a explicação do lance. O
/// usuário puxa ou rola para cima e ela sobe por cima do tabuleiro, com a
/// engine, o cartão da partida, o resumo, a tabela e a legenda; dentro dela
/// tudo rola, para nada ficar cortado em tela pequena ou com fonte grande.
/// Aberta, um "x" logo acima dela a desce de uma vez.
class _ReviewBody extends StatefulWidget {
  const _ReviewBody({
    required this.state,
    required this.attempt,
    required this.opponent,
  });

  final GameDetailsState state;
  final Attempt attempt;
  final String opponent;

  @override
  State<_ReviewBody> createState() => _ReviewBodyState();
}

class _ReviewBodyState extends State<_ReviewBody> {
  /// O maior tabuleiro da revisão.
  static const _maxBoard = 480.0;

  /// A linha de botões de andar pelos lances, embaixo do tabuleiro.
  static const _navigationHeight = 54.0;

  /// O mínimo da folha recolhida, em fração da altura e em pixels lógicos
  /// (vezes a escala do texto): o começo da explicação sempre à vista.
  static const _minPeekFraction = 0.26;
  static const _minPeek = 120.0;

  /// A folha recolhida nunca passa disso: o tabuleiro tem o resto.
  static const _maxPeekFraction = 0.75;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = widget.state;
    final attempt = widget.attempt;
    final user = attempt.userSide;
    final you = l10n.reviewYou;
    final (whiteName, blackName) = switch (user) {
      Side.white => (you, widget.opponent),
      Side.black => (widget.opponent, you),
      null => (l10n.sideWhite, l10n.sideBlack),
    };
    final summary = ReviewSummary(
      state: state,
      whiteName: whiteName,
      blackName: blackName,
    );
    final header = [_Header(state: state, attempt: attempt)];
    final footer = [
      _MoveTable(state: state),
      ReviewLegend(state: state, whiteName: whiteName, blackName: blackName),
    ];
    if (state.shownPosition == null) {
      return ListView(
        padding: scrollPadding(context),
        children: [summary, ...header, ...footer],
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final height = constraints.maxHeight;
        final width = constraints.maxWidth;
        // O tabuleiro ideal e os botões embaixo dele; a folha recolhida
        // fica com o resto, entre o mínimo e o máximo.
        final board = math.min(width - 2 * AppSpacing.lg, _maxBoard);
        final boardRoom =
            board + 2 * (_navigationHeight + AppSpacing.sm) + AppSpacing.md;
        final textScale = MediaQuery.textScalerOf(context).scale(1);
        final minPeek = math.max(
          _minPeekFraction * height,
          _minPeek * textScale,
        );
        final peek = (height - boardRoom).clamp(
          math.min(minPeek, _maxPeekFraction * height),
          _maxPeekFraction * height,
        );
        final boardArea = height - peek;
        return Stack(
          children: [
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: boardArea,
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
                bottom: ReviewNavigation(state: state, attempt: attempt),
              ),
            ),
            Positioned.fill(
              child: ViktorSheet(
                key: GameDetailsKeys.sheet,
                top: boardArea,
                scrollKey: GameDetailsKeys.panel,
                closeKey: GameDetailsKeys.closeSheet,
                padding: scrollPadding(context),
                children: [
                  summary,
                  MoveExplanation(state: state),
                  if (state.engine) EngineLinesPanel(state: state),
                  ...header,
                  ...footer,
                ],
              ),
            ),
          ],
        );
      },
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

  TextStyle _moveStyle(BuildContext context, int index) {
    final theme = Theme.of(context);
    final quality = state.reviewOf(index)?.quality;
    return theme.textTheme.titleSmall!.copyWith(
      fontWeight: FontWeight.w700,
      height: 1.4,
      color:
          quality?.listColor(theme.brightness) ?? theme.colorScheme.onSurface,
    );
  }

  TextSpan _notation(int index) => TextSpan(
    children: [
      for (final char in state.moves[index].san.split(''))
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
      TextSpan(text: state.reviewOf(index)?.quality.listAnnotation ?? ''),
    ],
  );

  double _width(BuildContext context, InlineSpan span, TextStyle style) {
    final painter = TextPainter(
      text: TextSpan(style: style, children: [span]),
      textDirection: TextDirection.ltr,
      textScaler: MediaQuery.textScalerOf(context),
    )..layout();
    final width = painter.width;
    painter.dispose();
    return width;
  }

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
    final replaced = math.min(state.variationFrom + 1, state.moves.length - 1);
    final variationRow = state.variation.isEmpty
        ? null
        : math.max(0, (replaced + offset) ~/ 2);
    final variation = _VariationLine(state: state);
    final numberWidth =
        _width(
          context,
          TextSpan(text: '${start.fullmoves + rows}.'),
          theme.textTheme.titleSmall!,
        ) +
        8;
    final moveWidths = [
      for (var i = 0; i < state.moves.length; i++)
        _width(context, _notation(i), _moveStyle(context, i)),
    ];
    final longest = moveWidths.fold(0.0, math.max);
    final timeStyle = theme.textTheme.labelMedium!.copyWith(
      color: colors.onSurfaceVariant,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    final timeWidth = state.moves
        .where((move) => move.time != null)
        .fold(
          0.0,
          (width, move) => math.max(
            width,
            _width(
              context,
              TextSpan(text: _seconds(context, move.time!)),
              timeStyle,
            ),
          ),
        );
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Card(
        margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        color: colors.surfaceContainerLow,
        clipBehavior: Clip.antiAlias,
        child: LayoutBuilder(
          builder: (context, box) {
            // Se nem o SAN sozinho cabe em meia linha, cada lado ganha uma
            // linha inteira. Tempos continuam alinhados no mesmo limite direito.
            final singleColumn =
                (box.maxWidth - 16 - numberWidth) / 2 < longest + 24;
            return Column(
              children: [
                if (variationRow != null && rows == 0) variation,
                for (var row = 0; row < rows; row++) ...[
                  Container(
                    color: row.isOdd
                        ? colors.onSurface.withValues(alpha: 0.04)
                        : null,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: numberWidth,
                          child: Padding(
                            padding: const EdgeInsets.only(top: 14),
                            child: Text(
                              '${start.fullmoves + row}.',
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: colors.onSurfaceVariant,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ),
                        ),
                        if (singleColumn)
                          Expanded(
                            child: Column(
                              children: [
                                _cell(
                                  context,
                                  row * 2 - offset,
                                  timeWidth,
                                  timeStyle,
                                  moveWidths,
                                ),
                                _cell(
                                  context,
                                  row * 2 + 1 - offset,
                                  timeWidth,
                                  timeStyle,
                                  moveWidths,
                                ),
                              ],
                            ),
                          )
                        else ...[
                          Expanded(
                            child: _cell(
                              context,
                              row * 2 - offset,
                              timeWidth,
                              timeStyle,
                              moveWidths,
                            ),
                          ),
                          Expanded(
                            child: _cell(
                              context,
                              row * 2 + 1 - offset,
                              timeWidth,
                              timeStyle,
                              moveWidths,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (row == variationRow) variation,
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _cell(
    BuildContext context,
    int index,
    double timeWidth,
    TextStyle timeStyle,
    List<double> moveWidths,
  ) {
    if (index < 0 || index >= state.moves.length) {
      return const SizedBox(height: 44);
    }
    final colors = Theme.of(context).colorScheme;
    final move = state.moves[index];
    final quality = state.reviewOf(index)?.quality;
    final selected = index == state.shownIndex;
    final time = move.time;
    final style = _moveStyle(context, index);
    final label = [
      move.san,
      if (quality != null) quality.label(context.l10n),
      if (time != null) _seconds(context, time),
    ].join(', ');
    void select() => context.read<GameDetailsCubit>().select(index);
    return Semantics(
      label: label,
      button: true,
      selected: selected,
      onTap: select,
      excludeSemantics: true,
      child: Tooltip(
        message: label,
        excludeFromSemantics: true,
        child: InkWell(
          key: GameDetailsKeys.move(index),
          borderRadius: BorderRadius.circular(AppShape.small),
          onTap: select,
          child: AnimatedContainer(
            duration: AppMotion.of(context).state,
            constraints: const BoxConstraints(minHeight: 44),
            margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              color: selected ? colors.secondaryContainer : Colors.transparent,
              borderRadius: BorderRadius.circular(AppShape.small),
              border: Border.all(
                color: selected ? colors.outline : Colors.transparent,
              ),
            ),
            child: LayoutBuilder(
              builder: (context, box) {
                final notation = Text.rich(
                  _notation(index),
                  key: quality == null
                      ? null
                      : GameDetailsKeys.moveQuality(index),
                  style: style,
                  strutStyle: StrutStyle.fromTextStyle(
                    style,
                    forceStrutHeight: true,
                  ),
                  softWrap: false,
                );
                final clock = SizedBox(
                  width: timeWidth,
                  child: time == null
                      ? null
                      : Text(
                          _seconds(context, time),
                          key: GameDetailsKeys.moveTime(index),
                          textAlign: TextAlign.right,
                          style: timeStyle,
                          softWrap: false,
                        ),
                );
                if (box.maxWidth < moveWidths[index] + timeWidth + 12) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      notation,
                      if (time != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: clock,
                          ),
                        ),
                    ],
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Expanded(child: notation),
                    const SizedBox(width: 12),
                    clock,
                  ],
                );
              },
            ),
          ),
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

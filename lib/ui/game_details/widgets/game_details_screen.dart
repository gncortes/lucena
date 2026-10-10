import 'dart:math' as math;

import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
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
import '../../core/widgets/sheet_close_button.dart';
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

  /// A folha aberta.
  static const _sheetMax = 0.94;

  final _sheet = DraggableScrollableController();

  // A altura de todo o conteúdo da folha (com o puxador): aberta, ela para
  // aí, sem vazio embaixo em tela alta.
  double? _contentHeight;

  bool _onContentMetrics(ScrollMetricsNotification notification) {
    final metrics = notification.metrics;
    final content =
        metrics.viewportDimension +
        metrics.maxScrollExtent -
        metrics.minScrollExtent;
    if (_contentHeight == null || (content - _contentHeight!).abs() > 1) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _contentHeight = content);
      });
    }
    return false;
  }

  // O tamanho da folha, para o "x". A folha avisa até durante a montagem;
  // o aviso passa para depois do quadro.
  final _sheetSize = ValueNotifier<double?>(null);

  void _onSheetChanged() {
    void update() {
      if (mounted && _sheet.isAttached) _sheetSize.value = _sheet.size;
    }

    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      SchedulerBinding.instance.addPostFrameCallback((_) => update());
    } else {
      update();
    }
  }

  @override
  void initState() {
    super.initState();
    _sheet.addListener(_onSheetChanged);
  }

  @override
  void dispose() {
    _sheet.removeListener(_onSheetChanged);
    _sheet.dispose();
    _sheetSize.dispose();
    super.dispose();
  }

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
    final header = [
      _Header(state: state, attempt: attempt),
      ReviewSummary(state: state, whiteName: whiteName, blackName: blackName),
    ];
    final footer = [
      _MoveTable(state: state),
      ReviewLegend(state: state, whiteName: whiteName, blackName: blackName),
    ];
    if (state.shownPosition == null) {
      return ListView(
        padding: scrollPadding(context),
        children: [...header, ...footer],
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
        final minSheet = (peek / height).toDouble();
        final boardArea = height - peek;
        // Aberta, a folha para na altura do conteúdo, até [_sheetMax].
        final content = _contentHeight;
        final maxSheet = content == null
            ? _sheetMax
            : (content / height).clamp(minSheet, _sheetMax).toDouble();
        final opens = maxSheet > minSheet + 0.01;
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
              child: DraggableScrollableSheet(
                key: GameDetailsKeys.sheet,
                controller: _sheet,
                initialChildSize: minSheet,
                minChildSize: minSheet,
                maxChildSize: opens ? maxSheet : minSheet,
                snap: opens,
                snapSizes: opens ? [minSheet, maxSheet] : null,
                builder: (context, scroll) => _sheetContent(context, scroll, [
                  MoveExplanation(state: state),
                  if (state.engine) EngineLinesPanel(state: state),
                  ...header,
                  ...footer,
                ]),
              ),
            ),
            // Folha cobrindo o tabuleiro: um "x" logo acima dela, para
            // descer de uma vez.
            ValueListenableBuilder(
              valueListenable: _sheetSize,
              builder: (context, size, _) {
                final open = size ?? minSheet;
                final covering = open > minSheet + 0.03;
                return PositionedDirectional(
                  end: SheetCloseButton.margin,
                  top: math.max(
                    0.0,
                    height * (1 - open) - SheetCloseButton.lift,
                  ),
                  child: IgnorePointer(
                    ignoring: !covering,
                    child: AnimatedOpacity(
                      duration: AppMotion.of(context).component,
                      opacity: covering ? 1 : 0,
                      child: SheetCloseButton(
                        key: GameDetailsKeys.closeSheet,
                        onPressed: () => _sheet.animateTo(
                          minSheet,
                          duration: AppMotion.of(context).component,
                          curve: AppMotion.enter,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  /// A folha: o puxador e o conteúdo, rolando por [scroll] (puxar sobe a
  /// folha antes de rolar o conteúdo). O mesmo visual da folha da fala.
  Widget _sheetContent(
    BuildContext context,
    ScrollController scroll,
    List<Widget> children,
  ) {
    final colors = Theme.of(context).colorScheme;
    const radius = BorderRadius.vertical(top: Radius.circular(AppShape.large));
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: 0.12),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        // A lista toda montada (sem preguiça): a altura dela é exata, e a
        // folha aberta para nela.
        child: NotificationListener<ScrollMetricsNotification>(
          onNotification: _onContentMetrics,
          child: SingleChildScrollView(
            key: GameDetailsKeys.panel,
            controller: scroll,
            padding: scrollPadding(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: colors.outlineVariant,
                        borderRadius: BorderRadius.circular(AppShape.full),
                      ),
                    ),
                  ),
                ),
                ...children,
              ],
            ),
          ),
        ),
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
        constraints: const BoxConstraints(minHeight: 44),
        margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: selected ? colors.secondaryContainer : Colors.transparent,
          borderRadius: BorderRadius.circular(AppShape.small),
        ),
        // O lance nunca é cortado: sem espaço na linha (tela estreita ou
        // fonte grande), o selo e o tempo descem para baixo dele.
        alignment: AlignmentDirectional.centerStart,
        child: Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text.rich(
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
              softWrap: false,
            ),
            // O selo e o tempo; sem espaço, o tempo quebra a linha.
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
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

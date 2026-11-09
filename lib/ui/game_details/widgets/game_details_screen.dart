import 'dart:math' as math;

import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:lucena/ui/core/widgets/lucena_app_bar.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/use_cases/clock_format.dart';
import '../../../routing/routes.dart';
import '../../core/widgets/load_error.dart';

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
import '../../core/theme/app_icon_size.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/character_avatar.dart';
import '../../core/widgets/figurine.dart';
import '../../core/widgets/goal_style.dart';
import '../../core/review/move_quality_ui.dart';
import '../../core/widgets/rating_value.dart';
import '../../core/widgets/container_navigation.dart';
import '../../core/widgets/scroll_padding.dart';
import '../../core/widgets/lucena_card.dart';
import '../view_models/game_details_cubit.dart';
import 'key_moments_section.dart';
import 'review_widgets.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_shape.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/skeleton.dart';
import '../../core/widgets/lucena_sheet.dart';
import '../../core/widgets/sheet_header.dart';
import '../../core/motion/shimmer_conteudo.dart';

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
    if (state.failed) {
      return LoadErrorScreen(
        kind: LoadErrorKind.generic,
        onAction: () => context.read<GameDetailsCubit>().load(
          language: Localizations.localeOf(context).languageCode,
        ),
        onBack: () =>
            context.canPop() ? context.pop() : context.go(Routes.home),
      );
    }
    return Scaffold(
      key: GameDetailsKeys.screen,
      appBar: LucenaAppBar(
        leading: ContainerNavigation.canClose(context)
            ? BackButton(onPressed: () => ContainerNavigation.close(context))
            : null,
        title: Text(
          state.ready && attempt == null
              ? l10n.partidaAnaliseTitulo
              : l10n.gameDetailsTitle,
        ),
      ),
      body: BoardViewport(
        usefulHeight: BoardViewport.usefulHeightOf(context),
        child: ShimmerConteudo(
          carregando: !state.ready,
          esqueleto: const _DetailsLoading(),
          child: !state.ready
              ? const SizedBox.shrink()
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
        ),
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

/// A revisão pronta: o tabuleiro na largura toda, as abas Resumo, Lances e
/// Motor (cada uma com a própria lista, que rola) e, fixos embaixo, os botões
/// de andar pelos lances com a engine e o menu.
class _ReviewBody extends StatelessWidget {
  const _ReviewBody({
    required this.state,
    required this.attempt,
    required this.opponent,
  });

  final GameDetailsState state;
  final Attempt attempt;
  final String opponent;

  /// O maior tabuleiro da revisão, e a altura mínima das abas com a lista
  /// embaixo dele (o tabuleiro encolhe antes de tirá-la).
  static const _maxBoard = 480.0;
  static const _maxBoardFraction = 0.5;
  static const _minBelow = kTextTabBarHeight + 2 * kMinInteractiveDimension;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final user = attempt.userSide;
    final you = l10n.reviewYou;
    final (whiteName, blackName) = switch (user) {
      Side.white => (you, opponent),
      Side.black => (opponent, you),
      null => (l10n.sideWhite, l10n.sideBlack),
    };
    final summary = [
      ReviewSummary(
        state: state,
        whiteName: whiteName,
        blackName: blackName,
        userIsWhite: user == null ? null : user == Side.white,
      ),
      KeyMomentsSection(
        state: state,
        userIsWhite: user == null ? null : user == Side.white,
      ),
      if ((state.review?.depth ?? 0) >=
          GameDetailsCubit.reviewWeights[ReviewSpeed.medium]!)
        QualityTable(
          state: state,
          leftName: whiteName,
          rightName: blackName,
          leftIsWhite: true,
        ),
      _Header(state: state, attempt: attempt),
      ReviewLegend(state: state, whiteName: whiteName, blackName: blackName),
    ];
    final moves = [
      MoveExplanation(state: state),
      if (state.variation.isEmpty) const _VariationHint(),
      _MoveTable(state: state, score: _score(attempt)),
    ];
    final engine = [if (state.engine) EngineLinesPanel(state: state)];
    if (state.shownPosition == null) {
      return ColoredBox(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: ListView(
          key: GameDetailsKeys.panel,
          padding: scrollPadding(context),
          children: [...summary, ...moves],
        ),
      );
    }
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                // A8: o tabuleiro no centro útil da tela; as abas e a lista
                // ficam com a sobra de baixo e a lista rola.
                final height = constraints.maxHeight;
                final centerY = (BoardViewport.centerYOf(context) ?? height / 2)
                    .clamp(0.0, height)
                    .toDouble();
                final below = height - _minBelow - centerY;
                final full = math.min(constraints.maxWidth, _maxBoard);
                final centered = math.min(full, 2 * math.min(centerY, below));
                // Tela deitada ou baixa, em que o tabuleiro inteiro não cabe
                // no centro: ele sobe ao alto com metade da altura, e a lista
                // fica com o resto.
                final fits = centered >= full - 0.5;
                final double board = fits
                    ? full
                    : math.max(0.0, math.min(full, _maxBoardFraction * height));
                final boardTop = fits ? centerY - board / 2 : 0.0;
                final controller = DefaultTabController.of(context);
                return Stack(
                  children: [
                    Positioned(
                      left: 0,
                      right: 0,
                      top: boardTop,
                      height: board,
                      child: Center(
                        child: ReviewBoard(
                          state: state,
                          size: board,
                          orientation: user ?? Side.white,
                        ),
                      ),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      top: boardTop + board,
                      bottom: 0,
                      child: _TabPanel(
                        state: state,
                        controller: controller,
                        summary: summary,
                        moves: moves,
                        engine: engine,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          ReviewNavigation(state: state, attempt: attempt),
        ],
      ),
    );
  }
}

/// As abas Resumo, Lances e Motor e, embaixo, a lista da aba escolhida.
class _TabPanel extends StatelessWidget {
  const _TabPanel({
    required this.state,
    required this.controller,
    required this.summary,
    required this.moves,
    required this.engine,
  });

  final GameDetailsState state;
  final TabController controller;
  final List<Widget> summary;
  final List<Widget> moves;
  final List<Widget> engine;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      children: [
        TabBar(
          onTap: (index) {
            // A aba Motor liga a engine; as outras mantêm a escolha.
            if (index == 2 && !state.engine) {
              context.read<GameDetailsCubit>().setEngine(on: true);
            }
          },
          tabs: [
            Tab(key: GameDetailsKeys.tabSummary, text: l10n.partidaAbaResumo),
            Tab(key: GameDetailsKeys.tabMoves, text: l10n.partidaAbaLances),
            Tab(key: GameDetailsKeys.tabEngine, text: l10n.reviewEngine),
          ],
        ),
        Expanded(
          child: AnimatedBuilder(
            animation: controller,
            builder: (context, _) => ListView(
              key: GameDetailsKeys.panel,
              padding: scrollPadding(context),
              children: switch (controller.index) {
                0 => summary,
                1 => moves,
                _ => engine,
              },
            ),
          ),
        ),
      ],
    );
  }
}

/// O placar da partida (1–0, 0–1, ½–½); sem o lado do jogador, só o empate.
String? _score(Attempt attempt) {
  final user = attempt.userSide;
  return switch (attempt.outcome) {
    AttemptOutcome.draw => '½–½',
    _ when user == null => null,
    final outcome =>
      (outcome == AttemptOutcome.win) == (user == Side.white) ? '1–0' : '0–1',
  };
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
    final reason = _endReasonLabel(l10n, attempt.endReason);
    final after = state.ratingAfter;
    final icon = switch (attempt.outcome) {
      AttemptOutcome.win => Icons.emoji_events,
      AttemptOutcome.draw => Icons.handshake_outlined,
      AttemptOutcome.loss => Icons.sentiment_dissatisfied_outlined,
    };
    final opponentName =
        character?.name ?? attempt.opponent.label(l10n, level: level);
    final when = DateFormat.yMMMd(locale)
        .add_Hm()
        .format(attempt.playedAt.toLocal());
    // O cartão da partida do canvas (CompCartaoPartida): o adversário e o
    // resultado, o rating à direita e os dados da partida em etiquetas.
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        0,
      ),
      child: LucenaCard(
        key: GameDetailsKeys.gameCard,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                if (character != null)
                  CharacterAvatar(
                    character: character,
                    size: CharacterAvatar.speech,
                  )
                else
                  Icon(
                    Icons.smart_toy_outlined,
                    size: CharacterAvatar.speech,
                    color: colors.outline,
                  ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _OpponentTitle(
                    icon: icon,
                    color: color,
                    title: [label, ?reason].join(' · '),
                    opponentName: opponentName,
                    level: level,
                    character: character,
                  ),
                ),
                if (after != null) ...[
                  const SizedBox(width: AppSpacing.md),
                  RatingValue(rating: after, change: state.ratingChange),
                ],
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                if (endgame != null)
                  _InfoChip(icon: Icons.extension_outlined, text: endgame),
                _InfoChip(
                  icon: Icons.timer_outlined,
                  text: time != null
                      ? paceLabel(l10n, time)
                      : l10n.challengeNoClock,
                ),
                _InfoChip(icon: Icons.event, text: when),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// O texto de como a partida acabou; sem motivo, nulo.
String? _endReasonLabel(AppLocalizations l10n, GameEndReason? reason) =>
    switch (reason) {
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

/// Uma etiqueta do cartão da partida: ícone e texto.
class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(AppShape.small),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: AppIconSize.small, color: colors.onSurfaceVariant),
            const SizedBox(width: AppSpacing.sm),
            Text(
              text,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// O resultado e o adversário (com o nível), ao lado do avatar.
class _OpponentTitle extends StatelessWidget {
  const _OpponentTitle({
    required this.icon,
    required this.color,
    required this.title,
    required this.opponentName,
    required this.level,
    required this.character,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String opponentName;
  final int? level;
  final Character? character;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: AppIconSize.small),
            const SizedBox(width: AppSpacing.sm),
            Flexible(
              child: Text(
                title,
                key: GameDetailsKeys.result,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: color,
                  fontWeight: AppWeight.heavy,
                ),
              ),
            ),
          ],
        ),
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: l10n.partidaContra(opponentName),
                style: const TextStyle(fontWeight: AppWeight.heavy),
              ),
              if (level != null && character != null)
                TextSpan(
                  text: ' ($level)',
                  style: TextStyle(color: colors.onSurfaceVariant),
                ),
            ],
          ),
          key: GameDetailsKeys.opponent,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleMedium,
        ),
      ],
    );
  }
}

/// Os lances em tabela (número, brancas, pretas), cada um com o tempo que
/// levou. Tocar num lance mostra a posição depois dele. A variante feita no
/// tabuleiro entra entre parênteses, menor e em itálico, logo abaixo da
/// linha do lance que ela troca. No fim, o placar.
class _MoveTable extends StatelessWidget {
  const _MoveTable({required this.state, this.score});

  final GameDetailsState state;
  final String? score;

  TextStyle _moveStyle(BuildContext context, int index) {
    final theme = Theme.of(context);
    final quality = state.reviewOf(index)?.quality;
    return theme.textTheme.titleSmall!.copyWith(
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
        margin: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          0,
        ),
        color: Colors.transparent,
        elevation: 0,
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
                  _MoveTableRow(
                    table: this,
                    row: row,
                    offset: offset,
                    firstNumber: start.fullmoves,
                    numberWidth: numberWidth,
                    singleColumn: singleColumn,
                    timeWidth: timeWidth,
                    timeStyle: timeStyle,
                    moveWidths: moveWidths,
                  ),
                  if (row == variationRow) variation,
                ],
                if (score case final score?)
                  _ScoreLine(score: score, numberWidth: numberWidth),
              ],
            );
          },
        ),
      ),
    );
  }

  // `3,4 s` ou `1:05` acima de um minuto.
  static String _seconds(BuildContext context, Duration time) {
    if (time.inSeconds >= 60) {
      return ClockFormat.minutesSeconds(time.inSeconds);
    }
    final locale = Localizations.localeOf(context).toString();
    final format = NumberFormat('0.0', locale);
    return '${format.format(time.inMilliseconds / 1000)} s';
  }
}

/// Uma linha da tabela de lances: o número e os lances das brancas e das
/// pretas (lado a lado, ou um sob o outro quando não cabem).
class _MoveTableRow extends StatelessWidget {
  const _MoveTableRow({
    required this.table,
    required this.row,
    required this.offset,
    required this.firstNumber,
    required this.numberWidth,
    required this.singleColumn,
    required this.timeWidth,
    required this.timeStyle,
    required this.moveWidths,
  });

  final _MoveTable table;
  final int row;
  final int offset;
  final int firstNumber;
  final double numberWidth;
  final bool singleColumn;
  final double timeWidth;
  final TextStyle timeStyle;
  final List<double> moveWidths;

  _MoveCell _cell(int index) => _MoveCell(
    table: table,
    index: index,
    timeWidth: timeWidth,
    timeStyle: timeStyle,
    moveWidths: moveWidths,
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Container(
      color: row.isOdd ? colors.onSurface.withValues(alpha: 0.04) : null,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: numberWidth,
            child: Padding(
              padding: const EdgeInsets.only(top: AppSpacing.lg),
              child: Text(
                '${firstNumber + row}.',
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
                  _cell(row * 2 - offset),
                  _cell(row * 2 + 1 - offset),
                ],
              ),
            )
          else ...[
            Expanded(child: _cell(row * 2 - offset)),
            Expanded(child: _cell(row * 2 + 1 - offset)),
          ],
        ],
      ),
    );
  }
}

/// O placar no fim da tabela de lances.
class _ScoreLine extends StatelessWidget {
  const _ScoreLine({required this.score, required this.numberWidth});

  final String score;
  final double numberWidth;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16 + numberWidth,
        AppSpacing.sm,
        AppSpacing.sm,
        AppSpacing.md,
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          score,
          key: GameDetailsKeys.score,
          style: Theme.of(context).textTheme.titleSmall,
        ),
      ),
    );
  }
}

/// O menu do lance da variante (toque e segure): copiar os lances até ele,
/// esconder as variantes ou apagar o lance e os seguintes.
Future<void> _showMoveMenu(
  BuildContext context,
  GameDetailsState state,
  int ply,
) {
  final cubit = context.read<GameDetailsCubit>();
  final l10n = context.l10n;
  var position = state.variationStart!;
  final parts = <String>[];
  var title = '';
  for (final (index, move) in state.variation.indexed) {
    final white = position.turn == Side.white;
    final number = white
        ? '${position.fullmoves}. '
        : index == 0
        ? '${position.fullmoves}... '
        : '';
    parts.add('$number${move.san}');
    if (index == ply) title = '$number${move.san}'.trim();
    position = move.position;
  }
  final copied = parts.take(ply + 1).join(' ');
  return showLucenaSheet<void>(
    context,
    sheetKey: GameDetailsKeys.moveMenu,
    closeKey: GameDetailsKeys.moveMenuClose,
    builder: (sheet) => SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SheetHeader(title: title, hint: l10n.partidaMenuDica),
          ListTile(
            key: GameDetailsKeys.menuCopy,
            leading: const Icon(Icons.content_copy),
            title: Text(l10n.partidaMenuCopiar),
            onTap: () async {
              Navigator.of(sheet).pop();
              await Clipboard.setData(ClipboardData(text: copied));
            },
          ),
          ListTile(
            key: GameDetailsKeys.menuHideVariations,
            leading: const Icon(Icons.visibility_off),
            title: Text(l10n.partidaMenuEsconder),
            onTap: () {
              Navigator.of(sheet).pop();
              cubit.clearVariation();
            },
          ),
          ListTile(
            key: GameDetailsKeys.menuDelete,
            leading: const Icon(Icons.delete),
            title: Text(l10n.partidaMenuApagar),
            onTap: () {
              Navigator.of(sheet).pop();
              cubit.deleteVariationFrom(ply);
            },
          ),
        ],
      ),
    ),
  );
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
          onLongPress: () => _showMoveMenu(context, state, ply),
          child: AnimatedContainer(
            duration: AppMotion.state,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xs,
              vertical: AppSpacing.xs,
            ),
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
      padding: const EdgeInsets.fromLTRB(
        48,
        AppSpacing.xs,
        AppSpacing.sm,
        AppSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.partidaSuaVariante,
            key: GameDetailsKeys.variationLabel,
            style: theme.textTheme.labelMedium?.copyWith(color: colors.primary),
          ),
          Wrap(runSpacing: AppSpacing.xs, children: children),
        ],
      ),
    );
  }
}

/// A dica de que dá para criar uma variante jogando no tabuleiro.
class _VariationHint extends StatelessWidget {
  const _VariationHint();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      key: GameDetailsKeys.variationHint,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        0,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.touch_app,
            size: AppIconSize.button,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              context.l10n.partidaVarianteDica,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Carregando: o tabuleiro e os lances em esqueleto.
class _DetailsLoading extends StatelessWidget {
  const _DetailsLoading();

  @override
  Widget build(BuildContext context) => ListView(
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
  );
}

class _MoveCell extends StatelessWidget {
  const _MoveCell({
    required this.table,
    required this.index,
    required this.timeWidth,
    required this.timeStyle,
    required this.moveWidths,
  });

  final _MoveTable table;
  final int index;
  final double timeWidth;
  final TextStyle timeStyle;
  final List<double> moveWidths;

  @override
  Widget build(BuildContext context) {
    if (index < 0 || index >= table.state.moves.length) {
      return const SizedBox(height: 44);
    }
    final colors = Theme.of(context).colorScheme;
    final move = table.state.moves[index];
    final quality = table.state.reviewOf(index)?.quality;
    final selected = index == table.state.shownIndex;
    final time = move.time;
    final style = table._moveStyle(context, index);
    final label = [
      move.san,
      if (quality != null) quality.label(context.l10n),
      if (time != null) _MoveTable._seconds(context, time),
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
            margin: const EdgeInsets.symmetric(
              vertical: AppSpacing.xs,
              horizontal: AppSpacing.xs,
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.sm,
            ),
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
                  table._notation(index),
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
                          _MoveTable._seconds(context, time),
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
                          padding: const EdgeInsets.only(top: AppSpacing.xs),
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
                    const SizedBox(width: AppSpacing.md),
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
}

import 'dart:math' as math;

import 'package:chessground/chessground.dart';
import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucena_ui/lucena_ui.dart';

import '../../../domain/models/board_settings.dart';
import '../../../domain/models/featured.dart';
import '../../../domain/use_cases/game_rules.dart';
import '../../core/board/board_settings_ui.dart';
import '../../core/keys/featured_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../free_board/widgets/game_actions_bar.dart';
import '../../settings/view_models/settings_cubit.dart';
import '../view_models/find_move_cubit.dart';
import 'featured_book_sheet.dart';
import 'featured_labels.dart';
import 'featured_next_sheet.dart';

/// "Ache o lance": a posição de uma partida real, sem relógio, e o jogador
/// acha o lance. O lance é conferido contra a solução (tablebase): errou,
/// tenta de novo; pode pedir uma dica ou ver a resposta.
class FindMoveScreen extends StatelessWidget {
  const FindMoveScreen({
    required this.endgame,
    this.tournament,
    this.tournamentFinals = 0,
    super.key,
  });

  final FeaturedEndgame endgame;
  final FeaturedTournament? tournament;

  /// Quantos finais o torneio tem (o subtítulo do "E agora?").
  final int tournamentFinals;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<FindMoveCubit>();
    return BlocBuilder<FindMoveCubit, FindMoveState>(
      builder: (context, state) => Scaffold(
        key: FeaturedKeys.findScreen,
        appBar: LucenaAppBar(
          title: Text(l10n.featuredFindTitle),
          actions: [
            IconButton(
              key: FeaturedKeys.bookButton,
              tooltip: l10n.featuredBookTitle,
              icon: const Icon(Icons.menu_book_outlined),
              onPressed: () => showFeaturedBook(
                context,
                endgame: endgame,
                tournament: tournament,
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: ListView(
                padding: scrollPadding(
                  context,
                  left: AppSpacing.lg,
                  right: AppSpacing.lg,
                  bottom: AppSpacing.lg,
                ),
                children: [
                  _Header(endgame: endgame, tournament: tournament),
                  const SizedBox(height: AppSpacing.md),
                  _FindBoard(endgame: endgame, state: state),
                  const SizedBox(height: AppSpacing.md),
                  _Feedback(state: state, cubit: cubit),
                ],
              ),
            ),
            _Actions(
              state: state,
              cubit: cubit,
              endgame: endgame,
              tournament: tournament,
              tournamentFinals: tournamentFinals,
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.endgame, required this.tournament});

  final FeaturedEndgame endgame;
  final FeaturedTournament? tournament;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final language = Localizations.localeOf(context).languageCode;
    final hook = endgame.hook.of(language);
    final side = endgame.userSide == Side.white ? 'white' : 'black';
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: AppSpacing.xs,
          children: [
            InfoChip(
              compact: true,
              icon: FeaturedLabels.originIcon(endgame.origin),
              label: FeaturedLabels.origin(l10n, endgame.origin),
            ),
            Text(
              FeaturedLabels.shortPlayers(l10n, endgame),
              key: FeaturedKeys.endgamePlayers,
              style: context.cardTitle,
            ),
            Text(
              FeaturedLabels.subtitle(l10n, language, endgame, tournament),
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            if (hook.isNotEmpty) Text(hook),
            Text(
              l10n.exerciseGoal(side, endgame.goal.code),
              key: FeaturedKeys.findPrompt,
              style: theme.textTheme.labelLarge,
            ),
          ],
        ),
      ),
    );
  }
}

/// O tabuleiro de jogar. Cada tentativa começa de um tabuleiro novo (o
/// lance errado não fica na posição).
class _FindBoard extends StatefulWidget {
  const _FindBoard({required this.endgame, required this.state});

  final FeaturedEndgame endgame;
  final FindMoveState state;

  @override
  State<_FindBoard> createState() => _FindBoardState();
}

class _FindBoardState extends State<_FindBoard> {
  ChessboardController? _controller;
  int _attempt = -1;

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  GameData _game(Position? position, {required bool active}) {
    return GameData(
      fen: widget.endgame.fen,
      playerSide: !active
          ? PlayerSide.none
          : position!.turn == Side.white
          ? PlayerSide.white
          : PlayerSide.black,
      sideToMove: position?.turn ?? Side.white,
      validMoves: position == null || !active
          ? const {}
          : GameRules.legalMoves(position),
      kingSquareInCheck: position == null
          ? null
          : GameRules.checkedKing(position),
    );
  }

  /// A seta do lance certo, depois de achar ou de ver a resposta.
  Set<Shape> _answer(BuildContext context) {
    final move = context.read<FindMoveCubit>().answerMove;
    if (move == null || !widget.state.finished) return const {};
    return {
      Arrow(
        color: Theme.of(context).colorScheme.primary,
        orig: move.from,
        dest: move.to,
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final position = GameRules.fromFen(widget.endgame.fen);
    final active = position != null && !state.finished;
    final board = context.select(
      (SettingsCubit cubit) => cubit.state?.board ?? const BoardSettings(),
    );
    final size = math.min(
      MediaQuery.sizeOf(context).width - 2 * AppSpacing.lg,
      420.0,
    );
    // Um lance errado: tabuleiro novo para a próxima tentativa.
    if (_attempt != state.attempts || _controller == null) {
      _controller?.dispose();
      _controller = ChessboardController(game: _game(position, active: active));
      _attempt = state.attempts;
    }
    return Center(
      child: IgnorePointer(
        ignoring: !active,
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Chessboard(
            key: FeaturedKeys.findBoard,
            size: size,
            controller: _controller!,
            shapes: _answer(context),
            settings: board.chessground,
            orientation: widget.endgame.userSide,
            onMove: (move, {viaDragAndDrop}) =>
                context.read<FindMoveCubit>().play(move),
          ),
        ),
      ),
    );
  }
}

class _Feedback extends StatelessWidget {
  const _Feedback({required this.state, required this.cubit});

  final FindMoveState state;
  final FindMoveCubit cubit;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final san = localizedSan(l10n, cubit.answerSan ?? cubit.answer ?? '');
    final (IconData?, Color, String?) result = switch (state.phase) {
      FindMovePhase.solved => (
        Icons.check_circle,
        AppColors.successColor,
        l10n.featuredFindRight(san),
      ),
      FindMovePhase.revealed => (
        Icons.visibility_outlined,
        colors.primary,
        l10n.featuredFindAnswer(san),
      ),
      FindMovePhase.wrong => (
        Icons.close,
        colors.error,
        l10n.featuredFindWrong,
      ),
      FindMovePhase.asking => (null, colors.onSurfaceVariant, null),
    };
    final (icon, color, text) = result;
    final role = cubit.hintRole;
    final language = Localizations.localeOf(context).languageCode;
    final own = cubit.endgame.hint.of(language);
    final hintText = own.isNotEmpty
        ? own
        : role == null
        ? null
        : l10n.featuredFindHint(role.name);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpacing.sm,
      children: [
        if (text != null)
          Row(
            key: FeaturedKeys.findResult,
            spacing: AppSpacing.sm,
            children: [
              Icon(icon, color: color, size: AppIconSize.standard),
              Expanded(
                child: Text(
                  text,
                  style: theme.textTheme.titleSmall?.copyWith(color: color),
                ),
              ),
            ],
          ),
        if (state.phase == FindMovePhase.wrong && !state.hint && cubit.hasHint)
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton.icon(
              key: FeaturedKeys.findHint,
              onPressed: cubit.showHint,
              icon: const Icon(Icons.lightbulb_outline),
              label: Text(l10n.featuredFindHintButton),
            ),
          ),
        if (state.hint && hintText != null && !state.finished)
          DecoratedBox(
            decoration: BoxDecoration(
              color: colors.secondaryContainer,
              borderRadius: BorderRadius.circular(AppShape.medium),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Text(
                hintText,
                key: FeaturedKeys.findHintText,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.onSecondaryContainer,
                ),
              ),
            ),
          ),
        Text(
          l10n.featuredFindNote,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _Actions extends StatelessWidget {
  const _Actions({
    required this.state,
    required this.cubit,
    required this.endgame,
    required this.tournament,
    required this.tournamentFinals,
  });

  final FindMoveState state;
  final FindMoveCubit cubit;
  final FeaturedEndgame endgame;
  final FeaturedTournament? tournament;
  final int tournamentFinals;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    if (state.finished) {
      final next = FilledButton.icon(
        key: FeaturedKeys.findContinue,
        onPressed: () => showFeaturedNext(
          context,
          endgame: endgame,
          tournament: tournament,
          tournamentFinals: tournamentFinals,
        ),
        icon: const Icon(Icons.arrow_forward),
        label: Text(l10n.featuredContinue),
      );
      return ActionsFooter(
        children: [
          // Depois de ver a resposta, dá para tentar de novo (canvas).
          if (state.phase == FindMovePhase.revealed)
            OutlinedButton.icon(
              key: FeaturedKeys.findRetry,
              onPressed: cubit.retry,
              icon: const Icon(Icons.replay),
              label: Text(l10n.featuredFindRetry),
            ),
          next,
        ],
      );
    }
    // A barra de ícone e rótulo da partida (canvas CompBarraAcoesPartida).
    final items = state.phase == FindMovePhase.wrong
        ? [
            GameActionButton(
              buttonKey: FeaturedKeys.findAnswer,
              icon: Icons.visibility_outlined,
              label: l10n.featuredFindShowAnswer,
              onPressed: cubit.reveal,
            ),
            GameActionButton(
              buttonKey: FeaturedKeys.findRetry,
              icon: Icons.replay,
              label: l10n.featuredFindRetry,
              onPressed: cubit.retry,
            ),
          ]
        : [
            if (cubit.hasHint)
              GameActionButton(
                buttonKey: FeaturedKeys.findHint,
                icon: Icons.lightbulb_outline,
                label: l10n.featuredFindHintButton,
                onPressed: state.hint ? null : cubit.showHint,
              ),
            GameActionButton(
              buttonKey: FeaturedKeys.findAnswer,
              icon: Icons.visibility_outlined,
              label: l10n.featuredFindShowAnswer,
              onPressed: cubit.reveal,
            ),
          ];
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        child: Row(spacing: AppSpacing.xs, children: items),
      ),
    );
  }
}

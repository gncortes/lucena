import 'dart:math' as math;

import 'package:chessground/chessground.dart';
import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/models/game_end.dart';
import '../../../domain/use_cases/game_rules.dart';
import '../../core/keys/free_board_keys.dart';
import '../../core/l10n/l10n.dart';
import '../view_models/free_board_cubit.dart';
import 'move_list.dart';

class FreeBoardScreen extends StatefulWidget {
  const FreeBoardScreen({super.key});

  @override
  State<FreeBoardScreen> createState() => _FreeBoardScreenState();
}

class _FreeBoardScreenState extends State<FreeBoardScreen> {
  // O jogador faz os dois lados: não há lance antecipado.
  static const _settings = ChessboardSettings(enablePremoves: false);

  // Altura reservada para o painel de cima e para a lista de lances.
  static const _statusHeight = 72.0;
  static const _minMovesHeight = 120.0;

  late final _board = ChessboardController(
    game: _gameData(context.read<FreeBoardCubit>().state),
  );

  @override
  void dispose() {
    _board.dispose();
    super.dispose();
  }

  GameData _gameData(FreeBoardState state) {
    final position = state.position;
    return GameData(
      fen: position.fen,
      // Com a partida terminada, o tabuleiro trava.
      playerSide: state.end == null ? PlayerSide.both : PlayerSide.none,
      sideToMove: position.turn,
      validMoves: GameRules.legalMoves(position),
      lastMove: state.lastMove,
      kingSquareInCheck: GameRules.checkedKing(position),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<FreeBoardCubit>();
    return BlocConsumer<FreeBoardCubit, FreeBoardState>(
      listener: (context, state) =>
          _board.updatePosition(_gameData(state), resetPremove: true),
      builder: (context, state) {
        return Scaffold(
          key: FreeBoardKeys.screen,
          appBar: AppBar(
            title: Text(context.l10n.freeBoardTitle),
            actions: [
              IconButton(
                key: FreeBoardKeys.newGameButton,
                icon: const Icon(Icons.restart_alt),
                tooltip: context.l10n.freeBoardNewGame,
                onPressed: cubit.newGame,
              ),
            ],
          ),
          body: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final boardSize = math.min(
                  constraints.maxWidth,
                  constraints.maxHeight - _statusHeight - _minMovesHeight,
                );
                return Column(
                  children: [
                    _Status(
                      minHeight: _statusHeight,
                      state: state,
                      onNewGame: cubit.newGame,
                    ),
                    // O tabuleiro não espelha em idiomas da direita para a esquerda.
                    Directionality(
                      textDirection: TextDirection.ltr,
                      child: Chessboard(
                        key: FreeBoardKeys.board,
                        size: boardSize,
                        controller: _board,
                        settings: _settings,
                        orientation: Side.white,
                        onMove: (move, {viaDragAndDrop}) => cubit.play(move),
                      ),
                    ),
                    Expanded(
                      child: MoveList(
                        moves: state.moves,
                        firstMoveNumber: state.start.fullmoves,
                        firstSide: state.start.turn,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }
}

/// Painel acima do tabuleiro: de quem é a vez ou, no fim, o resultado.
class _Status extends StatelessWidget {
  const _Status({
    required this.minHeight,
    required this.state,
    required this.onNewGame,
  });

  /// Texto longo (outros idiomas) pode passar disso; a lista de lances cede.
  final double minHeight;
  final FreeBoardState state;
  final VoidCallback onNewGame;

  @override
  Widget build(BuildContext context) {
    final end = state.end;
    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        switchInCurve: Curves.easeOutCubic,
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween(
              begin: const Offset(0, -0.25),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        ),
        child: ConstrainedBox(
          key: ValueKey<Object>(end ?? state.position.turn),
          constraints: BoxConstraints(minHeight: minHeight),
          child: end == null
              ? _Turn(side: state.position.turn)
              : _End(end: end, onNewGame: onNewGame),
        ),
      ),
    );
  }
}

class _Turn extends StatelessWidget {
  const _Turn({required this.side});

  final Side side;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // Disco da cor de quem joga.
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: side == Side.white ? Colors.white : Colors.black,
              border: Border.all(color: theme.colorScheme.outline, width: 1.5),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              side == Side.white
                  ? context.l10n.freeBoardWhiteToMove
                  : context.l10n.freeBoardBlackToMove,
              key: FreeBoardKeys.turn,
              style: theme.textTheme.titleMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class _End extends StatelessWidget {
  const _End({required this.end, required this.onNewGame});

  final GameEnd end;
  final VoidCallback onNewGame;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final reason = switch (end.reason) {
      GameEndReason.checkmate => l10n.freeBoardCheckmate,
      GameEndReason.stalemate => l10n.freeBoardStalemate,
      GameEndReason.insufficientMaterial => l10n.freeBoardInsufficientMaterial,
    };
    final result = switch (end.winner) {
      Side.white => l10n.freeBoardWhiteWins,
      Side.black => l10n.freeBoardBlackWins,
      null => l10n.freeBoardDraw,
    };
    return ColoredBox(
      key: FreeBoardKeys.endPanel,
      color: theme.colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(16, 8, 12, 8),
        child: Row(
          children: [
            Icon(
              end.winner == null ? Icons.handshake_outlined : Icons.flag,
              color: theme.colorScheme.onSecondaryContainer,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    reason,
                    key: FreeBoardKeys.endReason,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSecondaryContainer,
                    ),
                  ),
                  Text(
                    result,
                    key: FreeBoardKeys.endResult,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSecondaryContainer,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            FilledButton(
              key: FreeBoardKeys.endNewGameButton,
              onPressed: onNewGame,
              child: Text(l10n.freeBoardNewGame),
            ),
          ],
        ),
      ),
    );
  }
}

import 'dart:async';
import 'dart:math' as math;

import 'package:chessground/chessground.dart';
import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/models/board_settings.dart';
import '../../../domain/models/clock_settings.dart';
import '../../../domain/models/endgame_position.dart';
import '../../../domain/models/game_end.dart';
import '../../../domain/models/game_mode.dart';
import '../../../domain/use_cases/game_rules.dart';
import '../../../domain/use_cases/now.dart';
import '../../core/board/board_settings_ui.dart';
import '../../../routing/routes.dart';
import '../../core/keys/free_board_keys.dart';
import '../../catalog/widgets/catalog_ui.dart';
import '../../core/l10n/l10n.dart';
import '../../core/opponent/opponent_ui.dart';
import '../../settings/view_models/settings_cubit.dart';
import '../view_models/free_board_cubit.dart';
import '../view_models/talk_cubit.dart';
import 'clock_row.dart';
import 'character_bar.dart';
import 'clock_sheet.dart';
import 'move_list.dart';
import 'report_panel.dart';

class FreeBoardScreen extends StatefulWidget {
  const FreeBoardScreen({super.key});

  @override
  State<FreeBoardScreen> createState() => _FreeBoardScreenState();
}

class _FreeBoardScreenState extends State<FreeBoardScreen>
    with WidgetsBindingObserver {
  // Altura reservada para o painel de cima e para a lista de lances.
  static const _statusHeight = 72.0;
  static const _minMovesHeight = 120.0;

  late final ChessboardController _board;

  // O relógio não conta tiques: a tela só pede, várias vezes por segundo, que
  // os tempos sejam refeitos pelo instante atual.
  late final Timer _clockRefresh;

  @override
  void initState() {
    super.initState();
    final cubit = context.read<FreeBoardCubit>();
    _board = ChessboardController(game: _gameData(cubit.state));
    WidgetsBinding.instance.addObserver(this);
    final talk = context.read<TalkCubit>()
      // A partida nova já abre pronta: o personagem a vê desde o começo.
      ..update(cubit.state);
    var ticks = 0;
    _clockRefresh = Timer.periodic(const Duration(milliseconds: 100), (_) {
      cubit.tick();
      // As falas de tempo não precisam de tanta pressa: uma vez por segundo.
      if (++ticks % 10 == 0) talk.tick(cubit.state);
    });
  }

  // Voltando do segundo plano ou da tela bloqueada: relógios refeitos e, se
  // for a vez da máquina, ela volta a pensar.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<FreeBoardCubit>().resumed();
    }
  }

  Future<void> _confirmResign() async {
    final cubit = context.read<FreeBoardCubit>();
    final confirmed = await showResignSheet(context);
    if (confirmed ?? false) cubit.resign();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _clockRefresh.cancel();
    _board.dispose();
    super.dispose();
  }

  Future<void> _pickClock() async {
    final cubit = context.read<FreeBoardCubit>();
    final choice = await showClockSheet(
      context,
      current: cubit.state.clock?.config,
    );
    if (choice != null) cubit.newGameWithClock(choice.config);
  }

  GameData _gameData(FreeBoardState state) {
    final position = state.position;
    return GameData(
      fen: position.fen,
      playerSide: _playerSide(state),
      sideToMove: position.turn,
      validMoves: GameRules.legalMoves(position),
      lastMove: state.lastMove,
      kingSquareInCheck: GameRules.checkedKing(position),
    );
  }

  PlayerSide _playerSide(FreeBoardState state) {
    // Com a partida terminada, o tabuleiro trava.
    if (state.end != null) return PlayerSide.none;
    return switch (state.playerSide) {
      null => PlayerSide.both,
      Side.white => PlayerSide.white,
      Side.black => PlayerSide.black,
    };
  }

  void _onStateChanged(FreeBoardState state) {
    final isPlayerTurn = state.playerSide == state.position.turn;
    final premove = _board.premove;
    // O pré-lance só sobrevive enquanto espera a resposta do adversário.
    final keepPremove = state.end == null && state.moves.isNotEmpty;
    _board.updatePosition(_gameData(state), resetPremove: !keepPremove);
    if (!keepPremove || premove == null || !isPlayerTurn) return;
    // O adversário respondeu: o lance marcado antes é jogado em seguida. Se
    // ele deixou de ser legal, é só descartado.
    _board.premove = null;
    context.read<FreeBoardCubit>().play(premove);
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<FreeBoardCubit>();
    final boardSettings = context.select(
      (SettingsCubit cubit) => cubit.state?.board ?? const BoardSettings(),
    );
    final clockPosition = context.select(
      (SettingsCubit cubit) =>
          (cubit.state?.clock ?? const ClockSettings()).position,
    );
    final talk = context.watch<TalkCubit>().state;
    return BlocListener<FreeBoardCubit, FreeBoardState>(
      // O personagem vê cada lance, o fim e a partida nova.
      listenWhen: (previous, current) =>
          previous.ready != current.ready ||
          previous.ucis.length != current.ucis.length ||
          previous.end != current.end ||
          previous.startedAt != current.startedAt,
      listener: (context, state) => context.read<TalkCubit>().update(state),
      child: BlocConsumer<FreeBoardCubit, FreeBoardState>(
        // O tabuleiro só é refeito quando a partida muda, não a cada tique do
        // relógio.
        listenWhen: (previous, current) =>
            !identical(previous.position, current.position) ||
            previous.moves.length != current.moves.length ||
            previous.end != current.end ||
            previous.playerSide != current.playerSide ||
            previous.machineThinking != current.machineThinking,
        listener: (context, state) => _onStateChanged(state),
        builder: (context, state) {
          // Sair da tela pela seta ou pelo botão de voltar para o relógio e
          // guarda a partida.
          return PopScope(
            onPopInvokedWithResult: (didPop, _) {
              if (didPop) unawaited(cubit.leave());
            },
            child: _scaffold(
              context,
              cubit,
              state,
              boardSettings,
              clockPosition,
              talk,
            ),
          );
        },
      ),
    );
  }

  Widget _scaffold(
    BuildContext context,
    FreeBoardCubit cubit,
    FreeBoardState state,
    BoardSettings boardSettings,
    ClockPosition clockPosition,
    TalkState talk,
  ) {
    // Enquanto a partida em andamento é lida do aparelho, só a barra de cima:
    // o tabuleiro não pisca na posição errada.
    if (!state.ready) {
      return Scaffold(
        key: FreeBoardKeys.screen,
        appBar: AppBar(title: Text(context.l10n.freeBoardTitle)),
      );
    }
    final goal = state.mode.goal;
    final training = state.mode.userSide != null;
    final mode = state.mode;
    final speedrun = mode.isSpeedrun;
    return Scaffold(
      key: FreeBoardKeys.screen,
      appBar: AppBar(
        // No treino, o objetivo no lugar do título: ícone e uma palavra, que
        // cabem junto dos botões em qualquer idioma.
        title: goal == null
            ? Text(context.l10n.freeBoardTitle)
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    goal == PositionGoal.win
                        ? Icons.emoji_events_outlined
                        : Icons.shield_outlined,
                  ),
                  const SizedBox(width: 8),
                  Flexible(child: Text(goalLabel(context.l10n, goal))),
                ],
              ),
        actions: [
          if (training && state.end == null)
            IconButton(
              key: FreeBoardKeys.resignButton,
              icon: const Icon(Icons.flag_outlined),
              tooltip: context.l10n.gameResign,
              onPressed: _confirmResign,
            ),
          IconButton(
            key: FreeBoardKeys.flipButton,
            icon: const Icon(Icons.swap_vert),
            tooltip: context.l10n.freeBoardFlip,
            onPressed: cubit.flip,
          ),
          // No speedrun o relógio é o do speedrun e recomeçar apagaria o
          // tempo gasto: a etapa só termina jogando.
          if (!speedrun) ...[
            IconButton(
              key: FreeBoardKeys.clockButton,
              icon: const Icon(Icons.timer_outlined),
              tooltip: context.l10n.freeBoardClock,
              onPressed: _pickClock,
            ),
            IconButton(
              key: FreeBoardKeys.newGameButton,
              icon: const Icon(Icons.restart_alt),
              tooltip: context.l10n.freeBoardNewGame,
              onPressed: cubit.newGame,
            ),
          ],
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Sem relógio na partida, nenhuma fileira de relógio aparece.
            final clocks = state.clock == null ? null : clockPosition;
            final clockRows = switch (clocks) {
              null => 0,
              ClockPosition.sides => 2,
              ClockPosition.top || ClockPosition.bottom => 1,
            };
            final character = talk.character;
            final boardSize = math.min(
              constraints.maxWidth,
              constraints.maxHeight -
                  _statusHeight -
                  clockRows * ClockRow.height -
                  (character == null ? 0 : CharacterBar.height) -
                  _minMovesHeight,
            );
            const both = [Side.white, Side.black];
            return Column(
              children: [
                _Status(
                  minHeight: _statusHeight,
                  state: state,
                  // No speedrun, o fim leva de volta à tentativa: lá o
                  // jogador segue para a próxima etapa ou repete esta.
                  onNewGame: speedrun
                      ? () async {
                          // A tentativa lê a partida do banco: ela precisa
                          // estar gravada antes.
                          await cubit.saved();
                          if (!context.mounted) return;
                          context.go(
                            Routes.speedrunAttempt(
                              mode.speedrunId ?? '',
                              mode.speedrunAttemptId!,
                              game: context
                                  .read<Now>()()
                                  .millisecondsSinceEpoch,
                            ),
                          );
                        }
                      : cubit.newGame,
                ),
                if (state.machineThinking && state.clock == null)
                  _Thinking(mode: state.mode),
                if (character != null) CharacterBar(talk: talk),
                if (clocks == ClockPosition.top)
                  ClockRow(
                    sides: both,
                    state: state,
                    board: boardSettings,
                    talk: talk,
                  ),
                if (clocks == ClockPosition.sides)
                  ClockRow(
                    sides: [state.orientation.opposite],
                    state: state,
                    board: boardSettings,
                    talk: talk,
                  ),
                // O tabuleiro não espelha em idiomas da direita para a esquerda.
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: Chessboard(
                    key: FreeBoardKeys.board,
                    size: boardSize,
                    controller: _board,
                    settings: boardSettings.chessground,
                    orientation: state.orientation,
                    onMove: (move, {viaDragAndDrop}) => cubit.play(move),
                  ),
                ),
                if (clocks == ClockPosition.sides)
                  ClockRow(
                    sides: [state.orientation],
                    state: state,
                    board: boardSettings,
                    talk: talk,
                  ),
                if (clocks == ClockPosition.bottom)
                  ClockRow(
                    sides: both,
                    state: state,
                    board: boardSettings,
                    talk: talk,
                  ),
                if (state.report case final report?)
                  ReportPanel(report: report),
                Expanded(
                  child: MoveList(
                    moves: state.moves,
                    firstMoveNumber: state.start.fullmoves,
                    firstSide: state.start.turn,
                    pieceLetters: boardSettings.notation.pieceLetters(
                      context.l10n,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
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
    // Com relógio, quem está na vez é o relógio aceso: a linha "vez de" sai.
    final showsTurn = state.clock == null;
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
          key: ValueKey<Object>(end ?? (showsTurn ? state.position.turn : 0)),
          // Sem nada a mostrar, o painel some e o espaço fica para a lista.
          constraints: BoxConstraints(
            minHeight: end != null || showsTurn ? minHeight : 0,
          ),
          child: switch (end) {
            final end? => _End(
              end: end,
              fulfilled: state.fulfilled,
              speedrun: state.mode.isSpeedrun,
              onNewGame: onNewGame,
            ),
            null when showsTurn => _Turn(side: state.position.turn),
            null => const SizedBox(width: double.infinity),
          },
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
  const _End({
    required this.end,
    required this.fulfilled,
    required this.speedrun,
    required this.onNewGame,
  });

  final GameEnd end;

  /// A partida é uma etapa de speedrun: o botão volta para a tentativa.
  final bool speedrun;

  /// No treino: o objetivo foi cumprido. Nulo fora do treino.
  final bool? fulfilled;
  final VoidCallback onNewGame;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final reason = switch (end.reason) {
      GameEndReason.checkmate => l10n.freeBoardCheckmate,
      GameEndReason.stalemate => l10n.freeBoardStalemate,
      GameEndReason.insufficientMaterial => l10n.freeBoardInsufficientMaterial,
      GameEndReason.repetition => l10n.freeBoardRepetition,
      GameEndReason.fiftyMoves => l10n.freeBoardFiftyMoves,
      GameEndReason.timeout => l10n.freeBoardTimeout,
      GameEndReason.timeoutVsInsufficientMaterial =>
        l10n.freeBoardTimeoutVsInsufficientMaterial,
      GameEndReason.resign => l10n.gameResigned,
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
                  if (fulfilled case final done?)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        children: [
                          Icon(
                            done ? Icons.check_circle : Icons.cancel_outlined,
                            size: 18,
                            color: done
                                ? theme.colorScheme.primary
                                : theme.colorScheme.error,
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              done
                                  ? l10n.resultFulfilled
                                  : l10n.resultNotFulfilled,
                              key: FreeBoardKeys.endGoal,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: done
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.error,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            FilledButton(
              key: FreeBoardKeys.endNewGameButton,
              onPressed: onNewGame,
              // No treino, a mesma posição com a mesma configuração.
              child: Text(
                speedrun
                    ? l10n.speedrunContinue
                    : fulfilled == null
                    ? l10n.freeBoardNewGame
                    : l10n.resultPlayAgain,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A máquina está escolhendo o lance (partida sem relógio; com relógio, o
/// relógio dela correndo já mostra).
class _Thinking extends StatelessWidget {
  const _Thinking({required this.mode});

  final GameMode mode;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      key: FreeBoardKeys.machineThinking,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(
        children: [
          // Ícone parado: a tela não fica animando enquanto a máquina pensa.
          Icon(
            Icons.hourglass_top,
            size: 18,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              context.l10n.gameMachineThinking(
                mode.opponent.label(context.l10n, level: mode.level),
              ),
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

/// Pergunta antes de desistir. Devolve verdadeiro se o jogador confirmou.
Future<bool?> showResignSheet(BuildContext context) {
  return showModalBottomSheet<bool>(
    context: context,
    showDragHandle: true,
    useSafeArea: true,
    builder: (context) {
      final theme = Theme.of(context);
      final l10n = context.l10n;
      return SafeArea(
        top: false,
        child: Padding(
          key: FreeBoardKeys.resignSheet,
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.gameResignTitle, style: theme.textTheme.titleLarge),
              const SizedBox(height: 4),
              Text(
                l10n.gameResignHint,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                key: FreeBoardKeys.resignConfirmButton,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  backgroundColor: theme.colorScheme.error,
                  foregroundColor: theme.colorScheme.onError,
                ),
                icon: const Icon(Icons.flag),
                onPressed: () => Navigator.of(context).pop(true),
                label: Text(l10n.gameResign),
              ),
            ],
          ),
        ),
      );
    },
  );
}

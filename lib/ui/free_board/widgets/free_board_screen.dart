import 'dart:async';

import 'package:chessground/chessground.dart';
import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/models/board_settings.dart';
import '../../../domain/models/clock_settings.dart';
import '../../../domain/models/game_end.dart';
import '../../../domain/models/game_mode.dart';
import '../../../domain/use_cases/game_rules.dart';
import '../../../domain/use_cases/mastery.dart';
import '../../../domain/use_cases/now.dart';
import '../../core/board/board_settings_ui.dart';
import '../../../routing/routes.dart';
import '../../core/keys/free_board_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/opponent/opponent_ui.dart';
import '../../core/widgets/goal_style.dart';
import '../../core/widgets/rating_value.dart';
import '../../core/widgets/scroll_padding.dart';
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
  // Altura da linha "vez de" (partida sem relógio) e o mínimo que sobra
  // embaixo do tabuleiro para a faixa de lances.
  static const _turnHeight = 48.0;
  static const _minBottom = MoveList.height;

  late final ChessboardController _board;

  // O relógio não conta tiques: a tela só pede, várias vezes por segundo, que
  // os tempos sejam refeitos pelo instante atual.
  late final Timer _clockRefresh;

  // O cartão do resultado, aberto quando a partida termina nesta tela. Fechado,
  // o resultado fica no painel embaixo do tabuleiro.
  bool _resultOpen = false;

  // O dedo está no tabuleiro: a tela não rola enquanto isso.
  bool _touchingBoard = false;

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
          previous.startedAt != current.startedAt ||
          previous.drawOffer != current.drawOffer,
      listener: (context, state) => context.read<TalkCubit>().update(state),
      child: BlocListener<FreeBoardCubit, FreeBoardState>(
        // A máquina recusou o empate: um aviso curto, além da fala.
        listenWhen: (previous, current) =>
            previous.drawOffer != current.drawOffer &&
            current.drawOffer == DrawOffer.declined,
        listener: (context, state) => ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              key: FreeBoardKeys.drawDeclined,
              content: Text(context.l10n.gameDrawDeclined),
            ),
          ),
        child: BlocListener<FreeBoardCubit, FreeBoardState>(
          // A partida terminou agora: o cartão do resultado abre, como no
          // chess.com. Partida nova: ele fecha.
          listenWhen: (previous, current) => previous.end != current.end,
          listener: (context, state) =>
              setState(() => _resultOpen = state.end != null),
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
        ),
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
    return Scaffold(
      key: FreeBoardKeys.screen,
      appBar: AppBar(
        // No treino a barra fica só com os botões: o objetivo aparece no fim.
        title: goal == null ? Text(context.l10n.freeBoardTitle) : null,
        // No treino, só propor empate e desistir; virar, trocar o relógio e
        // recomeçar ficam no tabuleiro livre.
        actions: training
            ? [
                if (state.end == null && state.mode.opponent.isMachine) ...[
                  IconButton(
                    key: FreeBoardKeys.drawButton,
                    icon: const Icon(Icons.handshake_outlined),
                    tooltip: context.l10n.gameOfferDraw,
                    onPressed: state.canOfferDraw ? cubit.offerDraw : null,
                  ),
                  IconButton(
                    key: FreeBoardKeys.resignButton,
                    icon: const Icon(Icons.flag_outlined),
                    tooltip: context.l10n.gameResign,
                    onPressed: _confirmResign,
                  ),
                ],
              ]
            : [
                IconButton(
                  key: FreeBoardKeys.flipButton,
                  icon: const Icon(Icons.swap_vert),
                  tooltip: context.l10n.freeBoardFlip,
                  onPressed: cubit.flip,
                ),
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
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Sem relógio na partida, nenhuma fileira de relógio aparece.
            final clocks = state.clock == null ? null : clockPosition;
            final character = talk.character;
            final clockRows = switch (clocks) {
              null => 0,
              ClockPosition.sides => 2,
              ClockPosition.top || ClockPosition.bottom => 1,
            };
            final turnHeight = state.clock == null && state.end == null
                ? _turnHeight
                : 0.0;
            final fixed =
                turnHeight +
                clockRows * ClockRow.height +
                (state.machineThinking && state.clock == null ? 28 : 0) +
                _minBottom;
            // O retrato do personagem encolhe para a partida caber na tela
            // sem rolar, quando dá.
            final width = constraints.maxWidth;
            final avatar = character == null
                ? 0.0
                : (constraints.maxHeight -
                          fixed -
                          width -
                          CharacterBar.heightFor(0))
                      .clamp(CharacterBar.minAvatar, CharacterBar.maxAvatar)
                      .toDouble();
            // O tabuleiro ocupa sempre a largura toda; se não couber tudo, a
            // tela rola.
            final boardSize = width;
            const both = [Side.white, Side.black];
            final end = state.end;
            return Stack(
              children: [
                // A tela inteira rola, como nos apps de xadrez; com o dedo no
                // tabuleiro, a rolagem para e o lance (ou o arrastar da peça)
                // fica só com ele.
                SingleChildScrollView(
                  key: FreeBoardKeys.scrollArea,
                  physics: _touchingBoard
                      ? const NeverScrollableScrollPhysics()
                      : null,
                  padding: scrollPadding(context),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (turnHeight > 0)
                        SizedBox(
                          height: turnHeight,
                          child: _Turn(side: state.position.turn),
                        ),
                      if (state.machineThinking && state.clock == null)
                        _Thinking(mode: state.mode),
                      if (character != null)
                        CharacterBar(
                          talk: talk,
                          avatarSize: avatar,
                          // A linha do relógio dos lados já tem o nome dele.
                          showName: clocks != ClockPosition.sides,
                        ),
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
                      Listener(
                        onPointerDown: (_) =>
                            setState(() => _touchingBoard = true),
                        onPointerUp: (_) =>
                            setState(() => _touchingBoard = false),
                        onPointerCancel: (_) =>
                            setState(() => _touchingBoard = false),
                        child: Directionality(
                          textDirection: TextDirection.ltr,
                          child: Chessboard(
                            key: FreeBoardKeys.board,
                            size: boardSize,
                            controller: _board,
                            settings: boardSettings.chessground,
                            orientation: state.orientation,
                            onMove: (move, {viaDragAndDrop}) =>
                                cubit.play(move),
                          ),
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
                      // Embaixo do tabuleiro: o fim da partida (com o rating e
                      // as mensagens) e a faixa de lances.
                      if (end != null && !_resultOpen)
                        _end(context, cubit, state, end, card: false),
                      MoveList(
                        moves: state.moves,
                        firstMoveNumber: state.start.fullmoves,
                        firstSide: state.start.turn,
                        pieceLetters: boardSettings.notation.pieceLetters(
                          context.l10n,
                        ),
                      ),
                      if (state.report case final report?)
                        ReportPanel(report: report),
                    ],
                  ),
                ),
                if (end != null && _resultOpen)
                  Positioned.fill(
                    child: _ResultOverlay(
                      onClose: () => setState(() => _resultOpen = false),
                      child: _end(context, cubit, state, end, card: true),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _end(
    BuildContext context,
    FreeBoardCubit cubit,
    FreeBoardState state,
    GameEnd end, {
    required bool card,
  }) {
    final mode = state.mode;
    final next = state.report?.next;
    return _End(
      end: end,
      userSide: mode.opponent.isMachine ? mode.userSide : null,
      fulfilled: state.fulfilled,
      speedrun: mode.isSpeedrun,
      report: state.report,
      card: card,
      onClose: () => setState(() => _resultOpen = false),
      onNewGame: () => _newGame(context, cubit, mode),
      onNext: next == null ? null : () => _nextChallenge(context, cubit, next),
    );
  }

  Future<void> _newGame(
    BuildContext context,
    FreeBoardCubit cubit,
    GameMode mode,
  ) async {
    // No speedrun, o fim leva de volta à tentativa: lá o jogador segue para a
    // próxima etapa ou repete esta.
    if (!mode.isSpeedrun) {
      cubit.newGame();
      return;
    }
    // A tentativa lê a partida do banco: ela precisa estar gravada antes.
    await cubit.saved();
    if (!context.mounted) return;
    context.go(
      Routes.speedrunAttempt(
        mode.speedrunId ?? '',
        mode.speedrunAttemptId!,
        game: context.read<Now>()().millisecondsSinceEpoch,
      ),
    );
  }

  // Direto para a partida do próximo desafio, no lugar desta.
  Future<void> _nextChallenge(
    BuildContext context,
    FreeBoardCubit cubit,
    NextChallenge next,
  ) async {
    await cubit.saved();
    if (!context.mounted) return;
    context.pushReplacement(Routes.challengeGame(next.challenge));
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

/// O fundo escuro e o cartão do resultado por cima da partida, entrando com
/// animação, como no chess.com. Tocar fora fecha e deixa ver o tabuleiro.
class _ResultOverlay extends StatelessWidget {
  const _ResultOverlay({required this.onClose, required this.child});

  final VoidCallback onClose;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final instant = MediaQuery.disableAnimationsOf(context);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: instant ? Duration.zero : const Duration(milliseconds: 250),
      builder: (context, t, child) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onClose,
        child: ColoredBox(
          color: Colors.black.withValues(alpha: 0.5 * t),
          child: child,
        ),
      ),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          // Tocar no cartão não fecha.
          child: GestureDetector(onTap: () {}, child: child),
        ),
      ),
    );
  }
}

/// O fim da partida: o motivo e o resultado, o objetivo, o rating novo com a
/// variação (como no chess.com) e os botões de jogar de novo e, num desafio
/// da Jornada, de ir para o próximo. [card]: o cartão animado que abre por
/// cima da partida; senão, o painel embaixo do tabuleiro.
class _End extends StatefulWidget {
  const _End({
    required this.end,
    required this.userSide,
    required this.fulfilled,
    required this.speedrun,
    required this.report,
    required this.card,
    required this.onClose,
    required this.onNewGame,
    required this.onNext,
  });

  final GameEnd end;

  /// O lado do jogador contra a máquina: o título fala "Você venceu". Nulo
  /// no tabuleiro livre.
  final Side? userSide;

  /// A partida é uma etapa de speedrun: o botão volta para a tentativa.
  final bool speedrun;

  /// No treino: o objetivo foi cumprido. Nulo fora do treino.
  final bool? fulfilled;

  /// O rating e as mensagens; nulo enquanto é calculado ou fora do treino.
  final GameReport? report;
  final bool card;
  final VoidCallback onClose;
  final VoidCallback onNewGame;

  /// Ir para o próximo desafio da Jornada. Nulo quando não há.
  final VoidCallback? onNext;

  @override
  State<_End> createState() => _EndState();
}

class _EndState extends State<_End> with SingleTickerProviderStateMixin {
  // A entrada do cartão: ele cresce, o ícone salta e o rating conta até o
  // valor novo.
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  @override
  void initState() {
    super.initState();
    if (widget.card) _controller.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Com menos movimento pedido ao sistema, tudo já aparece no lugar.
    if (!widget.card || MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Animation<double> _interval(double begin, double end, Curve curve) =>
      CurvedAnimation(
        parent: _controller,
        curve: Interval(begin, end, curve: curve),
      );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final l10n = context.l10n;
    final end = widget.end;
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
      GameEndReason.drawAgreed => l10n.freeBoardDrawAgreed,
    };
    final result = switch (end.winner) {
      Side.white => l10n.freeBoardWhiteWins,
      Side.black => l10n.freeBoardBlackWins,
      null => l10n.freeBoardDraw,
    };
    final again = Text(
      widget.speedrun
          ? l10n.speedrunContinue
          : widget.fulfilled == null
          ? l10n.freeBoardNewGame
          : l10n.resultPlayAgain,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
    final onNext = widget.onNext;
    final buttons = [
      if (onNext != null)
        FilledButton.icon(
          key: FreeBoardKeys.endNextButton,
          onPressed: onNext,
          icon: const Icon(Icons.skip_next_rounded),
          label: Text(
            l10n.resultNextChallenge,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      // No treino, a mesma posição com a mesma configuração.
      if (onNext == null)
        FilledButton(
          key: FreeBoardKeys.endNewGameButton,
          onPressed: widget.onNewGame,
          child: again,
        )
      else
        OutlinedButton(
          key: FreeBoardKeys.endNewGameButton,
          onPressed: widget.onNewGame,
          child: again,
        ),
    ];
    final goal = switch (widget.fulfilled) {
      final done? => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            done ? Icons.check_circle : Icons.cancel_outlined,
            size: 18,
            color: ChangeColors.of(context, up: done),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              done ? l10n.resultFulfilled : l10n.resultNotFulfilled,
              key: FreeBoardKeys.endGoal,
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: ChangeColors.of(context, up: done),
              ),
            ),
          ),
        ],
      ),
      null => null,
    };
    final before = widget.report?.before?.rounded;
    final after = widget.report?.after?.rounded;
    Widget? rating(CrossAxisAlignment align, {required bool large}) {
      if (before == null || after == null) return null;
      final counting = _interval(0.35, 1, Curves.easeOutCubic);
      return Semantics(
        container: true,
        label: ratingSemantics(context, after, after - before),
        excludeSemantics: true,
        child: Column(
          key: FreeBoardKeys.ratingChange,
          crossAxisAlignment: align,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.reportRatingLabel,
              style: theme.textTheme.labelMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            AnimatedBuilder(
              animation: counting,
              builder: (context, _) => RatingValue(
                // O número conta do rating antigo até o novo.
                rating: (before + (after - before) * counting.value).round(),
                change: ((after - before) * counting.value).round(),
                up: after >= before,
                large: large,
                valueKey: FreeBoardKeys.ratingValue,
                changeKey: FreeBoardKeys.ratingDelta,
              ),
            ),
          ],
        ),
      );
    }

    if (!widget.card) {
      return _panel(theme, end, reason, result, goal, rating, buttons);
    }

    // O título do ponto de vista do jogador, quando ele joga contra a
    // máquina; no tabuleiro livre, quem venceu.
    final userSide = widget.userSide;
    final won = userSide != null && end.winner == userSide;
    final lost = userSide != null && end.winner == userSide.opposite;
    final title = end.winner == null
        ? l10n.freeBoardDraw
        : won
        ? l10n.resultYouWon
        : lost
        ? l10n.resultYouLost
        : result;
    final accent = won
        ? ChangeColors.of(context, up: true)
        : lost
        ? ChangeColors.of(context, up: false)
        : colors.onSurfaceVariant;
    final icon = end.winner == null
        ? Icons.handshake_rounded
        : lost
        ? Icons.flag_rounded
        : Icons.emoji_events_rounded;
    final entrance = _interval(0, 0.35, Curves.easeOutBack);
    final pop = _interval(0.15, 0.7, Curves.elasticOut);
    final ratingWidget = rating(CrossAxisAlignment.center, large: true);
    return FadeTransition(
      opacity: _interval(0, 0.2, Curves.easeOut),
      child: ScaleTransition(
        scale: Tween(begin: 0.8, end: 1.0).animate(entrance),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Material(
            key: FreeBoardKeys.endPanel,
            color: theme.colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(24),
            clipBehavior: Clip.antiAlias,
            elevation: 12,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Stack(
                  fit: StackFit.passthrough,
                  children: [
                    Padding(
                      key: FreeBoardKeys.resultCard,
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                      child: Column(
                        children: [
                          // Só o ícone leva a cor do resultado; o cartão
                          // fica neutro, como no chess.com.
                          ScaleTransition(
                            scale: pop,
                            child: Icon(icon, size: 44, color: accent),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            title,
                            key: FreeBoardKeys.resultTitle,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            reason,
                            key: FreeBoardKeys.endReason,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    PositionedDirectional(
                      top: 4,
                      end: 4,
                      child: IconButton(
                        key: FreeBoardKeys.resultClose,
                        tooltip: MaterialLocalizations.of(context)
                            .closeButtonTooltip,
                        icon: const Icon(Icons.close),
                        onPressed: widget.onClose,
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        result,
                        key: FreeBoardKeys.endResult,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                      if (goal != null) ...[
                        const SizedBox(height: 6),
                        Center(child: goal),
                      ],
                      if (ratingWidget != null) ...[
                        const SizedBox(height: 16),
                        Center(child: ratingWidget),
                      ],
                      const SizedBox(height: 20),
                      for (final (index, button) in buttons.indexed) ...[
                        if (index > 0) const SizedBox(height: 8),
                        SizedBox(height: 48, child: button),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// O painel embaixo do tabuleiro, depois de fechar o cartão (ou ao reabrir
  /// uma partida já terminada).
  Widget _panel(
    ThemeData theme,
    GameEnd end,
    String reason,
    String result,
    Widget? goal,
    Widget? Function(CrossAxisAlignment, {required bool large}) rating,
    List<Widget> buttons,
  ) {
    final colors = theme.colorScheme;
    final onColor = colors.onSecondaryContainer;
    final ratingWidget = rating(CrossAxisAlignment.end, large: false);
    return Container(
      key: FreeBoardKeys.endPanel,
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      padding: const EdgeInsetsDirectional.fromSTEB(14, 10, 14, 12),
      decoration: BoxDecoration(
        color: colors.secondaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                end.winner == null ? Icons.handshake_outlined : Icons.flag,
                color: onColor,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reason,
                      key: FreeBoardKeys.endReason,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: onColor,
                      ),
                    ),
                    Text(
                      result,
                      key: FreeBoardKeys.endResult,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: onColor,
                      ),
                    ),
                    if (goal != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: goal,
                      ),
                  ],
                ),
              ),
              if (ratingWidget != null) ...[
                const SizedBox(width: 8),
                ratingWidget,
              ],
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              for (final (index, button) in buttons.reversed.indexed) ...[
                if (index > 0) const SizedBox(width: 8),
                Expanded(child: button),
              ],
            ],
          ),
        ],
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

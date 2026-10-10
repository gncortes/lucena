import 'dart:async';

import 'package:chessground/chessground.dart';
import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/models/board_settings.dart';
import '../../../domain/models/clock_settings.dart';
import '../../../domain/models/game_end.dart';
import '../../../domain/models/pace.dart';
import '../../../domain/use_cases/game_rules.dart';
import '../../core/board/board_settings_ui.dart';
import '../../core/board/centered_board_layout.dart';
import '../../../routing/routes.dart';
import '../../core/keys/free_board_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/widgets/character_avatar.dart';
import '../../profile/view_models/profile_cubit.dart';
import '../../settings/view_models/settings_cubit.dart';
import '../view_models/free_board_cubit.dart';
import '../view_models/talk_cubit.dart';
import '../../conclusion/view_models/conclusion_cubit.dart';
import '../../../domain/models/conclusion.dart';
import '../../../domain/use_cases/conclusion_rules.dart';
import 'clock_row.dart';
import 'character_bar.dart';
import 'clock_sheet.dart';
import '../../core/widgets/versus_intro.dart';
import 'move_list.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_shape.dart';
import '../../core/opponent/opponent_ui.dart';

class FreeBoardScreen extends StatefulWidget {
  const FreeBoardScreen({super.key});

  @override
  State<FreeBoardScreen> createState() => _FreeBoardScreenState();
}

class _FreeBoardScreenState extends State<FreeBoardScreen>
    with WidgetsBindingObserver {
  late final ChessboardController _board;

  // O relógio não conta tiques: a tela só pede, várias vezes por segundo, que
  // os tempos sejam refeitos pelo instante atual.
  late final Timer _clockRefresh;

  // A partida contra a máquina acabou: o resultado em destaque por um
  // instante, antes da troca para a tela de conclusão (T51, B4).
  bool _concluding = false;

  // O jogador confirmou que sai do speedrun: a tela pode fechar.
  bool _quitting = false;

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

  // Sair no meio do speedrun: a tentativa termina aqui e fica no histórico,
  // sem recorde.
  Future<void> _confirmQuitSpeedrun(FreeBoardCubit cubit) async {
    final l10n = context.l10n;
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 12,
            children: [
              Text(
                l10n.speedrunQuitTitle,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              Text(
                l10n.speedrunAbandonQuestion,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              FilledButton(
                key: FreeBoardKeys.speedrunQuitConfirm,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  backgroundColor: Theme.of(context).colorScheme.error,
                  foregroundColor: Theme.of(context).colorScheme.onError,
                ),
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(l10n.speedrunAbandon),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(l10n.speedrunKeepGoing),
              ),
            ],
          ),
        ),
      ),
    );
    if (!(confirmed ?? false) || !mounted) return;
    await cubit.quitSpeedrun();
    if (!mounted) return;
    setState(() => _quitting = true);
    // Só depois de a tela aceitar fechar.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.of(context).maybePop();
    });
  }

  GameData _gameData(FreeBoardState state) {
    // Revendo um lance anterior, o tabuleiro mostra a posição daquele
    // momento.
    final position = state.shownPosition;
    return GameData(
      fen: position.fen,
      playerSide: _playerSide(state),
      sideToMove: position.turn,
      validMoves: state.browsing
          ? const <Square, Set<Square>>{}
          : GameRules.legalMoves(position),
      lastMove: state.shownMove,
      kingSquareInCheck: GameRules.checkedKing(position),
    );
  }

  PlayerSide _playerSide(FreeBoardState state) {
    // Com a partida terminada ou revendo um lance, o tabuleiro trava.
    if (state.end != null || state.browsing) return PlayerSide.none;
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
          // A partida contra a máquina terminou agora: a tela de conclusão
          // abre no lugar desta (T51, B4). No tabuleiro livre de dois, o fim
          // fica embaixo do tabuleiro.
          listenWhen: (previous, current) => previous.end != current.end,
          listener: (context, state) {
            if (state.end == null || !state.mode.opponent.isMachine) return;
            unawaited(_conclude(context, cubit, state));
          },
          child: BlocConsumer<FreeBoardCubit, FreeBoardState>(
            // O tabuleiro só é refeito quando a partida muda, não a cada tique do
            // relógio.
            listenWhen: (previous, current) =>
                !identical(previous.position, current.position) ||
                previous.moves.length != current.moves.length ||
                previous.viewedPly != current.viewedPly ||
                previous.end != current.end ||
                previous.playerSide != current.playerSide ||
                previous.machineThinking != current.machineThinking,
            listener: (context, state) => _onStateChanged(state),
            builder: (context, state) {
              // Sair da tela pela seta ou pelo botão de voltar para o relógio e
              // guarda a partida. No meio de um speedrun, sair encerra a
              // tentativa: antes, a confirmação.
              final speedrunOpen =
                  state.mode.isSpeedrun && state.end == null && !_quitting;
              return PopScope(
                canPop: !speedrunOpen,
                onPopInvokedWithResult: (didPop, _) {
                  if (didPop) {
                    if (!state.mode.isSpeedrun) unawaited(cubit.leave());
                  } else {
                    unawaited(_confirmQuitSpeedrun(cubit));
                  }
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
        // Os lances numa faixa, logo abaixo da barra: tocar num deles mostra a
        // posição daquele momento.
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(MoveList.height),
          child: MoveList(
            moves: state.moves,
            firstMoveNumber: state.start.fullmoves,
            firstSide: state.start.turn,
            selected: state.shownPly - 1,
            onSelected: (index) => cubit.view(index + 1),
            pieceLetters: boardSettings.notation.pieceLetters(context.l10n),
          ),
        ),
        // No treino a barra fica só com os botões: o objetivo aparece no fim.
        title: goal == null ? Text(context.l10n.freeBoardTitle) : null,
        // No treino, só propor empate e desistir; virar, trocar o relógio e
        // recomeçar ficam no tabuleiro livre.
        actions: training
            ? [
                // O som do personagem: liga e desliga a voz dele, e fica
                // gravado.
                if (talk.character != null && !talk.isEngine)
                  const CharacterSoundButton(),
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
                  icon: const Icon(Icons.av_timer_outlined),
                  tooltip: context.l10n.freeBoardClock,
                  onPressed: _pickClock,
                ),
                IconButton(
                  key: FreeBoardKeys.newGameButton,
                  icon: const Icon(Icons.add),
                  tooltip: context.l10n.freeBoardNewGame,
                  onPressed: cubit.newGame,
                ),
              ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Sem relógio na partida, cada lado tem a sua linha (o peão e o
            // nome), com a vez de quem joga; com relógio, onde o jogador
            // escolheu.
            final clocks = state.clock == null
                ? ClockPosition.sides
                : clockPosition;
            final character = talk.character;
            final nickname = context.select(
              (ProfileCubit cubit) => cubit.state?.nickname ?? '',
            );
            // O tabuleiro na largura toda, com o centro no centro do espaço
            // útil (T64): entre a barra do app (com a faixa de lances) e o
            // fim da área segura. O personagem e os relógios ficam em cima e
            // embaixo, no espaço que sobra de cada lado; sem espaço, o
            // retrato encolhe e, no limite, o tabuleiro também.
            final clocksAbove =
                clocks == ClockPosition.top || clocks == ClockPosition.sides
                ? ClockRow.height
                : 0.0;
            final clocksBelow =
                clocks == ClockPosition.bottom || clocks == ClockPosition.sides
                ? ClockRow.height
                : 0.0;
            // Só os relógios têm espaço garantido: o personagem fica com o
            // que sobra (o tabuleiro não diminui por causa dele).
            final reserveTop = clocksAbove;
            final centering = BoardCentering(
              constraints.biggest,
              gap: 0,
              reserveTop: reserveTop,
              reserveBottom: clocksBelow,
            );
            // O retrato do personagem fica com o que sobra em cima.
            final avatar = character == null
                ? 0.0
                : (centering.roomAbove -
                          clocksAbove -
                          CharacterBar.heightFor(0))
                      .clamp(CharacterBar.minAvatar, CharacterBar.maxAvatar)
                      .toDouble();
            const both = [Side.white, Side.black];
            final end = state.end;
            return Stack(
              // A tela toda: o fundo escuro do resultado cobre até embaixo,
              // mesmo com pouco conteúdo.
              fit: StackFit.expand,
              children: [
                CenteredBoardLayout(
                  key: FreeBoardKeys.scrollArea,
                  gap: 0,
                  reserveTop: reserveTop,
                  reserveBottom: clocksBelow,
                  top: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
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
                    ],
                  ),
                  // O tabuleiro não espelha em idiomas da direita para a
                  // esquerda.
                  board: LayoutBuilder(
                    builder: (context, box) => Stack(
                      alignment: Alignment.center,
                      children: [
                        Directionality(
                          textDirection: TextDirection.ltr,
                          child: Chessboard(
                            key: FreeBoardKeys.board,
                            size: box.maxWidth,
                            controller: _board,
                            // No ultra bullet o pré-lance fica sempre ligado:
                            // sem ele, não dá tempo de jogar no celular.
                            settings: _ultraBullet(state)
                                ? boardSettings
                                      .copyWith(premoves: true)
                                      .chessground
                                : boardSettings.chessground,
                            orientation: state.orientation,
                            onMove: (move, {viaDragAndDrop}) =>
                                cubit.play(move),
                          ),
                        ),
                        // Toda partida nova contra a máquina abre com o
                        // versus (na Maratona, com a contagem); só então
                        // o relógio corre.
                        if (state.held)
                          Positioned.fill(
                            child: VersusIntro(
                              playerName: nickname.isEmpty
                                  ? context.l10n.profileNicknameDefault
                                  : nickname,
                              opponentName:
                                  character?.name ??
                                  state.mode.opponent.label(
                                    context.l10n,
                                    level: state.mode.level,
                                  ),
                              opponentRating: talk.isEngine
                                  ? null
                                  : state.mode.level,
                              opponentAvatar: character == null
                                  ? const ColoredBox(
                                      color: Color(0xFF312E2B),
                                      child: Icon(
                                        Icons.smart_toy_outlined,
                                        color: Colors.white,
                                        size: 32,
                                      ),
                                    )
                                  : CharacterAvatar(
                                      character: character,
                                      size: 64,
                                    ),
                              countdown: state.mode.isMarathon,
                              stage: state.mode.isMarathon
                                  ? (state.mode.speedrunStage ?? 0) + 1
                                  : null,
                              playerSide: state.playerSide ?? state.orientation,
                              onDone: cubit.release,
                            ),
                          ),
                      ],
                    ),
                  ),
                  bottom: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
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
                      // Embaixo do tabuleiro: o fim da partida de dois.
                      if (end != null && !state.mode.opponent.isMachine)
                        _TwoPlayersEnd(end: end, onNewGame: cubit.newGame),
                    ],
                  ),
                ),
                // O resultado em destaque, antes da conclusão.
                if (end != null && _concluding)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: _EndFlash(end: end, userSide: state.mode.userSide),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  static bool _ultraBullet(FreeBoardState state) {
    final time = state.clock?.config.of(state.mode.userSide ?? Side.white);
    return time != null && PaceCategory.of(time) == PaceCategory.ultraBullet;
  }

  // A partida acabou: um instante com o resultado em destaque e a tela de
  // conclusão no lugar desta (voltar dela leva para antes da partida). Na
  // Maratona, a etapa vencida segue direto para a próxima, sem conclusão.
  Future<void> _conclude(
    BuildContext context,
    FreeBoardCubit cubit,
    FreeBoardState state,
  ) async {
    final pause = AppMotion.of(context).disabled ? Duration.zero : _flashTime;
    final marathonWin = state.mode.isMarathon && (state.fulfilled ?? false);
    if (!marathonWin) setState(() => _concluding = true);
    await Future.wait([cubit.saved(), Future<void>.delayed(pause)]);
    if (!context.mounted || cubit.state.end == null) return;
    final step = cubit.state.report?.speedrun;
    final next = step?.challenge;
    if (marathonWin && step != null && next != null) {
      setState(() => _quitting = true);
      context.pushReplacement(
        Routes.challengeGame(
          next,
          speedrunId: step.speedrunId,
          attemptId: step.attemptId,
          stage: step.stage,
          userTime: step.userTime,
        ),
      );
      return;
    }
    final recorded =
        state.mode.positionId != null &&
        state.outcome != null &&
        state.fulfilled != null;
    final id = recorded ? await cubit.savedGameId() : null;
    if (!context.mounted) return;
    setState(() => _quitting = true);
    if (id != null) {
      context.pushReplacement(Routes.conclusion(id, fresh: true));
      return;
    }
    // Sem gravar (posição personalizada): a conclusão vai pronta.
    final talk = context.read<TalkCubit>().state;
    final outcome = state.outcome;
    context.pushReplacement(
      Routes.conclusionNow,
      extra: ConclusionArgs(
        conclusion: Conclusion(
          kind: ConclusionKind.game,
          result: outcome == null
              ? ConclusionResult.draw
              : ConclusionRules.resultOf(outcome),
          actions: ConclusionRules.actionsFor(
            ConclusionKind.game,
            recorded: false,
          ),
          end: state.end,
          userSide: state.mode.userSide,
          fulfilled: state.fulfilled,
          finalFen: state.position.fen,
        ),
        opponent: talk.character,
        replay: GoRouterState.of(context).uri.toString(),
      ),
    );
  }

  /// Quanto o resultado fica em destaque antes da conclusão.
  static const _flashTime = AppMotion.celebrate;
}

/// O resultado em destaque por um instante, no meio do tabuleiro, quando a
/// partida contra a máquina acaba.
class _EndFlash extends StatelessWidget {
  const _EndFlash({required this.end, this.userSide});

  final GameEnd end;
  final Side? userSide;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final winner = end.winner;
    final title = winner == null
        ? l10n.conclusionDraw
        : winner == userSide
        ? l10n.resultYouWon
        : l10n.resultYouLost;
    return Center(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.6, end: 1),
        duration: AppMotion.of(context).screen,
        curve: AppMotion.pop,
        builder: (context, scale, child) =>
            Transform.scale(scale: scale, child: child),
        child: Container(
          key: FreeBoardKeys.endFlash,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          decoration: BoxDecoration(
            color: colors.inverseSurface.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(AppShape.large),
          ),
          child: Text(
            title,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: colors.onInverseSurface,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}

/// O fim da partida de dois, embaixo do tabuleiro: o motivo, o resultado e
/// "Nova partida".
class _TwoPlayersEnd extends StatelessWidget {
  const _TwoPlayersEnd({required this.end, required this.onNewGame});

  final GameEnd end;
  final VoidCallback onNewGame;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final onColor = colors.onSecondaryContainer;
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
    return Container(
      key: FreeBoardKeys.endPanel,
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      padding: const EdgeInsetsDirectional.fromSTEB(14, 10, 14, 12),
      decoration: BoxDecoration(
        color: colors.secondaryContainer,
        borderRadius: BorderRadius.circular(AppShape.large),
      ),
      child: Row(
        children: [
          Icon(
            end.winner == null
                ? Icons.handshake_outlined
                : end.reason == GameEndReason.resign
                ? Icons.flag
                : Icons.emoji_events,
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
                  style: theme.textTheme.bodyMedium?.copyWith(color: onColor),
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

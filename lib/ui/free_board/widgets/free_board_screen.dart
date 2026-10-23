import 'dart:async';

import 'package:chessground/chessground.dart';
import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lucena_ui/lucena_ui.dart';

import '../../../domain/models/board_settings.dart';
import '../../../domain/models/clock_settings.dart';
import '../../../domain/models/game_end.dart';
import '../../../domain/models/game_setup.dart';
import '../../challenge/widgets/challenge_result_share.dart';
import '../../core/keys/challenge_keys.dart';
import '../../../domain/models/pace.dart';
import '../../../domain/use_cases/game_rules.dart';
import '../../core/board/board_settings_ui.dart';
import '../../core/board/centered_board_layout.dart';
import '../../../routing/routes.dart';
import '../../core/keys/free_board_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/widgets/character_avatar.dart';
import '../../core/widgets/game_board_hero.dart';
import '../../core/widgets/game_entrance.dart';
import '../../profile/view_models/profile_cubit.dart';
import '../../settings/view_models/settings_cubit.dart';
import '../view_models/free_board_cubit.dart';
import '../view_models/talk_cubit.dart';
import '../../conclusion/view_models/conclusion_cubit.dart';
import '../../../domain/models/conclusion.dart';
import '../../../domain/use_cases/conclusion_rules.dart';
import 'clock_row.dart';
import 'game_actions_bar.dart';
import '../../catalog/widgets/catalog_ui.dart';
import 'character_bar.dart';
import 'sound_dialog.dart';
import 'clock_sheet.dart';
import '../../core/widgets/versus_intro.dart';
import 'move_list.dart';
import '../../core/opponent/opponent_ui.dart';
import '../../daily/view_models/daily_game_cubit.dart';
import '../../daily/widgets/daily_end_bar.dart';
import '../../featured/view_models/featured_endgame_cubit.dart';
import '../../featured/widgets/featured_game_bar.dart';

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

  // O jogador confirmou que sai do speedrun: a tela pode fechar.
  bool _quitting = false;

  // O que o "compartilhar" de um final em destaque captura.
  final _shareBoundary = GlobalKey();
  bool _confirmingQuit = false;
  // Só vale uma confirmação dada com o app em primeiro plano.
  AppLifecycleState _lifecycle = AppLifecycleState.resumed;

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
    _clockRefresh = Timer.periodic(AppMotion.clockRefresh, (_) {
      cubit.tick();
      // As falas de tempo não precisam de tanta pressa: uma vez por segundo.
      if (++ticks % 10 == 0) talk.tick(cubit.state);
    });
  }

  // Voltando do segundo plano ou da tela bloqueada: relógios refeitos e, se
  // for a vez da máquina, ela volta a pensar.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _lifecycle = state;
    if (state == AppLifecycleState.resumed) {
      context.read<FreeBoardCubit>().resumed();
    }
  }

  Future<void> _confirmDraw() async {
    final cubit = context.read<FreeBoardCubit>();
    final confirmed = await showDrawSheet(
      context,
      opponent: context.read<TalkCubit>().state.character?.name,
    );
    if ((confirmed ?? false) && mounted && cubit.state.canOfferDraw) {
      cubit.offerDraw();
    }
  }

  Future<void> _confirmResign() async {
    final cubit = context.read<FreeBoardCubit>();
    final confirmed = await showResignSheet(context);
    if (confirmed == true &&
        mounted &&
        _lifecycle == AppLifecycleState.resumed) {
      cubit.resign();
    }
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
    if (_confirmingQuit || _quitting) return;
    _confirmingQuit = true;
    final won = await cubit.speedrunStagesWon();
    if (!mounted) return;
    final l10n = context.l10n;
    final confirmed = await _showGameConfirmation(
      context,
      sheetKey: FreeBoardKeys.speedrunQuitSheet,
      confirmKey: FreeBoardKeys.speedrunQuitConfirm,
      cancelKey: FreeBoardKeys.speedrunQuitCancel,
      title: l10n.speedrunQuitTitle,
      hint: l10n.speedrunQuitHint(won),
      action: l10n.speedrunAbandon,
      cancel: l10n.speedrunKeepGoing,
      destructive: true,
    );
    _confirmingQuit = false;
    if (confirmed != true ||
        !mounted ||
        _lifecycle != AppLifecycleState.resumed) {
      return;
    }
    await cubit.quitSpeedrun(confirmed: true);
    if (!mounted) return;
    setState(() => _quitting = true);
    // Só depois de a tela aceitar fechar.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (context.canPop()) {
        context.pop();
      } else {
        final id = cubit.state.mode.speedrunId;
        context.go(id == null ? Routes.speedruns : Routes.speedrun(id));
      }
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
    return BlocListener<TalkCubit, TalkState>(
      listenWhen: (previous, current) =>
          previous.speechHintVersion != current.speechHintVersion,
      listener: (context, state) {
        final name = state.character?.name;
        if (name == null) return;
        showLucenaSnackBar(
          context,
          context.l10n.gameSpeechHint(name),
          key: FreeBoardKeys.speechHint,
          action: SnackBarAction(
            key: FreeBoardKeys.speechHintAdjust,
            label: context.l10n.gameSpeechAdjust,
            onPressed: () => showGameSoundDialog(context),
          ),
        );
      },
      child: BlocListener<FreeBoardCubit, FreeBoardState>(
        // Final do dia: a cor de cada lance e a primeira tentativa do dia.
        listenWhen: (previous, current) =>
            current.mode.dailyDate != null &&
            (previous.ucis.length != current.ucis.length ||
                previous.end != current.end ||
                previous.startedAt != current.startedAt),
        listener: (context, state) =>
            context.read<DailyGameCubit>().update(state),
        child: BlocListener<FreeBoardCubit, FreeBoardState>(
          // Final em destaque: o primeiro lance conta como tentativa.
          listenWhen: (previous, current) =>
              current.mode.featuredId != null &&
              previous.ucis.isEmpty &&
              current.ucis.isNotEmpty,
          listener: (context, state) =>
              unawaited(context.read<FeaturedEndgameCubit>().markPlayed()),
          child: BlocListener<FreeBoardCubit, FreeBoardState>(
            // O personagem vê cada lance, o fim e a partida nova.
            listenWhen: (previous, current) =>
                previous.ready != current.ready ||
                previous.ucis.length != current.ucis.length ||
                previous.end != current.end ||
                previous.startedAt != current.startedAt ||
                previous.drawOffer != current.drawOffer,
            listener: (context, state) =>
                context.read<TalkCubit>().update(state),
            child: BlocListener<FreeBoardCubit, FreeBoardState>(
              // A máquina recusou o empate: um aviso curto, além da fala.
              listenWhen: (previous, current) =>
                  previous.drawOffer != current.drawOffer &&
                  current.drawOffer == DrawOffer.declined,
              listener: (context, state) => showLucenaSnackBar(
                context,
                context.l10n.gameDrawDeclined,
                key: FreeBoardKeys.drawDeclined,
              ),
              child: BlocListener<FreeBoardCubit, FreeBoardState>(
                // A partida contra a máquina terminou agora: a tela de conclusão
                // abre no lugar desta (T51, B4). No tabuleiro livre de dois, o fim
                // fica embaixo do tabuleiro.
                listenWhen: (previous, current) => previous.end != current.end,
                listener: (context, state) {
                  if (!_marathonAdvance(state)) return;
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
                        state.mode.isSpeedrun &&
                        state.end == null &&
                        !_quitting;
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
        appBar: LucenaAppBar(title: Text(context.l10n.freeBoardTitle)),
      );
    }
    final training = state.mode.userSide != null;
    final featured = state.mode.featuredId != null;
    return Scaffold(
      key: FreeBoardKeys.screen,
      appBar: LucenaAppBar(
        actions: featured
            ? [
                FeaturedGameActions(
                  boundary: _shareBoundary,
                  ended: state.end != null && state.mode.opponent.isMachine,
                ),
              ]
            : null,
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
        title: state.mode.fromLink
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    context.l10n.journeyChallengeTitle,
                    key: FreeBoardKeys.title,
                  ),
                  Text(
                    _title(context, state, talk),
                    key: ChallengeKeys.linkGameSubtitle,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              )
            : Text(_title(context, state, talk), key: FreeBoardKeys.title),
      ),
      body: RepaintBoundary(
        key: featured ? _shareBoundary : null,
        child: BoardViewport(
          usefulHeight: BoardViewport.usefulHeightOf(context),
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Sem relógio na partida, cada lado tem a sua linha (o peão e o
                // nome), com a vez de quem joga; com relógio, onde o jogador
                // escolheu.
                final clocks = state.clock == null
                    ? ClockPosition.sides
                    : clockPosition;
                final character = talk.character;
                // Acabou a partida contra a máquina: o selo fica no tabuleiro e
                // o botão leva ao resultado; sem balão aberto (PropV2PartidaFim).
                if (state.end == null) {
                  _endAtOpen = false;
                  _endSeen = true;
                } else if (!_endSeen) {
                  _endAtOpen = true;
                  _endSeen = true;
                }
                final machineEnded =
                    state.end != null &&
                    state.mode.opponent.isMachine &&
                    !_marathonAdvance(state);
                final barTalk = machineEnded
                    ? talk.copyWith(clearLine: true)
                    : talk;
                final nickname = context.select(
                  (ProfileCubit cubit) => cubit.state?.nickname ?? '',
                );
                // O centro do tabuleiro é o centro da tela visível (a altura
                // menos as barras do sistema), como no às cegas e nas
                // estrelas. Retrato, nome e relógio compartilham uma única
                // linha; o balão flutua e não reserva altura.
                final clocksAbove =
                    clocks == ClockPosition.top || clocks == ClockPosition.sides
                    ? ClockRow.height
                    : 0.0;
                final clocksBelow =
                    clocks == ClockPosition.bottom ||
                        clocks == ClockPosition.sides
                    ? ClockRow.height
                    : 0.0;
                final reserveTop = clocksAbove;
                final centering = BoardCentering.balanced(
                  constraints.biggest,
                  gap: _boardGap,
                  reserveTop: reserveTop,
                  reserveBottom: clocksBelow,
                  footer: machineEnded && state.mode.fromLink
                      ? _LinkEndBar.height
                      : GameActionsBar.height,
                );
                const both = [Side.white, Side.black];
                final end = state.end;
                return Stack(
                  // A tela toda: o fundo escuro do resultado cobre até embaixo,
                  // mesmo com pouco conteúdo.
                  fit: StackFit.expand,
                  children: [
                    CenteredBoardLayout(
                      key: FreeBoardKeys.scrollArea,
                      gap: _boardGap,
                      balanced: true,
                      reserveTop: reserveTop,
                      reserveBottom: clocksBelow,
                      footer: machineEnded && featured
                          ? FeaturedEndBar(onAgain: cubit.newGame)
                          : machineEnded && state.mode.dailyDate != null
                          ? DailyEndBar(onAgain: cubit.newGame)
                          : machineEnded && state.mode.fromLink
                          ? _LinkEndBar(
                              onAgain: () => _playLinkAgain(cubit),
                              onShare: () => _shareLinkResult(context, state),
                              onMeetApp: () => _meetApp(context),
                            )
                          : machineEnded
                          ? _SeeResultBar(
                              onPressed: () => unawaited(
                                _conclude(context, cubit, cubit.state),
                              ),
                            )
                          : GameActionsBar(
                              training: training,
                              onResign:
                                  state.end == null &&
                                      state.mode.opponent.isMachine
                                  ? _confirmResign
                                  : null,
                              onDraw: state.canOfferDraw ? _confirmDraw : null,
                              onFlip: cubit.flip,
                              onClock: _pickClock,
                              onNewGame: cubit.newGame,
                              showSound: true,
                            ),
                      // Enquanto o tabuleiro termina o voo, a barra do
                      // adversário desce do alto e a do jogador sobe de baixo.
                      top: GameEntrance(
                        part: GameEntrancePart.top,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (character != null &&
                                clocks != ClockPosition.bottom)
                              CharacterBar(
                                talk: barTalk,
                                avatarSize: CharacterAvatar.player,
                                showName: false,
                                playerRow: ClockRow(
                                  sides: clocks == ClockPosition.top
                                      ? both
                                      : [state.orientation.opposite],
                                  state: state,
                                  board: boardSettings,
                                  talk: talk,
                                ),
                                // A ponta do balão a 4 dp do retrato (que começa 12 dp abaixo
                                // do alto da linha de 68).
                                speechTop: -72,
                              ),
                            if (character == null &&
                                clocks == ClockPosition.top)
                              ClockRow(
                                sides: both,
                                state: state,
                                board: boardSettings,
                                talk: talk,
                              ),
                            if (character == null &&
                                clocks == ClockPosition.sides)
                              ClockRow(
                                sides: [state.orientation.opposite],
                                state: state,
                                board: boardSettings,
                                talk: talk,
                              ),
                          ],
                        ),
                      ),
                      // O tabuleiro não espelha em idiomas da direita para a
                      // esquerda.
                      board: LayoutBuilder(
                        builder: (context, box) => Stack(
                          alignment: Alignment.center,
                          children: [
                            // No começo da partida, o tabuleiro da tela de
                            // antes (no alto) desliza e cresce até aqui.
                            GameBoardHero(
                              orientation: state.orientation,
                              child: Directionality(
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
                            ),
                            // Toda partida nova contra a máquina abre com o
                            // versus (na Maratona, com a contagem); só então
                            // o relógio corre.
                            // O selo do resultado sobre o tabuleiro, até o jogador seguir.
                            if (end != null &&
                                !_endAtOpen &&
                                state.mode.opponent.isMachine)
                              Positioned.fill(
                                child: IgnorePointer(
                                  child: _EndFlash(
                                    key: ValueKey(end),
                                    end: end,
                                    userSide: state.mode.userSide,
                                    // O final em destaque pisca por 1,5 s.
                                    short: state.mode.isUnratedFinal,
                                  ),
                                ),
                              ),
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
                                      ? ColoredBox(
                                          color: AppColors.chessBlackColor,
                                          child: const Icon(
                                            Icons.smart_toy_outlined,
                                            color: AppColors.chessWhiteColor,
                                            size: AppIconSize.large,
                                          ),
                                        )
                                      : CharacterPortrait(
                                          character: character,
                                          size: CharacterAvatar.versus,
                                        ),
                                  countdown: state.mode.isMarathon,
                                  stage: state.mode.isMarathon
                                      ? (state.mode.speedrunStage ?? 0) + 1
                                      : null,
                                  playerSide:
                                      state.playerSide ?? state.orientation,
                                  onDone: cubit.release,
                                ),
                              ),
                          ],
                        ),
                      ),
                      bottom: GameEntrance(
                        part: GameEntrancePart.bottom,
                        child: Column(
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
                            if (clocks == ClockPosition.bottom &&
                                character != null)
                              CharacterBar(
                                talk: barTalk,
                                avatarSize: CharacterAvatar.player,
                                showName: false,
                                playerRow: ClockRow(
                                  sides: both,
                                  state: state,
                                  board: boardSettings,
                                  talk: talk,
                                ),
                                // Mesmo com os relógios embaixo, a fala ocupa
                                // apenas a região acima do tabuleiro.
                                speechTop:
                                    -(centering.side + 2 * _boardGap + 80),
                              ),
                            if (clocks == ClockPosition.bottom &&
                                character == null)
                              ClockRow(
                                sides: both,
                                state: state,
                                board: boardSettings,
                                talk: talk,
                              ),
                            // Embaixo do tabuleiro: o fim da partida de dois.
                            if (end != null && !state.mode.opponent.isMachine)
                              _TwoPlayersEnd(
                                end: end,
                                onNewGame: cubit.newGame,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  String _title(BuildContext context, FreeBoardState state, TalkState talk) {
    final l10n = context.l10n;
    if (state.mode.isSpeedrun) return l10n.speedrunTitle;
    if (state.mode.featuredId != null) return l10n.featuredEndgameTitle;
    if (state.mode.dailyDate != null) return l10n.dailyTitle;
    if (state.mode.challengeId != null && talk.character != null) {
      return l10n.gameChallengeTitle(talk.character!.name);
    }
    final parts = state.mode.positionId?.split('.');
    if (parts != null && parts.length > 1) return endgameName(l10n, parts[1]);
    return l10n.freeBoardTitle;
  }

  static bool _ultraBullet(FreeBoardState state) {
    final time = state.clock?.config.of(state.mode.userSide ?? Side.white);
    return time != null && PaceCategory.of(time) == PaceCategory.ultraBullet;
  }

  // Só a etapa vencida da Maratona segue sozinha; nas demais partidas contra
  // a máquina o fim para no tabuleiro até o jogador tocar em "Ver o resultado".
  bool _marathonAdvance(FreeBoardState state) =>
      state.end != null &&
      state.mode.opponent.isMachine &&
      state.mode.isMarathon &&
      (state.fulfilled ?? false);

  // A partida acabou: a tela de conclusão no lugar desta (voltar dela leva
  // para antes da partida). Na Maratona, a etapa vencida segue direto para a
  // próxima, sem conclusão, depois de um instante com o resultado.
  // Enquanto a folha do sistema está aberta, outro toque não abre outra.
  bool _sharingResult = false;

  /// "Jogar de novo": o mesmo desafio, com o mesmo relógio.
  void _playLinkAgain(FreeBoardCubit cubit) => cubit.newGame();

  /// "Compartilhar": a folha do sistema com a imagem do resultado e o link.
  void _shareLinkResult(BuildContext context, FreeBoardState state) {
    final result = state.challengeResult;
    if (result == null) return;
    final l10n = context.l10n;
    final character = context.read<TalkCubit>().state.character;
    final level = state.mode.level;
    final name = state.mode.opponent == OpponentKind.stockfish
        ? l10n.setupOpponentStockfish
        : character == null || level == null
        ? l10n.opponentMaiaLevel(level ?? 0)
        : l10n.characterNameLevel(character.name, level);
    if (_sharingResult) return;
    _sharingResult = true;
    unawaited(
      shareChallengeResult(
        context,
        result: result,
        opponent: name,
      ).whenComplete(() => _sharingResult = false),
    );
  }

  /// "Conhecer o app": sai do desafio para a tela inicial.
  void _meetApp(BuildContext context) {
    setState(() => _quitting = true);
    context.go(Routes.home);
  }

  Future<void> _conclude(
    BuildContext context,
    FreeBoardCubit cubit,
    FreeBoardState state,
  ) async {
    final marathonWin = _marathonAdvance(state);
    final pause = AppMotion.of(context).disabled || !marathonWin
        ? Duration.zero
        : _flashTime;
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

  /// A tela abriu com a partida já terminada (retomada): sem selo (§12).
  /// Volta a falso quando uma partida nova começa.
  bool _endAtOpen = false;
  bool _endSeen = false;

  /// Quanto o resultado fica em destaque antes da conclusão: o selo inteiro
  /// (entra 200 ms, pico 1200 ms, sai 200 ms).
  static const _flashTime = _EndFlash.total;

  /// Entre as faixas dos jogadores e o tabuleiro (PropV2EtapaSpeedrunP360:
  /// faixa até 184, tabuleiro de 192 a 548, faixa a partir de 556).
  static const _boardGap = 8.0;
}

/// O rodapé da partida terminada contra a máquina: só "Ver o resultado"
/// (PropV2PartidaFim, CompRodapeAcoes).
class _SeeResultBar extends StatelessWidget {
  const _SeeResultBar({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ActionsFooter(
      children: [
        FilledButton.icon(
          key: FreeBoardKeys.seeResultButton,
          onPressed: onPressed,
          icon: const Icon(Icons.arrow_forward),
          label: Text(context.l10n.gameSeeResult),
        ),
      ],
    );
  }
}

/// O rodapé do fim de um desafio de link (PropV1LinkFim): jogar de novo e
/// compartilhar lado a lado, e "Conhecer o app" embaixo.
class _LinkEndBar extends StatelessWidget {
  const _LinkEndBar({
    required this.onAgain,
    required this.onShare,
    required this.onMeetApp,
  });

  final VoidCallback onAgain;
  final VoidCallback onShare;
  final VoidCallback onMeetApp;

  /// O rodapé inteiro: a linha de botões e o botão de texto.
  static const height = 112.0;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ActionsFooter(
          children: [
            OutlinedButton.icon(
              key: ChallengeKeys.endPlayAgain,
              onPressed: onAgain,
              icon: const Icon(Icons.refresh),
              label: Text(l10n.challengeEndPlayAgain),
            ),
            FilledButton.icon(
              key: ChallengeKeys.endShare,
              onPressed: onShare,
              icon: const Icon(Icons.share_outlined),
              label: Text(l10n.challengeShare),
            ),
          ],
        ),
        TextButton.icon(
          key: ChallengeKeys.endMeetApp,
          onPressed: onMeetApp,
          icon: const Icon(Icons.arrow_forward),
          label: Text(l10n.challengeEndMeetApp),
        ),
      ],
    );
  }
}

/// O resultado em destaque, no meio do tabuleiro, quando a partida contra a
/// máquina acaba: entra, fica no pico e sai sozinho (T65, §12).
class _EndFlash extends StatefulWidget {
  const _EndFlash({
    super.key,
    required this.end,
    this.userSide,
    this.short = false,
  });

  final GameEnd end;
  final Side? userSide;

  /// Pisca por [AppMotion.featuredFlash] (entra, fica e sai) em vez do tempo
  /// normal do selo.
  final bool short;

  /// Entrada, pico e saída (200 + 1200 + 200 ms).
  // coreografia do selo de fim: tempo de leitura, não token de animação
  static const total = AppMotion.narration;
  static const _fade = AppMotion.state;
  static const _reducedFade = AppMotion.reducedFade;

  @override
  State<_EndFlash> createState() => _EndFlashState();
}

class _EndFlashState extends State<_EndFlash>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this);
  bool _started = false;
  bool _reduced = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _reduced = AppMotion.of(context).disabled;
    final fade = _reduced ? _EndFlash._reducedFade : _EndFlash._fade;
    _controller.duration = widget.short
        ? AppMotion.featuredFlash
        : fade * 2 + AppMotion.narrationPeak;
    unawaited(_controller.forward());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final winner = widget.end.winner;
    final title = winner == null
        ? l10n.conclusionDraw
        : winner == widget.userSide
        ? l10n.resultYouWon
        : l10n.resultYouLost;
    final fade = _reduced ? _EndFlash._reducedFade : _EndFlash._fade;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        if (_controller.isCompleted) return const SizedBox.shrink();
        final total = _controller.duration!.inMilliseconds;
        final ms = _controller.value * total;
        final f = fade.inMilliseconds;
        final double opacity;
        var scale = 1.0;
        if (ms < f) {
          final t = AppMotion.enter.transform(ms / f);
          opacity = t;
          if (!_reduced) scale = 0.92 + 0.08 * t;
        } else if (ms > total - f) {
          opacity = 1 - AppMotion.exit.transform((ms - (total - f)) / f);
        } else {
          opacity = 1;
        }
        return Center(
          child: Opacity(
            opacity: opacity.clamp(0.0, 1.0),
            child: Transform.scale(scale: scale, child: child),
          ),
        );
      },
      child: Semantics(
        liveRegion: true,
        label: title,
        child: ExcludeSemantics(
          child: Container(
            key: FreeBoardKeys.endFlash,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xl,
              vertical: AppSpacing.lg,
            ),
            decoration: BoxDecoration(
              color: colors.inverseSurface.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(AppShape.large),
            ),
            child: Text(
              title,
              style: context.bigNumber?.copyWith(
                color: colors.onInverseSurface,
              ),
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
    return Card(
      key: FreeBoardKeys.endPanel,
      color: colors.secondaryContainer,
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.xs,
      ),
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.md,
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
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    reason,
                    key: FreeBoardKeys.endReason,
                    style: context.cardTitle?.copyWith(color: onColor),
                  ),
                  Text(
                    result,
                    key: FreeBoardKeys.endResult,
                    style: theme.textTheme.bodyMedium?.copyWith(color: onColor),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
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

/// Pergunta antes de desistir. Devolve verdadeiro se o jogador confirmou.
Future<bool?> showResignSheet(BuildContext context) => _showGameConfirmation(
  context,
  sheetKey: FreeBoardKeys.resignSheet,
  confirmKey: FreeBoardKeys.resignConfirmButton,
  cancelKey: FreeBoardKeys.confirmationCancel,
  title: context.l10n.gameResignTitle,
  hint: context.l10n.gameResignHint,
  action: context.l10n.gameResign,
  cancel: context.l10n.gameKeepPlaying,
  icon: Icons.flag_outlined,
  destructive: true,
);

/// A oferta só chega ao adversário depois da confirmação explícita. Com
/// [opponent], a dica diz o nome do personagem.
Future<bool?> showDrawSheet(BuildContext context, {String? opponent}) =>
    _showGameConfirmation(
      context,
      sheetKey: FreeBoardKeys.drawSheet,
      confirmKey: FreeBoardKeys.drawConfirmButton,
      cancelKey: FreeBoardKeys.confirmationCancel,
      title: context.l10n.gameDrawOfferTitle,
      hint: opponent == null
          ? context.l10n.gameDrawOfferHint
          : context.l10n.gameDrawOfferHintNamed(opponent),
      action: context.l10n.gameOfferDraw,
      cancel: context.l10n.gameKeepPlaying,
      icon: Icons.handshake_outlined,
    );

/// A folha de confirmação das telas de jogo (CompCabecalhoFolha + CompBotao):
/// o X branco fora, acima do canto final; a alça; título e dica; a ação
/// principal e o "continuar" contornado, os dois de 52 na largura toda. Fechar de qualquer jeito que não seja a ação devolve falso.
Future<bool?> _showGameConfirmation(
  BuildContext context, {
  required Key sheetKey,
  required Key confirmKey,
  required Key cancelKey,
  required String title,
  required String hint,
  required String action,
  required String cancel,
  IconData? icon,
  bool destructive = false,
}) async {
  final confirmed = await showLucenaSheet<bool>(
    context,
    sheetKey: sheetKey,
    closeKey: FreeBoardKeys.confirmationClose,
    builder: (context) {
      final theme = Theme.of(context);
      final colors = theme.colorScheme;
      final confirmStyle = FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(kButtonHeight),
        textStyle: AppButtonText.footer(context),
        backgroundColor: destructive ? colors.error : null,
        foregroundColor: destructive ? colors.onError : null,
      );
      void confirm() => Navigator.of(context).pop(true);
      return SafeArea(
        top: false,
        // Com fonte grande, a folha rola: os dois botões continuam ao alcance.
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SheetHeader(title: title, hint: hint),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl,
                  0,
                  AppSpacing.xl,
                  AppSpacing.xl,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: AppSpacing.sm,
                  children: [
                    if (icon == null)
                      FilledButton(
                        key: confirmKey,
                        style: confirmStyle,
                        onPressed: confirm,
                        child: Text(action, textAlign: TextAlign.center),
                      )
                    else
                      FilledButton.icon(
                        key: confirmKey,
                        style: confirmStyle,
                        icon: Icon(icon),
                        onPressed: confirm,
                        label: Text(action, textAlign: TextAlign.center),
                      ),
                    OutlinedButton(
                      key: cancelKey,
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(kButtonHeight),
                        textStyle: AppButtonText.footer(context),
                      ),
                      onPressed: () => Navigator.of(context).pop(false),
                      child: Text(cancel, textAlign: TextAlign.center),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
  // Fechar de qualquer jeito que não seja a ação devolve falso.
  return confirmed ?? false;
}

import 'dart:async';
import 'dart:math';

import 'package:chessground/chessground.dart';
import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/models/board_settings.dart';
import '../../../domain/use_cases/clock_engine.dart';
import '../../../domain/use_cases/game_rules.dart';
import '../../../domain/use_cases/spoken_text.dart';
import '../../core/board/board_settings_ui.dart';
import '../../core/keys/blind_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/opponent/opponent_ui.dart';
import '../../core/widgets/position_board.dart';
import '../../settings/view_models/settings_cubit.dart';
import '../view_models/blind_game_cubit.dart';

/// As frases do modo às cegas no idioma da tela.
BlindPhrases blindPhrases(AppLocalizations l10n) => BlindPhrases(
  yourTurn: l10n.blindSayYourTurn,
  notUnderstood: l10n.blindSayNotUnderstood,
  which: (options) => l10n.blindSayWhich(options.join(l10n.blindOr)),
  position: (white, black) => l10n.blindSayPosition(white, black),
  pawn: l10n.blindPawn,
  won: l10n.blindSayWon,
  lost: l10n.blindSayLost,
  draw: l10n.blindSayDraw,
  resigned: l10n.blindSayResigned,
  confirm: l10n.blindSayConfirm,
  start: l10n.blindSayStart,
  moveLine: (number, side, move) => l10n.blindSayMove(
    number,
    side == Side.white ? l10n.blindWhite : l10n.blindBlack,
    move,
  ),
  noMoves: l10n.blindSayNoMoves,
  illegal: (move) => l10n.blindSayIllegal(_capitalized(move)),
  drawAgreed: l10n.freeBoardDrawAgreed,
  drawDeclined: l10n.gameDrawDeclined,
);

/// Jogar às cegas, falando os lances (spike da T40): o estado em letras
/// grandes, o tabuleiro (com as peças, só as casas ou nenhum), o que o app
/// ouviu e o botão do microfone.
class BlindGameScreen extends StatefulWidget {
  const BlindGameScreen({super.key});

  @override
  State<BlindGameScreen> createState() => _BlindGameScreenState();
}

class _BlindGameScreenState extends State<BlindGameScreen> {
  ChessboardController? _board;

  @override
  void dispose() {
    _board?.dispose();
    super.dispose();
  }

  GameData _gameData(BlindState state) {
    final position = state.position!;
    final canPlay =
        state.phase == BlindPhase.playerTurn ||
        state.phase == BlindPhase.confirming;
    return GameData(
      fen: position.fen,
      playerSide: canPlay
          ? (state.userSide == Side.white ? PlayerSide.white : PlayerSide.black)
          : PlayerSide.none,
      sideToMove: position.turn,
      validMoves: canPlay ? GameRules.legalMoves(position) : const {},
      lastMove: state.lastMove,
      kingSquareInCheck: GameRules.checkedKing(position),
    );
  }

  void _onState(BuildContext context, BlindState state) {
    if (state.position == null) return;
    final board = _board;
    if (board == null) {
      _board = ChessboardController(game: _gameData(state));
    } else {
      board.updatePosition(_gameData(state), resetPremove: true);
    }
    final previous = _previous;
    _previous = state;
    if (state.mic == MicPermission.asking) _askMic(context);
    // Os avisos sobem no topo, sem mexer na tela.
    final l10n = context.l10n;
    final language = Localizations.localeOf(context).toLanguageTag();
    final illegal = state.illegalShown;
    if (illegal != null && illegal != previous.illegalShown) {
      _toast(
        context,
        l10n.blindIllegalHint(SpokenText.san(illegal, language)),
        Icons.block,
      );
    } else if (state.notUnderstood && !previous.notUnderstood) {
      final heard = state.heard;
      _toast(
        context,
        heard == null ? l10n.blindNotHeard : l10n.blindNotUnderstoodHint(heard),
        Icons.hearing_disabled_outlined,
      );
    } else if (state.tooShort && !previous.tooShort) {
      _toast(context, l10n.blindTapTooShort, Icons.touch_app_outlined);
    } else if (state.mic == MicPermission.denied &&
        previous.mic != MicPermission.denied) {
      _toast(context, l10n.blindMicDenied, Icons.mic_off_outlined);
    } else if (state.drawDeclines > previous.drawDeclines) {
      _toast(context, l10n.gameDrawDeclined, Icons.handshake_outlined);
    }
    // A confirmação do lance e a escolha da peça, num diálogo: o tabuleiro
    // não muda de tamanho.
    if (state.phase == BlindPhase.confirming &&
        previous.phase != BlindPhase.confirming) {
      _chooseOption(context);
    }
  }

  BlindState _previous = const BlindState();

  /// Um aviso no topo da tela, que some sozinho.
  void _toast(BuildContext context, String text, IconData icon) {
    final messenger = ScaffoldMessenger.of(context);
    final media = MediaQuery.of(context);
    final colors = Theme.of(context).colorScheme;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          key: BlindKeys.toast,
          behavior: SnackBarBehavior.floating,
          dismissDirection: DismissDirection.up,
          duration: const Duration(seconds: 3),
          backgroundColor: colors.inverseSurface,
          // No alto, logo abaixo da barra do título.
          margin: EdgeInsets.only(
            left: 16,
            right: 16,
            bottom: max(
              16,
              media.size.height -
                  media.padding.top -
                  kToolbarHeight -
                  media.viewInsets.bottom -
                  110,
            ),
          ),
          content: Row(
            children: [
              Icon(icon, color: colors.onInverseSurface, size: 20),
              const SizedBox(width: 12),
              Expanded(child: Text(text)),
            ],
          ),
        ),
      );
  }

  /// "Qual peça?" num diálogo, com as peças possíveis.
  Future<void> _chooseOption(BuildContext context) async {
    final cubit = context.read<BlindGameCubit>();
    final l10n = context.l10n;
    final language = Localizations.localeOf(context).toLanguageTag();
    final options = cubit.state.options;
    final chosen = await showDialog<Move>(
      context: context,
      builder: (context) => BlocListener<BlindGameCubit, BlindState>(
        bloc: cubit,
        // Respondeu por voz: o diálogo fecha sozinho.
        listenWhen: (a, b) => b.phase != BlindPhase.confirming,
        listener: (context, _) => Navigator.of(context).maybePop(),
        child: SimpleDialog(
          title: Text(l10n.blindStatusWhich),
          children: [
            for (final option in options)
              SimpleDialogOption(
                key: BlindKeys.option(option.san),
                onPressed: () => Navigator.pop(context, option.move),
                child: Text(
                  _capitalized(SpokenText.san(option.san, language)),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: Padding(
                padding: const EdgeInsets.only(right: 16, top: 8),
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    MaterialLocalizations.of(context).cancelButtonLabel,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
    if (chosen != null) {
      await cubit.playTouch(chosen);
    } else {
      cubit.cancelChoice();
    }
  }

  /// "Desistir da partida?"
  Future<void> _resign(BuildContext context) async {
    final cubit = context.read<BlindGameCubit>();
    final l10n = context.l10n;
    final sure = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.gameResignTitle),
        content: Text(l10n.gameResignHint),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
          ),
          FilledButton(
            key: BlindKeys.resignConfirm,
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.gameResign),
          ),
        ],
      ),
    );
    if (sure == true) await cubit.resign();
  }

  Future<void> _askMic(BuildContext context) async {
    final l10n = context.l10n;
    final cubit = context.read<BlindGameCubit>();
    final allow = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.mic_none),
        title: Text(l10n.blindMicTitle),
        content: Text(l10n.blindMicBody),
        actions: [
          TextButton(
            key: BlindKeys.micDeny,
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.blindMicDeny),
          ),
          FilledButton(
            key: BlindKeys.micAllow,
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.blindMicAllow),
          ),
        ],
      ),
    );
    if (allow ?? false) {
      await cubit.requestMic();
    } else {
      cubit.declineMic();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final cubit = context.read<BlindGameCubit>();
    return BlocConsumer<BlindGameCubit, BlindState>(
      listener: _onState,
      builder: (context, state) => Scaffold(
        key: BlindKeys.screen,
        appBar: AppBar(
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  l10n.blindTitleShort,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          actions: [
            if (state.started && state.phase != BlindPhase.finished) ...[
              IconButton(
                key: BlindKeys.offerDraw,
                tooltip: l10n.gameOfferDraw,
                icon: state.offeringDraw
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.handshake_outlined),
                onPressed: state.offeringDraw ? null : cubit.offerDraw,
              ),
              IconButton(
                key: BlindKeys.resign,
                tooltip: l10n.gameResign,
                icon: const Icon(Icons.flag_outlined),
                onPressed: () => _resign(context),
              ),
            ],
          ],
        ),
        body: !state.ready || state.position == null
            ? const SizedBox.shrink()
            : SafeArea(
                child: Column(
                  children: [
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          // O tabuleiro com a largura da tela, sem passar da
                          // altura que sobra (com o seletor em cima).
                          final size = min(
                            constraints.maxWidth - 32,
                            constraints.maxHeight - 100,
                          );
                          // Com o teclado aberto, a altura some: o tabuleiro
                          // sai até o teclado fechar.
                          if (size < 120) return const SizedBox.shrink();
                          return Align(
                            alignment: Alignment.topCenter,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: size,
                                  child: Align(
                                    alignment: AlignmentDirectional.centerEnd,
                                    child: _ViewPicker(state: state),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                _boardArea(context, state, size: size),
                                if (state.started) ...[
                                  const SizedBox(height: 10),
                                  if (state.hasClock)
                                    SizedBox(
                                      width: size,
                                      child: _Clocks(state: state),
                                    )
                                  else
                                    _Status(state: state),
                                ],
                                if (state.offlineMissing)
                                  SizedBox(
                                    width: size,
                                    child: Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: Text(
                                        l10n.blindOfflineMissing,
                                        key: BlindKeys.offlineMissing,
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                              color: theme
                                                  .colorScheme
                                                  .onSurfaceVariant,
                                            ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    if (state.phase == BlindPhase.intro)
                      _IntroPanel(state: state, cubit: cubit)
                    else if (state.phase == BlindPhase.finished)
                      _BottomSheetFrame(
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(52),
                          ),
                          onPressed: () => Navigator.of(context).maybePop(),
                          child: Text(l10n.tourBack),
                        ),
                      )
                    else
                      _TalkBar(state: state, cubit: cubit),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _boardArea(
    BuildContext context,
    BlindState state, {
    required double size,
  }) {
    final settings = context.select(
      (SettingsCubit cubit) => cubit.state?.board ?? const BoardSettings(),
    );
    final board = _board;
    final orientation = state.userSide;
    final Widget child = switch (state.view) {
      BlindView.hidden => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(
          Icons.visibility_off_outlined,
          size: 56,
          color: Theme.of(context).colorScheme.outline,
        ),
      ),
      BlindView.empty => _EmptyBoard(
        size: size,
        orientation: orientation,
        selected: state.selected,
        onTap: context.read<BlindGameCubit>().tapSquare,
      ),
      BlindView.board when board != null => Directionality(
        textDirection: TextDirection.ltr,
        child: Chessboard(
          key: BlindKeys.board,
          size: size,
          controller: board,
          settings: settings.chessground,
          orientation: orientation,
          onMove: (move, {viaDragAndDrop}) =>
              context.read<BlindGameCubit>().playTouch(_withQueen(state, move)),
        ),
      ),
      BlindView.board => const SizedBox.shrink(),
    };
    return Center(child: child);
  }

  /// O peão que chega à última fileira pelo toque vira dama.
  static Move _withQueen(BlindState state, Move move) {
    if (move is! NormalMove || move.promotion != null) return move;
    final pawn = state.position!.board.roleAt(move.from) == Role.pawn;
    return pawn && SquareSet.backranks.has(move.to)
        ? move.withPromotion(Role.queen)
        : move;
  }
}

/// Tabuleiro com as peças, só as casas ou nenhum: três ícones pequenos.
class _ViewPicker extends StatelessWidget {
  const _ViewPicker({required this.state});

  final BlindState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SegmentedButton<BlindView>(
      showSelectedIcon: false,
      style: SegmentedButton.styleFrom(
        visualDensity: VisualDensity.compact,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      segments: [
        for (final (view, label, icon) in [
          (BlindView.board, l10n.blindViewBoard, Icons.grid_on),
          (BlindView.empty, l10n.blindViewEmpty, Icons.grid_4x4),
          (BlindView.hidden, l10n.blindViewHidden, Icons.visibility_off),
        ])
          ButtonSegment(
            value: view,
            tooltip: label,
            icon: Icon(icon, key: BlindKeys.view(view), size: 20),
          ),
      ],
      selected: {state.view},
      onSelectionChanged: (selected) =>
          context.read<BlindGameCubit>().setView(selected.single),
    );
  }
}

/// Embaixo do tabuleiro, uma linha: de quem é a vez (ou o resultado). Os
/// lances ficam com "narrar a partida".
class _Status extends StatelessWidget {
  const _Status({required this.state});

  final BlindState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final won = state.userWon;
    final (text, icon, accent) = switch (state.phase) {
      BlindPhase.loading || BlindPhase.intro => (
        l10n.blindIntro,
        Icons.school_outlined,
        colors.secondary,
      ),
      BlindPhase.listening => (
        l10n.blindStatusListening,
        Icons.mic,
        colors.error,
      ),
      BlindPhase.confirming => (
        l10n.blindStatusWhich,
        Icons.help_outline,
        colors.tertiary,
      ),
      BlindPhase.playerTurn || BlindPhase.proposing => (
        l10n.blindStatusYourTurn,
        Icons.person_outline,
        colors.primary,
      ),
      BlindPhase.finished => (
        state.end?.winner == null
            ? l10n.blindSayDraw
            : won == true
            ? l10n.blindSayWon
            : l10n.blindSayLost,
        won == true ? Icons.emoji_events_outlined : Icons.flag_outlined,
        colors.secondary,
      ),
      BlindPhase.opponentThinking || BlindPhase.opponentSpeaking => (
        l10n.blindStatusOpponent,
        Icons.smart_toy_outlined,
        colors.outline,
      ),
    };
    return Semantics(
      liveRegion: true,
      child: Row(
        key: state.phase == BlindPhase.finished
            ? BlindKeys.result
            : BlindKeys.status,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20, color: accent),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              text,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Com relógio: o tempo do adversário, de quem é a vez e o tempo do jogador,
/// numa linha embaixo do tabuleiro.
class _Clocks extends StatelessWidget {
  const _Clocks({required this.state});

  final BlindState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final user = state.userSide;
    return Row(
      children: [
        _ClockChip(
          key: BlindKeys.opponentClock,
          label: state.kind.label(l10n, level: state.level),
          time: state.timeOf(user.opposite)!,
          running: state.running == user.opposite,
        ),
        Expanded(
          child: Center(child: _Status(state: state)),
        ),
        _ClockChip(
          key: BlindKeys.userClock,
          label: l10n.blindYou,
          time: state.timeOf(user)!,
          running: state.running == user,
        ),
      ],
    );
  }
}

/// O relógio de um lado: o nome e o tempo, em destaque quando corre e em
/// vermelho com pouco tempo.
class _ClockChip extends StatelessWidget {
  const _ClockChip({
    required this.label,
    required this.time,
    required this.running,
    super.key,
  });

  final String label;
  final Duration time;
  final bool running;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final low = time < ClockEngine.lowTime;
    final minutes = time.inMinutes;
    final seconds = time.inSeconds % 60;
    final text = low
        ? '$seconds.${(time.inMilliseconds % 1000) ~/ 100}'
        : '$minutes:${seconds.toString().padLeft(2, '0')}';
    final background = running
        ? (low ? colors.errorContainer : colors.primaryContainer)
        : colors.surfaceContainerHighest;
    final foreground = running
        ? (low ? colors.onErrorContainer : colors.onPrimaryContainer)
        : colors.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall?.copyWith(color: foreground),
          ),
          Text(
            text,
            style: theme.textTheme.titleMedium?.copyWith(
              color: foreground,
              fontWeight: FontWeight.w700,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

/// A moldura das partes de baixo: o fundo da barra, com a borda de cima.
class _BottomSheetFrame extends StatelessWidget {
  const _BottomSheetFrame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: child,
      ),
    );
  }
}

/// Antes de começar: ouvir onde estão as peças, ver o tabuleiro e começar.
class _IntroPanel extends StatelessWidget {
  const _IntroPanel({required this.state, required this.cubit});

  final BlindState state;
  final BlindGameCubit cubit;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final showing = state.view == BlindView.board;
    return _BottomSheetFrame(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.blindIntro,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  key: BlindKeys.introListen,
                  icon: const Icon(Icons.hearing),
                  label: Text(l10n.blindListenPosition),
                  onPressed: cubit.narratePosition,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  key: BlindKeys.introBoard,
                  icon: Icon(showing ? Icons.grid_4x4 : Icons.grid_on),
                  label: Text(
                    showing ? l10n.blindViewEmpty : l10n.blindShowBoard,
                  ),
                  onPressed: () => cubit.setView(
                    showing ? BlindView.empty : BlindView.board,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          FilledButton(
            key: BlindKeys.start,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
            ),
            onPressed: cubit.start,
            child: Text(l10n.blindStart),
          ),
        ],
      ),
    );
  }
}

/// A barra de baixo, como a de mandar áudio do WhatsApp, sempre com três
/// linhas (o tabuleiro não muda de tamanho):
///
/// 1. as ações em voz (posição, partida, último lance, medições);
/// 2. o áudio: a dica; gravando, o tempo e as ondas; entendido, o áudio
///    gravado e o microfone para gravar de novo;
/// 3. a entrada: o campo de digitar com o microfone (que vira enviar com
///    texto); gravando, descartar · "Ouvindo…" · enviar; entendido, não ·
///    o lance escrito · sim.
class _TalkBar extends StatefulWidget {
  const _TalkBar({required this.state, required this.cubit});

  final BlindState state;
  final BlindGameCubit cubit;

  @override
  State<_TalkBar> createState() => _TalkBarState();
}

class _TalkBarState extends State<_TalkBar> {
  final _typed = TextEditingController();

  @override
  void initState() {
    super.initState();
    _typed.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _typed.dispose();
    super.dispose();
  }

  void _send() {
    final text = _typed.text.trim();
    if (text.isEmpty) return;
    _typed.clear();
    FocusScope.of(context).unfocus();
    widget.cubit.playTyped(text);
  }

  String _clock(Duration duration) {
    final seconds = duration.inSeconds;
    return '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final cubit = widget.cubit;
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final listening = state.phase == BlindPhase.listening;
    final processing = state.processing;
    final enabled = (listening || state.canListen) && !processing;
    final language = Localizations.localeOf(context).toLanguageTag();
    final proposed = state.phase == BlindPhase.proposing
        ? state.proposal?.san ?? state.illegal
        : null;
    final canPlay =
        state.phase == BlindPhase.playerTurn ||
        state.phase == BlindPhase.proposing ||
        state.phase == BlindPhase.confirming;

    // 1. As ações em voz.
    final actions = SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _ActionChip(
            key: BlindKeys.narratePosition,
            icon: Icons.hearing,
            label: l10n.blindListenPosition,
            onPressed: cubit.narratePosition,
          ),
          const SizedBox(width: 8),
          _ActionChip(
            key: BlindKeys.narrateGame,
            icon: Icons.menu_book_outlined,
            label: l10n.blindNarrateGame,
            onPressed: cubit.narrateGame,
          ),
          if (state.lastOpponent != null) ...[
            const SizedBox(width: 8),
            _ActionChip(
              key: BlindKeys.repeat,
              icon: Icons.volume_up_outlined,
              label: l10n.blindHearAgain,
              onPressed: cubit.repeatOpponent,
            ),
          ],
          const SizedBox(width: 8),
          _ActionChip(
            key: BlindKeys.copyLog,
            icon: Icons.content_copy,
            label: l10n.blindCopyLog,
            onPressed: () => copyLog(context),
          ),
        ],
      ),
    );

    // 2. O áudio.
    final Widget audio;
    if (proposed != null) {
      audio = Row(
        children: [
          IconButton(
            key: BlindKeys.reRecord,
            tooltip: l10n.blindMicTooltip,
            visualDensity: VisualDensity.compact,
            icon: Icon(Icons.mic, color: colors.primary),
            onPressed: cubit.listen,
          ),
          Expanded(
            child: SizedBox(
              height: 24,
              child: CustomPaint(
                painter: _WavePainter(
                  state.levels,
                  colors.primary,
                  whole: true,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            _clock(state.recorded),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colors.onSurfaceVariant,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      );
    } else if (listening && processing) {
      audio = Row(
        children: [
          const SizedBox.square(
            dimension: 14,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 10),
          Text(
            l10n.blindProcessing,
            key: BlindKeys.processing,
            style: theme.textTheme.bodyMedium,
          ),
        ],
      );
    } else if (listening) {
      audio = _Recording(key: BlindKeys.recording, levels: state.levels);
    } else {
      audio = Row(
        children: [
          Expanded(
            child: Text(
              l10n.blindMicHint,
              key: BlindKeys.hint,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ),
          // Como falar e digitar os lances.
          IconButton(
            key: BlindKeys.help,
            tooltip: l10n.blindHelpTitle,
            visualDensity: VisualDensity.compact,
            icon: Icon(Icons.info_outline, color: colors.primary),
            onPressed: () => _showHelp(context),
          ),
        ],
      );
    }

    // 3. A entrada.
    final Widget leading;
    final Widget middle;
    final Widget trailing;
    if (proposed != null) {
      leading = _RoundButton(
        key: BlindKeys.reject,
        tooltip: l10n.blindConfirmNo,
        icon: Icons.close,
        color: colors.errorContainer,
        foreground: colors.onErrorContainer,
        onPressed: cubit.reject,
      );
      middle = _Pill(
        child: Row(
          children: [
            Expanded(
              child: Text(
                _capitalized(SpokenText.san(proposed, language)),
                key: BlindKeys.proposal,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            IconButton(
              key: BlindKeys.sayProposal,
              tooltip: l10n.blindHearAgain,
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.volume_up_outlined),
              onPressed: cubit.sayProposal,
            ),
          ],
        ),
      );
      trailing = _RoundButton(
        key: BlindKeys.confirm,
        tooltip: l10n.blindConfirmYes,
        icon: Icons.check,
        color: colors.primary,
        foreground: colors.onPrimary,
        onPressed: cubit.confirm,
      );
    } else if (listening) {
      leading = _RoundButton(
        key: BlindKeys.discard,
        tooltip: l10n.blindDiscard,
        icon: Icons.delete_outline,
        color: colors.errorContainer,
        foreground: colors.onErrorContainer,
        onPressed: processing ? null : cubit.cancelListening,
      );
      middle = _Pill(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.graphic_eq, size: 20, color: colors.error),
            const SizedBox(width: 8),
            Text(l10n.blindStatusListening, style: theme.textTheme.titleSmall),
          ],
        ),
      );
      trailing = _MicButton(enabled: enabled, listening: true, cubit: cubit);
    } else {
      leading = const SizedBox.shrink();
      middle = TextField(
        key: BlindKeys.typeField,
        controller: _typed,
        enabled: canPlay,
        autocorrect: false,
        enableSuggestions: false,
        textInputAction: TextInputAction.send,
        onSubmitted: (_) => _send(),
        decoration: InputDecoration(
          hintText: l10n.blindTypeHint,
          filled: true,
          fillColor: colors.surfaceContainerHighest,
          isDense: true,
          prefixIcon: const Icon(Icons.keyboard_outlined, size: 20),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
      );
      // Com texto, o microfone vira o "jogar" do que foi digitado.
      trailing = _typed.text.trim().isEmpty
          ? _MicButton(enabled: enabled, listening: false, cubit: cubit)
          : _RoundButton(
              key: BlindKeys.typeSend,
              tooltip: l10n.blindTypeSend,
              icon: Icons.send,
              color: Colors.green.shade600,
              foreground: Colors.white,
              onPressed: canPlay ? _send : null,
            );
    }

    return _BottomSheetFrame(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: 36, child: actions),
          const SizedBox(height: 4),
          SizedBox(
            height: 32,
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: audio,
            ),
          ),
          const SizedBox(height: 6),
          // Os filhos sempre nas mesmas vagas: o microfone segurado continua
          // o mesmo widget quando a gravação começa.
          Row(
            children: [
              leading,
              SizedBox(width: leading is SizedBox ? 0 : 8),
              Expanded(child: middle),
              const SizedBox(width: 8),
              trailing,
            ],
          ),
        ],
      ),
    );
  }
}

/// O "balão" do meio da barra.
class _Pill extends StatelessWidget {
  const _Pill({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minHeight: 44),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
    alignment: AlignmentDirectional.centerStart,
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(24),
    ),
    child: child,
  );
}

/// Como falar e digitar os lances, na notação do idioma do app.
void _showHelp(BuildContext context) {
  final l10n = context.l10n;
  final theme = Theme.of(context);
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) {
      Widget item(IconData icon, String text) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 22, color: theme.colorScheme.primary),
            const SizedBox(width: 14),
            Expanded(child: Text(text, style: theme.textTheme.bodyMedium)),
          ],
        ),
      );
      return SafeArea(
        child: SingleChildScrollView(
          key: BlindKeys.helpSheet,
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.blindHelpTitle, style: theme.textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(
                l10n.blindHelpIntro,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              item(Icons.extension_outlined, l10n.blindHelpPieces),
              item(Icons.keyboard_outlined, l10n.blindHelpTyped),
              item(Icons.mic_none, l10n.blindHelpVoice),
              item(Icons.record_voice_over_outlined, l10n.blindHelpCommands),
              item(Icons.touch_app_outlined, l10n.blindHelpTouch),
            ],
          ),
        ),
      );
    },
  );
}

/// Um botão redondo da barra (descartar, não, sim, teclado).
class _RoundButton extends StatelessWidget {
  const _RoundButton({
    required this.tooltip,
    required this.icon,
    required this.color,
    required this.foreground,
    required this.onPressed,
    super.key,
  });

  final String tooltip;
  final IconData icon;
  final Color color;
  final Color foreground;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: tooltip,
    style: IconButton.styleFrom(
      backgroundColor: color,
      foregroundColor: foreground,
      fixedSize: const Size.square(44),
    ),
    icon: Icon(icon, size: 22),
    onPressed: onPressed,
  );
}

/// Uma ação em voz na fileira de cima (ouvir a posição, narrar a partida).
class _ActionChip extends StatelessWidget {
  const _ActionChip({
    required this.icon,
    required this.label,
    required this.onPressed,
    super.key,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => ActionChip(
    visualDensity: VisualDensity.compact,
    avatar: Icon(icon, size: 16),
    label: Text(label),
    onPressed: onPressed,
  );
}

/// Copia as medições (o relatório do spike).
Future<void> copyLog(BuildContext context) async {
  final messenger = ScaffoldMessenger.of(context);
  final text = context.l10n.blindCopied;
  final log = await context.read<BlindGameCubit>().exportLog();
  await Clipboard.setData(ClipboardData(text: log));
  messenger.showSnackBar(SnackBar(content: Text(text)));
}

/// "dama f4" → "Dama f4".
String _capitalized(String text) =>
    text.isEmpty ? text : text[0].toUpperCase() + text.substring(1);

/// O botão do microfone, como o de áudio do WhatsApp.
///
/// Toque rápido: começa a gravar e o painel fica aberto (enviar e descartar
/// nos botões). Segurar: grava enquanto o dedo estiver nele; soltar envia;
/// arrastar o dedo para longe descarta. Gravando, ele vira o enviar.
class _MicButton extends StatefulWidget {
  const _MicButton({
    required this.enabled,
    required this.listening,
    required this.cubit,
  });

  final bool enabled;
  final bool listening;
  final BlindGameCubit cubit;

  /// Menos que isso é um toque (grava sem segurar), não um aperto.
  static const minHold = Duration(milliseconds: 350);

  /// Arrastar além disso, segurando, descarta.
  static const cancelDistance = 90.0;

  @override
  State<_MicButton> createState() => _MicButtonState();
}

class _MicButtonState extends State<_MicButton> {
  Timer? _hold;
  bool _longEnough = false;
  Offset? _start;
  bool _cancelled = false;

  // O dedo desceu com a gravação já aberta: é o "enviar".
  bool _sending = false;

  @override
  void dispose() {
    _hold?.cancel();
    super.dispose();
  }

  void _down(PointerDownEvent event) {
    if (!widget.enabled) return;
    if (widget.listening) {
      _sending = true;
      return;
    }
    _start = event.position;
    _cancelled = false;
    _longEnough = false;
    _hold?.cancel();
    _hold = Timer(_MicButton.minHold, () => _longEnough = true);
    widget.cubit.listen();
  }

  void _move(PointerMoveEvent event) {
    final start = _start;
    if (start == null || _cancelled || !_longEnough) return;
    if ((event.position - start).distance > _MicButton.cancelDistance) {
      _cancelled = true;
      widget.cubit.cancelListening();
    }
  }

  void _up(PointerUpEvent event) {
    if (_sending) {
      _sending = false;
      widget.cubit.stopListening();
      return;
    }
    final held = _start != null && !_cancelled && _longEnough;
    _start = null;
    _hold?.cancel();
    // Segurou: soltar envia. Tocou: a gravação fica aberta.
    if (held) widget.cubit.stopListening();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = Theme.of(context).colorScheme;
    final listening = widget.listening;
    final enabled = widget.enabled;
    return Semantics(
      button: true,
      enabled: enabled,
      label: listening ? l10n.blindSend : l10n.blindMicTooltip,
      child: Listener(
        key: BlindKeys.mic,
        onPointerDown: _down,
        onPointerMove: _move,
        onPointerUp: _up,
        onPointerCancel: (_) {
          if (_start != null && !_cancelled && _longEnough) {
            widget.cubit.cancelListening();
          }
          _start = null;
          _sending = false;
          _hold?.cancel();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: !enabled
                ? colors.surfaceContainerHighest
                : listening
                ? Colors.green.shade600
                : colors.primary,
          ),
          child: Icon(
            listening ? Icons.send : Icons.mic,
            size: 22,
            color: !enabled
                ? colors.onSurfaceVariant
                : listening
                ? Colors.white
                : colors.onPrimary,
          ),
        ),
      ),
    );
  }
}

/// Gravando, como no WhatsApp: o ponto vermelho piscando, o tempo, as ondas
/// da voz e o lembrete de arrastar para cancelar.
class _Recording extends StatefulWidget {
  const _Recording({required this.levels, super.key});

  final List<double> levels;

  @override
  State<_Recording> createState() => _RecordingState();
}

class _RecordingState extends State<_Recording>
    with SingleTickerProviderStateMixin {
  late final AnimationController _clock = AnimationController(
    vsync: this,
    duration: const Duration(hours: 1),
  )..forward();

  @override
  void dispose() {
    _clock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return AnimatedBuilder(
      animation: _clock,
      builder: (context, _) {
        final elapsed = _clock.lastElapsedDuration ?? Duration.zero;
        final seconds = elapsed.inSeconds;
        // O ponto pisca a cada meio segundo.
        final blink = elapsed.inMilliseconds ~/ 500 % 2 == 0;
        return Row(
          children: [
            AnimatedOpacity(
              opacity: blink ? 1 : 0.25,
              duration: const Duration(milliseconds: 200),
              child: Icon(
                Icons.fiber_manual_record,
                size: 14,
                color: colors.error,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}',
              style: theme.textTheme.titleMedium?.copyWith(
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: SizedBox(
                height: 28,
                child: CustomPaint(
                  painter: _WavePainter(widget.levels, colors.onErrorContainer),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// As ondas da voz, uma barra por medida de volume.
///
/// Gravando ([whole] falso): as medidas crescem da esquerda e, quando não
/// cabem mais, andam para a esquerda (a mais nova sempre à direita). O áudio
/// gravado ([whole]): a gravação inteira, comprimida na largura.
class _WavePainter extends CustomPainter {
  _WavePainter(this.levels, this.color, {this.whole = false});

  final List<double> levels;
  final Color color;
  final bool whole;

  static const _bar = 3.0;
  static const _gap = 2.0;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeCap = StrokeCap.round
      ..strokeWidth = _bar;
    final faint = Paint()
      ..color = color.withValues(alpha: 0.35)
      ..strokeCap = StrokeCap.round
      ..strokeWidth = _bar;
    final count = (size.width / (_bar + _gap)).floor();
    if (count <= 0) return;
    final bars = _bars(count);
    final middle = size.height / 2;
    for (var i = 0; i < count; i++) {
      final x = i * (_bar + _gap) + _bar / 2;
      final level = i < bars.length ? bars[i] : null;
      if (level == null) {
        // O resto da linha, ainda sem som: pontinhos.
        canvas.drawLine(Offset(x, middle - 1), Offset(x, middle + 1), faint);
        continue;
      }
      final half = max(1.5, level * middle);
      canvas.drawLine(
        Offset(x, middle - half),
        Offset(x, middle + half),
        paint,
      );
    }
  }

  List<double> _bars(int count) {
    if (levels.isEmpty) return const [];
    if (!whole) {
      return levels.length > count
          ? levels.sublist(levels.length - count)
          : levels;
    }
    // A gravação inteira: cada barra é o pico do seu pedaço.
    if (levels.length <= count) return levels;
    final out = <double>[];
    for (var i = 0; i < count; i++) {
      final start = i * levels.length ~/ count;
      final end = max(start + 1, (i + 1) * levels.length ~/ count);
      out.add(levels.sublist(start, end).reduce(max));
    }
    return out;
  }

  @override
  bool shouldRepaint(_WavePainter old) =>
      old.levels != levels || old.color != color || old.whole != whole;
}

/// O tabuleiro só com as casas, que aceita o lance pelo toque: a casa de
/// origem e depois a de destino. As peças não aparecem.
class _EmptyBoard extends StatelessWidget {
  const _EmptyBoard({
    required this.size,
    required this.orientation,
    required this.selected,
    required this.onTap,
  });

  final double size;
  final Side orientation;
  final Square? selected;
  final ValueChanged<Square> onTap;

  Square _squareAt(Offset local) {
    final cell = size / 8;
    final column = (local.dx / cell).floor().clamp(0, 7);
    final row = (local.dy / cell).floor().clamp(0, 7);
    final white = orientation == Side.white;
    final file = white ? column : 7 - column;
    final rank = white ? 7 - row : row;
    return Square(rank * 8 + file);
  }

  Offset _cornerOf(Square square) {
    final cell = size / 8;
    final white = orientation == Side.white;
    final column = white ? square.file.value : 7 - square.file.value;
    final row = white ? 7 - square.rank.value : square.rank.value;
    return Offset(column * cell, row * cell);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final selected = this.selected;
    return Directionality(
      textDirection: TextDirection.ltr,
      child: GestureDetector(
        key: BlindKeys.emptyBoard,
        onTapUp: (details) => onTap(_squareAt(details.localPosition)),
        child: SizedBox.square(
          dimension: size,
          child: Stack(
            children: [
              PositionBoard(
                fen: '8/8/8/8/8/8/8/8 w - - 0 1',
                size: size,
                orientation: orientation,
                coordinates: true,
              ),
              if (selected != null)
                Positioned(
                  left: _cornerOf(selected).dx,
                  top: _cornerOf(selected).dy,
                  child: IgnorePointer(
                    child: Container(
                      width: size / 8,
                      height: size / 8,
                      decoration: BoxDecoration(
                        color: colors.primary.withValues(alpha: 0.35),
                        border: Border.all(color: colors.primary, width: 2),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

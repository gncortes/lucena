import '../../../domain/models/load_failure.dart';

import 'dart:async';

import 'package:chessground/chessground.dart';
import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';

import '../../core/widgets/skeleton.dart';

import '../../course_guide/widgets/training_load_error.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/training/course_training_repository.dart';
import '../../../domain/models/board_settings.dart';
import '../../../domain/models/character.dart';
import '../../../domain/models/training/training_course_config.dart';
import '../../../domain/use_cases/game_rules.dart';
import '../../../domain/use_cases/now.dart';
import '../../core/board/board_settings_ui.dart';
import '../../core/board/centered_board_layout.dart';
import '../../core/analytics/analytics_context.dart';
import '../../core/keys/training_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_motion.dart';
import '../../core/widgets/training_canvas_layout.dart';
import '../../core/theme/canvas_symbols.dart';
import '../../core/widgets/lucena_app_bar.dart';
import '../../core/widgets/script_speech_sheet.dart';
import '../../core/widgets/teacher_speech.dart' show LessonVoiceButton;
import '../../core/widgets/lesson_sound_dialog.dart';
import '../../lesson_script/view_models/lesson_script_state.dart';
import '../../lesson_script/widgets/script_move_list.dart';
import '../../settings/view_models/settings_cubit.dart';
import '../view_models/training_opening_cubit.dart';
import '../../core/motion/retorno_do_lance.dart';
import '../../core/motion/celebracao.dart';
import '../../core/motion/entrada_de_resultado.dart';
import '../../core/motion/tabuleiro_hero.dart';
import '../../core/motion/tabuleiro_animado.dart';

class TrainingOpeningScreen extends StatelessWidget {
  const TrainingOpeningScreen({
    required this.repository,
    required this.config,
    required this.now,
    required this.lessonId,
    required this.teacher,
    required this.onNextGoal,
    this.heroTag,
    this.preview,
    this.partId,
    this.onProgress,
    super.key,
  });
  final TrainingRepository repository;
  final TrainingCourseConfig config;
  final Now now;
  final String lessonId;
  final Character teacher;
  final VoidCallback onNextGoal;
  final Object? heroTag;
  final TrainingOpeningState? preview;
  final String? partId;
  final VoidCallback? onProgress;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => TrainingOpeningCubit(
      repository: repository,
      config: config,
      now: now,
      analytics: context.analytics,
      trainingAnalytics: context.trainingAnalytics,
    )..load(lessonId: lessonId, partId: partId),
    child: _OpeningView(screen: this),
  );
}

class _OpeningView extends StatefulWidget {
  const _OpeningView({required this.screen});
  final TrainingOpeningScreen screen;
  @override
  State<_OpeningView> createState() => _OpeningViewState();
}

class _OpeningViewState extends State<_OpeningView> {
  ChessboardController? _controller;
  String? _boardLine;
  Timer? _replay;
  String? _replayFen;
  int? _lastCursor;

  /// H-ANI-11/12: o último lance do aluno, a tentativa (key nova do retorno)
  /// e se a peça do lance errado já voltou à origem.
  NormalMove? _played;
  int _attempt = 0;
  bool _returned = false;
  final _boardKey = GlobalKey();
  String? _heroId;
  @override
  void dispose() {
    _replay?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      BlocConsumer<TrainingOpeningCubit, TrainingOpeningState>(
        listener: (context, state) {
          if (state.error) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(context.l10n.trainingExerciseSaveError)),
            );
          }
        },
        builder: (context, state) {
          final loading = state.phase == TrainingOpeningPhase.loading;
          if (loading && widget.screen.preview != null) {
            state = widget.screen.preview!;
          }
          final l = context.l10n;
          final cubit = context.read<TrainingOpeningCubit>();
          final ready =
              state.line != null && state.phase != TrainingOpeningPhase.expired;
          final bank = state.resources?.openings[state.lessonId] ?? [];
          final multipart = state.trecho?.lines.isNotEmpty == true;
          final number = bank.indexWhere((t) => t.id == state.trecho?.id) + 1;
          final notation = multipart
              ? state.line!.notationIndices(
                  state.reviewing ? state.shown : state.cursor,
                )
              : [for (var i = 0; i < state.cursor; i++) i];
          final speechText = _openingSpeech(l, state, number, bank.length);
          final lesson = state.resources?.lessons
              .where((l) => l.id == state.lessonId)
              .firstOrNull;
          if (state.phase == TrainingOpeningPhase.unavailable) {
            return trainingLoadError(
              context,
              state.failure,
              () => cubit.load(
                lessonId: widget.screen.lessonId,
                partId: widget.screen.partId,
              ),
            );
          }
          if (state.phase == TrainingOpeningPhase.expired ||
              (state.phase != TrainingOpeningPhase.loading && !ready)) {
            // Trecho que saiu do dia ou nunca carregou: erro padrão, com ação.
            return trainingLoadError(
              context,
              LoadFailure.unavailable,
              () => cubit.load(
                lessonId: widget.screen.lessonId,
                partId: widget.screen.partId,
              ),
            );
          }
          final footer = _OpeningFooter(
            state: state,
            loading: loading,
            onProgress: widget.screen.onProgress,
            onNextGoal: widget.screen.onNextGoal,
          );
          return Scaffold(
            key: TrainingKeys.openingScreen,
            appBar: LucenaAppBar(
              centerTitle: true,
              leading: const _OpeningBack(),
              title: _OpeningTitle(
                state: state,
                ready: ready,
                lessonTitle: lesson?.title,
                number: number,
                total: bank.length,
              ),
            ),
            body: BoardViewport(
              usefulHeight: BoardViewport.usefulHeightOf(context),
              bottomBar: ready ? TrainingCanvasFooter.height : 0,
              child: Stack(
                children: [
                  SafeArea(
                    child: !ready
                        ? const SkeletonList()
                        : _OpeningPage(
                            ignoring: loading || _replayFen != null,
                            teacher: widget.screen.teacher,
                            text: speechText,
                            state: state,
                            moves: notation,
                            onOpen: () => _fullSpeech(context, speechText),
                            boardBuilder: (size) => Builder(
                              builder: (context) =>
                                  _board(context, state, size),
                            ),
                          ),
                  ),
                  // H-15: a abertura inteira concluída comemora com a
                  // Celebração pequena, por cima da tela parada.
                  if (ready &&
                      state.phase == TrainingOpeningPhase.complete &&
                      state.allPartsDone)
                    const Positioned.fill(child: _OpeningCelebration()),
                ],
              ),
            ),
            // H-ANI-25: no fim, o tabuleiro e a fala ficam e os botões do fim
            // entram por último.
            bottomNavigationBar: !ready
                ? null
                : state.phase == TrainingOpeningPhase.complete
                ? EntradaDeResultado(
                    id: 'abertura-${state.lessonId}-${state.trecho!.id}',
                    botoes: footer,
                  )
                : footer,
          );
        },
      );

  void _fullSpeech(BuildContext context, String text) {
    showScriptSpeechSheet(
      context,
      canvasLayout: true,
      action: LessonVoiceButton(
        audible: false,
        speed: 1,
        showSpeedBadge: false,
        canvasLayout: true,
        onPressed: () => showLessonSoundDialog(context),
      ),
      viktor: widget.screen.teacher,
      title: context.l10n.teacherName(widget.screen.teacher.name),
      texts: [text],
    );
  }

  Widget _board(BuildContext context, TrainingOpeningState state, double size) {
    final cubit = context.read<TrainingOpeningCubit>();
    final lineId = '${state.lessonId}:${state.trecho!.id}';
    final changedLine = _boardLine != lineId;
    final animation = AppMotion.of(context).component;
    if (changedLine) {
      _replay?.cancel();
      _replayFen = null;
      _played = null;
    } else if (_lastCursor != state.cursor &&
        !state.reviewing &&
        state.transitionFens.length > 1 &&
        animation > Duration.zero) {
      _replay?.cancel();
      final frames = state.transitionFens;
      var frame = 0;
      _replayFen = frames.first;
      _replay = Timer.periodic(animation, (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }
        setState(() {
          frame++;
          if (frame >= frames.length) {
            timer.cancel();
            _replayFen = null;
          } else {
            _replayFen = frames[frame];
          }
        });
      });
    }
    _lastCursor = state.cursor;
    final played = _played;
    // O lance errado fica na casa até o retorno devolver a peça.
    final wrongShown =
        state.wrong && played != null && !_returned && _replayFen == null;
    final baseFen = _replayFen ?? state.fen!;
    final fen = wrongShown
        ? GameRules.fromFen(baseFen)!.play(played).fen
        : baseFen;
    final position = GameRules.fromFen(fen)!;
    final playing =
        state.phase == TrainingOpeningPhase.playing &&
        !state.reviewing &&
        _replayFen == null &&
        !wrongShown;
    final data = GameData(
      fen: fen,
      playerSide: playing
          ? (position.turn == Side.black ? PlayerSide.black : PlayerSide.white)
          : PlayerSide.none,
      sideToMove: position.turn,
      validMoves: playing ? GameRules.legalMoves(position) : const {},
      lastMove: wrongShown
          ? played
          : state.shown == 0
          ? null
          : state.line!.moveAt(state.shown - 1) == null
          ? null
          : Move.parse(state.line!.moveAt(state.shown - 1)!),
      kingSquareInCheck: GameRules.checkedKing(position),
    );
    if (_controller == null) {
      _controller = ChessboardController(game: data);
    } else {
      _controller!.updatePosition(
        data,
        animate: (!state.wrong || _returned) && !changedLine,
        resetPremove: true,
      );
    }
    _boardLine = lineId;
    final settings = context.select(
      (SettingsCubit c) => c.state?.board ?? const BoardSettings(),
    );
    final hint = playing && state.hint
        ? Move.parse(state.line!.acceptedAt(state.cursor).first)
        : null;
    Widget board = Directionality(
      textDirection: TextDirection.ltr,
      // H-ANI-10: deslize do kit, captura que encolhe e halo do xeque.
      child: TabuleiroAnimado(
        controlador: _controller!,
        orientacao: state.trecho!.black ? Side.black : Side.white,
        tamanho: size,
        pecas: settings.chessground.pieceAssets,
        child: Chessboard(
          key: TrainingKeys.openingBoard,
          size: size,
          controller: _controller!,
          orientation: state.trecho!.black ? Side.black : Side.white,
          settings: TabuleiroAnimado.ajustes(context, settings.chessground),
          shapes: {
            if (hint is NormalMove)
              Arrow(
                color: Theme.of(context).colorScheme.primary,
                orig: hint.from,
                dest: hint.to,
              ),
          },
          onMove: (move, {viaDragAndDrop}) {
            setState(() {
              _played = move is NormalMove ? move : null;
              _attempt++;
              _returned = false;
            });
            cubit.play(move.uci);
          },
        ),
      ),
    );
    board = KeyedSubtree(key: _boardKey, child: board);
    final side = state.trecho!.black ? Side.black : Side.white;
    final retorno = played == null || state.reviewing
        ? null
        : wrongShown
        ? TipoDeRetorno.erro
        : !state.wrong &&
              state.firstTry.isNotEmpty &&
              position.board.pieceAt(played.to)?.color == side
        ? TipoDeRetorno.acerto
        : null;
    if (retorno != null) {
      board = RetornoDoLance(
        key: ValueKey('opening $_attempt'),
        tipo: retorno,
        casa: played!.to,
        orientacao: side,
        tamanho: size,
        vibrar: context.read<SettingsCubit>().state?.vibration ?? true,
        aoVoltar: retorno == TipoDeRetorno.erro
            ? () {
                if (mounted) setState(() => _returned = true);
              }
            : null,
        child: board,
      );
    }
    if (widget.screen.heroTag case final tag?) {
      board = Hero(tag: tag, child: board);
    } else {
      // H-ANI-02: o tabuleiro voa da tela de antes com o mesmo id (o FEN
      // com que a tela abre).
      board = TabuleiroHero(
        id: _heroId ??= state.line!.fens[state.shown],
        child: board,
      );
    }
    return board;
  }
}

/// A fala do professor conforme o momento do trecho.
String _openingSpeech(
  AppLocalizations l,
  TrainingOpeningState state,
  int number,
  int bankLength,
) {
  return state.phase == TrainingOpeningPhase.complete
      ? state.allPartsDone
            ? l.trainingOpeningFinished(state.trecho!.title, bankLength)
            : l.trainingOpeningPartComplete(number)
      : state.wrong
      ? l.trainingOpeningWrong
      : state.firstTry.isNotEmpty
      ? l.trainingFixedCorrect
      : l.trainingOpeningPrompt;
}

/// O rodapé do trecho: dica, navegação pelos lances e os botões do fim.
class _OpeningFooter extends StatelessWidget {
  const _OpeningFooter({
    required this.state,
    required this.loading,
    required this.onProgress,
    required this.onNextGoal,
  });

  final TrainingOpeningState state;
  final bool loading;
  final VoidCallback? onProgress;
  final VoidCallback onNextGoal;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final cubit = context.read<TrainingOpeningCubit>();
    return SafeArea(
      child: IgnorePointer(
        ignoring: loading,
        child: TrainingCanvasFooter(
          leading: state.phase == TrainingOpeningPhase.complete
              ? null
              : TrainingCanvasFooter.hint(
                  key: TrainingKeys.exerciseHint,
                  label: l.exerciseHintFree,
                  onPressed:
                      state.phase == TrainingOpeningPhase.playing &&
                          !state.reviewing
                      ? cubit.hint
                      : null,
                ),
          navigation: state.phase == TrainingOpeningPhase.complete
              ? []
              : [
                  TrainingCanvasFooter.round(
                    key: TrainingKeys.prevMove,
                    icon: CanvasSymbols.chevronLeft,
                    label: l.trainingPrevMove,
                    navigation: true,
                    onPressed: state.shown == 0
                        ? null
                        : () => cubit.review(state.shown - 1),
                  ),
                  TrainingCanvasFooter.round(
                    key: TrainingKeys.nextMove,
                    icon: CanvasSymbols.chevronRight,
                    label: l.trainingNextMove,
                    navigation: true,
                    onPressed: state.reviewing
                        ? () => cubit.review(state.shown + 1)
                        : null,
                  ),
                ],
          secondary: state.phase != TrainingOpeningPhase.complete
              ? null
              : TrainingCanvasFooter.button(
                  key: state.allPartsDone
                      ? TrainingKeys.openingProgress
                      : TrainingKeys.openingNextPart,
                  label: state.allPartsDone
                      ? l.trainingViewProgress
                      : l.trainingNextPart,
                  onPressed: state.allPartsDone ? onProgress : cubit.nextPart,
                ),
          primary: state.error
              ? TrainingCanvasFooter.button(
                  key: TrainingKeys.openingSaveRetry,
                  label: l.lessonRetry,
                  primary: true,
                  onPressed: cubit.retry,
                )
              : state.phase != TrainingOpeningPhase.complete
              ? null
              : TrainingCanvasFooter.button(
                  key: TrainingKeys.nextGoal,
                  label: l.trainingNextGoal,
                  primary: true,
                  onPressed: onNextGoal,
                ),
        ),
      ),
    );
  }
}

/// A lista de lances do trecho, tocável para revisar.
class _OpeningNotation extends StatelessWidget {
  const _OpeningNotation({required this.state, required this.moves});

  final TrainingOpeningState state;
  final List<int> moves;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<TrainingOpeningCubit>();
    return ScriptMoveList(
      moves: [
        for (final i in moves)
          if (state.line!.moveAt(i) != null)
            ScriptMoveEntry(
              id: '${i + 1}',
              san: state.line!.san[i],
              number: state.line!.moveNumberAt(i),
              side: state.line!.sideAt(i),
              variant: false,
            ),
      ],
      currentId: state.shown == 0 ? null : '${state.shown}',
      onTap: (id) => cubit.notationTap(int.parse(id)),
    );
  }
}

/// A página do trecho: fala do professor, tabuleiro e lista de lances.
class _OpeningPage extends StatelessWidget {
  const _OpeningPage({
    required this.ignoring,
    required this.teacher,
    required this.text,
    required this.state,
    required this.moves,
    required this.onOpen,
    required this.boardBuilder,
  });

  final bool ignoring;
  final Character teacher;
  final String text;
  final TrainingOpeningState state;
  final List<int> moves;
  final VoidCallback onOpen;
  final Widget Function(double size) boardBuilder;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: ignoring,
      child: TrainingCanvasPage(
        pageKey: TrainingKeys.openingPage,
        teacher: teacher,
        text: text,
        onOpen: onOpen,
        boardBuilder: boardBuilder,
        notation: _OpeningNotation(state: state, moves: moves),
      ),
    );
  }
}

/// O voltar do topo: fecha a tela.
class _OpeningBack extends StatelessWidget {
  const _OpeningBack();

  @override
  Widget build(BuildContext context) {
    return IconButton(
      key: TrainingKeys.openingBack,
      icon: const Icon(CanvasSymbols.arrowBack),
      tooltip: MaterialLocalizations.of(context).backButtonTooltip,
      onPressed: () => Navigator.of(context).maybePop(),
    );
  }
}

/// O título do topo: o trecho e a parte, ou "Aberturas" enquanto carrega.
class _OpeningTitle extends StatelessWidget {
  const _OpeningTitle({
    required this.state,
    required this.ready,
    required this.lessonTitle,
    required this.number,
    required this.total,
  });

  final TrainingOpeningState state;
  final bool ready;
  final String? lessonTitle;
  final int number;
  final int total;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Text(
      key: TrainingKeys.openingTitle(state.lessonId ?? ''),
      ready
          ? l.trainingOpeningTitle(
              state.trecho!.lines.isNotEmpty
                  ? state.trecho!.title
                  : lessonTitle ?? state.trecho!.title,
              number,
              total,
            )
          : l.trainingOpeningsTitle,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }
}

/// A celebração pequena do fim da abertura, por cima da tela parada.
class _OpeningCelebration extends StatelessWidget {
  const _OpeningCelebration();

  @override
  Widget build(BuildContext context) {
    return const IgnorePointer(
      child: Celebracao(
        tamanho: TamanhoDaCelebracao.pequena,
        escalar: false,
        child: SizedBox.expand(),
      ),
    );
  }
}

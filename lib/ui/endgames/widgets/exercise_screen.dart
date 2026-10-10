import 'dart:async';
import 'dart:math';

import 'package:chessground/chessground.dart';
import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/models/board_settings.dart';
import '../../../domain/models/endgame_lesson.dart';
import '../../../domain/use_cases/game_export.dart';
import '../../../domain/use_cases/game_rules.dart';
import '../../../routing/routes.dart';
import '../../core/board/board_settings_ui.dart';
import '../../core/board/exercise_layout.dart';
import '../../core/board/speech_flash.dart';
import '../../core/keys/endgames_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/widgets/external_page_sheet.dart';
import '../../core/widgets/one_line.dart';
import '../../core/widgets/position_board.dart';
import '../../core/widgets/step_timer.dart';
import '../../core/widgets/teacher_speech.dart';
import '../../settings/view_models/settings_cubit.dart';
import '../view_models/exercise_cubit.dart';
import 'endgame_ui.dart';
import 'stars_row.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_spacing.dart';

/// Um exercício: o Viktor dá o enunciado, o aluno acha os lances no
/// tabuleiro; no fim, a solução, as estrelas ganhas e o próximo exercício.
class ExerciseScreen extends StatefulWidget {
  const ExerciseScreen({
    this.lessonId,
    this.exerciseId,
    this.previewFen,
    super.key,
  });

  /// A aula e o exercício (da rota), para o voo da miniatura da lista até o
  /// tabuleiro: [previewFen] é a posição, mostrada parada enquanto o
  /// exercício carrega, porque o voo precisa do destino já no primeiro quadro.
  final String? lessonId;
  final String? exerciseId;
  final String? previewFen;

  @override
  State<ExerciseScreen> createState() => _ExerciseScreenState();
}

class _ExerciseScreenState extends State<ExerciseScreen>
    with TickerProviderStateMixin {
  ChessboardController? _board;

  late final _shake = AnimationController(
    vsync: this,
    duration: AppMotion.component,
  );

  /// O lance errado fica um instante no tabuleiro, em vermelho.
  // A casa ou o lance tocado na fala, por um instante no tabuleiro.
  final _flash = SpeechFlash();

  late final _wrongFlash = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );

  // O layout: 0 resolvendo (tabuleiro no centro), 1 resolvido (no alto,
  // com o resultado e a fala embaixo). Uma animação só leva de um ao outro.
  late final _mode = AnimationController(
    vsync: this,
    duration: AppMotion.component,
  );
  double? _target;

  // O cronômetro: anda enquanto o aluno resolve; resolvido, fica parado no
  // tempo final.
  final _elapsed = ValueNotifier(Duration.zero);
  Timer? _ticker;

  // A altura do enunciado: só cresce no exercício, para o tabuleiro não
  // pular quando a fala muda de tamanho.
  final _header = HeaderMemo();

  // A tela inteira e onde o corpo começa, para achar o centro da tela.
  Size _screen = Size.zero;
  double _bodyTop = 0;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(milliseconds: 250), (_) {
      if (!mounted) return;
      final cubit = context.read<ExerciseCubit>();
      if (cubit.state.layout == ExerciseLayoutMode.solving) {
        _elapsed.value = cubit.elapsed;
      }
    });
  }

  /// Leva o tabuleiro ao layout do estado: animado, ou direto na abertura e
  /// com "reduzir movimento".
  void _setMode(
    BuildContext context,
    ExerciseState state, {
    required bool animate,
  }) {
    final target = state.layout == ExerciseLayoutMode.solving ? 0.0 : 1.0;
    if (target == _target) return;
    _target = target;
    if (!animate || AppMotion.of(context).disabled) {
      _mode.value = target;
      return;
    }
    _mode.animateTo(
      target,
      duration: AppMotion.of(context).component,
      curve: AppMotion.enter,
    );
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _mode.dispose();
    _elapsed.dispose();
    _board?.dispose();
    _shake.dispose();
    _wrongFlash.dispose();
    _flash.dispose();
    super.dispose();
  }

  GameData _gameData(ExerciseState state) {
    final fen = state.fen!;
    final side = state.side;
    final position = GameRules.fromFen(fen);
    return GameData(
      fen: fen,
      playerSide: position == null || !state.interactive
          ? PlayerSide.none
          : (side == Side.white ? PlayerSide.white : PlayerSide.black),
      sideToMove: position?.turn ?? side,
      validMoves: position == null ? const {} : GameRules.legalMoves(position),
      lastMove: state.lastMove,
      kingSquareInCheck: position == null
          ? null
          : GameRules.checkedKing(position),
    );
  }

  ExerciseState _previous = const ExerciseState();

  void _onState(BuildContext context, ExerciseState state) {
    final previous = _previous;
    _previous = state;
    _setMode(context, state, animate: previous.ready);
    // Resolvendo: o cronômetro já com o tempo do exercício (ao reabrir o
    // app, o tabuleiro nasce aqui, antes do primeiro tique).
    if (state.layout == ExerciseLayoutMode.solving) {
      _elapsed.value = context.read<ExerciseCubit>().elapsed;
    }
    if (state.mistakes > previous.mistakes) {
      _shake.forward(from: 0);
      _wrongFlash.forward(from: 0);
    }
    if (state.fen == null) return;
    final board = _board;
    if (board == null) {
      _board = ChessboardController(game: _gameData(state));
      return;
    }
    board.updatePosition(
      _gameData(state),
      animate: previous.fen != state.fen,
      resetPremove: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<ExerciseCubit>();
    final boardSettings = context.select(
      (SettingsCubit cubit) => cubit.state?.board ?? const BoardSettings(),
    );
    _screen = MediaQuery.sizeOf(context);
    // O corpo começa logo abaixo da barra de cima.
    _bodyTop = MediaQuery.paddingOf(context).top + kToolbarHeight;
    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) cubit.leave();
      },
      child: BlocConsumer<ExerciseCubit, ExerciseState>(
        listener: _onState,
        builder: (context, state) {
          if (state.fen != null && _board == null) {
            _board = ChessboardController(game: _gameData(state));
            _setMode(context, state, animate: false);
            _elapsed.value = cubit.elapsed;
          }
          final lesson = state.lesson;
          return Scaffold(
            key: ExerciseKeys.screen,
            // Só o número: o título da aula, longo, ficou na tela dela.
            appBar: AppBar(
              title: lesson == null
                  ? null
                  : Text(
                      l10n.exerciseTitle(state.number, state.count),
                      key: ExerciseKeys.counter,
                    ),
              // O que o exercício vale agora: dourada (3), prata (2) ou
              // bronze (1); cada erro ou dica desce um degrau.
              actions: [
                if (state.exercise case final exercise?)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(end: 12),
                    child: Semantics(
                      // Resolvido: o que ganhou de quanto valia (a estrela
                      // grande some quando o Viktor explica).
                      label: state.phase == ExercisePhase.done
                          ? l10n.exerciseEarned(
                              state.earned ?? 0,
                              exercise.stars,
                            )
                          : l10n.exercisePoints(_worth(state, exercise)),
                      excludeSemantics: true,
                      child: ValueStar(
                        key: ExerciseKeys.stars,
                        points: _worth(state, exercise),
                      ),
                    ),
                  ),
              ],
            ),
            body: SafeArea(child: _body(context, state, boardSettings)),
          );
        },
      ),
    );
  }

  /// O que o exercício vale agora: as estrelas dele menos erros e dicas, ou
  /// o ganho, depois de resolvido.
  static int _worth(ExerciseState state, Exercise exercise) =>
      state.phase == ExercisePhase.done
      ? (state.earned ?? 0)
      : max(0, exercise.stars - state.mistakes - state.hints);

  /// O tabuleiro fica com chave: o voo da miniatura só continua se o widget
  /// for o mesmo entre o carregamento e o exercício aberto.
  static const _boardAreaKey = ValueKey('exercise.boardArea');

  Widget _body(
    BuildContext context,
    ExerciseState state,
    BoardSettings boardSettings,
  ) {
    final l10n = context.l10n;
    if (!state.ready) return _loading(context, state, boardSettings);
    final exercise = state.exercise;
    if (state.missing || exercise == null) {
      return Center(
        child: Text(l10n.exerciseMissing, key: ExerciseKeys.missing),
      );
    }
    return Column(
      children: [
        SizedBox.shrink(key: ExerciseKeys.open(state.lesson!.id, exercise.id)),
        Expanded(child: _area(context, state, boardSettings)),
        // Resolvendo: a dica e o cronômetro. Resolvido: o próximo passo.
        AnimatedSwitcher(
          duration: AppMotion.of(context).component,
          child: KeyedSubtree(
            key: ValueKey(state.phase == ExercisePhase.done),
            child: state.phase == ExercisePhase.done
                ? _actions(context, state)
                : _solvingFooter(context, state),
          ),
        ),
      ],
    );
  }

  /// O espaço do tabuleiro (T60). Resolvendo: o Viktor com o enunciado em
  /// cima e o tabuleiro no centro da tela. Resolvido: o tabuleiro sobe e
  /// entram embaixo as estrelas, a solução e a fala dele.
  Widget _area(
    BuildContext context,
    ExerciseState state,
    BoardSettings boardSettings,
  ) {
    final exercise = state.exercise;
    return LayoutBuilder(
      builder: (context, box) => AnimatedBuilder(
        animation: _mode,
        builder: (context, _) {
          final t = _mode.value;
          return CustomMultiChildLayout(
            delegate: _AreaDelegate(
              header: _header..stepKey = '${state.lesson?.id}.${exercise?.id}',
              centerY: _screen.height / 2 - _bodyTop,
              mode: _mode,
            ),
            children: [
              if (t < 1 && state.ready && exercise != null)
                LayoutId(
                  id: _Slot.prompt,
                  child: FadeTransition(
                    opacity: ReverseAnimation(_mode),
                    // Com rolagem, o enunciado mede só o que ocupa (e rola
                    // se for comprido demais).
                    child: SingleChildScrollView(
                      child: _prompt(context, state),
                    ),
                  ),
                ),
              LayoutId(
                id: _Slot.board,
                child: LayoutBuilder(
                  builder: (context, slot) => KeyedSubtree(
                    key: _boardAreaKey,
                    child: _boardArea(
                      context,
                      state,
                      boardSettings,
                      size: slot.maxWidth,
                    ),
                  ),
                ),
              ),
              // A vez, enquanto o aluno joga; some enquanto o outro lado
              // pensa e volta depois da resposta.
              if (t == 0 &&
                  state.ready &&
                  exercise != null &&
                  state.phase == ExercisePhase.active)
                LayoutId(
                  id: _Slot.turn,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      context.l10n.exerciseYourTurn(
                        state.side == Side.white ? 'white' : 'black',
                      ),
                      key: ExerciseKeys.goal,
                      style: Theme.of(context).textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              if (t > 0 && state.ready && exercise != null)
                LayoutId(
                  id: _Slot.below,
                  child: FadeTransition(
                    opacity: _mode,
                    child: _result(context, state, boardSettings),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  /// Em cima, enquanto o aluno resolve: o Viktor pequeno e o balão ao lado,
  /// só quando ele fala (erro, dica). De quem é a vez fica embaixo, junto da
  /// dica e do cronômetro.
  Widget _prompt(BuildContext context, ExerciseState state) {
    final viktor = state.viktor;
    if (viktor == null || state.speech == null) return const SizedBox.shrink();
    final speech = state.speech;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: TeacherSpeech(
        speechContext: SpeechContext.game,
        teacher: viktor,
        text: speech,
        emotion: state.emotion,
        avatarSize: 40,
        bubbleKey: ExerciseKeys.speech,
        onLink: (link) => _flash.toggle(
          link,
          fen: state.fen,
          color: Theme.of(context).colorScheme.primary,
        ),
        onSpoken: (link) => _flash.show(
          link,
          fen: state.fen,
          color: Theme.of(context).colorScheme.primary,
        ),
        speaks: true,
      ),
    );
  }

  /// Resolvido: as estrelas, a solução e a fala do Viktor (correção ou
  /// explicação), rolando sob o tabuleiro.
  Widget _result(
    BuildContext context,
    ExerciseState state,
    BoardSettings boardSettings,
  ) {
    final viktor = state.viktor;
    return SingleChildScrollView(
      key: ExerciseKeys.scroll,
      child: Column(
        children: [
          _belowBoard(context, state, boardSettings),
          if (viktor != null && state.speech != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: TeacherSpeech(
                speechContext: SpeechContext.teaching,
                teacher: viktor,
                text: state.speech,
                emotion: state.emotion,
                avatarSize: 56,
                bubbleKey: ExerciseKeys.speech,
                onLink: (link) => _flash.toggle(
                  link,
                  fen: state.fen,
                  color: Theme.of(context).colorScheme.primary,
                ),
                onSpoken: (link) => _flash.show(
                  link,
                  fen: state.fen,
                  color: Theme.of(context).colorScheme.primary,
                ),
                speaks: true,
              ),
            ),
        ],
      ),
    );
  }

  /// Enquanto o exercício carrega: o tabuleiro parado no centro (se a rota
  /// trouxe a posição), para a miniatura pousar nele.
  Widget _loading(
    BuildContext context,
    ExerciseState state,
    BoardSettings boardSettings,
  ) {
    if (widget.previewFen == null) return const SizedBox.shrink();
    return Column(
      children: [
        Expanded(child: _area(context, state, boardSettings)),
        const SizedBox(height: 64),
      ],
    );
  }

  /// Resolvendo: a dica (com o que ela custa) à esquerda e o cronômetro à
  /// direita (os lados trocam em árabe).
  Widget _solvingFooter(BuildContext context, ExerciseState state) {
    final l10n = context.l10n;
    final cubit = context.read<ExerciseCubit>();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // As ações tomam o espaço que sobra, alinhadas ao início; o texto
              // fica numa linha só e encolhe se faltar largura.
              Expanded(
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (state.interactive)
                        Flexible(
                          child: OutlinedButton.icon(
                            key: ExerciseKeys.hintButton,
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(0, 48),
                            ),
                            onPressed: cubit.askHint,
                            icon: const Icon(Icons.lightbulb_outline),
                            // O texto diz o que a dica custa agora: um ponto, o
                            // último (o exercício deixa de pontuar) ou nada.
                            label: OneLine(switch (_worth(
                              state,
                              state.exercise!,
                            )) {
                              0 => l10n.exerciseHintFree,
                              1 => l10n.exerciseHintLast,
                              _ => l10n.exerciseHint,
                            }),
                          ),
                        ),
                      // Com a nota fechada, a posição vai para a análise do
                      // Lichess.
                      if (state.locked && state.interactive) ...[
                        const SizedBox(width: 8),
                        Flexible(child: _lichessButton(context, state)),
                      ],
                      if (state.phase == ExercisePhase.waiting)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            const SizedBox(width: 10),
                            Text(l10n.lessonThinking),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              StepTimer(key: ExerciseKeys.timer, elapsed: _elapsed),
            ],
          ),
        ],
      ),
    );
  }

  Widget _boardArea(
    BuildContext context,
    ExerciseState state,
    BoardSettings boardSettings, {
    required double size,
  }) {
    final board = _board;
    final previewFen = widget.previewFen;
    if (board == null && previewFen == null) return const SizedBox.shrink();
    final lessonId = state.lesson?.id ?? widget.lessonId ?? '';
    final exerciseId = state.exercise?.id ?? widget.exerciseId ?? '';
    final hint = state.hint;
    final wrong = state.wrongMove;
    return AnimatedBuilder(
      animation: Listenable.merge([_shake, _wrongFlash]),
      builder: (context, child) => Transform.translate(
        offset: Offset(sin(_shake.value * pi * 4) * 8 * (1 - _shake.value), 0),
        child: child,
      ),
      // A miniatura da lista voa até aqui e vira o tabuleiro.
      child: Hero(
        tag: exerciseHeroTag(lessonId, exerciseId),
        child: board == null
            ? PositionBoard(
                fen: previewFen!,
                size: size,
                radius: 0,
                coordinates: true,
              )
            : Directionality(
                textDirection: TextDirection.ltr,
                child: AnimatedBuilder(
                  animation: Listenable.merge([_wrongFlash, _flash]),
                  builder: (context, _) => Chessboard(
                    key: ExerciseKeys.board,
                    size: size,
                    controller: board,
                    settings: boardSettings.chessground,
                    orientation: state.side,
                    shapes: {
                      if (hint is NormalMove)
                        Arrow(
                          color: const Color(0xcc15781b),
                          orig: hint.from,
                          dest: hint.to,
                        ),
                      if (wrong is NormalMove && _wrongFlash.isAnimating)
                        Arrow(
                          color: const Color(0xccc62828),
                          orig: wrong.from,
                          dest: wrong.to,
                        ),
                      ..._flash.shapesFor(state.fen),
                    },
                    onMove: (move, {viaDragAndDrop}) =>
                        context.read<ExerciseCubit>().play(move),
                  ),
                ),
              ),
      ),
    );
  }

  /// Depois de resolver: as estrelas ganhas em tamanho grande e a linha da
  /// solução.
  Widget _belowBoard(
    BuildContext context,
    ExerciseState state,
    BoardSettings boardSettings,
  ) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final exercise = state.exercise!;
    if (state.phase != ExercisePhase.done) return const SizedBox.shrink();
    final earned = state.earned ?? 0;
    // Sem linha de "Solução": com o Viktor explicando, a fala já diz; sem
    // fala, só a nota (a estrela).
    if (state.speech != null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Semantics(
            label: l10n.exerciseEarned(earned, exercise.stars),
            excludeSemantics: true,
            // A estrela entra girando e com rebote ao resolver.
            child: TweenAnimationBuilder<double>(
              key: ExerciseKeys.earnedStar,
              tween: Tween(begin: 0, end: 1),
              duration: AppMotion.of(context).celebrate,
              curve: AppMotion.pop,
              builder: (context, value, child) => Transform.rotate(
                angle: (1 - value) * pi,
                child: Transform.scale(scale: value, child: child),
              ),
              child: ValueStar(points: earned, size: 56),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.exerciseEarned(earned, exercise.stars),
            key: ExerciseKeys.earned,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  /// "Analisar no Lichess": a posição do exercício no tabuleiro de análise.
  Widget _lichessButton(BuildContext context, ExerciseState state) =>
      TextButton.icon(
        key: ExerciseKeys.lichessButton,
        // Dentro do app, na folha da página: a aula fica atrás.
        onPressed: () =>
            showExternalPage(context, GameExport.lichess(state.exercise!.fen)),
        icon: const Icon(Icons.open_in_new_rounded),
        label: Text(context.l10n.exerciseLichess),
      );

  Widget _actions(BuildContext context, ExerciseState state) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final cubit = context.read<ExerciseCubit>();
    final lesson = state.lesson!;
    if (state.phase == ExercisePhase.done) {
      final next = state.nextExercise;
      // Com fundo: o Patrol confere o painel pelo toque no centro dele.
      return Container(
        key: ExerciseKeys.solved,
        color: Colors.transparent,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Nota fechada: este é treino livre.
            if (state.locked)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  l10n.exerciseScoreLocked,
                  key: ExerciseKeys.locked,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            // Uma linha só: "Ver explicação" fixo à esquerda (a pedido, sem
            // empurrar o tabuleiro) e o próximo passo à direita. Sem
            // "Resolvido!": a estrela da barra já diz.
            Row(
              children: [
                if (state.canExplain)
                  Flexible(
                    child: TextButton.icon(
                      key: ExerciseKeys.explainButton,
                      onPressed: cubit.showExplanation,
                      icon: const Icon(Icons.forum_outlined),
                      label: OneLine(l10n.lessonSeeExplanation),
                    ),
                  ),
                if (state.locked)
                  Flexible(child: _lichessButton(context, state)),
                const Spacer(),
                if (next != null)
                  FilledButton(
                    key: ExerciseKeys.nextButton,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(140, 48),
                    ),
                    onPressed: () => context.pushReplacement(
                      Routes.endgameExercise(lesson.id, next),
                    ),
                    child: Text(l10n.exerciseNext),
                  )
                else if (state.locked)
                  // Treino avulso: a nota já está fechada, volta à aula.
                  FilledButton(
                    key: ExerciseKeys.backButton,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(140, 48),
                    ),
                    onPressed: () => context.pop(),
                    child: Text(l10n.exerciseBack),
                  )
                else
                  FilledButton(
                    // O último da série: a tela de resultado, que volta à
                    // aula.
                    key: ExerciseKeys.resultButton,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(140, 48),
                    ),
                    onPressed: () => context.pushReplacement(
                      Routes.endgameExercisesDone(lesson.id),
                    ),
                    child: Text(l10n.exerciseSeeResult),
                  ),
              ],
            ),
          ],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Row(
        children: [
          if (state.interactive)
            OutlinedButton.icon(
              key: ExerciseKeys.hintButton,
              onPressed: cubit.askHint,
              icon: const Icon(Icons.lightbulb_outline),
              // O texto diz o que a dica custa agora: um ponto, o último
              // (o exercício deixa de pontuar) ou nada.
              label: Text(switch (_worth(state, state.exercise!)) {
                0 => l10n.exerciseHintFree,
                1 => l10n.exerciseHintLast,
                _ => l10n.exerciseHint,
              }),
            ),
          // Com a nota fechada, a posição vai para a análise do Lichess.
          if (state.locked && state.interactive) ...[
            const SizedBox(width: 8),
            _lichessButton(context, state),
          ],
          if (state.phase == ExercisePhase.waiting)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 10),
                Text(l10n.lessonThinking),
              ],
            ),
        ],
      ),
    );
  }
}

/// As partes do espaço do tabuleiro do exercício.
enum _Slot { prompt, board, turn, below }

/// Posiciona o enunciado, o tabuleiro e o resultado pelo andamento de
/// [mode] (0 resolvendo, 1 resolvido).
class _AreaDelegate extends MultiChildLayoutDelegate {
  _AreaDelegate({
    required this.header,
    required this.centerY,
    required this.mode,
  }) : super(relayout: mode);

  final HeaderMemo header;
  final double centerY;
  final Animation<double> mode;

  @override
  void performLayout(Size size) {
    final t = mode.value;
    final hasPrompt = hasChild(_Slot.prompt);
    var top = header.held;
    var measured = false;
    if (hasPrompt && top == null) {
      // Passo novo: o enunciado medido (comprido demais, rola).
      top = layoutChild(
        _Slot.prompt,
        BoxConstraints(maxWidth: size.width, maxHeight: size.height * 0.4),
      ).height;
      header.hold(top);
      measured = true;
    }
    final solving = ExerciseLayout.solvingRect(
      size,
      header: top ?? 0,
      centerY: centerY,
    );
    if (hasPrompt && !measured) {
      // Enunciado já medido: cresce até o topo do tabuleiro, que não sai do
      // lugar (fala maior rola).
      layoutChild(
        _Slot.prompt,
        BoxConstraints(
          maxWidth: size.width,
          maxHeight: max(top!, solving.top - ExerciseLayout.gutter),
        ),
      );
    }
    if (hasPrompt) positionChild(_Slot.prompt, Offset(0, -t * 24));
    final explaining = ExerciseLayout.explainingRect(
      size,
      sheetRoom: size.height * 0.4,
    );
    final rect = Rect.lerp(solving, explaining, t)!;
    layoutChild(_Slot.board, BoxConstraints.tight(rect.size));
    positionChild(_Slot.board, rect.topLeft);
    if (hasChild(_Slot.turn)) {
      // De quem é a vez, logo abaixo do tabuleiro.
      layoutChild(_Slot.turn, BoxConstraints.loose(Size(size.width, 80)));
      positionChild(_Slot.turn, Offset(0, rect.bottom + ExerciseLayout.gutter));
    }
    if (hasChild(_Slot.below)) {
      final below = explaining.bottom + ExerciseLayout.gutter;
      layoutChild(
        _Slot.below,
        BoxConstraints.tight(Size(size.width, max(0, size.height - below))),
      );
      positionChild(_Slot.below, Offset(0, below + (1 - t) * 48));
    }
  }

  @override
  bool shouldRelayout(_AreaDelegate old) =>
      old.header != header || old.centerY != centerY || old.mode != mode;
}

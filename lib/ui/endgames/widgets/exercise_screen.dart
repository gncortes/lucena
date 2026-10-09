import 'dart:math';

import 'package:chessground/chessground.dart';
import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../domain/models/board_settings.dart';
import '../../../domain/models/endgame_lesson.dart';
import '../../../domain/use_cases/endgame_lesson_rules.dart';
import '../../../domain/use_cases/game_export.dart';
import '../../../domain/use_cases/game_rules.dart';
import '../../../routing/routes.dart';
import '../../core/board/board_settings_ui.dart';
import '../../core/board/speech_flash.dart';
import '../../core/keys/endgames_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/widgets/figurine.dart';
import '../../core/widgets/position_board.dart';
import '../../core/widgets/teacher_speech.dart';
import '../../settings/view_models/settings_cubit.dart';
import '../view_models/exercise_cubit.dart';
import 'endgame_ui.dart';
import 'stars_row.dart';
import '../../core/theme/app_motion.dart';

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

  @override
  void dispose() {
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
    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) cubit.leave();
      },
      child: BlocConsumer<ExerciseCubit, ExerciseState>(
        listener: _onState,
        builder: (context, state) {
          if (state.fen != null && _board == null) {
            _board = ChessboardController(game: _gameData(state));
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
                      label: l10n.exercisePoints(_worth(state, exercise)),
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

  /// O tabuleiro fica com chave: a coluna troca de filhos quando o exercício
  /// carrega, e o voo da miniatura só continua se o widget for o mesmo.
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
    final viktor = state.viktor;
    return _layout(
      context,
      state,
      boardSettings,
      top: [
        SizedBox.shrink(key: ExerciseKeys.open(state.lesson!.id, exercise.id)),
      ],
      // O Viktor só entra quando tem o que dizer (erro, dica, explicação),
      // abaixo do tabuleiro, como na lição.
      below: viktor == null
          ? null
          : AnimatedSize(
              duration: AppMotion.of(context).component,
              curve: AppMotion.enter,
              alignment: Alignment.topCenter,
              child: state.speech == null
                  ? const SizedBox(width: double.infinity)
                  : Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
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
            ),
      bottom: _actions(context, state),
    );
  }

  /// A tela toda rola: o alto ([top]), o tabuleiro e o que vem sob ele; os
  /// botões ([bottom]) ficam fixos embaixo. O tabuleiro tem a largura da tela,
  /// com um teto de altura, como na lição.
  Widget _layout(
    BuildContext context,
    ExerciseState state,
    BoardSettings boardSettings, {
    required List<Widget> top,
    Widget? below,
    required Widget bottom,
  }) => Column(
    children: [
      Expanded(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            key: ExerciseKeys.scroll,
            child: Column(
              children: [
                ...top,
                KeyedSubtree(
                  key: _boardAreaKey,
                  child: _boardArea(
                    context,
                    state,
                    boardSettings,
                    size: max(
                      min(
                        constraints.maxWidth - 16,
                        constraints.maxHeight * 0.6,
                      ),
                      120.0,
                    ),
                  ),
                ),
                ?below,
              ],
            ),
          ),
        ),
      ),
      bottom,
    ],
  );

  /// Enquanto o exercício carrega: o mesmo desenho, com a posição parada no
  /// lugar do tabuleiro (se a rota a trouxe), para a miniatura pousar nela.
  Widget _loading(
    BuildContext context,
    ExerciseState state,
    BoardSettings boardSettings,
  ) {
    if (widget.previewFen == null) return const SizedBox.shrink();
    return _layout(
      context,
      state,
      boardSettings,
      top: const [SizedBox(height: 8)],
      bottom: const SizedBox(height: 64),
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
    return Builder(
      builder: (context) {
        final hint = state.hint;
        final wrong = state.wrongMove;
        return Column(
          children: [
            AnimatedBuilder(
              animation: Listenable.merge([_shake, _wrongFlash]),
              builder: (context, child) => Transform.translate(
                offset: Offset(
                  sin(_shake.value * pi * 4) * 8 * (1 - _shake.value),
                  0,
                ),
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
                              if (wrong is NormalMove &&
                                  _wrongFlash.isAnimating)
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
            ),
            // Sob o tabuleiro: o objetivo (antes) ou as estrelas e a solução
            // (depois).
            if (state.ready && state.exercise != null)
              ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 96),
                child: _belowBoard(context, state, boardSettings),
              ),
          ],
        );
      },
    );
  }

  /// Antes de resolver: de quem é a vez e o objetivo. Depois: as estrelas
  /// ganhas em tamanho grande e a linha da solução.
  Widget _belowBoard(
    BuildContext context,
    ExerciseState state,
    BoardSettings boardSettings,
  ) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final exercise = state.exercise!;
    if (state.phase != ExercisePhase.done) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              state.interactive ? l10n.exerciseYourMove : l10n.lessonThinking,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            // Só de quem é a vez: se ganha ou empata, o aluno descobre.
            Text(
              l10n.exerciseTurn(state.side == Side.white ? 'white' : 'black'),
              key: ExerciseKeys.goal,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }
    final earned = state.earned ?? 0;
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
          const SizedBox(height: 4),
          _SolutionLine(
            moves: EndgameLessonRules.solution(exercise),
            fen: exercise.fen,
            pieceLetters: boardSettings.notation.pieceLetters(l10n),
          ),
        ],
      ),
    );
  }

  /// "Analisar no Lichess": a posição do exercício no tabuleiro de análise.
  Widget _lichessButton(BuildContext context, ExerciseState state) =>
      TextButton.icon(
        key: ExerciseKeys.lichessButton,
        onPressed: () => launchUrl(
          GameExport.lichess(state.exercise!.fen),
          mode: LaunchMode.externalApplication,
        ),
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
            // A explicação detalhada só a pedido: sem ela, o elogio curto
            // não empurra o tabuleiro. Com a nota fechada, também a análise
            // no Lichess.
            if (state.canExplain || state.locked)
              Wrap(
                spacing: 8,
                children: [
                  if (state.canExplain)
                    TextButton.icon(
                      key: ExerciseKeys.explainButton,
                      onPressed: cubit.showExplanation,
                      icon: const Icon(Icons.forum_outlined),
                      label: Text(l10n.lessonSeeExplanation),
                    ),
                  if (state.locked) _lichessButton(context, state),
                ],
              ),
            Row(
              children: [
                // "Resolvido!" só no acerto limpo: com erro ou dica, a correção
                // do Viktor já diz o que houve.
                Expanded(
                  child: state.earned == state.exercise?.stars
                      ? Text(
                          l10n.exerciseSolved,
                          key: ExerciseKeys.solvedLabel,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
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

/// A linha da solução ("1.Kd4 Kg5 2.Nf4"), com figurinos ou as letras do
/// idioma, conforme a notação escolhida.
class _SolutionLine extends StatelessWidget {
  const _SolutionLine({
    required this.moves,
    required this.fen,
    required this.pieceLetters,
  });

  final List<String> moves;
  final String fen;
  final Map<String, String>? pieceLetters;

  @override
  Widget build(BuildContext context) {
    if (moves.isEmpty) return const SizedBox.shrink();
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final parts = fen.split(' ');
    final blackFirst = parts.length > 1 && parts[1] == 'b';
    var number = parts.length > 5 ? int.tryParse(parts[5]) ?? 1 : 1;
    final style = theme.textTheme.titleSmall?.copyWith(
      fontWeight: FontWeight.w600,
    );
    final figurineStyle = TextStyle(
      fontFamily: Figurine.fontFamily,
      fontWeight: FontWeight.w400,
      fontSize: (style?.fontSize ?? 14) * 1.15,
    );
    final spans = <InlineSpan>[];
    final spoken = StringBuffer();
    var whiteToMove = !blackFirst;
    for (final (index, san) in moves.indexed) {
      if (index > 0) {
        spans.add(const TextSpan(text: '  '));
        spoken.write(' ');
      }
      if (whiteToMove) {
        spans.add(TextSpan(text: '$number.'));
        spoken.write('$number.');
      } else if (index == 0) {
        spans.add(TextSpan(text: '$number...'));
        spoken.write('$number...');
      }
      for (final char in san.split('')) {
        final letter = pieceLetters?[char];
        if (letter != null) {
          spans.add(TextSpan(text: letter));
          spoken.write(letter);
        } else if (Figurine.ofLetter[char] case final figurine?
            when pieceLetters == null) {
          spans.add(TextSpan(text: figurine, style: figurineStyle));
          spoken.write(char);
        } else {
          spans.add(TextSpan(text: char));
          spoken.write(char);
        }
      }
      if (!whiteToMove) number++;
      whiteToMove = !whiteToMove;
    }
    return Semantics(
      label: '${l10n.exerciseSolution}: $spoken',
      excludeSemantics: true,
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '${l10n.exerciseSolution}: ',
              style: style?.copyWith(
                fontWeight: FontWeight.w400,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            ...spans,
          ],
        ),
        key: ExerciseKeys.solution,
        style: style,
        textAlign: TextAlign.center,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

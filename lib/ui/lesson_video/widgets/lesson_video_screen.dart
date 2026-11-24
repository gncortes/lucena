import 'dart:math';

import 'package:chessground/chessground.dart';
import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/models/glossary_term.dart';
import '../../glossary/widgets/glossary_text.dart';
import '../../../domain/models/board_settings.dart';
import '../../../domain/models/character.dart';
import '../../../domain/use_cases/game_rules.dart';
import '../../../domain/use_cases/video_timeline.dart';
import '../../../domain/use_cases/video_turn.dart';
import '../../core/board/board_settings_ui.dart';
import '../../core/keys/lesson_script_keys.dart';
import '../../core/keys/lesson_video_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/character_avatar.dart';
import '../../core/widgets/lucena_app_bar.dart';
import '../../lesson_script/widgets/script_board.dart';
import '../../settings/view_models/settings_cubit.dart';
import '../view_models/lesson_video_cubit.dart';
import '../view_models/lesson_video_turn_view.dart';

/// Medidas da tela do vídeo (contrato T-aula-video, 412×917).
abstract final class LessonVideoLayout {
  /// Bloco de cima, abaixo da app bar: 8 + balão 76 + 8 + faixa 44 + 8.
  static const balloonHeight = 76.0;
  static const stripHeight = 44.0;
  static const gap = 8.0;
  static const top = gap + balloonHeight + gap + stripHeight + gap;

  /// Bloco de baixo: barra 32 + tempo 16 + 8 + controles 72 + 40 de margem
  /// (o centro dos controles a ~76 da borda).
  static const barHeight = 32.0;
  static const timeHeight = 16.0;
  static const controlsHeight = 72.0;
  static const bottomMargin = 40.0;
  static const bottom =
      barHeight + timeHeight + gap + controlsHeight + bottomMargin;

  /// Lado do tabuleiro numa área de [area] (abaixo da app bar): a regra de
  /// `partida()`, centro exato com os dois blocos de fora.
  static double boardSide(Size area) =>
      max(0, min(area.width, area.height - 2 * max(top, bottom)));
}

/// A aula em vídeo (L1, atrás de flag): app bar com o livro do Glossário,
/// balão de 2 linhas, faixa do Viktor, tabuleiro no centro, barra, controles
/// e o rodapé do fim da etapa.
class LessonVideoScreen extends StatelessWidget {
  const LessonVideoScreen({
    required this.title,
    this.viktor,
    this.onGlossary,
    this.onNextStage,
    this.terms = const [],
    this.onTerm,
    super.key,
  });

  final String title;
  final Character? viktor;

  /// O livro do topo: quem abre pausa o vídeo e vai ao Glossário.
  final VoidCallback? onGlossary;

  /// Os termos do Glossário sublinhados na fala.
  final List<GlossaryTerm> terms;

  /// Tocar um termo sublinhado: quem abre pausa o vídeo e vai ao Glossário
  /// filtrado pelo termo (com a folha/Wikipédia); nulo = só sublinha.
  final ValueChanged<GlossaryTerm>? onTerm;

  /// "Próxima etapa" no fim; nulo esconde o botão.
  final VoidCallback? onNextStage;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      key: LessonVideoKeys.screen,
      appBar: LucenaAppBar(
        title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
        centerTitle: true,
        actions: [
          IconButton(
            key: LessonVideoKeys.glossaryButton,
            tooltip: l10n.glossaryOpen,
            icon: const Icon(Icons.menu_book),
            onPressed: onGlossary,
          ),
        ],
      ),
      body: BlocBuilder<LessonVideoCubit, LessonVideoState>(
        builder: (context, state) => switch (state.status) {
          LessonVideoStatus.loading => const Center(
            key: LessonVideoKeys.loading,
            child: CircularProgressIndicator(),
          ),
          LessonVideoStatus.failed => Center(
            key: LessonVideoKeys.unavailable,
            child: TextButton(
              onPressed: () => context.read<LessonVideoCubit>().start(),
              child: Text(l10n.lessonVideoPlay),
            ),
          ),
          LessonVideoStatus.ready => _Body(
            state: state,
            viktor: viktor,
            onNextStage: onNextStage,
            terms: terms,
            onTerm: onTerm,
          ),
        },
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({
    required this.state,
    this.viktor,
    this.onNextStage,
    this.terms = const [],
    this.onTerm,
  });

  final LessonVideoState state;
  final Character? viktor;
  final VoidCallback? onNextStage;
  final List<GlossaryTerm> terms;
  final ValueChanged<GlossaryTerm>? onTerm;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<LessonVideoCubit>();
    final marks = context.select(
      (SettingsCubit c) => c.state?.lessonMarks ?? true,
    );
    final board = context.select(
      (SettingsCubit c) => c.state?.board ?? const BoardSettings(),
    );
    final frame = state.frame;
    return LayoutBuilder(
      builder: (context, box) {
        final area = box.biggest;
        final side = LessonVideoLayout.boardSide(area);
        return Stack(
          children: [
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              height: LessonVideoLayout.top,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  12,
                  LessonVideoLayout.gap,
                  12,
                  LessonVideoLayout.gap,
                ),
                child: Column(
                  children: [
                    SizedBox(
                      height: LessonVideoLayout.balloonHeight,
                      child: _Balloon(
                        frame: frame,
                        visible: state.captions,
                        terms: terms,
                        onTerm: onTerm,
                      ),
                    ),
                    const SizedBox(height: LessonVideoLayout.gap),
                    SizedBox(
                      height: LessonVideoLayout.stripHeight,
                      child: _ViktorStrip(
                        viktor: viktor,
                        marks: marks,
                        onMarks: () => context
                            .read<SettingsCubit>()
                            .setLessonMarks(shown: !marks),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (frame != null)
              Positioned(
                left: (area.width - side) / 2,
                top: (area.height - side) / 2,
                width: side,
                height: side,
                child: _VideoBoard(
                  key: LessonVideoKeys.board,
                  frame: frame,
                  size: side,
                  settings: board,
                  shapes: marks,
                  flip: state.flip,
                  yourMove: state.waiting,
                  turn: state.turn,
                  onMove: cubit.onMove,
                ),
              ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: LessonVideoLayout.bottom,
              child: _Bottom(
                state: state,
                cubit: cubit,
                onNextStage: onNextStage,
              ),
            ),
          ],
        );
      },
    );
  }
}

/// O balão da legenda: a fala surge até a palavra dita, em 2 linhas.
class _Balloon extends StatelessWidget {
  const _Balloon({
    required this.frame,
    required this.visible,
    this.terms = const [],
    this.onTerm,
  });

  final VideoFrame? frame;
  final bool visible;
  final List<GlossaryTerm> terms;
  final ValueChanged<GlossaryTerm>? onTerm;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final frame = this.frame;
    final text = frame == null ? '' : _shown(frame);
    if (!visible) {
      // Legenda desligada: no lugar do balão, só o aviso (protótipo).
      return Align(
        alignment: AlignmentDirectional.topStart,
        child: SizedBox(
          key: LessonVideoKeys.captionsOff,
          height: 48,
          child: Padding(
            padding: const EdgeInsetsDirectional.only(start: 16),
            child: Row(
              children: [
                Icon(
                  Icons.closed_caption_disabled,
                  size: 20,
                  color: colors.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Text(
                  context.l10n.lessonVideoCaptionsOff,
                  style: TextStyle(
                    fontSize: 14,
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return AnimatedOpacity(
      opacity: visible ? 1 : 0,
      duration: const Duration(milliseconds: 150),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.outlineVariant),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Align(
            alignment: AlignmentDirectional.topStart,
            child: DefaultTextStyle.merge(
              overflow: TextOverflow.ellipsis,
              child: GlossaryText(
                text,
                key: LessonVideoKeys.caption,
                terms: terms,
                maxLines: 2,
                onOpen: onTerm,
                style: Theme.of(context).textTheme.bodyLarge
                    ?.copyWith(fontSize: 18, height: 26 / 18),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Até a palavra dita; falada inteira, a fala toda.
  static String _shown(VideoFrame frame) {
    final caption = frame.caption;
    if (frame.spoken || frame.words.isEmpty) return caption;
    final word = frame.word;
    if (word == null) return '';
    final end = frame.words[word.clamp(0, frame.words.length - 1)].end;
    return caption.substring(0, end.clamp(0, caption.length));
  }
}

class _ViktorStrip extends StatelessWidget {
  const _ViktorStrip({
    required this.viktor,
    required this.marks,
    required this.onMarks,
  });

  final Character? viktor;
  final bool marks;
  final VoidCallback onMarks;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final viktor = this.viktor;
    return Row(
      children: [
        if (viktor != null)
          CharacterAvatar(
            character: viktor,
            size: CharacterAvatar.lesson,
            radius: 6,
          ),
        if (viktor != null) const SizedBox(width: 8),
        Expanded(
          child: Text(
            l10n.teacherName(viktor?.name ?? 'Viktor'),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(color: colors.primary),
          ),
        ),
        IconButton(
          key: LessonScriptKeys.marksToggle,
          tooltip: marks ? l10n.lessonHideMarks : l10n.lessonShowMarks,
          style: IconButton.styleFrom(
            backgroundColor: marks ? null : colors.surfaceContainerHigh,
          ),
          icon: Icon(marks ? Icons.layers : Icons.layers_clear),
          onPressed: onMarks,
        ),
      ],
    );
  }
}

class _Bottom extends StatelessWidget {
  const _Bottom({required this.state, required this.cubit, this.onNextStage});

  final LessonVideoState state;
  final LessonVideoCubit cubit;
  final VoidCallback? onNextStage;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = Theme.of(context).colorScheme;
    final total = state.total.inMilliseconds;
    final value = total == 0
        ? 0.0
        : (state.position.inMilliseconds / total).clamp(0.0, 1.0);
    final position = _clock(state.position);
    final whole = _clock(state.total);
    final turn = state.turn;
    // Na sua vez: play e ±10 não valem. Tocando a fala do lance (ramo), só
    // o ±10 não vale (o play pausa e retoma a fala).
    final paused = state.waiting;
    final noSkip = paused || (turn?.inBranch ?? false);
    final reveal = state.waiting && turn != null && turn.canReveal;
    final column = Column(
      children: [
        SizedBox(
          height: LessonVideoLayout.barHeight,
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 4,
              activeTrackColor: colors.primary,
              inactiveTrackColor: colors.outlineVariant,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
            ),
            child: Slider(
              key: LessonVideoKeys.bar,
              value: value,
              semanticFormatterCallback: (_) =>
                  l10n.lessonVideoTimeSemantics(position, whole),
              onChanged: (v) =>
                  cubit.seek(Duration(milliseconds: (v * total).round())),
            ),
          ),
        ),
        SizedBox(
          height: LessonVideoLayout.timeHeight,
          child: Padding(
            padding: const EdgeInsetsDirectional.only(start: 24, end: 16),
            child: Row(
              children: [
                Text(
                  l10n.lessonVideoTime(position, whole),
                  key: LessonVideoKeys.time,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (state.notice) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text.rich(
                      key: LessonVideoKeys.notice,
                      TextSpan(
                        text: '${l10n.lessonVideoStoppedHere} ',
                        children: [
                          WidgetSpan(
                            alignment: PlaceholderAlignment.middle,
                            child: GestureDetector(
                              key: LessonVideoKeys.noticeAction,
                              onTap: cubit.restart,
                              child: Text(
                                l10n.lessonVideoRestart,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: colors.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ] else if (state.voice == VideoVoice.missing ||
                    state.voice == VideoVoice.failed) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: _VoiceNotice(state: state, cubit: cubit),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: LessonVideoLayout.gap),
        SizedBox(
          height: LessonVideoLayout.controlsHeight,
          child: state.ended
              ? _EndFooter(cubit: cubit, onNextStage: onNextStage)
              : _Controls(
                  state: state,
                  cubit: cubit,
                  dim: paused,
                  noSkip: noSkip,
                ),
        ),
        const SizedBox(height: LessonVideoLayout.bottomMargin),
      ],
    );
    if (!reveal) return column;
    return Stack(
      children: [
        column,
        PositionedDirectional(
          end: 16,
          top: _revealTop,
          height: _revealHeight,
          child: _RevealPill(onPressed: cubit.reveal),
        ),
      ],
    );
  }

  /// A pílula "Ver a resposta" (Vídeo 27): o desenho de 32 na linha do
  /// tempo, à direita (o tempo fica à esquerda), de logo abaixo do trilho
  /// até o topo dos controles. O alvo de 48 passa 8 acima e abaixo.
  static const _revealHeight = 48.0;
  static const _revealTop =
      LessonVideoLayout.barHeight + LessonVideoLayout.gap - _revealHeight / 2;

  static String _clock(Duration d) {
    final s = d.inSeconds;
    return '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';
  }
}

class _Controls extends StatelessWidget {
  const _Controls({
    required this.state,
    required this.cubit,
    required this.dim,
    required this.noSkip,
  });

  final LessonVideoState state;
  final LessonVideoCubit cubit;

  /// Na sua vez: play e ±10 esmaecidos.
  final bool dim;

  /// ±10 desligados (na vez e no ramo).
  final bool noSkip;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = Theme.of(context).colorScheme;
    final rate = state.rate == state.rate.roundToDouble()
        ? state.rate.toStringAsFixed(0)
        : state.rate.toString();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          SizedBox(
            width: 56,
            height: 48,
            child: TextButton(
              key: LessonVideoKeys.rate,
              onPressed: cubit.cycleRate,
              child: Text(
                l10n.lessonVideoRateValue(rate),
                semanticsLabel: l10n.lessonVideoRate,
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ),
          ),
          const Spacer(),
          Opacity(
            opacity: dim ? 0.38 : 1,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  key: LessonVideoKeys.back10,
                  tooltip: l10n.lessonVideoBack10,
                  iconSize: 32,
                  constraints: const BoxConstraints.tightFor(
                    width: 56,
                    height: 56,
                  ),
                  icon: const Icon(Icons.replay_10),
                  onPressed: noSkip
                      ? null
                      : () => cubit.skip(-LessonVideoCubit.skipStep),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  key: LessonVideoKeys.playPause,
                  tooltip: state.playing
                      ? l10n.lessonVideoPause
                      : l10n.lessonVideoPlay,
                  iconSize: 40,
                  style: IconButton.styleFrom(
                    backgroundColor: colors.primary,
                    fixedSize: const Size.square(72),
                  ),
                  icon: Icon(state.playing ? Icons.pause : Icons.play_arrow),
                  onPressed: dim ? null : cubit.toggle,
                ),
                const SizedBox(width: 8),
                IconButton(
                  key: LessonVideoKeys.forward10,
                  tooltip: l10n.lessonVideoForward10,
                  iconSize: 32,
                  constraints: const BoxConstraints.tightFor(
                    width: 56,
                    height: 56,
                  ),
                  icon: const Icon(Icons.forward_10),
                  onPressed: noSkip
                      ? null
                      : () => cubit.skip(LessonVideoCubit.skipStep),
                ),
              ],
            ),
          ),
          const Spacer(),
          SizedBox(
            width: 56,
            child: IconButton(
              key: LessonVideoKeys.captions,
              tooltip: state.captions
                  ? l10n.lessonVideoCaptionsHide
                  : l10n.lessonVideoCaptionsShow,
              iconSize: 24,
              icon: Icon(
                state.captions
                    ? Icons.closed_caption
                    : Icons.closed_caption_off,
              ),
              onPressed: cubit.toggleCaptions,
            ),
          ),
        ],
      ),
    );
  }
}

/// A pílula tonal "Ver a resposta" (protótipo `pilulaK`, a mesma da
/// retomada): 32 de altura, ícone `visibility` 18, alvo de 48.
class _RevealPill extends StatelessWidget {
  const _RevealPill({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Center(
      widthFactor: 1,
      child: FilledButton.tonalIcon(
        key: LessonVideoKeys.reveal,
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: colors.secondaryContainer,
          foregroundColor: colors.onSecondaryContainer,
          minimumSize: const Size(0, 32),
          fixedSize: const Size.fromHeight(32),
          padding: const EdgeInsetsDirectional.only(start: 12, end: 14),
          tapTargetSize: MaterialTapTargetSize.padded,
          shape: const StadiumBorder(),
          textStyle: Theme.of(context).textTheme.labelLarge
              ?.copyWith(fontSize: 13, fontWeight: FontWeight.w600),
        ),
        icon: const Icon(Icons.visibility, size: 18),
        label: Text(context.l10n.lessonVideoReveal),
      ),
    );
  }
}

class _EndFooter extends StatelessWidget {
  const _EndFooter({required this.cubit, this.onNextStage});

  final LessonVideoCubit cubit;
  final VoidCallback? onNextStage;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              key: LessonVideoKeys.endRestart,
              style: OutlinedButton.styleFrom(minimumSize: const Size(0, 48)),
              onPressed: cubit.restart,
              child: Text(l10n.lessonBackToStart),
            ),
          ),
          if (onNextStage != null) ...[
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                key: LessonVideoKeys.endNext,
                style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
                onPressed: onNextStage,
                child: Text(l10n.lessonNextStage),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// O tabuleiro do app mostrando o quadro do vídeo. Na sua vez (Vídeo 25)
/// ganha o contorno `primary` de 3 e aceita lance só das casas `movable`
/// (vazio = qualquer peça do lado que joga); fora dela, tocando o ramo ou
/// em pergunta `legacy` o toque não move peça (Vídeo 1). O selo ✗/✓ fica no canto da
/// casa (Vídeo 26/28/30).
class _VideoBoard extends StatefulWidget {
  const _VideoBoard({
    required this.frame,
    required this.size,
    required this.settings,
    required this.shapes,
    required this.flip,
    required this.yourMove,
    required this.turn,
    required this.onMove,
    super.key,
  });

  final VideoFrame frame;
  final double size;
  final BoardSettings settings;
  final bool shapes;
  final bool flip;

  /// O vídeo parou na pergunta: o contorno de "sua vez".
  final bool yourMove;
  final VideoTurnView? turn;
  final ValueChanged<String> onMove;

  @override
  State<_VideoBoard> createState() => _VideoBoardState();
}

class _VideoBoardState extends State<_VideoBoard> {
  late final _controller = ChessboardController(game: _data());

  /// O tabuleiro aceita lance agora (só no vídeo parado na pergunta).
  static bool _live(_VideoBoard w) =>
      w.yourMove && (w.turn?.awaitingMove ?? false);

  /// As casas de onde sai lance (vazio = todas as do lado que joga).
  static List<String> _from(_VideoBoard w) =>
      _live(w) ? w.turn!.movable : const [];

  GameData _data() {
    final frame = widget.frame;
    final last = frame.lastMove;
    final position = _live(widget) ? GameRules.fromFen(frame.fen) : null;
    final turn =
        position?.turn ?? (frame.fen.contains(' b') ? Side.black : Side.white);
    final from = {for (final s in _from(widget)) Square.fromName(s)};
    return GameData(
      fen: frame.fen,
      playerSide: position == null
          ? PlayerSide.none
          : turn == Side.white
          ? PlayerSide.white
          : PlayerSide.black,
      sideToMove: turn,
      validMoves: position == null
          ? const {}
          : {
              for (final e in GameRules.legalMoves(position).entries)
                if (from.isEmpty || from.contains(e.key)) e.key: e.value,
            },
      lastMove: last == null ? null : Move.parse(last),
    );
  }

  @override
  void didUpdateWidget(_VideoBoard old) {
    super.didUpdateWidget(old);
    final moved = old.frame.fen != widget.frame.fen;
    final oldFrom = _from(old);
    final from = _from(widget);
    final movableChanged =
        _live(old) != _live(widget) ||
        oldFrom.length != from.length ||
        !oldFrom.every(from.contains);
    if (moved ||
        old.frame.lastMove != widget.frame.lastMove ||
        movableChanged) {
      _controller.updatePosition(
        _data(),
        animate: moved && widget.frame.animating,
        resetPremove: true,
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Set<Shape> _shapes(ColorScheme colors) {
    if (!widget.shapes || widget.frame.animating) return const {};
    return {
      for (final a in widget.frame.arrows)
        Arrow(
          color: ScriptShapes.arrow(colors, a.color),
          orig: Square.fromName(a.from),
          dest: Square.fromName(a.to),
        ),
      for (final m in widget.frame.marks)
        Circle(color: ScriptShapes.green, orig: Square.fromName(m)),
    };
  }

  /// O selo da vez: ✗ na casa do erro, ✓ no destino do lance certo.
  (String, bool)? _seal() {
    final turn = widget.turn;
    final last = turn?.last;
    if (turn == null || last == null) return null;
    switch (last) {
      case TurnResult.wrong || TurnResult.outside:
        final sq = turn.wrongSquare;
        return sq == null ? null : (sq, false);
      case TurnResult.right || TurnResult.alternative:
        final sq = turn.rightSquare;
        if (sq != null) return (sq, true);
        final move = widget.frame.lastMove;
        return move == null || move.length < 4
            ? null
            : (move.substring(2, 4), true);
      case TurnResult.revealed:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final seal = _seal();
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Chessboard(
          size: widget.size,
          controller: _controller,
          settings: widget.settings.chessground,
          orientation: widget.flip ? Side.black : Side.white,
          shapes: _shapes(colors),
          onMove: (move, {viaDragAndDrop}) => widget.onMove(move.uci),
        ),
        if (widget.yourMove)
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                key: LessonVideoKeys.yourMove,
                decoration: BoxDecoration(
                  border: Border.all(color: colors.primary, width: 3),
                ),
              ),
            ),
          ),
        if (seal != null) _sealAt(seal.$1, ok: seal.$2),
      ],
    );
  }

  /// O selo de 22 no canto de cima à direita da casa (protótipo `selo()`:
  /// 17 para dentro da borda direita, 5 acima da de cima).
  Widget _sealAt(String square, {required bool ok}) {
    final q = widget.size / 8;
    final file = square.codeUnitAt(0) - 'a'.codeUnitAt(0);
    final rank = int.parse(square.substring(1, 2)) - 1;
    final col = widget.flip ? 7 - file : file;
    final row = widget.flip ? rank : 7 - rank;
    return Positioned(
      left: (col + 1) * q - 17,
      top: row * q - 5,
      width: 22,
      height: 22,
      child: IgnorePointer(
        child: DecoratedBox(
          key: ok ? LessonVideoKeys.rightMark : LessonVideoKeys.wrongMark,
          decoration:
              const BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.black38,
                    blurRadius: 2,
                    offset: Offset(0, 1),
                  ),
                ],
              ).copyWith(
                color: ok ? AppColors.moveSealRight : AppColors.moveSealWrong,
              ),
          child: Icon(
            ok ? Icons.check : Icons.close,
            size: 16,
            color: AppColors.white,
          ),
        ),
      ),
    );
  }
}

/// Sem a voz do capítulo (Vídeo 10–11): "Sem áudio." e "Baixar a voz", ou
/// "Não deu para baixar a voz." e "Tentar novamente". Com a voz desligada nos
/// ajustes, nada (leitura sem aviso).
class _VoiceNotice extends StatelessWidget {
  const _VoiceNotice({required this.state, required this.cubit});

  final LessonVideoState state;
  final LessonVideoCubit cubit;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = Theme.of(context).colorScheme;
    final small = Theme.of(context).textTheme.bodySmall;
    final failed = state.voice == VideoVoice.failed;
    // A ação fica sempre à vista; a mensagem encolhe com reticências.
    return LayoutBuilder(
      builder: (context, constraints) => Row(
        key: LessonVideoKeys.voiceNotice,
        children: [
          Icon(
            failed ? Icons.error : Icons.volume_off,
            size: 16,
            color: failed ? colors.error : colors.onSurfaceVariant,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              failed ? l10n.lessonVideoVoiceFailed : l10n.lessonVideoNoAudio,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: small,
            ),
          ),
          const SizedBox(width: 8),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: max(0, constraints.maxWidth - 28),
            ),
            child: GestureDetector(
              key: LessonVideoKeys.voiceNoticeAction,
              onTap: cubit.downloadVoice,
              child: Text(
                failed ? l10n.lessonRetry : l10n.lessonVideoDownloadVoice,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: small?.copyWith(
                  color: colors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

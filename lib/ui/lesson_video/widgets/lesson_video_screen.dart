import 'dart:math';

import 'package:chessground/chessground.dart';
import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/models/board_settings.dart';
import '../../../domain/models/character.dart';
import '../../../domain/use_cases/video_timeline.dart';
import '../../core/board/board_settings_ui.dart';
import '../../core/keys/lesson_script_keys.dart';
import '../../core/keys/lesson_video_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/widgets/character_avatar.dart';
import '../../core/widgets/lucena_app_bar.dart';
import '../../lesson_script/widgets/script_board.dart';
import '../../settings/view_models/settings_cubit.dart';
import '../view_models/lesson_video_cubit.dart';

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
    super.key,
  });

  final String title;
  final Character? viktor;

  /// O livro do topo (o Glossário é do L5; até lá, quem abre decide).
  final VoidCallback? onGlossary;

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
          ),
        },
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.state, this.viktor, this.onNextStage});

  final LessonVideoState state;
  final Character? viktor;
  final VoidCallback? onNextStage;

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
                      child: _Balloon(frame: frame, visible: state.captions),
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
  const _Balloon({required this.frame, required this.visible});

  final VideoFrame? frame;
  final bool visible;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final frame = this.frame;
    final text = frame == null ? '' : _shown(frame);
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
            child: Text(
              text,
              key: LessonVideoKeys.caption,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyLarge
                  ?.copyWith(fontSize: 18, height: 26 / 18),
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
    final paused = state.waiting;
    return Column(
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
                        text: '${l10n.lessonVideoResumeNotice} ',
                        children: [
                          WidgetSpan(
                            alignment: PlaceholderAlignment.middle,
                            child: GestureDetector(
                              key: LessonVideoKeys.noticeAction,
                              onTap: cubit.restart,
                              child: Text(
                                l10n.lessonVideoResumeRestart,
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
              : _Controls(state: state, cubit: cubit, dim: paused),
        ),
        const SizedBox(height: LessonVideoLayout.bottomMargin),
      ],
    );
  }

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
  });

  final LessonVideoState state;
  final LessonVideoCubit cubit;

  /// Na sua vez: play e ±10 esmaecidos.
  final bool dim;

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
                  onPressed: dim
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
                  onPressed: dim
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

/// O tabuleiro do app mostrando o quadro do vídeo (sem lance no L1: a sua
/// vez entra no L2). Toque fora da sua vez não move peça nem pausa.
class _VideoBoard extends StatefulWidget {
  const _VideoBoard({
    required this.frame,
    required this.size,
    required this.settings,
    required this.shapes,
    required this.flip,
    super.key,
  });

  final VideoFrame frame;
  final double size;
  final BoardSettings settings;
  final bool shapes;
  final bool flip;

  @override
  State<_VideoBoard> createState() => _VideoBoardState();
}

class _VideoBoardState extends State<_VideoBoard> {
  late final _controller = ChessboardController(game: _data());

  GameData _data() {
    final frame = widget.frame;
    final last = frame.lastMove;
    return GameData(
      fen: frame.fen,
      playerSide: PlayerSide.none,
      sideToMove: frame.fen.contains(' b') ? Side.black : Side.white,
      validMoves: const {},
      lastMove: last == null ? null : Move.parse(last),
    );
  }

  @override
  void didUpdateWidget(_VideoBoard old) {
    super.didUpdateWidget(old);
    final moved = old.frame.fen != widget.frame.fen;
    if (moved || old.frame.lastMove != widget.frame.lastMove) {
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

  @override
  Widget build(BuildContext context) => Chessboard(
    size: widget.size,
    controller: _controller,
    settings: widget.settings.chessground,
    orientation: widget.flip ? Side.black : Side.white,
    shapes: _shapes(Theme.of(context).colorScheme),
    onMove: (move, {viaDragAndDrop}) {},
  );
}

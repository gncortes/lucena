import 'dart:async';
import 'dart:math' as math;

import 'package:chessground/chessground.dart';
import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../domain/models/attempt.dart';
import '../../../domain/models/board_settings.dart';
import '../../../domain/models/character.dart';
import '../../../domain/models/game_review.dart';
import '../../../domain/use_cases/game_export.dart';
import '../../../domain/use_cases/game_rules.dart';
import '../../core/widgets/one_line.dart';
import '../../core/board/board_settings_ui.dart';
import '../../core/keys/game_details_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/review/move_quality_ui.dart';
import '../../core/widgets/figurine.dart';
import '../../core/widgets/teacher_speech.dart';
import '../../settings/view_models/settings_cubit.dart';
import '../view_models/game_details_cubit.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_shape.dart';

/// As qualidades na ordem do resumo, da melhor para a pior.
const _summaryOrder = [
  MoveQuality.great,
  MoveQuality.best,
  MoveQuality.excellent,
  MoveQuality.good,
  MoveQuality.forced,
  MoveQuality.inaccuracy,
  MoveQuality.mistake,
  MoveQuality.miss,
  MoveQuality.blunder,
];

/// Um lance em notação algébrica, com os desenhos das peças.
class SanText extends StatelessWidget {
  const SanText(this.san, {this.style, super.key});

  final String san;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) => Text.rich(
    TextSpan(
      children: [
        for (final char in san.split(''))
          if (Figurine.ofLetter[char] case final figurine?)
            TextSpan(
              text: figurine,
              style: const TextStyle(
                fontFamily: Figurine.fontFamily,
                fontWeight: FontWeight.w400,
              ),
            )
          else
            TextSpan(text: char),
      ],
    ),
    style: style,
    textDirection: TextDirection.ltr,
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
  );
}

/// A revisão: antes dela, o botão (e o progresso); depois, a precisão de
/// cada lado e quantos lances de cada qualidade cada um fez.
class ReviewSummary extends StatelessWidget {
  const ReviewSummary({
    required this.state,
    required this.whiteName,
    required this.blackName,
    super.key,
  });

  final GameDetailsState state;
  final String whiteName;
  final String blackName;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final review = state.review;
    final total = state.moves.length;
    final done = (state.reviewProgress * total).round();
    final Widget child;
    if (state.reviewing) {
      child = Column(
        key: GameDetailsKeys.reviewProgress,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.reviewRunning(math.min(done + 1, total), total),
            style: theme.textTheme.titleSmall,
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppShape.small),
            child: LinearProgressIndicator(
              value: state.reviewProgress,
              minHeight: 8,
            ),
          ),
        ],
      );
    } else if (review == null) {
      child = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.insights, color: colors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.reviewStart,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            l10n.reviewSpeedHint,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 10),
          _speedButtons(context, 0),
        ],
      );
    } else {
      child = Column(
        key: GameDetailsKeys.reviewSummary,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: _name(context, whiteName, TextAlign.start)),
              Expanded(
                child: Text(
                  l10n.reviewAccuracy,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ),
              Expanded(child: _name(context, blackName, TextAlign.end)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _AccuracyBox(
                key: GameDetailsKeys.accuracyWhite,
                value: review.whiteAccuracy,
                light: true,
              ),
              const Spacer(),
              _AccuracyBox(
                key: GameDetailsKeys.accuracyBlack,
                value: review.blackAccuracy,
                light: false,
              ),
            ],
          ),
          // Revisada às pressas (ou só passando os lances): dá para revisar
          // de novo com mais tempo de engine.
          if (review.depth <
              GameDetailsCubit.reviewWeights[ReviewSpeed.deep]!) ...[
            const SizedBox(height: 14),
            Text(
              l10n.reviewDeeper,
              style: theme.textTheme.labelLarge?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            _speedButtons(context, review.depth),
          ],
        ],
      );
    }
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      color: colors.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (state.viktor case final viktor? when state.stories.isNotEmpty)
              _StoryTeller(
                viktor: viktor,
                stories: state.stories,
                first: state.attempt?.playedAt.millisecond ?? 0,
                running: state.reviewing,
              ),
            child,
          ],
        ),
      ),
    );
  }

  /// As três revisões: as já feitas (até [above]) marcadas com o ✓ e sem
  /// toque; as mais pesadas, para fazer. Os nomes numa linha só, que
  /// encolhe se faltar largura.
  Widget _speedButtons(BuildContext context, int above) {
    final l10n = context.l10n;
    final speeds = [
      (ReviewSpeed.quick, GameDetailsKeys.reviewQuick, l10n.reviewQuick),
      (ReviewSpeed.medium, GameDetailsKeys.reviewButton, l10n.reviewMedium),
      (ReviewSpeed.deep, GameDetailsKeys.reviewDeep, l10n.reviewDeep),
    ];
    final style = FilledButton.styleFrom(
      minimumSize: const Size.fromHeight(46),
      padding: const EdgeInsets.symmetric(horizontal: 10),
    );
    // A próxima a fazer fica em destaque.
    final next = speeds
        .firstWhere(
          (s) => GameDetailsCubit.reviewWeights[s.$1]! > above,
          orElse: () => speeds.last,
        )
        .$1;
    return Row(
      children: [
        for (final (i, (speed, key, label)) in speeds.indexed) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(
            child: () {
              void onPressed() =>
                  context.read<GameDetailsCubit>().review(speed: speed);
              final done = GameDetailsCubit.reviewWeights[speed]! <= above;
              final enabled = state.moves.isNotEmpty && !done;
              if (done) {
                return OutlinedButton.icon(
                  key: key,
                  style: style,
                  onPressed: null,
                  icon: const Icon(Icons.check_rounded, size: 18),
                  label: OneLine(label),
                );
              }
              return speed == next
                  ? FilledButton(
                      key: key,
                      style: style,
                      onPressed: enabled ? onPressed : null,
                      child: OneLine(label),
                    )
                  : FilledButton.tonal(
                      key: key,
                      style: style,
                      onPressed: enabled ? onPressed : null,
                      child: OneLine(label),
                    );
            }(),
          ),
        ],
      ],
    );
  }

  Widget _name(BuildContext context, String name, TextAlign align) => Text(
    name,
    textAlign: align,
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
    style: Theme.of(context).textTheme.titleSmall
        ?.copyWith(fontWeight: FontWeight.w700),
  );
}

/// Enquanto a revisão roda, o Viktor conta uma história de xadrez, e troca
/// de história de tempos em tempos. Pronta a revisão, a história do momento
/// fica até o ✕ no balão (ninguém perde o fim dela).
class _StoryTeller extends StatefulWidget {
  const _StoryTeller({
    required this.viktor,
    required this.stories,
    required this.first,
    required this.running,
  });

  final Character viktor;
  final List<String> stories;

  /// A primeira história (cada partida começa por uma).
  final int first;

  /// A revisão está rodando (só então a história troca).
  final bool running;

  /// Quanto tempo cada história fica.
  static const every = Duration(seconds: 18);

  @override
  State<_StoryTeller> createState() => _StoryTellerState();
}

class _StoryTellerState extends State<_StoryTeller> {
  late int _index = widget.first;
  Timer? _timer;

  /// Já houve revisão rodando nesta tela (abrir uma partida já revisada
  /// não conta história).
  late bool _told = widget.running;
  bool _closed = false;

  @override
  void initState() {
    super.initState();
    if (widget.running) _start();
  }

  @override
  void didUpdateWidget(_StoryTeller old) {
    super.didUpdateWidget(old);
    if (widget.running && !old.running) {
      _told = true;
      _closed = false;
      _start();
    } else if (!widget.running && old.running) {
      _timer?.cancel();
    }
  }

  void _start() {
    _timer?.cancel();
    _timer = Timer.periodic(
      _StoryTeller.every,
      (_) => setState(() => _index++),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_told || _closed) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TeacherSpeech(
        key: GameDetailsKeys.story,
        teacher: widget.viktor,
        text: widget.stories[_index % widget.stories.length],
        avatarSize: 40,
        speechContext: SpeechContext.teaching,
        typed: true,
        closeKey: GameDetailsKeys.storyClose,
        onClose: () async {
          _timer?.cancel();
          setState(() => _closed = true);
          final text = widget.stories[_index % widget.stories.length];
          await TeacherSpeech.speechOf(context)?.stopIf(text);
        },
      ),
    );
  }
}

/// No fim da tela: o que cada símbolo quer dizer e, depois da revisão,
/// quantos lances de cada um cada lado fez.
class ReviewLegend extends StatelessWidget {
  const ReviewLegend({
    required this.state,
    required this.whiteName,
    required this.blackName,
    super.key,
  });

  final GameDetailsState state;
  final String whiteName;
  final String blackName;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final review = state.review;
    final firstIsWhite = state.start?.turn != Side.black;
    final white = review?.counts(white: true, firstIsWhite: firstIsWhite);
    final black = review?.counts(white: false, firstIsWhite: firstIsWhite);
    TextStyle? count(MoveQuality quality, int value) =>
        theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w800,
          color: value == 0 ? colors.outline : quality.color,
          fontFeatures: const [FontFeature.tabularFigures()],
        );
    return Card(
      key: GameDetailsKeys.legend,
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      color: colors.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.reviewLegend,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (review != null) ...[
                  _legendHeader(context, whiteName),
                  _legendHeader(context, blackName),
                ],
              ],
            ),
            const SizedBox(height: 6),
            for (final quality in _summaryOrder)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  children: [
                    MoveQualityBadge(quality, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            quality.label(l10n),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: quality.color,
                            ),
                          ),
                          Text(
                            quality.meaning(l10n),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (white != null && black != null) ...[
                      SizedBox(
                        width: 56,
                        child: Text(
                          '${white[quality]}',
                          key: GameDetailsKeys.count(quality.name, white: true),
                          textAlign: TextAlign.center,
                          style: count(quality, white[quality]!),
                        ),
                      ),
                      SizedBox(
                        width: 56,
                        child: Text(
                          '${black[quality]}',
                          key: GameDetailsKeys.count(
                            quality.name,
                            white: false,
                          ),
                          textAlign: TextAlign.center,
                          style: count(quality, black[quality]!),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _legendHeader(BuildContext context, String name) => SizedBox(
    width: 56,
    child: Text(
      name,
      textAlign: TextAlign.center,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(context).textTheme.labelMedium
          ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
    ),
  );
}

/// A precisão de um lado numa caixa clara (brancas) ou escura (pretas),
/// como os relógios.
class _AccuracyBox extends StatelessWidget {
  const _AccuracyBox({required this.value, required this.light, super.key});

  final double? value;
  final bool light;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    final value = this.value;
    final text = value == null ? '–' : formatAccuracy(value, locale);
    return Container(
      constraints: const BoxConstraints(minWidth: 96),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: light ? const Color(0xFFF2F2F0) : const Color(0xFF2B2B2B),
        borderRadius: BorderRadius.circular(AppShape.medium),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: light ? const Color(0xFF1E1E1E) : Colors.white,
          fontSize: 26,
          fontWeight: FontWeight.w800,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}

/// O tabuleiro da revisão: a posição do lance mostrado, a anotação dele na
/// casa de destino e, com a engine ligada, a seta do melhor lance; sem a
/// engine, depois de um erro, a seta do lance que era melhor. Ao lado, a
/// barra de avaliação. Como num tabuleiro de análise, dá para jogar a partir
/// da posição mostrada: os lances viram uma variante.
class ReviewBoard extends StatefulWidget {
  const ReviewBoard({
    required this.state,
    required this.size,
    required this.orientation,
    super.key,
  });

  final GameDetailsState state;
  final double size;
  final Side orientation;

  @override
  State<ReviewBoard> createState() => _ReviewBoardState();
}

class _ReviewBoardState extends State<ReviewBoard> {
  late final ChessboardController _controller = ChessboardController(
    game: _game(widget.state),
  );

  static const _barWidth = 24.0;

  GameData _game(GameDetailsState state) {
    final position = state.shownPosition!;
    return GameData(
      fen: position.fen,
      playerSide: position.isGameOver ? PlayerSide.none : PlayerSide.both,
      sideToMove: position.turn,
      validMoves: GameRules.legalMoves(position),
      lastMove: state.shownMove,
      kingSquareInCheck: GameRules.checkedKing(position),
    );
  }

  @override
  void didUpdateWidget(ReviewBoard old) {
    super.didUpdateWidget(old);
    final before = old.state.shownPosition;
    final after = widget.state.shownPosition;
    if (!identical(before, after)) {
      // Só anima o lance seguinte (na partida ou na variante); os saltos
      // trocam a posição de uma vez.
      final forward = identical(widget.state.shownBefore, before);
      _controller.updatePosition(
        _game(widget.state),
        animate: forward,
        resetPremove: true,
      );
    }
  }

  /// A última avaliação mostrada na barra.
  EngineScore? _lastScore;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final settings = context.select(
      (SettingsCubit cubit) => cubit.state?.board ?? const BoardSettings(),
    );
    final showBar = context.select(
      (SettingsCubit cubit) => cubit.state?.evalBar ?? true,
    );
    final shown = state.shownScore;
    if (showBar && shown == null) {
      // Sem anotação nem engine: uma avaliação rápida só para a barra.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.read<GameDetailsCubit>().scoreShown();
      });
    }
    // Enquanto a engine avalia a posição nova, a barra fica onde estava (não
    // volta para o meio).
    final score = shown ?? _lastScore;
    _lastScore = score;
    final boardSize = showBar ? widget.size - _barWidth - 6 : widget.size;
    final locale = Localizations.localeOf(context).toString();
    final reviewed = state.shownReview;
    final move = state.shownMove;
    final annotations = <Square, Annotation>{
      if (reviewed != null && move is NormalMove)
        move.to: Annotation(
          symbol: reviewed.quality.symbol,
          color: reviewed.quality.color,
        ),
    };
    final shapes = <Shape>{
      if (_arrow(state) case (final orig, final dest, final color))
        Arrow(color: color, orig: orig, dest: dest),
    };
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showBar) ...[
            _EvalBar(
              key: GameDetailsKeys.evalBar,
              whiteWin: score?.whiteWinPercent,
              label: score == null ? null : formatScore(score, locale),
              height: boardSize,
              width: _barWidth,
              whiteBottom: widget.orientation == Side.white,
            ),
            const SizedBox(width: 6),
          ],
          // Sem recorte em volta: a anotação do lance passa um pouco da casa
          // (na fileira de cima, da borda do tabuleiro).
          Chessboard(
            key: GameDetailsKeys.board,
            size: boardSize,
            controller: _controller,
            orientation: widget.orientation,
            settings: settings.chessground.copyWith(
              borderRadius: const BorderRadius.all(
                Radius.circular(AppShape.small),
              ),
            ),
            annotations: annotations,
            shapes: shapes,
            onMove: (move, {viaDragAndDrop}) =>
                context.read<GameDetailsCubit>().play(move),
          ),
        ],
      ),
    );
  }

  /// A seta: com a engine, o melhor lance na posição mostrada (azul); sem
  /// ela, depois de um erro, o que era melhor no lugar dele (verde).
  static (Square, Square, Color)? _arrow(GameDetailsState state) {
    if (state.engine) {
      final lines = state.shownLines;
      if (lines == null || lines.isEmpty || lines.first.moves.isEmpty) {
        return null;
      }
      return _squares(lines.first.moves.first, const Color(0xCC3E7BC4));
    }
    final reviewed = state.shownReview;
    final best = reviewed?.best;
    if (reviewed == null || best == null || !reviewed.quality.isError) {
      return null;
    }
    return _squares(best, const Color(0xCC5FA14A));
  }

  static (Square, Square, Color)? _squares(String uci, Color color) {
    final move = Move.parse(uci);
    if (move is! NormalMove) return null;
    return (move.from, move.to, color);
  }
}

/// A barra de avaliação: a parte clara é a chance de vitória das brancas.
class _EvalBar extends StatelessWidget {
  const _EvalBar({
    required this.whiteWin,
    required this.label,
    required this.height,
    required this.width,
    required this.whiteBottom,
    super.key,
  });

  final double? whiteWin;

  /// A avaliação escrita (`+1,2`, `M3`), na ponta do lado que está melhor.
  final String? label;
  final double height;
  final double width;
  final bool whiteBottom;

  @override
  Widget build(BuildContext context) {
    final share = (whiteWin ?? 50) / 100;
    final white = Container(color: const Color(0xFFF2F2F0));
    final black = Container(color: const Color(0xFF3A3A3A));
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppShape.small),
      child: SizedBox(
        width: width,
        height: height,
        child: TweenAnimationBuilder<double>(
          tween: Tween(end: share),
          duration: AppMotion.component,
          curve: AppMotion.enter,
          builder: (context, value, _) {
            final whitePart = (height * value).clamp(0.0, height);
            final bar = Column(
              children: whiteBottom
                  ? [
                      SizedBox(height: height - whitePart, child: black),
                      SizedBox(height: whitePart, child: white),
                    ]
                  : [
                      SizedBox(height: whitePart, child: white),
                      SizedBox(height: height - whitePart, child: black),
                    ],
            );
            final label = this.label;
            if (label == null) return bar;
            // O número fica na ponta de quem está melhor, na cor oposta.
            final whiteAhead = value >= 0.5;
            final atBottom = whiteAhead == whiteBottom;
            return Stack(
              children: [
                bar,
                Positioned(
                  left: 0,
                  right: 0,
                  top: atBottom ? null : 4,
                  bottom: atBottom ? 4 : null,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: whiteAhead
                              ? const Color(0xFF3A3A3A)
                              : const Color(0xFFF2F2F0),
                        ),
                      ),
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

/// Sob o tabuleiro: o lance mostrado, a qualidade e a avaliação; depois de
/// um erro, o lance que era melhor.
class MoveExplanation extends StatelessWidget {
  const MoveExplanation({required this.state, super.key});

  final GameDetailsState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final locale = Localizations.localeOf(context).toString();
    final index = state.shownIndex;
    final reviewed = state.shownReview;
    final Widget title;
    Widget? subtitle;
    Widget? trailing;
    Widget? leading;
    if (state.variationPly case final ply?) {
      // Um lance da variante: sem anotação, com a avaliação da engine.
      final move = state.variation[ply];
      final before = state.shownBefore!;
      final number = before.turn == Side.white
          ? '${before.fullmoves}.'
          : '${before.fullmoves}...';
      leading = Icon(Icons.call_split, color: colors.onSurfaceVariant);
      title = SanText('$number ${move.san}', style: theme.textTheme.titleSmall);
      subtitle = Text(
        l10n.reviewVariation,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: colors.onSurfaceVariant,
        ),
      );
      if (state.shownScore case final score?) {
        trailing = Text(
          formatScore(score, locale),
          style: theme.textTheme.titleSmall?.copyWith(
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        );
      }
    } else if (index < 0) {
      title = Text(l10n.reviewStartPosition, style: theme.textTheme.titleSmall);
    } else {
      final move = state.moves[index];
      final number = _number(state, index);
      if (reviewed == null) {
        title = SanText(
          '$number ${move.san}',
          style: theme.textTheme.titleSmall,
        );
        // A engine está avaliando este lance agora.
        if (state.annotating.contains(index)) {
          trailing = const SizedBox.square(
            dimension: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          );
        }
      } else {
        leading = MoveQualityBadge(reviewed.quality, size: 28);
        title = Text.rich(
          TextSpan(
            children: [
              TextSpan(text: '$number '),
              ..._sanSpans(move.san),
              TextSpan(text: ': ${reviewed.quality.label(l10n)}'),
            ],
          ),
          style: theme.textTheme.titleSmall?.copyWith(
            color: reviewed.quality.color,
            fontWeight: FontWeight.w800,
          ),
        );
        trailing = Text(
          formatScore(reviewed.after, locale),
          style: theme.textTheme.titleSmall?.copyWith(
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        );
        final best = reviewed.best;
        final before = index == 0
            ? state.start
            : state.moves[index - 1].position;
        if (best != null &&
            before != null &&
            reviewed.quality.index >= MoveQuality.excellent.index &&
            reviewed.quality != MoveQuality.forced) {
          final san = GameRules.sanLine(before, [best]);
          if (san.isNotEmpty) {
            // O lance entra no lugar dele na frase traduzida.
            final parts = l10n.reviewBestWas(_slot).split(_slot);
            subtitle = Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: parts.first),
                  ..._sanSpans(san.single),
                  if (parts.length > 1) TextSpan(text: parts.last),
                ],
              ),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            );
          }
        }
      }
    }
    return Container(
      key: GameDetailsKeys.explanation,
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppShape.medium),
      ),
      child: Row(
        children: [
          if (leading != null) ...[leading, const SizedBox(width: 12)],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [title, ?subtitle],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }

  static const _slot = '\u0000';

  /// `12.` para um lance das brancas, `12...` para um das pretas.
  static String _number(GameDetailsState state, int index) {
    final start = state.start!;
    final blackFirst = start.turn == Side.black;
    final ply = index + (blackFirst ? 1 : 0);
    final number = start.fullmoves + ply ~/ 2;
    return ply.isEven ? '$number.' : '$number...';
  }
}

List<InlineSpan> _sanSpans(String san) => [
  for (final char in san.split(''))
    if (Figurine.ofLetter[char] case final figurine?)
      TextSpan(
        text: figurine,
        style: const TextStyle(
          fontFamily: Figurine.fontFamily,
          fontWeight: FontWeight.w400,
        ),
      )
    else
      TextSpan(text: char),
];

/// Os botões de lance a lance, a engine e o menu de abrir fora e copiar.
class ReviewNavigation extends StatelessWidget {
  const ReviewNavigation({
    required this.state,
    required this.attempt,
    super.key,
  });

  final GameDetailsState state;
  final Attempt attempt;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<GameDetailsCubit>();
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 0),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Row(
          children: [
            IconButton(
              key: GameDetailsKeys.first,
              tooltip: l10n.reviewFirst,
              onPressed: state.atStart ? null : cubit.first,
              icon: const Icon(Icons.first_page),
            ),
            IconButton.filledTonal(
              key: GameDetailsKeys.previous,
              tooltip: l10n.reviewPrevious,
              onPressed: state.atStart ? null : cubit.previous,
              icon: const Icon(Icons.chevron_left),
            ),
            IconButton.filledTonal(
              key: GameDetailsKeys.next,
              tooltip: l10n.reviewNext,
              onPressed: state.atEnd ? null : cubit.next,
              icon: const Icon(Icons.chevron_right),
            ),
            IconButton(
              key: GameDetailsKeys.last,
              tooltip: l10n.reviewLast,
              onPressed: state.atEnd ? null : cubit.last,
              icon: const Icon(Icons.last_page),
            ),
            // Em tela estreita ou com fonte grande, o nome da engine encolhe
            // (reticências) e os botões de lance ficam inteiros.
            Expanded(
              child: Align(
                alignment: AlignmentDirectional.centerEnd,
                child: FilterChip(
                  key: GameDetailsKeys.engineButton,
                  selected: state.engine,
                  showCheckmark: false,
                  avatar: Icon(
                    Icons.memory,
                    size: 18,
                    color: state.engine ? colors.onSecondaryContainer : null,
                  ),
                  label: Text(
                    l10n.reviewEngine,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onSelected: (_) => cubit.toggleEngine(),
                ),
              ),
            ),
            PopupMenuButton<_Export>(
              key: GameDetailsKeys.moreButton,
              tooltip: l10n.reviewMore,
              onSelected: (choice) => _export(context, choice),
              itemBuilder: (context) => [
                CheckedPopupMenuItem(
                  key: GameDetailsKeys.evalBarToggle,
                  value: _Export.evalBar,
                  checked: context.read<SettingsCubit>().state?.evalBar ?? true,
                  child: Text(l10n.reviewEvalBar),
                ),
                const PopupMenuDivider(),
                PopupMenuItem(
                  key: GameDetailsKeys.openLichess,
                  value: _Export.lichess,
                  child: ListTile(
                    leading: const Icon(Icons.open_in_new),
                    title: Text(l10n.reviewOpenLichess),
                  ),
                ),
                PopupMenuItem(
                  key: GameDetailsKeys.openChessCom,
                  value: _Export.chessCom,
                  child: ListTile(
                    leading: const Icon(Icons.open_in_new),
                    title: Text(l10n.reviewOpenChessCom),
                  ),
                ),
                PopupMenuItem(
                  key: GameDetailsKeys.copyFen,
                  value: _Export.fen,
                  child: ListTile(
                    leading: const Icon(Icons.content_copy),
                    title: Text(l10n.reviewCopyFen),
                  ),
                ),
                PopupMenuItem(
                  key: GameDetailsKeys.copyPgn,
                  value: _Export.pgn,
                  child: ListTile(
                    leading: const Icon(Icons.description_outlined),
                    title: Text(l10n.reviewCopyPgn),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _export(BuildContext context, _Export choice) async {
    final fen = state.shownPosition?.fen;
    if (fen == null) return;
    final messenger = ScaffoldMessenger.of(context);
    final copied = context.l10n.reviewCopied;
    switch (choice) {
      case _Export.evalBar:
        final settings = context.read<SettingsCubit>();
        await settings.setEvalBar(enabled: !(settings.state?.evalBar ?? true));
      case _Export.lichess:
        await launchUrl(
          GameExport.lichess(fen),
          mode: LaunchMode.externalApplication,
        );
      case _Export.chessCom:
        await launchUrl(
          GameExport.chessCom(fen),
          mode: LaunchMode.externalApplication,
        );
      case _Export.fen:
        await Clipboard.setData(ClipboardData(text: fen));
        messenger.showSnackBar(SnackBar(content: Text(copied)));
      case _Export.pgn:
        final result = switch (attempt.outcome) {
          AttemptOutcome.draw => '1/2-1/2',
          AttemptOutcome.win => attempt.userSide == Side.black ? '0-1' : '1-0',
          AttemptOutcome.loss => attempt.userSide == Side.black ? '1-0' : '0-1',
        };
        await Clipboard.setData(
          ClipboardData(
            text: GameExport.pgn(
              startFen: state.start!.fen,
              sans: [for (final move in state.moves) move.san],
              result: result,
              date: attempt.playedAt.toLocal(),
            ),
          ),
        );
        messenger.showSnackBar(SnackBar(content: Text(copied)));
    }
  }
}

enum _Export { evalBar, lichess, chessCom, fen, pgn }

/// Com a engine ligada: as melhores linhas da posição mostrada, cada uma com
/// a avaliação e os primeiros lances.
class EngineLinesPanel extends StatelessWidget {
  const EngineLinesPanel({required this.state, super.key});

  final GameDetailsState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final locale = Localizations.localeOf(context).toString();
    final lines = state.shownLines;
    final position = state.shownPosition;
    final List<Widget> children;
    if (lines == null) {
      children = [
        Row(
          children: [
            const SizedBox.square(
              dimension: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 10),
            Text(l10n.reviewEngineThinking),
          ],
        ),
      ];
    } else if (lines.isEmpty || position == null) {
      children = [Text(l10n.reviewEngineOver)];
    } else {
      children = [
        for (final (index, line) in lines.indexed)
          Padding(
            key: GameDetailsKeys.engineLine(index),
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Container(
                  width: 58,
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: line.score.whiteWinPercent >= 50
                        ? const Color(0xFFF2F2F0)
                        : const Color(0xFF2B2B2B),
                    borderRadius: BorderRadius.circular(AppShape.small),
                  ),
                  child: Text(
                    formatScore(line.score, locale),
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: line.score.whiteWinPercent >= 50
                          ? const Color(0xFF1E1E1E)
                          : Colors.white,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SanText(
                    _numbered(
                      position,
                      GameRules.sanLine(position, line.moves, max: 8),
                    ),
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
      ];
    }
    return Card(
      key: GameDetailsKeys.engineLines,
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      color: colors.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...children,
            const SizedBox(height: 4),
            Text(
              'Stockfish · ${l10n.reviewDepth(state.shownDepth ?? GameDetailsCubit.engineDepths.first)}',
              style: theme.textTheme.labelSmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// `12. Kd4 Kc6 13. Rb3` a partir de [position].
  static String _numbered(Position position, List<String> sans) {
    final out = StringBuffer();
    var number = position.fullmoves;
    var white = position.turn == Side.white;
    for (final (index, san) in sans.indexed) {
      if (white) {
        out.write('$number. ');
      } else if (index == 0) {
        out.write('$number... ');
      }
      out.write('$san ');
      if (!white) number++;
      white = !white;
    }
    return out.toString().trimRight();
  }
}

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../../domain/models/variation_tree.dart';
import '../../core/board/board_settings_ui.dart';
import '../../core/keys/school_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_shape.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/typing_dots.dart';

/// O botão que cobre ou mostra os lances ainda não vistos da faixa (T69): no
/// cabeçalho do Viktor e, no modo variante, sozinho no canto da faixa.
class HiddenMovesButton extends StatelessWidget {
  const HiddenMovesButton({
    required this.buttonKey,
    required this.hidden,
    required this.onPressed,
    super.key,
  });

  final Key buttonKey;

  /// Os lances não vistos estão cobertos (ligado).
  final bool hidden;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return IconButton(
      key: buttonKey,
      visualDensity: VisualDensity.standard,
      tooltip: hidden ? l10n.lessonShowAllMoves : l10n.lessonHideNextMoves,
      isSelected: hidden,
      icon: const Icon(Icons.blur_off),
      selectedIcon: const Icon(Icons.blur_on),
      onPressed: onPressed,
    );
  }
}

/// A revelação em curso: qual lance e um número que muda a cada pedido (o
/// mesmo lance pode ser pedido de novo).
typedef RevealEvent = ({TreePosition position, int stamp});

/// A faixa do modo variante (T68, variante B do canvas): as linhas de lances
/// (a principal e, recuadas, as alternativas), o lance da vez em destaque e,
/// embaixo, o comentário daquele ponto. É o filho da folha do Viktor, que
/// rola e esmaece o que não cabe; cada lance é um alvo de toque de 48 dp.
///
/// Com [hideUnseen] (T69), os lances fora de [revealed] ficam cobertos por um
/// bloco granulado por linha; tocar no bloco ([onReveal]) ou avançar revela.
class VariationStrip extends StatefulWidget {
  const VariationStrip({
    required this.tree,
    required this.position,
    required this.text,
    required this.onSelect,
    this.hideUnseen = false,
    this.revealed = const {},
    this.revealing,
    this.onReveal,
    this.onToggleHidden,
    this.maxHeight,
    this.typing = false,
    super.key,
  });

  final VariationTree tree;

  /// O lance da vez.
  final TreePosition position;

  /// O comentário do ponto.
  final String text;

  /// O motor está pensando (T70, crit. 8d/9c): os três pontos no lugar do
  /// comentário.
  final bool typing;

  /// Toque num lance: o tabuleiro vai à posição dele.
  final ValueChanged<TreePosition> onSelect;

  /// Os lances não vistos ficam cobertos.
  final bool hideUnseen;

  /// Os lances que o aluno já viu nesta linha.
  final Set<TreePosition> revealed;

  /// O lance que acaba de ser revelado (anima o bloco).
  final RevealEvent? revealing;

  /// Toque num bloco, com o índice da linha em `tree.rows`.
  final ValueChanged<int>? onReveal;

  /// O botão do canto da faixa; nulo, sem botão.
  final VoidCallback? onToggleHidden;

  /// Altura máxima do cabeçalho mais a lista de linhas (o que cabe na folha
  /// recolhida, acima do rodapé). Acima disso a lista rola por dentro, com o
  /// cabeçalho fixo; nulo, sem limite.
  final double? maxHeight;

  /// Recuo das alternativas: 4 de margem + 2 do filete + 10 de respiro
  /// (canvas T68, `.svr`).
  static const branchIndent = 16.0;

  /// Alvo mínimo de toque de cada lance.
  static const tapSize = 48.0;

  /// O trecho abre com o lance da vez ("1...Re6. O rei…"), que a linha de
  /// cima já mostra em destaque: a notação do começo sai do texto. Quando o
  /// lance é o sujeito da frase ("3.Rf5 é um bom lance…"), o texto fica
  /// inteiro: cortar deixaria um pedaço começando em minúscula.
  @visibleForTesting
  static String withoutLeadingMove(String text) {
    final rest = text.replaceFirst(
      RegExp(
        r'^\s*\d+\.(?:\.\.)?\s*[A-Za-z][A-Za-z0-9=+#x\-]*[!?]{0,2}[.:,]?\s+',
      ),
      '',
    );
    if (rest == text || rest.isEmpty) return rest;
    final first = rest[0];
    return first.toLowerCase() == first && first.toUpperCase() != first
        ? text
        : rest;
  }

  @override
  State<VariationStrip> createState() => _VariationStripState();
}

class _VariationStripState extends State<VariationStrip> {
  final _scroll = ScrollController();
  final _listBox = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _follow(animate: false),
    );
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(VariationStrip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.position == widget.position) return;
    WidgetsBinding.instance.addPostFrameCallback((_) => _follow(animate: true));
  }

  /// A lista de linhas rola para o lance da vez ficar no alto dela; o
  /// cabeçalho (linha 0 e o botão) fica fora da lista e não se mexe. Sem
  /// sobra de conteúdo, `maxScrollExtent` é 0 e nada rola.
  void _follow({required bool animate}) {
    if (!mounted || !_scroll.hasClients) return;
    final list = _listBox.currentContext?.findRenderObject();
    final current = _currentElement?.findRenderObject();
    var target = 0.0;
    if (list != null && current != null && current.attached) {
      var inside = false;
      for (RenderObject? node = current; node != null; node = node.parent) {
        if (identical(node, list)) {
          inside = true;
          break;
        }
      }
      final viewport = RenderAbstractViewport.maybeOf(current);
      if (inside && viewport != null) {
        target = viewport.getOffsetToReveal(current, 0).offset;
      }
    }
    final position = _scroll.position;
    target = target.clamp(position.minScrollExtent, position.maxScrollExtent);
    if ((target - position.pixels).abs() < .5) return;
    final motion = AppMotion.of(context);
    if (!animate || motion.disabled) {
      _scroll.jumpTo(target);
    } else {
      _scroll.animateTo(target, duration: motion.state, curve: AppMotion.move);
    }
  }

  BuildContext? get _currentElement {
    BuildContext? found;
    void visit(Element element) {
      if (found != null) return;
      if (element.widget.key == LessonKeys.variationStripCurrent) {
        found = element;
        return;
      }
      element.visitChildren(visit);
    }

    (context as Element).visitChildren(visit);
    return found;
  }

  Widget _row(int index, VariationRow row, TextStyle body, bool hasButton) =>
      _StripRow(
        tree: widget.tree,
        row: row,
        index: index,
        current: widget.position,
        style: body,
        hideUnseen: widget.hideUnseen,
        revealed: widget.revealed,
        revealing: widget.revealing,
        reserveEnd: index == 0 && hasButton ? VariationStrip.tapSize : 0,
        onSelect: widget.onSelect,
        onReveal: widget.onReveal,
      );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final body = theme.textTheme.bodyLarge!;
    final text = VariationStrip.withoutLeadingMove(widget.text);
    final tree = widget.tree;
    final button = widget.onToggleHidden;
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        0,
      ),
      child: Semantics(
        container: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Na área das linhas, o toque fora de lance e de bloco não abre
            // o painel (ponto 7 da T68); abrem a alça e o comentário.
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {},
              child: Stack(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: widget.maxHeight ?? double.infinity,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (tree.rows.isNotEmpty)
                            _row(0, tree.rows.first, body, button != null),
                          if (tree.rows.length > 1)
                            Flexible(
                              child: Scrollbar(
                                controller: _scroll,
                                thumbVisibility: true,
                                child: SingleChildScrollView(
                                  key: LessonKeys.variationStripList,
                                  controller: _scroll,
                                  child: Column(
                                    key: _listBox,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      for (final (index, row)
                                          in tree.rows.indexed.skip(1))
                                        _row(index, row, body, button != null),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  if (button != null)
                    PositionedDirectional(
                      top: 0,
                      end: 0,
                      child: HiddenMovesButton(
                        buttonKey: LessonKeys.variationHiddenToggle,
                        hidden: widget.hideUnseen,
                        onPressed: button,
                      ),
                    ),
                ],
              ),
            ),
            if (widget.typing) ...[
              const SizedBox(height: AppSpacing.xs),
              Divider(height: 1, thickness: 1, color: colors.outlineVariant),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: TypingDots(key: LessonKeys.sheetTyping),
                ),
              ),
            ] else if (text.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xs),
              Divider(height: 1, thickness: 1, color: colors.outlineVariant),
              const SizedBox(height: AppSpacing.sm),
              _Comment(
                text: text,
                style: body.copyWith(color: colors.onSurface),
                hiddenMoves: widget.hideUnseen
                    ? _hiddenNotations(tree, widget.revealed, widget.position)
                    : const {},
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// A notação (sem número e sem !?) dos lances cobertos. O lance citado
  /// segue o estado do lance da linha em foco (a principal, ou a principal até
  /// o ramo mais o ramo); o que não aparece nela só vale coberto se todas as
  /// ocorrências na árvore estiverem cobertas.
  static Set<String> _hiddenNotations(
    VariationTree tree,
    Set<TreePosition> revealed,
    TreePosition focus,
  ) {
    String sanOf(String label) => label
        .replaceFirst(RegExp(r'^\d+\.(?:\.\.)?'), '')
        .replaceFirst(RegExp(r'[!?]+$'), '');
    final all = <String, bool>{};
    final line = <String, bool>{};
    final inLine = {
      ...tree.pathTo(focus),
      if (focus.branch case final id?)
        for (var k = 1; k <= tree.branchOf(id)!.moves.length; k++)
          TreePosition.branch(id, k)
      else
        for (var i = 1; i <= tree.main.length; i++) TreePosition.main(i),
    };
    void visit(String label, TreePosition position) {
      final san = sanOf(label);
      if (san.isEmpty) return;
      final hidden = !revealed.contains(position);
      all[san] = (all[san] ?? true) && hidden;
      if (inLine.contains(position)) line[san] = (line[san] ?? true) && hidden;
    }

    for (final (i, move) in tree.main.indexed) {
      visit(move.label, TreePosition.main(i + 1));
    }
    for (final branch in tree.branches) {
      for (final (i, move) in branch.moves.indexed) {
        visit(move.label, TreePosition.branch(branch.id, i + 1));
      }
    }
    return {
      for (final entry in all.entries)
        if (line[entry.key] ?? entry.value) entry.key,
    };
  }
}

/// O granulado dos lances ocultos (`GRAO` do canvas v3): fundo
/// `surfaceContainerHigh` e pontos de raio ~1 dp numa grade de 4 dp.
class _GrainPainter extends CustomPainter {
  const _GrainPainter({required this.fill, required this.dot});

  final Color fill;
  final Color dot;

  static const grid = 4.0;
  static const radius = 1.0;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.save();
    canvas.clipRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(AppShape.small)),
    );
    canvas.drawRect(rect, Paint()..color = fill);
    final paint = Paint()..color = dot;
    for (var y = grid / 2; y < size.height; y += grid) {
      for (var x = grid / 2; x < size.width; x += grid) {
        canvas.drawCircle(Offset(x, y), radius, paint);
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_GrainPainter old) => old.fill != fill || old.dot != dot;
}

class _Grain extends StatelessWidget {
  const _Grain({required this.width, required this.height, this.boxKey});

  final double width;
  final double height;
  final Key? boxKey;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SizedBox(
      key: boxKey,
      width: width,
      height: height,
      child: CustomPaint(
        painter: _GrainPainter(
          fill: colors.surfaceContainerHigh,
          dot: colors.onSurfaceVariant.withValues(alpha: .42),
        ),
      ),
    );
  }
}

/// O comentário do ponto; o lance citado que ainda está coberto vira um
/// trecho granulado do tamanho do texto.
class _Comment extends StatelessWidget {
  const _Comment({
    required this.text,
    required this.style,
    required this.hiddenMoves,
  });

  final String text;
  final TextStyle style;

  /// Notações cobertas (sem número).
  final Set<String> hiddenMoves;

  @override
  Widget build(BuildContext context) {
    if (hiddenMoves.isEmpty) return Text(text, style: style);
    final alternatives =
        (hiddenMoves.toList()..sort((a, b) => b.length.compareTo(a.length)))
            .map(RegExp.escape)
            .join('|');
    final move = RegExp(
      '(?<![\\p{L}\\p{N}])(?:\\d+\\.(?:\\.\\.)?\\s*)?(?:$alternatives)'
      '[!?]{0,2}(?![\\p{L}\\p{N}])',
      unicode: true,
    );
    final matches = move.allMatches(text).toList();
    if (matches.isEmpty) return Text(text, style: style);
    // Lances seguidos (só espaço entre eles) formam um trecho só.
    final runs = <(int, int)>[];
    for (final match in matches) {
      if (runs.isNotEmpty &&
          text.substring(runs.last.$2, match.start).trim().isEmpty) {
        runs[runs.length - 1] = (runs.last.$1, match.end);
      } else {
        runs.add((match.start, match.end));
      }
    }
    final label = context.l10n.lessonHiddenMoves;
    final scaler = MediaQuery.textScalerOf(context);
    final direction = Directionality.of(context);
    final spans = <InlineSpan>[];
    var cursor = 0;
    for (final (index, run) in runs.indexed) {
      if (run.$1 > cursor) {
        spans.add(TextSpan(text: text.substring(cursor, run.$1)));
      }
      final painter = TextPainter(
        text: TextSpan(text: text.substring(run.$1, run.$2), style: style),
        textDirection: direction,
        textScaler: scaler,
      )..layout();
      spans.add(
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Semantics(
            label: label,
            excludeSemantics: true,
            child: _Grain(
              boxKey: index == 0 ? LessonKeys.variationHiddenComment : null,
              width: painter.width,
              height: painter.height,
            ),
          ),
        ),
      );
      painter.dispose();
      cursor = run.$2;
    }
    if (cursor < text.length) spans.add(TextSpan(text: text.substring(cursor)));
    return Text.rich(TextSpan(style: style, children: spans));
  }
}

/// A medida de uma linha da faixa depois do layout (relativa ao `Stack`).
class _Metrics {
  const _Metrics(this.buttons, this.texts);

  /// O alvo de cada lance; depois dos lances, o do resultado (se houver).
  final List<Rect> buttons;

  /// O texto de cada lance; depois dos lances, o do resultado.
  final List<Rect> texts;

  bool sameAs(_Metrics? other) =>
      other != null &&
      other.buttons.length == buttons.length &&
      [
        for (var i = 0; i < buttons.length; i++)
          other.buttons[i] == buttons[i] && other.texts[i] == texts[i],
      ].every((same) => same);
}

/// Uma linha da faixa: os lances, o filete do ramo e os blocos de lances
/// ocultos (um por linha visual), com a animação de revelar.
class _StripRow extends StatefulWidget {
  const _StripRow({
    required this.tree,
    required this.row,
    required this.index,
    required this.current,
    required this.style,
    required this.hideUnseen,
    required this.revealed,
    required this.revealing,
    required this.reserveEnd,
    required this.onSelect,
    required this.onReveal,
  });

  final VariationTree tree;
  final VariationRow row;
  final int index;
  final TreePosition current;
  final TextStyle style;
  final bool hideUnseen;
  final Set<TreePosition> revealed;
  final RevealEvent? revealing;
  final double reserveEnd;
  final ValueChanged<TreePosition> onSelect;
  final ValueChanged<int>? onReveal;

  @override
  State<_StripRow> createState() => _StripRowState();
}

class _StripRowState extends State<_StripRow> with TickerProviderStateMixin {
  /// Altura do bloco, centrado na linha de 48 (canvas v3).
  static const blockHeight = 28.0;

  /// Folga do bloco depois do fim do último lance coberto.
  static const blockPad = AppSpacing.sm;

  /// Dos lances de 0,6 da largura de onde vem o que desliza para fora.
  static const slideFrom = .6;

  /// O filete das alternativas: margem antes dele e largura; o respiro
  /// depois completa o [VariationStrip.branchIndent].
  static const branchMargin = 4.0;
  static const branchRule = 2.0;

  late final AnimationController _reveal = AnimationController(
    vsync: this,
    duration: AppMotion.reveal,
    value: 1,
  );
  late final AnimationController _fade = AnimationController(
    vsync: this,
    duration: AppMotion.state,
    value: widget.hideUnseen ? 1 : 0,
  );
  final _stack = GlobalKey();
  late List<GlobalKey> _buttonKeys;
  late List<GlobalKey> _textKeys;
  final _resultKey = GlobalKey();
  _Metrics? _metrics;
  int? _revealIndex;
  bool _measureQueued = false;

  @override
  void initState() {
    super.initState();
    _makeKeys();
  }

  void _makeKeys() {
    final count = widget.row.moves.length;
    _buttonKeys = List.generate(count, (_) => GlobalKey());
    _textKeys = List.generate(count, (_) => GlobalKey());
  }

  @override
  void didUpdateWidget(_StripRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.row.moves.length != widget.row.moves.length) _makeKeys();
    // Árvore, linha ou estilo novos: a medida antiga não vale, e nenhum quadro
    // pinta o bloco na posição de antes. (O destaque não move nada: o lance da
    // vez reserva a largura do negrito, ver `_MoveButton`.)
    if (_signature(oldWidget) != _signature(widget)) _metrics = null;
    final motion = AppMotion.of(context);
    if (oldWidget.hideUnseen != widget.hideUnseen) {
      final target = widget.hideUnseen ? 1.0 : 0.0;
      if (motion.disabled) {
        _fade.value = target;
      } else {
        _fade.animateTo(target, duration: motion.state);
      }
    }
    final event = widget.revealing;
    if (event != null && event != oldWidget.revealing && widget.hideUnseen) {
      final index = widget.row.moves.indexWhere(
        (move) => move.position == event.position,
      );
      if (index >= 0) {
        _revealIndex = index;
        if (motion.disabled) {
          _reveal.value = 1;
        } else {
          _reveal.forward(from: 0);
        }
      }
    }
  }

  static String _signature(_StripRow w) =>
      '${w.row.branch?.id}|${w.row.result}|${w.reserveEnd}|${w.style.hashCode}|'
      '${w.row.moves.map((m) => m.shown).join(' ')}';

  @override
  void dispose() {
    _reveal.dispose();
    _fade.dispose();
    super.dispose();
  }

  void _queueMeasure() {
    if (_measureQueued) return;
    _measureQueued = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _measureQueued = false;
      if (!mounted) return;
      final stack = _stack.currentContext?.findRenderObject();
      if (stack is! RenderBox || !stack.attached || !stack.hasSize) return;
      Rect? rectOf(GlobalKey key) {
        final box = key.currentContext?.findRenderObject();
        if (box is! RenderBox || !box.attached || !box.hasSize) return null;
        return box.localToGlobal(Offset.zero, ancestor: stack) & box.size;
      }

      final buttons = <Rect>[];
      final texts = <Rect>[];
      for (var i = 0; i < _buttonKeys.length; i++) {
        final button = rectOf(_buttonKeys[i]);
        final text = rectOf(_textKeys[i]);
        if (button == null || text == null) return;
        buttons.add(button);
        texts.add(text);
      }
      if (widget.row.result != null) {
        final result = rectOf(_resultKey);
        if (result == null) return;
        buttons.add(result);
        texts.add(result);
      }
      final next = _Metrics(buttons, texts);
      if (!next.sameAs(_metrics)) setState(() => _metrics = next);
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final branch = widget.row.branch;
    final wrap = AnimatedBuilder(
      animation: Listenable.merge([_reveal, _fade]),
      builder: (context, _) => LayoutBuilder(
        builder: (context, _) {
          _queueMeasure();
          return Stack(
            key: _stack,
            clipBehavior: Clip.none,
            children: [
              Padding(
                padding: EdgeInsetsDirectional.only(end: widget.reserveEnd),
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: _items(context, colors, l10n),
                ),
              ),
              ..._blocks(context),
            ],
          );
        },
      ),
    );
    if (branch == null) return wrap;
    final tree = widget.tree;
    final replaced = branch.at < tree.main.length
        ? tree.rows
              .expand((r) => r.moves)
              .firstWhere((m) => m.position == TreePosition.main(branch.at + 1))
              .label
        : '';
    return Semantics(
      container: true,
      label: l10n.lessonVariationAlternative(
        replaced.replaceFirst(RegExp(r'^\d+\.(?:\.\.)?'), ''),
      ),
      child: Container(
        key: LessonKeys.variationBranch(branch.id),
        margin: const EdgeInsetsDirectional.only(start: branchMargin),
        padding: const EdgeInsetsDirectional.only(
          start: VariationStrip.branchIndent - branchMargin - branchRule,
        ),
        decoration: BoxDecoration(
          border: BorderDirectional(
            start: BorderSide(color: colors.outlineVariant, width: branchRule),
          ),
        ),
        child: wrap,
      ),
    );
  }

  /// O lance já visto? (Fora do botão: com ele desligado todos aparecem.)
  bool _unseen(int moveIndex) =>
      !widget.revealed.contains(widget.row.moves[moveIndex].position);

  /// Opacidade de quem está coberto: some com o bloco que entra por cima.
  double _coveredOpacity() => 1 - _fade.value;

  List<Widget> _items(
    BuildContext context,
    ColorScheme colors,
    AppLocalizations l10n,
  ) {
    final row = widget.row;
    final branch = row.branch;
    final sliding = _reveal.isAnimating ? _revealIndex : null;
    final slide = AppMotion.revealCurve.transform(_reveal.value);
    return [
      for (final (i, move) in row.moves.indexed)
        _MoveButton(
          key: branch == null
              ? LessonKeys.variationMove(move.position.ply)
              : LessonKeys.variationBranchMove(branch.id, move.position.ply),
          buttonKey: _buttonKeys[i],
          textKey: _textKeys[i],
          shown: move.shown,
          state: widget.tree.stateOf(move.position, widget.current),
          branch: branch != null,
          style: widget.style,
          covered: _unseen(i) && widget.hideUnseen,
          opacity: _unseen(i) ? _coveredOpacity() : 1,
          slide: sliding == i ? slideFrom * (1 - slide) : 0,
          onTap: () => widget.onSelect(move.position),
        ),
      if (row.result case final result?)
        _resultItem(
          context,
          colors,
          l10n,
          result,
          branch!.id,
          sliding == row.moves.length - 1 ? slideFrom * (1 - slide) : 0,
        ),
    ];
  }

  /// O que desliza para fora junto com o lance revelado.
  static Widget _slid(double slide, Widget child) => slide > 0
      ? ClipRect(
          child: FractionalTranslation(
            translation: Offset(slide, 0),
            child: child,
          ),
        )
      : child;

  bool get _resultUnseen =>
      widget.row.moves.isNotEmpty && _unseen(widget.row.moves.length - 1);

  Widget _resultItem(
    BuildContext context,
    ColorScheme colors,
    AppLocalizations l10n,
    VariationResult result,
    String branchId,
    double slide,
  ) {
    final covered = _resultUnseen && widget.hideUnseen;
    return Opacity(
      opacity: _resultUnseen ? _coveredOpacity() : 1,
      child: ExcludeSemantics(
        excluding: covered,
        child: Semantics(
          label: switch (result) {
            VariationResult.draw => l10n.lessonLineResultDraw,
          },
          excludeSemantics: true,
          child: Padding(
            padding: const EdgeInsetsDirectional.only(start: 6),
            child: ConstrainedBox(
              key: _resultKey,
              constraints: const BoxConstraints(
                minHeight: VariationStrip.tapSize,
              ),
              child: Center(
                widthFactor: 1,
                child: _slid(
                  slide,
                  Text(
                    '\u2066${result.symbol}\u2069',
                    key: LessonKeys.variationResult(branchId),
                    style: widget.style.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Os blocos da linha: um por linha visual que tenha lance coberto.
  List<Widget> _blocks(BuildContext context) {
    final metrics = _metrics;
    final row = widget.row;
    final items = row.moves.length + (row.result == null ? 0 : 1);
    if (metrics == null ||
        metrics.buttons.length != items ||
        (!widget.hideUnseen && _fade.value == 0) ||
        row.moves.isEmpty) {
      return const [];
    }
    final last = row.moves.length - 1;
    bool covered(int i) => i < row.moves.length ? _unseen(i) : _unseen(last);
    final animated = _reveal.isAnimating ? _revealIndex : null;
    // O "=" sai junto com o último lance do ramo.
    final resultIndex = row.result == null ? -1 : row.moves.length;
    final animatedGroup = {
      ?animated,
      if (animated == last && resultIndex >= 0) resultIndex,
    };
    final t = AppMotion.revealCurve.transform(_reveal.value);
    // Agrupa os itens por linha visual (mesmo topo, a 1 dp).
    final lines = <List<int>>[];
    for (var i = 0; i < items; i++) {
      if (lines.isNotEmpty &&
          (metrics.buttons[lines.last.first].top - metrics.buttons[i].top)
                  .abs() <
              1) {
        lines.last.add(i);
      } else {
        lines.add([i]);
      }
    }
    final blocks = <Widget>[];
    var keyed = false;
    for (final line in lines) {
      final hidden = [
        for (final i in line)
          if (covered(i) || animatedGroup.contains(i)) i,
      ];
      if (hidden.isEmpty) continue;
      final first = hidden.first;
      final right =
          hidden.map((i) => metrics.texts[i].right).reduce(math.max) + blockPad;
      var left = metrics.texts[first].left;
      var opacity = 1.0;
      if (animated != null && first == animated) {
        final rest = hidden.where((i) => !animatedGroup.contains(i));
        final next = rest.isEmpty ? null : rest.first;
        final to = next == null ? right : metrics.texts[next].left;
        left = left + (to - left) * t;
        if (next == null) {
          opacity = ((right - left) / 16).clamp(0.0, 1.0);
        }
      }
      final width = math.max(0.0, right - left);
      if (width <= 0) continue;
      final center = metrics.buttons[first].center.dy;
      final hit = math.max(width, VariationStrip.tapSize);
      final block = Positioned(
        left: left,
        top: center - VariationStrip.tapSize / 2,
        width: hit,
        height: VariationStrip.tapSize,
        child: IgnorePointer(
          ignoring: !widget.hideUnseen,
          child: Opacity(
            opacity: opacity * _fade.value,
            child: Semantics(
              button: true,
              label: context.l10n.lessonHiddenMoves,
              onTapHint: context.l10n.lessonRevealNextMove,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => widget.onReveal?.call(widget.index),
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: _Grain(
                    boxKey: keyed
                        ? null
                        : LessonKeys.variationHiddenBlock(widget.index),
                    width: width,
                    height: blockHeight,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      keyed = true;
      blocks.add(block);
    }
    return blocks;
  }
}

/// Um lance da faixa: o alvo de toque de 48 dp; o da vez em destaque.
class _MoveButton extends StatelessWidget {
  const _MoveButton({
    required this.buttonKey,
    required this.textKey,
    required this.shown,
    required this.state,
    required this.branch,
    required this.style,
    required this.onTap,
    this.covered = false,
    this.opacity = 1,
    this.slide = 0,
    super.key,
  });

  final GlobalKey buttonKey;
  final GlobalKey textKey;
  final String shown;

  String _text(BuildContext context) => localizedSan(context.l10n, shown);
  final VariationMoveState state;
  final bool branch;
  final TextStyle style;
  final VoidCallback onTap;

  /// Coberto pelo bloco: sem toque e sem leitor de tela.
  final bool covered;
  final double opacity;

  /// Quanto do texto ainda falta deslizar (fração da largura), ao revelar.
  final double slide;

  double _reservedWidth(BuildContext context) {
    final painter = TextPainter(
      text: TextSpan(
        text: '\u2066${_text(context)}\u2069',
        style: style.copyWith(fontWeight: FontWeight.w600),
      ),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
    )..layout();
    final width = painter.width;
    painter.dispose();
    return width;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final current = state == VariationMoveState.current;
    final label = Text(
      // Notação isolada da direção do texto (RTL); o leitor de tela lê o
      // lance sem os caracteres de isolamento.
      '\u2066${_text(context)}\u2069',
      semanticsLabel: _text(context),
      key: current ? LessonKeys.variationStripCurrent : null,
      style: style.copyWith(
        color: current
            ? colors.primary
            : branch
            ? colors.onSurfaceVariant
            : colors.onSurface,
        fontWeight: current
            ? FontWeight.w600
            : branch
            ? FontWeight.w400
            : FontWeight.w500,
      ),
    );
    // O lance da vez (canvas T68, `.cur`): fundo com cantos de 4 que passa
    // 2 dp de cada lado do texto, sem mudar a posição dele.
    final text = DecoratedBox(
      decoration: BoxDecoration(
        color: current ? colors.primaryContainer : null,
        borderRadius: BorderRadius.circular(AppShape.tiny),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        // A medida do texto (o bloco e os 12 dp entre lances) é a dele, sem
        // a folga do fundo.
        child: KeyedSubtree(
          key: textKey,
          // Reserva a largura do negrito (o lance da vez): trocar o
          // destaque não move nenhum vizinho nem o bloco.
          // O deslize fica dentro da medida: a translação não pode entrar
          // no retângulo medido (localToGlobal aplica a transformação).
          child: SizedBox(
            width: _reservedWidth(context),
            child: _StripRowState._slid(slide, label),
          ),
        ),
      ),
    );
    return ExcludeSemantics(
      excluding: covered,
      child: IgnorePointer(
        ignoring: covered,
        child: Opacity(
          opacity: opacity,
          child: InkWell(
            key: buttonKey,
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppShape.small),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minWidth: VariationStrip.tapSize,
                minHeight: VariationStrip.tapSize,
              ),
              child: Padding(
                // (4 + 2) + (2 + 4): 12 dp entre os textos (T69, canvas v3);
                // os 2 de dentro são a folga do fundo do lance da vez.
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Center(widthFactor: 1, child: text),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

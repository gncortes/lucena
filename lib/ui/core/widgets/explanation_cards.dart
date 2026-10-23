import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lucena_ui/lucena_ui.dart';

import '../../../domain/models/explanation.dart';
import '../keys/explanation_keys.dart';
import '../l10n/l10n.dart';
import 'lesson_quote.dart';

typedef ExplanationParagraph = ({String text, ExplanationVariation? variation});

/// Shared presentation. All board updates are temporary view callbacks.
class ExplanationCards extends StatefulWidget {
  const ExplanationCards({
    required this.payload,
    this.lessonV2 = false,
    required this.paragraph,
    this.variationParagraph,
    this.groupedParagraph,
    this.hasInlineNavigation,
    this.onVariation,
    this.activeCursor,
    super.key,
  });
  final ExplanationPayload payload;
  final bool lessonV2;
  final VariationCursor? activeCursor;
  final Widget Function(String) paragraph;
  final Widget Function(String, ExplanationVariation?)? variationParagraph;
  final Widget Function(List<ExplanationParagraph>)? groupedParagraph;
  final bool Function(String, ExplanationVariation, ExplanationVariation?)?
  hasInlineNavigation;
  final ValueChanged<VariationCursor?>? onVariation;
  @override
  State<ExplanationCards> createState() => _ExplanationCardsState();
}

class _ExplanationCardsState extends State<ExplanationCards> {
  VariationCursor? _cursor;
  String? _unavailable;
  final Set<String> _expanded = {};
  Widget _paragraph(String text, [ExplanationVariation? variation]) =>
      widget.variationParagraph?.call(text, variation) ??
      widget.paragraph(text);

  List<ExplanationParagraph> _texts(ExplanationBlock block) {
    final roots = block.variations.where((v) => v.parentId == null).toList();
    final origin = roots.length == 1 ? roots.single : null;
    final selected = _cursor;
    final texts = <ExplanationParagraph>[
      for (final text in block.texts) (text: text, variation: origin),
      if (selected != null &&
          block.variations.any((v) => v.id == selected.variation.id))
        for (final text
            in widget.lessonV2
                ? selected.variation.explanationByPly[selected.ply] ??
                      const <String>[]
                : selected.texts)
          if (!block.texts.contains(text) ||
              origin?.id != selected.variation.id)
            (text: text, variation: selected.variation),
    ];
    final seen = <(String, String?)>{};
    return texts.where((p) => seen.add((p.text, p.variation?.id))).toList();
  }

  Widget _body(ExplanationBlock block) {
    final texts = _texts(block);
    return widget.groupedParagraph?.call(texts) ??
        _paragraph(
          texts.map((p) => p.text).join('\n\n'),
          texts.isNotEmpty &&
                  texts.every((p) => p.variation == texts.first.variation)
              ? texts.first.variation
              : null,
        );
  }

  bool _showSelector(ExplanationBlock block, ExplanationVariation variation) {
    if (RegExp(r'^[A-Z](?:\.\d+)*$').hasMatch(variation.label)) return true;
    // Keep the fallback control unless a verified inline move actually opens
    // this same origin. A matching caption alone is insufficient.
    return !_texts(block).any(
      (p) =>
          widget.hasInlineNavigation?.call(p.text, variation, p.variation) ==
          true,
    );
  }

  /// No `lessonV2` a seção começa pelo lance e o lance já é um link no
  /// parágrafo (de [block] ou da própria linha): não há linha só com o lance.
  bool _inlineMove(
    ExplanationBlock block,
    ExplanationVariation variation,
    List<String> own,
  ) {
    if (!widget.lessonV2 || widget.hasInlineNavigation == null) return false;
    return [..._texts(block).map((p) => p.text), ...own].any(
      (text) => widget.hasInlineNavigation!(text, variation, variation) == true,
    );
  }

  /// Linha principal que recolhe/expande: o chevron vai na primeira linha
  /// do parágrafo da seção (canvas `tentativa`), sem linha própria.
  ExplanationVariation? _chevronLine(ExplanationBlock block) {
    for (final v in block.variations) {
      if (v.parentId != null) continue;
      final own = v.texts.where((t) => !block.texts.contains(t)).toList();
      if (_children(block, v.id).isNotEmpty && _inlineMove(block, v, own)) {
        return v;
      }
    }
    return null;
  }

  VariationCursor? _verifiedCursor(VariationCursor? current) {
    if (current == null) return null;
    for (final node in widget.payload.variations) {
      if (node.id == current.variation.id &&
          node.contextId == current.variation.contextId &&
          node.parentId == current.variation.parentId &&
          node.parentPly == current.variation.parentPly &&
          node.originFen == current.variation.originFen &&
          listEquals(node.movesUci, current.variation.movesUci)) {
        return widget.payload.openVariation(node)?.at(current.ply);
      }
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _cursor = _verifiedCursor(widget.activeCursor);
    _revealCursor();
  }

  @override
  void didUpdateWidget(ExplanationCards old) {
    super.didUpdateWidget(old);
    if (old.activeCursor != widget.activeCursor) {
      _cursor = _verifiedCursor(widget.activeCursor);
      _revealCursor();
    }
    if (!identical(old.payload, widget.payload)) {
      _cursor = _verifiedCursor(_cursor);
      _unavailable = null;
      _expanded.removeWhere(
        (id) => !widget.payload.variations.any((v) => v.id == id),
      );
    }
  }

  void _revealCursor() {
    var node = _cursor?.variation;
    final seen = <String>{};
    while (node != null && seen.add(node.id)) {
      final parentId = node.parentId;
      if (parentId == null) break;
      _expanded.add(parentId);
      node = widget.payload.variations
          .where((v) => v.id == parentId)
          .firstOrNull;
    }
  }

  /// O lance azul do cabeçalho: abre a linha no tabuleiro ([onVariation]).
  /// Expandir ou recolher é só do chevron ([_toggle]).
  void _select(ExplanationVariation variation) {
    final cursor = widget.payload.openVariation(variation);
    setState(() {
      if (cursor == null) {
        _unavailable = variation.id;
      } else {
        _cursor = cursor;
        _unavailable = null;
      }
    });
    if (cursor != null) widget.onVariation?.call(cursor);
  }

  final _lineKeys = <String, GlobalKey>{};

  /// Abre ou fecha as respostas no lugar: não rola para o topo; se o card
  /// aberto passar da borda de baixo, rola só o necessário (A16).
  void _toggle(String id) {
    final opening = !_expanded.contains(id);
    setState(() {
      if (!_expanded.add(id)) _expanded.remove(id);
    });
    if (!opening) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final target = _lineKeys[id]?.currentContext;
      if (!mounted || target == null || !target.mounted) return;
      Scrollable.ensureVisible(
        target,
        duration: AppMotion.of(context).component,
        curve: AppMotion.enter,
        alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
      );
    });
  }

  void _move(VariationCursor? cursor) {
    setState(() => _cursor = cursor);
    widget.onVariation?.call(cursor);
  }

  String _title(BuildContext context, ExplanationKind kind) => switch (kind) {
    ExplanationKind.context => context.l10n.explanationContext,
    ExplanationKind.playedIncorrect =>
      widget.lessonV2
          ? context.l10n.lessonIncorrectMove
          : context.l10n.explanationPlayedIncorrect,
    ExplanationKind.playedCorrect =>
      widget.lessonV2
          ? context.l10n.lessonCorrectMove
          : context.l10n.explanationPlayedCorrect,
    ExplanationKind.mainSolution =>
      widget.lessonV2
          ? context.l10n.lessonCorrectMove
          : context.l10n.explanationMainSolution,
    ExplanationKind.otherSolutions => context.l10n.explanationOtherSolutions,
    ExplanationKind.failedAlternatives =>
      widget.lessonV2
          ? context.l10n.lessonFailedAlternatives
          : context.l10n.explanationFailedAlternatives,
  };
  String _outcome(BuildContext context, VariationOutcome outcome) =>
      switch (outcome) {
        VariationOutcome.accepted => context.l10n.explanationAccepted,
        VariationOutcome.losing => context.l10n.explanationLosing,
        VariationOutcome.doesNotMeetGoal =>
          context.l10n.explanationDoesNotMeetGoal,
      };
  List<ExplanationVariation> _children(ExplanationBlock block, String id) =>
      block.variations
          .where(
            (v) => v.parentId == id && widget.payload.openVariation(v) != null,
          )
          .toList();

  /// O lance do cabeçalho da linha: `primary` peso 500, sem sublinhado, mesmo
  /// com `?`/`!` (o símbolo carrega o resultado; LICOES-V2 §2). A letra só
  /// aparece com 2+ escolhas do aluno no mesmo ponto ([letter]).
  Widget _v2Title(
    BuildContext context,
    ExplanationVariation variation, {
    required bool letter,
  }) {
    final colors = Theme.of(context).colorScheme;
    final move = Text(
      variation.movesSan.first,
      style: TextStyle(fontWeight: FontWeight.w500, color: colors.primary),
    );
    if (!letter) return move;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '${variation.label}) ',
          style: TextStyle(fontWeight: FontWeight.w500, color: colors.tertiary),
        ),
        Flexible(child: move),
      ],
    );
  }

  /// O chevron das respostas: 48×48, só expande/recolhe (A15). A margem
  /// de −12 alinha o glifo à borda do texto, como no canvas (`tentativa`).
  Widget _chevron(
    BuildContext context,
    String id,
    bool expanded, {
    bool shifted = true,
  }) {
    final colors = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final label = expanded ? l10n.explanationCollapse : l10n.explanationExpand;
    final shift = !shifted
        ? 0.0
        : Directionality.of(context) == TextDirection.rtl
        ? -12.0
        : 12.0;
    return Transform.translate(
      offset: Offset(shift, 0),
      child: MergeSemantics(
        child: Semantics(
          expanded: expanded,
          child: IconButton(
            key: ExplanationKeys.expand(id),
            tooltip: label,
            style: IconButton.styleFrom(
              fixedSize: const Size(48, 48),
              minimumSize: const Size(48, 48),
            ),
            color: colors.onSurfaceVariant,
            onPressed: () => _toggle(id),
            icon: Icon(expanded ? Icons.expand_less : Icons.expand_more),
          ),
        ),
      ),
    );
  }

  Widget _line(
    BuildContext context,
    ExplanationBlock block,
    ExplanationVariation variation, {
    bool principal = true,
  }) {
    final children = _children(block, variation.id);
    final expandable = principal && children.isNotEmpty;
    final expanded = _expanded.contains(variation.id);
    final showText = !expandable || expanded;
    final selected = _cursor?.variation.id == variation.id;
    final texts = variation.texts
        .where((text) => !block.texts.contains(text))
        .toList();
    final inline = _inlineMove(block, variation, texts);
    final selector = !inline && _showSelector(block, variation);
    final labelled =
        variation.movesSan.isNotEmpty &&
        RegExp(r'^[A-Z](?:\.\d+)*$').hasMatch(variation.label);
    final letter =
        principal &&
        block.kind != ExplanationKind.failedAlternatives &&
        block.variations.where((v) => v.parentId == null).length > 1;
    // O lance fica destacado num lugar só: se o texto da linha já o cita, o
    // título não se repete (a linha expansível mantém o título: leva o chevron).
    final move = variation.movesSan.isEmpty
        ? null
        : variation.movesSan.first.replaceAll(RegExp(r'[?!+#]+$'), '');
    final cited =
        widget.lessonV2 &&
        !expandable &&
        move != null &&
        texts.any((t) => t.contains(move));
    final hasRow = !cited && (selector || (expandable && !inline));
    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (hasRow)
          Row(
            children: [
              Expanded(
                child: MergeSemantics(
                  child: Semantics(
                    selected: selected,
                    // Variante única (V2): o leitor lê só o lance, sem "A, ...".
                    label: widget.lessonV2 && principal && !letter
                        ? null
                        : '${variation.label}, ${variation.outcomeText ?? _outcome(context, variation.outcome)}',
                    child: Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: TextButton(
                        key: ExplanationKeys.variation(variation.id),
                        style: TextButton.styleFrom(
                          minimumSize: const Size(48, 48),
                          padding: EdgeInsets.zero,
                          alignment: AlignmentDirectional.centerStart,
                          tapTargetSize: MaterialTapTargetSize.padded,
                          textStyle: const TextStyle(
                            fontSize: 16,
                            height: 1.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        onPressed: widget.onVariation == null
                            ? null
                            : () => _select(variation),
                        child: widget.lessonV2 && labelled
                            ? _v2Title(context, variation, letter: letter)
                            : Text(
                                labelled
                                    ? principal
                                          ? '${variation.label}) ${variation.movesSan.first}'
                                          : variation.movesSan.first
                                    : variation.label,
                              ),
                      ),
                    ),
                  ),
                ),
              ),
              if (expandable) _chevron(context, variation.id, expanded),
            ],
          ),
        if (showText && texts.isNotEmpty)
          Padding(
            padding: EdgeInsets.zero,
            child: _paragraph(texts.join('\n\n'), variation),
          ),
      ],
    );
    // Canvas D14: full-width principal lines, with each child and its replies
    // grouped in one soft block. Ancestry stays in semantics, without a rail.
    final line = Column(
      key: expandable
          ? _lineKeys.putIfAbsent(variation.id, GlobalKey.new)
          : null,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        body,
        if (showText)
          for (final (i, child) in children.indexed)
            if (principal)
              Card(
                margin: EdgeInsets.only(top: i == 0 ? 0 : AppSpacing.sm),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: _line(context, block, child, principal: false),
                ),
              )
            else ...[
              const Divider(),
              _line(context, block, child, principal: false),
            ],
      ],
    );
    // Sem linha do lance e sem nada a mostrar: não ocupa espaço.
    final empty =
        inline && !(showText && (texts.isNotEmpty || children.isNotEmpty));
    if (empty) return const SizedBox.shrink();
    // Card da tentativa: colado ao parágrafo quando há linha de 48 dp (ela já
    // traz 12 dp de ar); 8 dp em cima quando o texto vem direto.
    return principal
        ? Padding(
            padding: EdgeInsets.only(top: hasRow ? 0 : AppSpacing.sm),
            child: line,
          )
        : line;
  }

  /// O contexto/história (citação): bloco de contexto com título que não é o
  /// "Lance certo" da folha do lance errado.
  bool _isQuote(BuildContext context, ExplanationBlock b) =>
      b.kind == ExplanationKind.context &&
      b.title.isNotEmpty &&
      b.title != context.l10n.lessonCorrectMove;

  /// Parágrafo de história: o que cita partida, jogador, torneio ou local
  /// (os nomes vêm marcados como link, `{{Nome|id}}`, no conteúdo).
  static final _historyMark = RegExp(r'\{\{[^{}|]+\|[^{}]+\}\}');

  /// Só o contexto histórico vai para a citação (LICOES-V2 §3). O objetivo e
  /// o ensino do bloco de contexto viram texto normal, no começo do painel;
  /// depois do lance do aluno (acerto ou erro) eles não se repetem.
  List<ExplanationBlock> _splitContext(
    BuildContext context,
    ExplanationPayload payload,
  ) {
    final answered =
        payload.state == ExplanationState.correct ||
        payload.state == ExplanationState.incorrect;
    return [
      for (final b in payload.explanations)
        if (!_isQuote(context, b))
          b
        else ...[
          if (!answered && b.texts.any((t) => !_historyMark.hasMatch(t)))
            ExplanationBlock(
              id: '${b.id}.plain',
              kind: b.kind,
              texts: [
                for (final t in b.texts)
                  if (!_historyMark.hasMatch(t)) t,
              ],
            ),
          if (b.texts.any(_historyMark.hasMatch) || b.variations.isNotEmpty)
            ExplanationBlock(
              id: b.id,
              kind: b.kind,
              title: b.title,
              texts: [
                for (final t in b.texts)
                  if (_historyMark.hasMatch(t)) t,
              ],
              variations: b.variations,
            ),
        ],
    ];
  }

  /// Ordem do canvas: erro (se houver) -> certo -> contexto/história (citação)
  /// -> "Também não funcionam". O resto segue a ordem do conteúdo.
  List<ExplanationBlock> _ordered(BuildContext context) {
    final all = _splitContext(context, widget.payload);
    final error = all.indexWhere(
      (b) => b.kind == ExplanationKind.playedIncorrect,
    );
    // Solução vista (LICOES-V2 §4): o payload já traz Lance certo -> lance
    // do aluno -> Também não funcionam; a ordem dele vale e a citação de
    // contexto vai por último.
    final right = all.indexWhere((b) => b.kind == ExplanationKind.mainSolution);
    final first = all.indexWhere((b) => !_isQuote(context, b));
    if (error >= 0 && right >= 0 && right == first && right < error) {
      return [
        ...all.where((b) => !_isQuote(context, b)),
        ...all.where((b) => _isQuote(context, b)),
      ];
    }
    return [
      ...all.where((b) => b.kind == ExplanationKind.playedIncorrect),
      ...all.where(
        (b) =>
            b.kind != ExplanationKind.playedIncorrect &&
            b.kind != ExplanationKind.failedAlternatives &&
            !_isQuote(context, b),
      ),
      ...all.where((b) => _isQuote(context, b)),
      ...all.where((b) => b.kind == ExplanationKind.failedAlternatives),
    ];
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.lessonV2) return _legacyBuild(context);
    final blocks = _ordered(context);
    final theme = Theme.of(context);
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (index, block) in blocks.indexed)
          Padding(
            key: ExplanationKeys.block(block.id),
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Entre ideias: 12 (o fim do bloco anterior) + linha + 12.
                if (index > 0) ...[
                  Divider(),
                  const SizedBox(height: AppSpacing.md),
                ],
                if (_isQuote(context, block))
                  LessonQuote(id: block.id, texts: block.texts)
                else ...[
                  if (_hasHeader(context, block))
                    Padding(
                      // Parágrafo logo abaixo: 8. Linha logo abaixo: ela mesma
                      // traz o ar (8 em cima do texto ou os 12 do botão de 48).
                      padding: EdgeInsets.only(
                        bottom: _texts(block).isNotEmpty ? AppSpacing.sm : 0,
                      ),
                      child: Text(
                        _label(context, block, rtl),
                        key: ExplanationKeys.header(block.id),
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontSize: 12,
                          height: 16 / 12,
                          fontWeight: FontWeight.w500,
                          letterSpacing: rtl ? 0 : 0.6,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  if (_texts(block).isNotEmpty) _paragraphWithChevron(block),
                  for (final variation in block.variations)
                    if (variation.parentId == null)
                      _line(context, block, variation),
                  if (_unavailable != null &&
                      block.variations.any((v) => v.id == _unavailable))
                    Text(
                      context.l10n.explanationUnavailable,
                      key: ExplanationKeys.unavailable,
                    ),
                ],
              ],
            ),
          ),
      ],
    );
  }

  Widget _paragraphWithChevron(ExplanationBlock block) {
    final line = _chevronLine(block);
    final body = Padding(
      key: ExplanationKeys.paragraph(block.id, 0),
      padding: line == null
          ? EdgeInsets.zero
          : const EdgeInsetsDirectional.only(end: 48),
      child: _body(block),
    );
    if (line == null) return body;
    // O chevron (48×48) fica na primeira linha, na coluna reservada à direita.
    return Stack(
      fit: StackFit.passthrough,
      children: [
        body,
        PositionedDirectional(
          end: 0,
          top: 0,
          child: _chevron(
            context,
            line.id,
            _expanded.contains(line.id),
            shifted: false,
          ),
        ),
      ],
    );
  }

  /// Rótulo da seção (V2): o contexto sem título e o título "A ideia
  /// principal" do asset não têm rótulo; o texto começa direto.
  bool _hasHeader(BuildContext context, ExplanationBlock block) {
    if (block.kind == ExplanationKind.context) return block.title.isNotEmpty;
    if (block.kind == ExplanationKind.mainSolution) {
      return block.title.isEmpty ||
          block.title == context.l10n.lessonCorrectMove;
    }
    return true;
  }

  /// O rótulo da seção: caixa alta, menos em árabe (sem caixa).
  String _label(BuildContext context, ExplanationBlock block, bool rtl) {
    final text =
        block.title.isEmpty || block.kind == ExplanationKind.failedAlternatives
        ? _title(context, block.kind)
        : block.title;
    return rtl ? text : text.toUpperCase();
  }

  Widget _legacyBuild(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final cursor = _cursor;
    // Old lessons supply only context, without authored sections. Preserve the
    // compact preview with one bubble per explanation.
    if (widget.payload.positionId.isEmpty &&
        widget.payload.explanations.every(
          (b) => b.kind == ExplanationKind.context,
        )) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final block in widget.payload.explanations)
            Padding(
              key: ExplanationKeys.paragraph(block.id, 0),
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _body(block),
            ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final block in widget.payload.explanations)
          Card(
            key: ExplanationKeys.block(block.id),
            margin: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    key: ExplanationKeys.header(block.id),
                    block.title.isEmpty
                        ? _title(context, block.kind)
                        : block.title,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  if (block.variations.isNotEmpty)
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: [
                        for (final variation in block.variations)
                          if ((variation.parentId == null ||
                                  variation.parentId == cursor?.variation.id ||
                                  variation.id == cursor?.variation.id) &&
                              _showSelector(block, variation))
                            Semantics(
                              selected: cursor?.variation.id == variation.id,
                              label:
                                  '${variation.label}, ${variation.outcomeText ?? _outcome(context, variation.outcome)}',
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  minHeight: 44,
                                  minWidth: 44,
                                ),
                                child: OutlinedButton(
                                  key: ExplanationKeys.variation(variation.id),
                                  style: OutlinedButton.styleFrom(
                                    minimumSize: const Size(44, 44),
                                    backgroundColor:
                                        cursor?.variation.id == variation.id
                                        ? colors.primaryContainer
                                        : null,
                                  ),
                                  onPressed: widget.onVariation == null
                                      ? null
                                      : () => _select(variation),
                                  child: Text(variation.label),
                                ),
                              ),
                            ),
                      ],
                    ),
                  if (_texts(block).isNotEmpty)
                    Padding(
                      key: ExplanationKeys.paragraph(block.id, 0),
                      padding: const EdgeInsets.only(top: AppSpacing.sm),
                      child: _body(block),
                    ),
                  if (_unavailable != null &&
                      block.variations.any((v) => v.id == _unavailable))
                    Text(
                      context.l10n.explanationUnavailable,
                      key: ExplanationKeys.unavailable,
                    ),
                  if (cursor != null &&
                      block.variations.any(
                        (v) => v.id == cursor.variation.id,
                      )) ...[
                    if (cursor.variation.parentId != null)
                      TextButton.icon(
                        key: ExplanationKeys.parent,
                        onPressed: () => _move(
                          widget.payload.parentCursor(cursor.variation),
                        ),
                        icon: const Icon(Icons.chevron_left),
                        label: Text(context.l10n.explanationParent),
                      ),
                    Text(
                      cursor.variation.outcomeText ??
                          _outcome(context, cursor.variation.outcome),
                    ),
                    if (cursor.moves.length > 1)
                      Wrap(
                        spacing: AppSpacing.xs,
                        children: [
                          IconButton(
                            key: ExplanationKeys.first,
                            tooltip: context.l10n.explanationFirst,
                            onPressed: cursor.canPrevious
                                ? () => _move(cursor.at(0))
                                : null,
                            icon: const Icon(Icons.first_page),
                          ),
                          IconButton(
                            key: ExplanationKeys.previous,
                            tooltip: context.l10n.explanationPrevious,
                            onPressed: cursor.canPrevious
                                ? () => _move(cursor.previous())
                                : null,
                            icon: const Icon(Icons.chevron_left),
                          ),
                          IconButton(
                            key: ExplanationKeys.next,
                            tooltip: context.l10n.explanationNext,
                            onPressed: cursor.canNext
                                ? () => _move(cursor.next())
                                : null,
                            icon: const Icon(Icons.chevron_right),
                          ),
                          IconButton(
                            key: ExplanationKeys.last,
                            tooltip: context.l10n.explanationLast,
                            onPressed: cursor.canNext
                                ? () => _move(cursor.at(cursor.moves.length))
                                : null,
                            icon: const Icon(Icons.last_page),
                          ),
                        ],
                      ),
                    TextButton.icon(
                      key: ExplanationKeys.restore,
                      onPressed: () => _move(null),
                      icon: const Icon(Icons.undo),
                      label: Text(context.l10n.explanationReturn),
                    ),
                  ],
                ],
              ),
            ),
          ),
      ],
    );
  }
}

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../domain/models/explanation.dart';
import '../keys/explanation_keys.dart';
import '../l10n/l10n.dart';

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

  void _select(ExplanationVariation variation) {
    final cursor = widget.payload.openVariation(variation);
    setState(() {
      if (cursor == null) {
        _unavailable = variation.id;
      } else {
        _cursor = cursor;
        _unavailable = null;
        if (widget.lessonV2 &&
            variation.parentId == null &&
            widget.payload.variations.any((v) => v.parentId == variation.id)) {
          if (!_expanded.add(variation.id)) _expanded.remove(variation.id);
        }
      }
    });
    if (cursor != null) widget.onVariation?.call(cursor);
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
    ExplanationKind.mainSolution => context.l10n.explanationMainSolution,
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

  Widget _line(
    BuildContext context,
    ExplanationBlock block,
    ExplanationVariation variation, {
    bool principal = true,
  }) {
    final colors = Theme.of(context).colorScheme;
    final children = _children(block, variation.id);
    final expandable = principal && children.isNotEmpty;
    final expanded = _expanded.contains(variation.id);
    final showText = !expandable || expanded;
    final selected = _cursor?.variation.id == variation.id;
    final texts = variation.texts
        .where((text) => !block.texts.contains(text))
        .toList();
    final selector = _showSelector(block, variation);
    final labelled =
        variation.movesSan.isNotEmpty &&
        RegExp(r'^[A-Z](?:\.\d+)*$').hasMatch(variation.label);
    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (selector || expandable)
          MergeSemantics(
            child: Semantics(
              selected: selected,
              expanded: expandable ? expanded : null,
              label:
                  '${variation.label}, ${variation.outcomeText ?? _outcome(context, variation.outcome)}',
              child: TextButton(
                key: ExplanationKeys.variation(variation.id),
                style: TextButton.styleFrom(
                  minimumSize: const Size(44, 44),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  alignment: AlignmentDirectional.centerStart,
                  backgroundColor: selected ? colors.primaryContainer : null,
                  textStyle: const TextStyle(
                    fontSize: 16,
                    height: 1.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                onPressed: widget.onVariation == null
                    ? null
                    : () => _select(variation),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        labelled
                            ? '${variation.label}) ${variation.movesSan.first}'
                            : variation.label,
                      ),
                    ),
                    if (expandable)
                      Icon(expanded ? Icons.expand_less : Icons.expand_more),
                  ],
                ),
              ),
            ),
          ),
        if (showText && texts.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _paragraph(texts.join('\n\n'), variation),
          ),
      ],
    );
    // Recursive data, flat presentation: every marker and every paragraph
    // stays in the same column regardless of ancestry depth.
    return Stack(
      children: [
        if (showText && children.isNotEmpty)
          PositionedDirectional(
            start: 9,
            top: 22,
            bottom: 0,
            width: 1,
            child: ColoredBox(color: colors.outlineVariant),
          ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 20,
                  height: 44,
                  child: Icon(
                    Icons.circle,
                    size: 8,
                    color: selected ? colors.primary : colors.outline,
                  ),
                ),
                Expanded(child: body),
              ],
            ),
            if (showText)
              for (final child in children)
                _line(context, block, child, principal: false),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.lessonV2) return _legacyBuild(context);
    final cursor = _cursor;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (index, block) in widget.payload.explanations.indexed)
          Padding(
            key: ExplanationKeys.block(block.id),
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (index > 0) const Divider(height: 16),
                if (block.kind != ExplanationKind.context ||
                    block.title.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      block.title.isEmpty
                          ? _title(context, block.kind)
                          : block.title,
                      key: ExplanationKeys.header(block.id),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontSize: 12,
                        height: 16 / 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                if (_texts(block).isNotEmpty)
                  Padding(
                    key: ExplanationKeys.paragraph(block.id, 0),
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _body(block),
                  ),
                for (final variation in block.variations)
                  if (variation.parentId == null)
                    _line(context, block, variation),
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
                      onPressed: () =>
                          _move(widget.payload.parentCursor(cursor.variation)),
                      icon: const Icon(Icons.chevron_left),
                      label: Text(context.l10n.explanationPrevious),
                    ),
                  Text(
                    cursor.variation.outcomeText ??
                        _outcome(context, cursor.variation.outcome),
                  ),
                  if (cursor.moves.length > 1)
                    Wrap(
                      spacing: 4,
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
      ],
    );
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
              padding: const EdgeInsets.only(bottom: 8),
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
            margin: const EdgeInsets.only(bottom: 8),
            child: Padding(
              padding: const EdgeInsets.all(12),
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
                      spacing: 8,
                      runSpacing: 8,
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
                      padding: const EdgeInsets.only(top: 8),
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
                        label: Text(context.l10n.explanationPrevious),
                      ),
                    Text(
                      cursor.variation.outcomeText ??
                          _outcome(context, cursor.variation.outcome),
                    ),
                    if (cursor.moves.length > 1)
                      Wrap(
                        spacing: 4,
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

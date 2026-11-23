import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/models/glossary_term.dart';
import '../../../domain/use_cases/glossary_search.dart';
import '../../../routing/routes.dart';

/// Um texto (a fala do balão) com os termos do Glossário sublinhados em
/// `primary`. Tocar um termo abre o Glossário filtrado por ele, com a
/// Wikipédia (ou a folha do termo, sem internet). Quem precisa pausar antes
/// (a aula em vídeo) passa [onOpen] e decide; sem ele, abre a rota.
class GlossaryText extends StatefulWidget {
  const GlossaryText(
    this.text, {
    required this.terms,
    this.style,
    this.onOpen,
    this.maxLines,
    super.key,
  });

  final String text;
  final List<GlossaryTerm> terms;
  final TextStyle? style;
  final int? maxLines;
  final ValueChanged<GlossaryTerm>? onOpen;

  /// Abre a rota do Glossário filtrada pelo termo (volta quando o usuário
  /// sai dela).
  static Future<void> open(BuildContext context, GlossaryTerm term) =>
      context.push(Routes.glossaryAt(query: term.name, term: term.id));

  @override
  State<GlossaryText> createState() => _GlossaryTextState();
}

class _GlossaryTextState extends State<GlossaryText> {
  final _recognizers = <TapGestureRecognizer>[];

  void _clear() {
    for (final recognizer in _recognizers) {
      recognizer.dispose();
    }
    _recognizers.clear();
  }

  TapGestureRecognizer _tap(GlossaryTerm term) {
    final recognizer = TapGestureRecognizer()
      ..onTap = () {
        final onOpen = widget.onOpen;
        if (onOpen != null) {
          onOpen(term);
        } else {
          GlossaryText.open(context, term);
        }
      };
    _recognizers.add(recognizer);
    return recognizer;
  }

  @override
  void dispose() {
    _clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _clear();
    final text = widget.text;
    final matches = GlossarySearch.find(text, widget.terms);
    if (matches.isEmpty) {
      return Text(text, style: widget.style, maxLines: widget.maxLines);
    }
    final colors = Theme.of(context).colorScheme;
    final termStyle = TextStyle(
      color: colors.primary,
      decoration: TextDecoration.underline,
      decorationColor: colors.primary,
    );
    var cursor = 0;
    final spans = <InlineSpan>[];
    for (final match in matches) {
      spans
        ..add(TextSpan(text: text.substring(cursor, match.start)))
        ..add(
          TextSpan(
            text: text.substring(match.start, match.end),
            style: termStyle,
            recognizer: _tap(match.term),
          ),
        );
      cursor = match.end;
    }
    spans.add(TextSpan(text: text.substring(cursor)));
    return Text.rich(
      TextSpan(children: spans),
      style: widget.style,
      maxLines: widget.maxLines,
    );
  }
}

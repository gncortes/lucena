import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../../domain/use_cases/wiki_markup.dart';
import '../../core/widgets/teacher_speech.dart';
import 'wiki_sheet.dart';

/// Um texto de aula fora do balão (a história, o treino final): os nomes
/// marcados (`{{Andersson|ulf-andersson}}`) com página na Wikipedia ficam
/// sublinhados e abrem a página num toque; os outros, texto normal.
class LinkedText extends StatefulWidget {
  const LinkedText(this.text, {this.style, super.key});

  final String text;
  final TextStyle? style;

  @override
  State<LinkedText> createState() => _LinkedTextState();
}

class _LinkedTextState extends State<LinkedText> {
  final _recognizers = <TapGestureRecognizer>[];

  void _clear() {
    for (final recognizer in _recognizers) {
      recognizer.dispose();
    }
    _recognizers.clear();
  }

  TapGestureRecognizer _tap(Uri url) {
    final recognizer = TapGestureRecognizer()
      ..onTap = () => showWikiPage(context, url);
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
    final marked = WikiMarkup.parse(widget.text);
    final text = marked.text;
    final language = Localizations.localeOf(context).languageCode;
    final wiki = TeacherSpeech.wikiOf(context);
    final pages = [
      for (final mark in marked.marks)
        if (wiki.url(mark.key, language) case final url?) (mark, url),
    ];
    if (pages.isEmpty) return Text(text, style: widget.style);
    final colors = Theme.of(context).colorScheme;
    final pageStyle = TextStyle(
      color: colors.primary,
      decoration: TextDecoration.underline,
      decorationColor: colors.primary,
    );
    return Text.rich(
      TextSpan(
        children: [
          for (final (index, (mark, url)) in pages.indexed) ...[
            TextSpan(
              text: text.substring(
                index == 0 ? 0 : pages[index - 1].$1.end,
                mark.start,
              ),
            ),
            TextSpan(text: mark.text, style: pageStyle, recognizer: _tap(url)),
          ],
          TextSpan(text: text.substring(pages.last.$1.end)),
        ],
      ),
      style: widget.style,
    );
  }
}

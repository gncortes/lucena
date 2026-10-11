/// Um nome marcado numa fala (`{{Andersson|ulf-andersson}}`): o texto que
/// aparece, a chave do link e a posição dele no texto sem a marcação.
class WikiMark {
  const WikiMark({
    required this.start,
    required this.end,
    required this.text,
    required this.key,
  });

  /// Do caractere [start] até antes de [end], no texto sem a marcação.
  final int start;
  final int end;
  final String text;

  /// A chave em `assets/lessons/links.json`.
  final String key;

  @override
  bool operator ==(Object other) =>
      other is WikiMark &&
      other.start == start &&
      other.end == end &&
      other.text == text &&
      other.key == key;

  @override
  int get hashCode => Object.hash(start, end, text, key);

  @override
  String toString() => 'WikiMark($text|$key @ $start)';
}

/// Uma fala já sem a marcação, com os nomes marcados.
class MarkedText {
  const MarkedText(this.text, this.marks);

  /// O texto como aparece e como a voz lê: só o texto visível.
  final String text;
  final List<WikiMark> marks;
}

/// A marcação dos nomes de jogadores e lugares nas falas das aulas:
/// `{{texto visível|chave}}`. A chave aponta a página da Wikipedia em
/// `assets/lessons/links.json`. Fora da tela que desenha o link (a voz, os
/// títulos, a cópia), só o texto visível.
abstract final class WikiMarkup {
  static final _mark = RegExp(r'\{\{([^{}|]+)\|([^{}|]+)\}\}');

  /// [text] sem a marcação e os nomes marcados, nas posições do texto limpo.
  static MarkedText parse(String text) {
    if (!text.contains('{{')) return MarkedText(text, const []);
    final out = StringBuffer();
    final marks = <WikiMark>[];
    var last = 0;
    for (final match in _mark.allMatches(text)) {
      out.write(text.substring(last, match.start));
      final visible = match[1]!;
      final start = out.length;
      out.write(visible);
      marks.add(
        WikiMark(
          start: start,
          end: out.length,
          text: visible,
          key: match[2]!.trim(),
        ),
      );
      last = match.end;
    }
    out.write(text.substring(last));
    return MarkedText(out.toString(), marks);
  }

  /// Só o texto visível.
  static String plain(String text) => parse(text).text;

  /// As chaves usadas em [text].
  static Iterable<String> keys(String text) =>
      parse(text).marks.map((mark) => mark.key);
}

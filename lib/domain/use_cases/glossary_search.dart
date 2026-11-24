import '../models/glossary_term.dart';

/// Um termo do Glossário achado num texto: onde começa e termina.
class GlossaryMatch {
  const GlossaryMatch(this.term, this.start, this.end);

  final GlossaryTerm term;
  final int start;
  final int end;
}

/// A busca do Glossário e os termos de uma fala, sem acento nem caixa:
/// "oposicao" acha "Oposição".
abstract final class GlossarySearch {
  /// Os termos cujo nome ou sinônimo contém [query]; busca vazia devolve
  /// todos.
  static List<GlossaryTerm> filter(List<GlossaryTerm> terms, String query) {
    final wanted = fold(query.trim());
    if (wanted.isEmpty) return terms;
    return [
      for (final term in terms)
        if ([
          term.name,
          ...term.synonyms,
        ].any((name) => fold(name).contains(wanted)))
          term,
    ];
  }

  /// Como o termo aparece numa fala: cada variante do nome, sem o
  /// parêntese ("ala do rei / ala da dama", "corte (do rei)" → "corte"),
  /// e os sinônimos.
  static List<String> forms(GlossaryTerm term) {
    final plain = term.name.replaceAll(RegExp(r'\s*\([^)]*\)'), '');
    return {
      for (final part in plain.split(RegExp(r'\s*/\s*|,\s*')))
        if (part.trim().isNotEmpty) part.trim(),
      for (final synonym in term.synonyms)
        if (synonym.trim().isNotEmpty) synonym.trim(),
    }.toList();
  }

  /// Os termos citados em [text], palavra inteira, sem sobreposição; o nome
  /// mais longo ganha ("Oposição distante" antes de "Oposição"). Aceita o
  /// plural simples com "s" ("xeques").
  static List<GlossaryMatch> find(String text, List<GlossaryTerm> terms) {
    final folded = fold(text);
    final byLength = [
      for (final term in terms)
        for (final form in forms(term)) (term: term, name: fold(form)),
    ]..sort((a, b) => b.name.length.compareTo(a.name.length));
    final found = <GlossaryMatch>[];
    bool free(int start, int end) =>
        found.every((m) => end <= m.start || start >= m.end);
    for (final (:term, :name) in byLength) {
      if (name.isEmpty) continue;
      var from = 0;
      while (true) {
        final start = folded.indexOf(name, from);
        if (start < 0) break;
        var end = start + name.length;
        if (end < folded.length && folded[end] == 's') end++;
        if (_boundary(folded, start - 1) &&
            _boundary(folded, end) &&
            free(start, end)) {
          found.add(GlossaryMatch(term, start, end));
        }
        from = start + 1;
      }
    }
    return found..sort((a, b) => a.start.compareTo(b.start));
  }

  static bool _boundary(String text, int index) =>
      index < 0 || index >= text.length || !_letter.hasMatch(text[index]);

  /// Minúsculas e sem acento, com o mesmo comprimento do original (os
  /// índices de [find] valem no texto original).
  static String fold(String text) {
    final out = StringBuffer();
    for (final char in text.toLowerCase().split('')) {
      out.write(_plain[char] ?? char);
    }
    return out.toString();
  }

  static final _letter = RegExp(r'[a-z0-9\-]');

  static const _plain = {
    'á': 'a', 'à': 'a', 'â': 'a', 'ã': 'a', 'ä': 'a', //
    'é': 'e', 'è': 'e', 'ê': 'e', 'ë': 'e', //
    'í': 'i', 'ì': 'i', 'î': 'i', 'ï': 'i', //
    'ó': 'o', 'ò': 'o', 'ô': 'o', 'õ': 'o', 'ö': 'o', //
    'ú': 'u', 'ù': 'u', 'û': 'u', 'ü': 'u', //
    'ç': 'c', 'ñ': 'n',
  };
}

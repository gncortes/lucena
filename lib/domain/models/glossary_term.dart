/// Um termo do Glossário (`assets/glossary/glossario.json`, gerado por
/// `tools/gen_glossario.py`): o nome, a definição curta e, quando há, o
/// verbete da Wikipédia (`chaveWiki` = "pt:Zugzwang").
class GlossaryTerm {
  const GlossaryTerm({
    required this.id,
    required this.name,
    required this.definition,
    this.wikiKey,
    this.synonyms = const [],
    this.note,
    this.lessons = const [],
  });

  final String id;
  final String name;
  final String definition;

  /// Outros nomes do termo ("peão passado afastado"): a busca e a fala casam.
  final List<String> synonyms;

  /// A curiosidade do termo (`nota`), quando há.
  final String? note;

  /// As aulas que usam o termo (`aulas`, ex. `endgames/basics.kingPawn`).
  final List<String> lessons;

  /// `<idioma>:<título do verbete>`; nula quando o termo não tem verbete.
  final String? wikiKey;

  /// A página do verbete (`https://pt.wikipedia.org/wiki/Zugzwang`).
  Uri? get wikiUrl {
    final key = wikiKey;
    if (key == null) return null;
    final split = key.indexOf(':');
    if (split <= 0 || split == key.length - 1) return null;
    final language = key.substring(0, split);
    final title = key.substring(split + 1);
    return Uri.https('$language.wikipedia.org', '/wiki/$title');
  }

  /// Lê `{"id", "nome", "definicao", "sinonimos"?, "nota"?, "chaveWiki"?,
  /// "aulas"?}`; nulo se faltar id, nome ou definição.
  static GlossaryTerm? fromJson(Object? json) {
    if (json is! Map<String, dynamic>) return null;
    final id = json['id'];
    final name = json['nome'];
    final definition = json['definicao'];
    final wiki = json['chaveWiki'];
    final note = json['nota'];
    if (id is! String || name is! String || definition is! String) return null;
    if (id.isEmpty || name.isEmpty || definition.isEmpty) return null;
    return GlossaryTerm(
      id: id,
      name: name,
      definition: definition,
      wikiKey: wiki is String && wiki.isNotEmpty ? wiki : null,
      synonyms: _strings(json['sinonimos']),
      note: note is String && note.isNotEmpty ? note : null,
      lessons: _strings(json['aulas']),
    );
  }

  static List<String> _strings(Object? list) {
    if (list is! List) return const [];
    return [
      for (final item in list)
        if (item is String && item.trim().isNotEmpty) item.trim(),
    ];
  }

  @override
  bool operator ==(Object other) =>
      other is GlossaryTerm &&
      other.id == id &&
      other.name == name &&
      other.definition == definition &&
      other.wikiKey == wikiKey &&
      other.note == note &&
      _same(other.synonyms, synonyms) &&
      _same(other.lessons, lessons);

  static bool _same(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    definition,
    wikiKey,
    note,
    Object.hashAll(synonyms),
    Object.hashAll(lessons),
  );
}

/// Um termo do Glossário (`assets/glossary/glossario.json`, gerado por
/// `tools/gen_glossario.py`): o nome, a definição curta e, quando há, o
/// verbete da Wikipédia (`chaveWiki` = "pt:Zugzwang").
class GlossaryTerm {
  const GlossaryTerm({
    required this.id,
    required this.name,
    required this.definition,
    this.wikiKey,
  });

  final String id;
  final String name;
  final String definition;

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

  /// Lê `{"id", "nome", "definicao", "chaveWiki"}`; nulo se faltar algo.
  static GlossaryTerm? fromJson(Object? json) {
    if (json is! Map<String, dynamic>) return null;
    final id = json['id'];
    final name = json['nome'];
    final definition = json['definicao'];
    final wiki = json['chaveWiki'];
    if (id is! String || name is! String || definition is! String) return null;
    if (id.isEmpty || name.isEmpty || definition.isEmpty) return null;
    return GlossaryTerm(
      id: id,
      name: name,
      definition: definition,
      wikiKey: wiki is String && wiki.isNotEmpty ? wiki : null,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is GlossaryTerm &&
      other.id == id &&
      other.name == name &&
      other.definition == definition &&
      other.wikiKey == wikiKey;

  @override
  int get hashCode => Object.hash(id, name, definition, wikiKey);
}

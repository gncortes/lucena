/// As páginas da Wikipedia dos nomes marcados nas falas, por chave e idioma.
class WikiLinks {
  const WikiLinks(this._urls);

  static const empty = WikiLinks({});

  /// Chave → idioma (`pt`, `en`) → endereço.
  final Map<String, Map<String, String>> _urls;

  Iterable<String> get keys => _urls.keys;

  bool contains(String key) => _urls.containsKey(key);

  /// A página de [key] em [language] ou, sem ela, em inglês. Nula se a chave
  /// não tem página: o nome fica como texto normal.
  Uri? url(String key, String language) {
    final urls = _urls[key];
    if (urls == null) return null;
    final code = language.split(RegExp('[-_]')).first.toLowerCase();
    final url = urls[code] ?? urls['en'];
    return url == null ? null : Uri.tryParse(url);
  }

  /// Lê `{"chave": {"pt": "https://...", "en": "https://..."}}`. O que não
  /// tem esse formato é ignorado.
  static WikiLinks fromJson(Object? json) {
    if (json is! Map<String, dynamic>) return empty;
    return WikiLinks({
      for (final MapEntry(:key, :value) in json.entries)
        if (value is Map<String, dynamic>)
          key: {
            for (final MapEntry(key: language, value: url) in value.entries)
              if (url is String && url.isNotEmpty) language: url,
          },
    });
  }
}

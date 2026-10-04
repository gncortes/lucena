/// Idiomas oferecidos em Configurações (Grupo 1 do plano), cada um com o
/// nome escrito no próprio idioma.
enum AppLanguage {
  english('en', 'English'),
  portugueseBrazil('pt', 'Português (Brasil)'),
  portuguesePortugal('pt_PT', 'Português (Portugal)'),
  spanish('es', 'Español'),
  french('fr', 'Français'),
  german('de', 'Deutsch'),
  italian('it', 'Italiano'),
  russian('ru', 'Русский'),
  ukrainian('uk', 'Українська'),
  polish('pl', 'Polski'),
  turkish('tr', 'Türkçe'),
  dutch('nl', 'Nederlands'),
  hindi('hi', 'हिन्दी'),
  arabic('ar', 'العربية'),
  persian('fa', 'فارسی'),
  chineseSimplified('zh', '简体中文'),
  japanese('ja', '日本語'),
  korean('ko', '한국어'),
  vietnamese('vi', 'Tiếng Việt'),
  indonesian('id', 'Bahasa Indonesia'),

  /// Pseudo-idioma que alonga os textos ~40%: só aparece nos testes.
  pseudo('en_XA', '[Pseudo-idioma longo]', testOnly: true);

  const AppLanguage(this.code, this.nativeName, {this.testOnly = false});

  /// Código salvo nas preferências e usado no nome do arquivo ARB.
  final String code;
  final String nativeName;
  final bool testOnly;

  /// Os idiomas que o usuário pode escolher.
  static List<AppLanguage> get selectable =>
      values.where((language) => !language.testOnly).toList();

  static AppLanguage? fromCode(String? code) {
    for (final language in values) {
      if (language.code == code) return language;
    }
    return null;
  }
}

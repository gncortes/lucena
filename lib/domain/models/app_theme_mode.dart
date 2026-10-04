/// Aparência do app: seguir o aparelho, sempre clara ou sempre escura.
enum AppThemeMode {
  system('system'),
  light('light'),
  dark('dark');

  const AppThemeMode(this.code);

  /// Código salvo nas preferências.
  final String code;

  /// Código desconhecido ou ausente volta a seguir o aparelho.
  static AppThemeMode fromCode(String? code) {
    for (final mode in values) {
      if (mode.code == code) return mode;
    }
    return system;
  }
}

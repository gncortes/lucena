import '../../../l10n/app_localizations.dart';
import 'country_names.dart';

/// Os países no idioma do app, em ordem alfabética (CLDR, E1.21).
abstract final class Countries {
  static Map<String, String> _names(AppLocalizations l10n) =>
      countryNames[l10n.localeName] ??
      countryNames[l10n.localeName.split('_').first] ??
      countryNames['en']!;

  /// Todos, em ordem alfabética do idioma: código ISO e nome.
  static Iterable<MapEntry<String, String>> all(AppLocalizations l10n) =>
      _names(l10n).entries;

  /// O nome do país; código desconhecido fica como veio.
  static String name(AppLocalizations l10n, String code) =>
      _names(l10n)[code.toUpperCase()] ?? code;

  /// Os que têm [query] no nome (sem acento nem maiúscula) ou no código.
  static Iterable<MapEntry<String, String>> search(
    AppLocalizations l10n,
    String query,
  ) {
    final wanted = _fold(query.trim());
    if (wanted.isEmpty) return all(l10n);
    return all(l10n).where(
      (country) =>
          _fold(country.value).contains(wanted) ||
          country.key.toLowerCase() == wanted,
    );
  }

  static const _plain = {
    'á': 'a', 'à': 'a', 'â': 'a', 'ã': 'a', 'ä': 'a', 'å': 'a', //
    'é': 'e', 'è': 'e', 'ê': 'e', 'ë': 'e', //
    'í': 'i', 'ì': 'i', 'î': 'i', 'ï': 'i', //
    'ó': 'o', 'ò': 'o', 'ô': 'o', 'õ': 'o', 'ö': 'o', 'ø': 'o', //
    'ú': 'u', 'ù': 'u', 'û': 'u', 'ü': 'u', //
    'ç': 'c', 'ñ': 'n', 'ý': 'y', 'ÿ': 'y', 'ś': 's', 'š': 's', 'ł': 'l',
  };

  static String _fold(String text) =>
      text.toLowerCase().split('').map((char) => _plain[char] ?? char).join();

  /// A bandeira em emoji, montada das duas letras do código.
  static String flag(String code) {
    final letters = code.toUpperCase();
    if (!RegExp(r'^[A-Z]{2}$').hasMatch(letters)) return '';
    const base = 0x1F1E6 - 0x41;
    return String.fromCharCodes(letters.codeUnits.map((c) => base + c));
  }
}

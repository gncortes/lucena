import '../models/user_profile.dart';

/// Validação dos campos do perfil.
abstract final class ProfileRules {
  static final _spaces = RegExp(r'\s+');

  /// Lê o rating digitado. Nulo se não for um número inteiro dentro da faixa.
  ///
  /// Aceita também os algarismos árabes e persas, que alguns teclados enviam.
  static int? parseRating(String text) {
    final value = int.tryParse(_asciiDigits(text.trim()));
    if (value == null) return null;
    if (value < UserProfile.minRating || value > UserProfile.maxRating) {
      return null;
    }
    return value;
  }

  /// O apelido como é gravado: sem espaços sobrando e dentro do tamanho máximo.
  /// Vazio quer dizer "usar o apelido padrão".
  static String cleanNickname(String text) {
    final clean = text.trim().replaceAll(_spaces, ' ');
    if (clean.length <= UserProfile.maxNicknameLength) return clean;
    return clean.substring(0, UserProfile.maxNicknameLength).trimRight();
  }

  static String _asciiDigits(String text) {
    final buffer = StringBuffer();
    for (final rune in text.runes) {
      if (rune >= 0x0660 && rune <= 0x0669) {
        buffer.writeCharCode(rune - 0x0660 + 0x30);
      } else if (rune >= 0x06F0 && rune <= 0x06F9) {
        buffer.writeCharCode(rune - 0x06F0 + 0x30);
      } else {
        buffer.writeCharCode(rune);
      }
    }
    return buffer.toString();
  }
}

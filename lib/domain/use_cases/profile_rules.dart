import '../models/user_profile.dart';

/// Validação dos campos do perfil.
abstract final class ProfileRules {
  static final _spaces = RegExp(r'\s+');

  /// O apelido como é gravado: sem espaços sobrando e dentro do tamanho máximo.
  /// Vazio quer dizer "usar o apelido padrão".
  static String cleanNickname(String text) {
    final clean = text.trim().replaceAll(_spaces, ' ');
    if (clean.length <= UserProfile.maxNicknameLength) return clean;
    return clean.substring(0, UserProfile.maxNicknameLength).trimRight();
  }
}

import 'json.dart';

/// Id do direito do treinador em `acessos/{uid}.cursos` (mesmo esquema dos
/// cursos; em dev o painel concede).
const coachGrantId = 'treinador';

/// De onde vêm as partidas.
enum Platform {
  lichess('lichess'),
  chesscom('chesscom');

  const Platform(this.wire);

  final String wire;

  static Platform? parse(Object? value) => byWire(values, (p) => p.wire, value);
}

/// `users/{uid}/treinador/conta`: a conta do Lichess ou do chess.com ligada.
final class CoachAccount {
  const CoachAccount({
    required this.platform,
    required this.username,
    this.linkedAt,
    this.lastFetch,
    this.modelGamesNotice = false,
  });

  final Platform platform;
  final String username;
  final DateTime? linkedAt;

  /// A última vez que o servidor buscou partidas novas.
  final DateTime? lastFetch;

  /// Quer o aviso das partidas-modelo (aba Seu jogo).
  final bool modelGamesNotice;

  static CoachAccount? fromJson(Object? json) {
    final m = asMap(json);
    final platform = Platform.parse(m['plataforma']);
    final username = text(m['usuario']);
    if (platform == null || username == null || username.isEmpty) return null;
    return CoachAccount(
      platform: platform,
      username: username,
      linkedAt: data(m['ligadaEm']),
      lastFetch: data(m['ultimaBusca']),
      modelGamesNotice: logical(m['avisoModelos']),
    );
  }

  Map<String, Object?> toJson() => {
    'plataforma': platform.wire,
    'usuario': username,
    if (linkedAt != null) 'ligadaEm': linkedAt!.toIso8601String(),
    if (lastFetch != null) 'ultimaBusca': lastFetch!.toIso8601String(),
    'avisoModelos': modelGamesNotice,
  };

  @override
  bool operator ==(Object other) =>
      other is CoachAccount &&
      other.platform == platform &&
      other.username == username &&
      other.linkedAt == linkedAt &&
      other.lastFetch == lastFetch &&
      other.modelGamesNotice == modelGamesNotice;

  @override
  int get hashCode =>
      Object.hash(platform, username, linkedAt, lastFetch, modelGamesNotice);
}

/// Por que a conta não ligou.
enum LinkAccountFailure {
  /// O usuário não existe na plataforma.
  doesNotExist,

  /// O Lichess/chess.com ou o servidor não responderam (ou sem rede).
  noResponse,

  /// A conta do Lucena não tem o direito `treinador`.
  noPlan,

  /// Precisa entrar numa conta do Lucena antes.
  noLogin,

  /// O login do Lichess não vale mais (token revogado ou expirado).
  lichessLogin,

  /// Passou do limite de tentativas de ligar do dia.
  tooMany,
}

final class LinkAccountException implements Exception {
  const LinkAccountException(this.failure);

  final LinkAccountFailure failure;

  @override
  String toString() => 'LigarContaException($failure)';
}

import 'json.dart';

/// Id do direito do treinador em `acessos/{uid}.cursos` (mesmo esquema dos
/// cursos; em dev o painel concede).
const treinadorGrantId = 'treinador';

/// De onde vêm as partidas.
enum Plataforma {
  lichess('lichess'),
  chesscom('chesscom');

  const Plataforma(this.wire);

  final String wire;

  static Plataforma? parse(Object? value) =>
      porWire(values, (p) => p.wire, value);
}

/// `users/{uid}/treinador/conta`: a conta do Lichess ou do chess.com ligada.
final class TreinadorConta {
  const TreinadorConta({
    required this.plataforma,
    required this.usuario,
    this.ligadaEm,
    this.ultimaBusca,
    this.avisoModelos = false,
  });

  final Plataforma plataforma;
  final String usuario;
  final DateTime? ligadaEm;

  /// A última vez que o servidor buscou partidas novas.
  final DateTime? ultimaBusca;

  /// Quer o aviso das partidas-modelo (aba Seu jogo).
  final bool avisoModelos;

  static TreinadorConta? fromJson(Object? json) {
    final m = mapa(json);
    final plataforma = Plataforma.parse(m['plataforma']);
    final usuario = texto(m['usuario']);
    if (plataforma == null || usuario == null || usuario.isEmpty) return null;
    return TreinadorConta(
      plataforma: plataforma,
      usuario: usuario,
      ligadaEm: data(m['ligadaEm']),
      ultimaBusca: data(m['ultimaBusca']),
      avisoModelos: logico(m['avisoModelos']),
    );
  }

  Map<String, Object?> toJson() => {
    'plataforma': plataforma.wire,
    'usuario': usuario,
    if (ligadaEm != null) 'ligadaEm': ligadaEm!.toIso8601String(),
    if (ultimaBusca != null) 'ultimaBusca': ultimaBusca!.toIso8601String(),
    'avisoModelos': avisoModelos,
  };

  @override
  bool operator ==(Object other) =>
      other is TreinadorConta &&
      other.plataforma == plataforma &&
      other.usuario == usuario &&
      other.ligadaEm == ligadaEm &&
      other.ultimaBusca == ultimaBusca &&
      other.avisoModelos == avisoModelos;

  @override
  int get hashCode =>
      Object.hash(plataforma, usuario, ligadaEm, ultimaBusca, avisoModelos);
}

/// Por que a conta não ligou.
enum FalhaLigarConta {
  /// O usuário não existe na plataforma.
  naoExiste,

  /// O Lichess/chess.com ou o servidor não responderam (ou sem rede).
  semResposta,

  /// A conta do Lucena não tem o direito `treinador`.
  semPlano,

  /// Precisa entrar numa conta do Lucena antes.
  semLogin,
}

final class LigarContaException implements Exception {
  const LigarContaException(this.falha);

  final FalhaLigarConta falha;

  @override
  String toString() => 'LigarContaException($falha)';
}

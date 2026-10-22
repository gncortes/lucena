import '../../../domain/models/platform_rating.dart';

/// Por que a conexão com o Lichess não terminou.
enum LichessFailure {
  /// A pessoa recusou na página do Lichess ou voltou sem autorizar.
  cancelled,

  /// Sem internet, navegador que não abriu ou resposta inesperada.
  network,
}

class LichessException implements Exception {
  const LichessException(this.failure);

  final LichessFailure failure;

  @override
  String toString() => 'LichessException(${failure.name})';
}

/// A conta do Lichess ligada ao Lucena (decisão 3b): login no site do
/// Lichess, token só no armazenamento seguro do aparelho.
abstract class LichessRepository {
  /// Abre o login no navegador e espera a volta. Lança [LichessException].
  Future<PlatformRating> connect();

  /// Desiste da conexão em andamento: [connect] lança `cancelled`.
  void cancel();

  /// O app abriu pela volta do Lichess, depois de ter sido fechado no
  /// navegador: termina aquela conexão. Nulo: não há volta pendente.
  /// Lança [LichessException].
  Future<PlatformRating?> resume();

  /// Lê os ratings de novo, com o token gravado. Lança [LichessException].
  Future<PlatformRating> account();

  /// A última leitura dos ratings (a do [connect] ou do [account]), para a
  /// folha do Perfil mostrar sem rede. Nulo: desconectado.
  Future<PlatformRating?> lastRead();

  /// Revoga o token no Lichess e apaga do aparelho.
  Future<void> disconnect();

  Future<bool> isConnected();
}

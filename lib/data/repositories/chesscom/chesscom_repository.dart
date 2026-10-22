import '../../../domain/models/platform_rating.dart';

enum ChessComFailure {
  /// O usuário não existe ou não tem rating de bullet, blitz nem rápidas.
  notFound,

  /// Sem internet ou resposta inesperada.
  network,
}

class ChessComException implements Exception {
  const ChessComException(this.failure);

  final ChessComFailure failure;

  @override
  String toString() => 'ChessComException(${failure.name})';
}

/// O rating público de um usuário do Chess.com.
abstract class ChessComRepository {
  /// Lança [ChessComException].
  Future<PlatformRating> stats(String user);
}

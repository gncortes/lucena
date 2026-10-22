import 'package:lucena/data/repositories/chesscom/chesscom_repository.dart';
import 'package:lucena/domain/models/platform_rating.dart';

/// Um Chess.com com os usuários que o teste mandar.
class FakeChessComRepository implements ChessComRepository {
  FakeChessComRepository({
    Map<String, PlatformRating>? users,
    this.offline = false,
  }) : users = users ?? {};

  final Map<String, PlatformRating> users;
  bool offline;

  @override
  Future<PlatformRating> stats(String user) async {
    if (offline) throw const ChessComException(ChessComFailure.network);
    final rating = users[user.trim().toLowerCase()];
    if (rating == null) throw const ChessComException(ChessComFailure.notFound);
    return rating;
  }
}

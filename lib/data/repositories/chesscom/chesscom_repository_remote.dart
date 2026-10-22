import '../../../domain/models/platform_rating.dart';
import '../../../domain/use_cases/now.dart';
import '../../services/chesscom_service.dart';
import 'chesscom_repository.dart';

class RemoteChessComRepository implements ChessComRepository {
  RemoteChessComRepository(this._service, {required this._now});

  final ChessComService _service;
  final Now _now;

  @override
  Future<PlatformRating> stats(String user) async {
    final Map<String, Object?>? json;
    try {
      json = await _service.stats(user.trim());
    } on ChessComServiceException {
      throw const ChessComException(ChessComFailure.network);
    }
    if (json == null) throw const ChessComException(ChessComFailure.notFound);
    final rating = parseStats(user.trim(), json, _now());
    if (rating.main == null) {
      throw const ChessComException(ChessComFailure.notFound);
    }
    return rating;
  }

  /// A resposta de `/stats`: `chess_blitz.last.rating` e as partidas de
  /// `record` (vitórias, derrotas e empates).
  static PlatformRating parseStats(
    String user,
    Map<String, Object?> json,
    DateTime now,
  ) {
    ModeRating? mode(String name) {
      final stats = json[name];
      if (stats is! Map) return null;
      final last = stats['last'];
      final rating = last is Map ? last['rating'] : null;
      if (rating is! num) return null;
      final record = stats['record'];
      var games = 0;
      if (record is Map) {
        for (final key in const ['win', 'loss', 'draw']) {
          final count = record[key];
          if (count is num) games += count.toInt();
        }
      }
      return ModeRating(rating: rating.round(), games: games);
    }

    return PlatformRating(
      user: user,
      readAt: now,
      bullet: mode('chess_bullet'),
      blitz: mode('chess_blitz'),
      rapid: mode('chess_rapid'),
    );
  }
}

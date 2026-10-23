/// O rating de um modo de jogo num site (Lichess ou Chess.com).
class ModeRating {
  const ModeRating({
    required this.rating,
    required this.games,
    this.provisional = false,
  });

  final int rating;
  final int games;

  /// Poucas partidas: o site marca o rating com "?".
  final bool provisional;

  @override
  bool operator ==(Object other) =>
      other is ModeRating &&
      other.rating == rating &&
      other.games == games &&
      other.provisional == provisional;

  @override
  int get hashCode => Object.hash(rating, games, provisional);
}

/// Os ratings lidos de uma conta do Lichess ou do Chess.com. Um modo sem
/// partidas fica nulo.
class PlatformRating {
  const PlatformRating({
    required this.user,
    required this.readAt,
    this.bullet,
    this.blitz,
    this.rapid,
  });

  /// O nome do usuário como o site escreve.
  final String user;
  final DateTime readAt;
  final ModeRating? bullet;
  final ModeRating? blitz;
  final ModeRating? rapid;

  /// O modo que vale para o Lucena: o blitz, depois o rápido e o bullet; um
  /// rating firme ganha de um provisório. Nulo sem nenhum modo.
  RatingMode? get mainMode {
    final modes = [
      if (blitz != null) RatingMode.blitz,
      if (rapid != null) RatingMode.rapid,
      if (bullet != null) RatingMode.bullet,
    ];
    for (final mode in modes) {
      if (!of(mode)!.provisional) return mode;
    }
    return modes.firstOrNull;
  }

  ModeRating? get main => switch (mainMode) {
    final mode? => of(mode),
    null => null,
  };

  ModeRating? of(RatingMode mode) => switch (mode) {
    RatingMode.bullet => bullet,
    RatingMode.blitz => blitz,
    RatingMode.rapid => rapid,
  };

  @override
  bool operator ==(Object other) =>
      other is PlatformRating &&
      other.user == user &&
      other.readAt == readAt &&
      other.bullet == bullet &&
      other.blitz == blitz &&
      other.rapid == rapid;

  @override
  int get hashCode => Object.hash(user, readAt, bullet, blitz, rapid);
}

enum RatingMode { bullet, blitz, rapid }

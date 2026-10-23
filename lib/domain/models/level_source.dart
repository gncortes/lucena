/// De onde veio o rating do jogador: o que ele aceitou em "Seu nível".
enum LevelSource {
  /// O resultado do teste de nível.
  test,

  /// Lido da conta do Lichess (login pelo site do Lichess).
  lichess,

  /// Lido do rating público do Chess.com.
  chesscom,

  /// O número que a pessoa informou.
  manual,

  /// "Não sei jogar, quero aprender do zero".
  zero;

  static LevelSource? fromCode(Object? code) => values.asNameMap()[code];
}

/// A origem do número informado à mão em "Informar o meu rating".
enum RatingOrigin {
  lichess,
  chesscom,
  fide,
  cbx,

  /// "Não sei".
  unknown;

  static RatingOrigin? fromCode(Object? code) => values.asNameMap()[code];
}

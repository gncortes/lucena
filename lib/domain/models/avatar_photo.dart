/// O que aparece no avatar do jogador (§2.12).
enum AvatarPhoto {
  /// A inicial do nome, na cor escolhida.
  none,

  /// A foto da conta do Google.
  google,

  /// A foto que a pessoa tirou ou escolheu, no Firebase Storage.
  upload;

  static AvatarPhoto fromCode(Object? code) => values.asNameMap()[code] ?? none;
}

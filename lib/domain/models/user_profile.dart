import 'package:freezed_annotation/freezed_annotation.dart';

import 'goal_preference.dart';
import 'level_source.dart';
import 'rating_level.dart';

part 'user_profile.freezed.dart';

/// Perfil do jogador, gravado no aparelho. Com conta, ele também sobe para a
/// nuvem (E1.13), mas a fonte da verdade continua sendo o aparelho.
@freezed
abstract class UserProfile with _$UserProfile {
  const factory UserProfile({
    /// Apelido escolhido. Vazio usa o apelido padrão, traduzido na tela.
    @Default('') String nickname,

    /// Rating aproximado: o da faixa que o jogador escolheu.
    @Default(UserProfile.defaultRating) int rating,

    /// O objetivo escolhido na primeira abertura. Nulo: quem já usava o app
    /// antes da pergunta (a tela inicial fica como era).
    GoalPreference? goal,

    /// De onde veio o [rating]. Nulo: quem já usava o app antes de "Seu
    /// nível".
    LevelSource? levelSource,

    /// O usuário do Lichess conectado (o token fica só no armazenamento
    /// seguro do aparelho, nunca aqui).
    String? lichessUser,

    /// O usuário do Chess.com informado em "Seu nível".
    String? chessComUser,

    /// A cor do avatar (índice em [avatarColors]), com a inicial do nome.
    @Default(0) int avatarColor,

    /// O avatar é a foto da conta do Google, no lugar da inicial.
    @Default(false) bool googlePhoto,

    /// O país (código ISO, como `BR`): vem da região do celular, sem
    /// seletor. Nulo: o celular não informou.
    String? country,
  }) = _UserProfile;

  const UserProfile._();

  /// Quem ainda não escolheu entra como jogador casual.
  static const defaultRating = 1150;
  static const maxNicknameLength = 20;

  /// Quantas cores de avatar existem (as cores ficam no tema da tela).
  static const avatarColors = 5;

  /// A faixa de rating do jogador.
  RatingLevel get level => RatingLevel.of(rating);
}

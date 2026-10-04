import 'package:freezed_annotation/freezed_annotation.dart';

import 'rating_level.dart';

part 'user_profile.freezed.dart';

/// Perfil local do jogador. Não sai do aparelho.
@freezed
abstract class UserProfile with _$UserProfile {
  const factory UserProfile({
    /// Apelido escolhido. Vazio usa o apelido padrão, traduzido na tela.
    @Default('') String nickname,

    /// Rating aproximado: o da faixa que o jogador escolheu.
    @Default(UserProfile.defaultRating) int rating,
  }) = _UserProfile;

  const UserProfile._();

  /// Quem ainda não escolheu entra como jogador casual.
  static const defaultRating = 1150;
  static const maxNicknameLength = 20;

  /// A faixa de rating do jogador.
  RatingLevel get level => RatingLevel.of(rating);
}

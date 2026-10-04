import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_profile.freezed.dart';

/// Perfil local do jogador. Não sai do aparelho.
@freezed
abstract class UserProfile with _$UserProfile {
  const factory UserProfile({
    /// Apelido escolhido. Vazio usa o apelido padrão, traduzido na tela.
    @Default('') String nickname,

    /// Rating aproximado, informado pelo próprio jogador.
    @Default(UserProfile.defaultRating) int rating,
  }) = _UserProfile;

  static const minRating = 100;
  static const maxRating = 3500;
  static const defaultRating = 1200;
  static const maxNicknameLength = 20;
}

import 'package:freezed_annotation/freezed_annotation.dart';

import 'avatar_photo.dart';
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

    /// Quando o [lichessUser] foi ligado ao Lucena (sobe com a conta, para
    /// medir quem tem conta e Lichess vinculados). Nulo: sem Lichess.
    DateTime? lichessLinkedAt,

    /// O usuário do Chess.com informado em "Seu nível".
    String? chessComUser,

    /// A cor do avatar (índice em [avatarColors]), com a inicial do nome.
    @Default(0) int avatarColor,

    /// A foto no lugar da inicial: a do Google ou a enviada (§2.12).
    @Default(AvatarPhoto.none) AvatarPhoto photo,

    /// O endereço da foto enviada ([AvatarPhoto.upload]).
    String? photoUrl,

    /// O país (código ISO, como `BR`): vem da região do celular e a pessoa
    /// troca em "Seu país". Nulo: o celular não informou.
    String? country,

    /// O estado, opcional (E1.21). No Brasil é a sigla (`PR`), que também
    /// escolhe o tópico de torneios; nos outros países, o que a pessoa
    /// escreveu.
    String? state,

    /// A cidade, opcional, como a pessoa escreveu.
    String? city,
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

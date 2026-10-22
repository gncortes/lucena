import 'package:flutter/widgets.dart';

import '../../../domain/models/rating_level.dart';

abstract final class ProfileKeys {
  /// Abre o teste de nível (T52).
  static const placementTest = Key('profile.placementTest');

  static const screen = Key('profile.screen');
  static const nicknameField = Key('profile.nickname');
  static const saveButton = Key('profile.save');

  /// Campo que mostra a faixa de rating e abre o painel de escolha.
  static const levelField = Key('profile.level');
  static const levelName = Key('profile.level.name');

  static const levelSheet = Key('profile.level.sheet');
  static const levelConfirmButton = Key('profile.level.confirm');

  /// Opção de uma faixa no painel de escolha; só vale depois de confirmar.
  static Key levelOption(RatingLevel level) =>
      Key('profile.level.option.${level.name}');

  /// O rating de finais: o cartão, o número, quantas partidas e a curva.
  static const ratingCard = Key('profile.rating');
}

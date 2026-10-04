import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../domain/models/user_profile.dart';

part 'profile_state.freezed.dart';

@freezed
abstract class ProfileState with _$ProfileState {
  const factory ProfileState({
    /// O perfil gravado. Nulo até a primeira leitura terminar.
    UserProfile? profile,

    /// A última tentativa de salvar tinha um rating fora da faixa.
    @Default(false) bool ratingInvalid,
  }) = _ProfileState;
}

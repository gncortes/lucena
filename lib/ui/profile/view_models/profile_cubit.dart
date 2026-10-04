import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/profile/profile_repository.dart';
import '../../../domain/models/user_profile.dart';
import '../../../domain/use_cases/profile_rules.dart';
import 'profile_state.dart';

export 'profile_state.dart';

/// Perfil do jogador: leitura, validação e gravação.
class ProfileCubit extends Cubit<ProfileState> {
  ProfileCubit(this._repository) : super(const ProfileState());

  final ProfileRepository _repository;

  Future<void> load() async {
    emit(state.copyWith(profile: await _repository.load()));
  }

  /// Valida o que foi digitado e grava. Devolve se gravou; com rating fora da
  /// faixa, nada é gravado e o estado passa a apontar o erro.
  Future<bool> save({required String nickname, required String rating}) async {
    final parsedRating = ProfileRules.parseRating(rating);
    if (parsedRating == null) {
      emit(state.copyWith(ratingInvalid: true));
      return false;
    }
    final profile = UserProfile(
      nickname: ProfileRules.cleanNickname(nickname),
      rating: parsedRating,
    );
    await _repository.save(profile);
    emit(ProfileState(profile: profile));
    return true;
  }

  /// O erro some quando o jogador volta a editar ou sai da tela.
  void clearError() {
    if (state.ratingInvalid) emit(state.copyWith(ratingInvalid: false));
  }
}

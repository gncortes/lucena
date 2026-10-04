import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/profile/profile_repository.dart';
import '../../../domain/models/rating_level.dart';
import '../../../domain/models/user_profile.dart';
import '../../../domain/use_cases/profile_rules.dart';

/// Perfil do jogador. O estado é nulo até a primeira leitura terminar.
class ProfileCubit extends Cubit<UserProfile?> {
  ProfileCubit(this._repository) : super(null);

  final ProfileRepository _repository;

  Future<void> load() async => emit(await _repository.load());

  /// Grava o apelido digitado (já limpo) e o rating da faixa escolhida.
  Future<void> save({
    required String nickname,
    required RatingLevel level,
  }) async {
    final profile = UserProfile(
      nickname: ProfileRules.cleanNickname(nickname),
      rating: level.rating,
    );
    await _repository.save(profile);
    emit(profile);
  }
}

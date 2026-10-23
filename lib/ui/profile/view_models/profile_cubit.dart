import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/profile/profile_repository.dart';
import '../../../domain/models/avatar_photo.dart';
import '../../../domain/models/goal_preference.dart';
import '../../../domain/models/user_profile.dart';
import '../../../domain/use_cases/profile_rules.dart';

/// Perfil do jogador. O estado é nulo até a primeira leitura terminar.
class ProfileCubit extends Cubit<UserProfile?> {
  /// [region] é a região do celular (código ISO, como `BR`): sem país
  /// gravado, o perfil fica com ela (regra 17).
  ProfileCubit(this._repository, {this._region}) : super(null);

  final ProfileRepository _repository;
  final String? Function()? _region;

  /// O país da região do celular, se ele informar.
  String? get phoneCountry {
    final region = _region?.call();
    return region == null || region.isEmpty ? null : region.toUpperCase();
  }

  Future<void> load() async {
    var profile = await _repository.load();
    final region = _region?.call();
    if (profile.country == null && region != null && region.isNotEmpty) {
      profile = profile.copyWith(country: region.toUpperCase());
      await _repository.save(profile);
    }
    emit(profile);
  }

  /// "Seus dados": o apelido (já limpo) e o avatar. O resto fica.
  Future<void> saveData({
    required String nickname,
    required int avatarColor,
    AvatarPhoto photo = AvatarPhoto.none,
    String? photoUrl,
  }) async {
    final profile = (await _repository.load()).copyWith(
      nickname: ProfileRules.cleanNickname(nickname),
      avatarColor: avatarColor.clamp(0, UserProfile.avatarColors - 1),
      photo: photo,
      photoUrl: photo == AvatarPhoto.upload ? photoUrl : null,
    );
    await _repository.save(profile);
    emit(profile);
  }

  /// "Seu país": troca o país. Estado e cidade eram do país antigo e saem.
  Future<void> setCountry(String country) async {
    final current = await _repository.load();
    final code = country.toUpperCase();
    if (current.country == code) return emit(current);
    final profile = current.copyWith(country: code, state: null, city: null);
    await _repository.save(profile);
    emit(profile);
  }

  /// A folha "Estado e cidade" (E1.21). Campo vazio apaga.
  Future<void> setRegion({String? state, String? city}) async {
    String? clean(String? text) {
      final trimmed = text?.trim();
      return trimmed == null || trimmed.isEmpty ? null : trimmed;
    }

    final profile = (await _repository.load()).copyWith(
      state: clean(state),
      city: clean(city),
    );
    await _repository.save(profile);
    emit(profile);
  }

  /// Troca o objetivo na hora (a folha do Perfil tem o próprio "Salvar").
  Future<void> setGoal(GoalPreference goal) async {
    final profile = (await _repository.load()).copyWith(goal: goal);
    await _repository.save(profile);
    emit(profile);
  }
}

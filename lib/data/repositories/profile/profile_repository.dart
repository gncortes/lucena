import '../../../domain/models/user_profile.dart';

/// Fonte da verdade do perfil do jogador.
abstract class ProfileRepository {
  Future<UserProfile> load();

  Future<void> save(UserProfile profile);
}

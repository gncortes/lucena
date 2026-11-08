import '../../../domain/models/user_profile.dart';

/// Fonte da verdade do perfil do jogador.
abstract class ProfileRepository {
  Future<UserProfile> load();

  Future<void> save(UserProfile profile);

  /// Cada perfil gravado, na hora. Quem guarda o perfil em memória (o
  /// `ProfileCubit`) acompanha as gravações feitas por outras telas, como o
  /// tour, sem esperar o app reabrir.
  Stream<UserProfile> get changes;
}

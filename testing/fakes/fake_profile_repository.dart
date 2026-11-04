import 'dart:async';

import 'package:lucena/data/repositories/profile/profile_repository.dart';
import 'package:lucena/domain/models/user_profile.dart';

/// Perfil só na memória. [saved] guarda tudo o que foi gravado, em ordem.
class FakeProfileRepository implements ProfileRepository {
  FakeProfileRepository([this.profile = const UserProfile()]);

  UserProfile profile;
  final saved = <UserProfile>[];

  /// Segura a leitura até completar.
  Completer<void>? loadGate;

  @override
  Future<UserProfile> load() async {
    await loadGate?.future;
    return profile;
  }

  @override
  Future<void> save(UserProfile profile) async {
    this.profile = profile;
    saved.add(profile);
  }
}

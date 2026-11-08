import 'dart:async';

import 'package:lucena/data/repositories/profile/profile_repository.dart';
import 'package:lucena/domain/models/user_profile.dart';

/// Perfil só na memória. [saved] guarda tudo o que foi gravado, em ordem.
class FakeProfileRepository implements ProfileRepository {
  FakeProfileRepository([this.profile = const UserProfile()]);

  UserProfile profile;
  final saved = <UserProfile>[];
  final _changes = StreamController<UserProfile>.broadcast();

  @override
  Stream<UserProfile> get changes => _changes.stream;

  /// Segura a leitura até completar.
  Completer<void>? loadGate;

  /// A próxima gravação falha (uma vez).
  bool failNextSave = false;

  @override
  Future<UserProfile> load() async {
    await loadGate?.future;
    return profile;
  }

  @override
  Future<void> save(UserProfile profile) async {
    if (failNextSave) {
      failNextSave = false;
      throw StateError('save failed');
    }
    this.profile = profile;
    saved.add(profile);
    _changes.add(profile);
  }
}

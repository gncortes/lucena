import 'package:drift/drift.dart';

import '../../../domain/models/user_profile.dart';
import '../../services/database/app_database.dart';
import 'profile_repository.dart';

/// Perfil gravado no banco local.
class LocalProfileRepository implements ProfileRepository {
  LocalProfileRepository(this._database);

  // O app tem um perfil só: sempre a mesma linha.
  static const _rowId = 1;

  final AppDatabase _database;

  @override
  Future<UserProfile> load() async {
    final query = _database.select(_database.profiles)
      ..where((profile) => profile.id.equals(_rowId));
    final row = await query.getSingleOrNull();
    if (row == null) return const UserProfile();
    return UserProfile(nickname: row.nickname, rating: row.rating);
  }

  @override
  Future<void> save(UserProfile profile) async {
    await _database
        .into(_database.profiles)
        .insertOnConflictUpdate(
          ProfilesCompanion.insert(
            id: const Value(_rowId),
            nickname: profile.nickname,
            rating: profile.rating,
          ),
        );
  }
}

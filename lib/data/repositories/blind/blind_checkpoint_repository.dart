import 'dart:convert';

import '../../../domain/models/blind_checkpoint.dart';
import '../../services/preferences_service.dart';

abstract class BlindCheckpointRepository {
  Future<BlindCheckpoint?> load();
  Future<void> save(BlindCheckpoint checkpoint);
  Future<void> clear();
}

class LocalBlindCheckpointRepository implements BlindCheckpointRepository {
  LocalBlindCheckpointRepository(this._preferences);
  final PreferencesService _preferences;
  static const key = 'blind.checkpoint';

  @override
  Future<BlindCheckpoint?> load() async {
    final text = await _preferences.getString(key);
    if (text == null) return null;
    try {
      return BlindCheckpoint.fromJson(jsonDecode(text) as Map<String, dynamic>);
    } on Object {
      await clear();
      return null;
    }
  }

  @override
  Future<void> save(BlindCheckpoint checkpoint) =>
      _preferences.setString(key, jsonEncode(checkpoint.toJson()));

  @override
  Future<void> clear() => _preferences.remove(key);
}

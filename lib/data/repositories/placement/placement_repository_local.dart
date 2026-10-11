import 'dart:convert';

import '../../../domain/models/placement.dart';
import '../../services/asset_service.dart';
import '../../services/preferences_service.dart';
import 'placement_repository.dart';

/// O mapa e o banco dos assets; o teste em andamento e o resultado nas
/// preferências do aparelho (fechar à força volta na mesma pergunta).
class LocalPlacementRepository implements PlacementRepository {
  LocalPlacementRepository(this._assets, this._preferences);

  final AssetService _assets;
  final PreferencesService _preferences;

  static const skillsPath = 'assets/placement/skills.json';
  static const itemsPath = 'assets/placement/items.json';
  static const _ongoingKey = 'placement.ongoing';
  static const _resultKey = 'placement.result';

  Future<SkillMap>? _skills;
  Future<PlacementBank>? _bank;

  @override
  Future<SkillMap> skills() => _skills ??= _assets
      .loadString(skillsPath)
      .then(
        (raw) => SkillMap.fromJson(jsonDecode(raw) as Map<String, dynamic>),
      );

  @override
  Future<PlacementBank> bank() => _bank ??= _assets
      .loadString(itemsPath)
      .then(
        (raw) =>
            PlacementBank.fromJson(jsonDecode(raw) as Map<String, dynamic>),
      );

  @override
  Future<PlacementState?> ongoing() async {
    final raw = await _preferences.getString(_ongoingKey);
    if (raw == null) return null;
    try {
      return PlacementState.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } on Object {
      // Gravado por outra versão e ilegível: o teste recomeça.
      return null;
    }
  }

  @override
  Future<void> saveOngoing(PlacementState state) =>
      _preferences.setString(_ongoingKey, jsonEncode(state.toJson()));

  @override
  Future<void> clearOngoing() => _preferences.remove(_ongoingKey);

  @override
  Future<PlacementResult?> result() async {
    final raw = await _preferences.getString(_resultKey);
    if (raw == null) return null;
    try {
      return PlacementResult.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } on Object {
      return null;
    }
  }

  @override
  Future<void> saveResult(PlacementResult result) =>
      _preferences.setString(_resultKey, jsonEncode(result.toJson()));
}

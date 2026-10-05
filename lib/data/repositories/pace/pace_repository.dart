import 'dart:convert';

import '../../../domain/models/pace.dart';
import '../../services/asset_service.dart';

/// Os ritmos nomeados e como o Maia decide em cada categoria de ritmo.
abstract class PaceRepository {
  Future<PaceTable> table();
}

/// Lidos de `assets/progression/time_controls.json`, uma vez.
class AssetPaceRepository implements PaceRepository {
  AssetPaceRepository(this._assets);

  static const path = 'assets/progression/time_controls.json';

  final AssetService _assets;
  Future<PaceTable>? _table;

  @override
  Future<PaceTable> table() => _table ??= _load();

  Future<PaceTable> _load() async => PaceTable.fromJson(
    jsonDecode(await _assets.loadString(path)) as Map<String, dynamic>,
  );
}

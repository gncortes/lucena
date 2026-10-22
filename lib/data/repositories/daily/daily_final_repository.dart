import 'dart:convert';

import '../../../domain/models/daily_final.dart';
import '../../../domain/use_cases/daily_final_rules.dart';
import '../../../domain/use_cases/streak_rules.dart';
import '../../services/asset_service.dart';
import '../../services/preferences_service.dart';
import '../positions/positions_repository.dart';

/// O final do dia e a primeira tentativa de cada dia.
abstract class DailyFinalRepository {
  /// O final do dia de [at]. Nulo sem fila (ou com o id fora do catálogo).
  Future<DailyFinal?> of(DateTime at);

  /// A primeira tentativa do dia de [at]. Nula: ainda não jogou.
  Future<DailyRecord?> record(DateTime at);

  /// Grava [record] se for a primeira do dia; as outras não valem.
  Future<void> saveFirst(DailyRecord record);
}

/// A fila em `assets/daily/queue.json` e as tentativas nas preferências. O
/// documento do dia do Firestore (o painel troca o final) entra com a E1.02.
class LocalDailyFinalRepository implements DailyFinalRepository {
  LocalDailyFinalRepository(this._assets, this._positions, this._preferences);

  static const path = 'assets/daily/queue.json';

  final AssetService _assets;
  final PositionsRepository _positions;
  final PreferencesService _preferences;

  Future<DailyQueue>? _queue;

  static String _recordKey(DateTime day) =>
      'daily.${DailyRecord.dayCode(StreakRules.day(day))}';

  Future<DailyQueue> _load() => _queue ??= () async {
    try {
      final text = await _assets.loadString(path);
      return DailyQueue.fromJson(jsonDecode(text) as Map<String, dynamic>);
    } catch (_) {
      return DailyQueue.empty;
    }
  }();

  @override
  Future<DailyFinal?> of(DateTime at) async {
    final id = DailyFinalRules.idOf(at, await _load());
    if (id == null) return null;
    final position = await _positions.byId(id);
    if (position == null) return null;
    return DailyFinal(date: StreakRules.day(at), position: position);
  }

  @override
  Future<DailyRecord?> record(DateTime at) async {
    final text = await _preferences.getString(_recordKey(at));
    if (text == null) return null;
    try {
      return DailyRecord.fromJson(jsonDecode(text) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> saveFirst(DailyRecord record) async {
    if (await this.record(record.date) != null) return;
    await _preferences.setString(
      _recordKey(record.date),
      jsonEncode(record.toJson()),
    );
  }
}

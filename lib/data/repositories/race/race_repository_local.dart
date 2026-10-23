import 'dart:convert';
import 'dart:math';

import '../../../domain/models/race.dart';
import '../../../domain/use_cases/now.dart';
import '../../../domain/use_cases/race_rules.dart';
import '../../services/asset_service.dart';
import '../../services/preferences_service.dart';
import 'race_repository.dart';

/// A Corrida guardada no aparelho (preferências, em JSON), com o banco de
/// problemas lido de `assets/race/race_problems.json`.
class LocalRaceRepository implements RaceRepository {
  LocalRaceRepository(
    this._assets,
    this._preferences,
    this._now, {
    this.offersWarmUpByDefault = true,
  });

  static const path = 'assets/race/race_problems.json';
  static const _recordKey = 'race.record';
  static const _historyKey = 'race.history';
  static const _ongoingKey = 'race.ongoing';
  static const _themeKey = 'race.theme';
  static const _warmUpKey = 'race.warmUp.offer';

  /// Quantas Corridas o histórico guarda.
  static const historyLimit = 20;

  /// O que vale antes de o jogador escolher "Não perguntar de novo".
  final bool offersWarmUpByDefault;

  final AssetService _assets;
  final PreferencesService _preferences;
  final Now _now;
  List<RaceProblem>? _problems;

  @override
  Future<List<RaceProblem>> problems() async {
    final cached = _problems;
    if (cached != null) return cached;
    final json =
        jsonDecode(await _assets.loadString(path)) as Map<String, dynamic>;
    return _problems = [
      for (final item in (json['problems'] as List))
        RaceProblem.fromJson(item as Map<String, dynamic>),
    ];
  }

  Future<Map<String, dynamic>?> _readMap(String key) async {
    final text = await _preferences.getString(key);
    if (text == null) return null;
    try {
      return jsonDecode(text) as Map<String, dynamic>;
    } on Object {
      // Gravação ilegível: como se não houvesse.
      await _preferences.remove(key);
      return null;
    }
  }

  @override
  Future<RaceRecord> record() async {
    final json = await _readMap(_recordKey);
    if (json == null) return const RaceRecord();
    try {
      return RaceRecord.fromJson(json);
    } on Object {
      return const RaceRecord();
    }
  }

  @override
  Future<List<RaceResult>> history() async {
    final text = await _preferences.getString(_historyKey);
    if (text == null) return const [];
    try {
      return [
        for (final item in jsonDecode(text) as List)
          RaceResult.fromJson(item as Map<String, dynamic>),
      ];
    } on Object {
      await _preferences.remove(_historyKey);
      return const [];
    }
  }

  @override
  Future<RaceRun?> ongoing() async {
    final json = await _readMap(_ongoingKey);
    if (json == null) return null;
    try {
      return RaceRun.fromJson(json);
    } on Object {
      await _preferences.remove(_ongoingKey);
      return null;
    }
  }

  @override
  Future<void> restoreRecord(RaceRecord record) async {
    final before = await this.record();
    await _preferences.setString(
      _recordKey,
      jsonEncode(
        RaceRecord(
          corrects: max(before.corrects, record.corrects),
          hardest: max(before.hardest, record.hardest),
        ).toJson(),
      ),
    );
  }

  @override
  Future<void> saveOngoing(RaceRun run) =>
      _preferences.setString(_ongoingKey, jsonEncode(run.toJson()));

  @override
  Future<RaceOutcome> finish(RaceRun run, RaceEnd end) async {
    final before = await record();
    final outcome = RaceRules.finish(run, end, before, _now());
    final history = [outcome.result, ...await this.history()];
    await _preferences.setString(
      _recordKey,
      jsonEncode(RaceRules.merge(before, run).toJson()),
    );
    await _preferences.setString(
      _historyKey,
      jsonEncode([
        for (final result in history.take(historyLimit)) result.toJson(),
      ]),
    );
    await _preferences.remove(_ongoingKey);
    return outcome;
  }

  @override
  Future<void> discardOngoing() => _preferences.remove(_ongoingKey);

  @override
  Future<RaceTheme?> theme() async =>
      RaceTheme.fromCode(await _preferences.getString(_themeKey));

  @override
  Future<void> setTheme(RaceTheme? theme) => theme == null
      ? _preferences.remove(_themeKey)
      : _preferences.setString(_themeKey, theme.name);

  @override
  Future<bool> offersWarmUp() async =>
      await _preferences.getBool(_warmUpKey) ?? offersWarmUpByDefault;

  @override
  Future<void> setOffersWarmUp({required bool value}) =>
      _preferences.setBool(_warmUpKey, value: value);
}

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
  // O recorde de antes da escolha de duração vale como o de 3 minutos.
  static const _recordKey = 'race.record';
  static const _record5Key = 'race.record.5min';
  static const _durationKey = 'race.duration';
  static const _historyKey = 'race.history';
  static const _ongoingKey = 'race.ongoing';
  static const _filterKey = 'race.filter';
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

  String _keyOf(RaceDuration duration) =>
      duration == RaceDuration.fiveMinutes ? _record5Key : _recordKey;

  @override
  Future<RaceDuration> duration() async => RaceDuration.fromMinutes(
    int.tryParse(await _preferences.getString(_durationKey) ?? ''),
  );

  @override
  Future<void> setDuration(RaceDuration duration) =>
      _preferences.setString(_durationKey, '${duration.minutes}');

  @override
  Future<RaceRecord> record({
    RaceDuration duration = RaceDuration.threeMinutes,
  }) async {
    final json = await _readMap(_keyOf(duration));
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
  Future<void> restoreRecord(
    RaceRecord record, {
    RaceDuration duration = RaceDuration.threeMinutes,
  }) async {
    final before = await this.record(duration: duration);
    await _preferences.setString(
      _keyOf(duration),
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
    final before = await record(duration: run.duration);
    final outcome = RaceRules.finish(run, end, before, _now());
    final history = [outcome.result, ...await this.history()];
    await _preferences.setString(
      _keyOf(run.duration),
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
  Future<RaceFilter> filter() async {
    final json = await _readMap(_filterKey);
    return json == null ? const RaceFilter() : RaceFilter.fromJson(json);
  }

  @override
  Future<void> setFilter(RaceFilter filter) =>
      _preferences.setString(_filterKey, jsonEncode(filter.toJson()));

  @override
  Future<bool> offersWarmUp() async =>
      await _preferences.getBool(_warmUpKey) ?? offersWarmUpByDefault;

  @override
  Future<void> setOffersWarmUp({required bool value}) =>
      _preferences.setBool(_warmUpKey, value: value);
}

import 'dart:async';

import 'package:lucena/data/services/firebase/remote_config_service.dart';

/// O Remote Config na memória: [values] é o que está ativo, [fetched] o que
/// a próxima busca traz, e [update] imita a mudança em tempo real.
class FakeRemoteConfigService implements RemoteConfigService {
  FakeRemoteConfigService({Map<String, Object>? fetched})
    : fetched = {...?fetched};

  final Map<String, Object> values = {};
  final Map<String, Object> fetched;
  final _updates = StreamController<Set<String>>.broadcast();
  bool failFetch = false;
  int fetches = 0;

  @override
  Future<void> start({
    required Map<String, Object> defaults,
    required Duration minimumFetchInterval,
  }) async => values.addAll({...defaults, ...values});

  @override
  Future<bool> fetchAndActivate() async {
    fetches++;
    if (failFetch) throw StateError('sem rede');
    final changed = fetched.entries.any((e) => values[e.key] != e.value);
    values.addAll(fetched);
    return changed;
  }

  /// O console mudou [changed] e o app já ativou.
  void update(Map<String, Object> changed) {
    values.addAll(changed);
    _updates.add(changed.keys.toSet());
  }

  @override
  int getInt(String key) => values[key] as int? ?? 0;

  @override
  bool getBool(String key) => values[key] as bool? ?? false;

  @override
  String getString(String key) => values[key] as String? ?? '';

  @override
  Stream<Set<String>> get onUpdated => _updates.stream;
}

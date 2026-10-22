import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../config/remote_defaults.dart';
import '../../services/firebase/remote_config_service.dart';

/// Os valores do Remote Config que o app lê (E1.32 §1), já com o tipo.
///
/// Antes de [start] terminar, e sempre sem Firebase, valem os padrões de
/// `remote_defaults.dart`.
abstract class RemoteFlagsRepository {
  /// Liga os padrões e o último valor buscado. A busca nova fica com
  /// [refresh], que ninguém espera na abertura.
  Future<void> start();

  /// Busca no Firebase. Valor novo sai em [changes].
  Future<void> refresh();

  /// Build (`versionCode`) abaixo disso vê a atualização obrigatória.
  int get updateMinBuild;

  /// Build abaixo disso vê a atualização recomendada.
  int get updateRecommendedBuild;

  /// O interruptor geral do anúncio (E1.25).
  bool get adsEnabled;

  /// Lições abertas sem anúncio (E1.25, decisão 3b).
  int get adsFreeLessons;

  /// O intervalo mínimo entre dois anúncios, em segundos (E1.25).
  int get adsMinGapSeconds;

  /// As chaves que mudaram, numa busca ou em tempo real.
  Stream<Set<String>> get changes;
}

class RemoteConfigFlagsRepository implements RemoteFlagsRepository {
  RemoteConfigFlagsRepository(
    this._config, {
    this.minimumFetchInterval = const Duration(hours: 12),
  });

  final RemoteConfigService _config;

  /// 12 h na Play; 0 no QA, para a conferência da §6.5 valer na hora.
  final Duration minimumFetchInterval;

  final _changes = StreamController<Set<String>>.broadcast();
  StreamSubscription<Set<String>>? _updates;
  Future<void>? _starting;

  // Até os padrões chegarem ao serviço, o repositório responde com eles.
  bool _ready = false;

  @override
  Future<void> start() => _starting ??= _start();

  Future<void> _start() async {
    try {
      await _config.start(
        defaults: remoteDefaults,
        minimumFetchInterval: minimumFetchInterval,
      );
      _ready = true;
    } on Object catch (error) {
      debugPrint('Remote Config sem padrões gravados: $error');
    }
    _updates = _config.onUpdated.listen(
      _changes.add,
      // Sem rede, o tempo real só para de chegar: vale o que já tem.
      onError: (Object error) => debugPrint('Remote Config: $error'),
    );
  }

  @override
  Future<void> refresh() async {
    await start();
    try {
      if (await _config.fetchAndActivate()) {
        _changes.add(remoteDefaults.keys.toSet());
      }
    } on Object catch (error) {
      // Sem rede ou o Firebase recusou: fica o último valor (ou o padrão).
      debugPrint('Remote Config sem busca: $error');
    }
  }

  int _int(String key) =>
      _ready ? _config.getInt(key) : remoteDefaults[key]! as int;

  @override
  int get updateMinBuild => _int(RemoteKeys.updateMinBuild);

  @override
  int get updateRecommendedBuild => _int(RemoteKeys.updateRecommendedBuild);

  @override
  bool get adsEnabled => _ready
      ? _config.getBool(RemoteKeys.adsEnabled)
      : remoteDefaults[RemoteKeys.adsEnabled]! as bool;

  @override
  int get adsFreeLessons => _int(RemoteKeys.adsFreeLessons);

  @override
  int get adsMinGapSeconds => _int(RemoteKeys.adsMinGapSeconds);

  @override
  Stream<Set<String>> get changes => _changes.stream;

  /// Só nos testes: o app vive enquanto o repositório vive.
  @visibleForTesting
  Future<void> dispose() async {
    await _updates?.cancel();
    await _changes.close();
  }
}

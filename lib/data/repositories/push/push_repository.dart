import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../../domain/use_cases/alerts_rules.dart';
import '../../services/firebase/push_service.dart';
import '../../services/preferences_service.dart';
import '../../services/system_settings_service.dart';

/// O push (E1.21): campanhas pelo console do Firebase e, depois, os avisos
/// das Cloud Functions (E1.20) por tópico.
abstract class PushRepository {
  /// O tópico de todos os aparelhos.
  static const everyone = 'all';

  /// Liga o push deste aparelho: entra nos tópicos. Não pede permissão.
  Future<void> start();

  /// Pede a permissão de notificação (Android 13+). Verdadeiro: concedida.
  Future<bool> requestPermission();

  /// Se o Android deixa o Lucena mostrar avisos agora. Não pergunta nada.
  Future<bool> permitted();

  /// Falso sem o Firebase (build do F-Droid): as chaves de push somem.
  bool get available;

  /// Segue exatamente os tópicos [topics]: entra nos novos e sai dos que
  /// ficaram de fora (a lista seguida fica gravada no aparelho).
  Future<void> follow(Set<String> topics);

  /// Abre os ajustes de notificação do Lucena no Android. Falso se não deu.
  Future<bool> openSystemSettings();

  /// O endereço que um aviso tocado quer abrir (campo `link` dos dados).
  Stream<Uri> get openedLinks;

  /// O endereço do aviso tocado que abriu o app.
  Future<Uri?> initialLink();
}

class FirebasePushRepository implements PushRepository {
  const FirebasePushRepository(
    this._service,
    this._preferences, {
    this._system = const SystemSettingsService(),
  });

  static const _followedKey = 'push.topics';

  final PushService _service;
  final PreferencesService _preferences;
  final SystemSettingsService _system;

  @override
  Future<void> start() async {
    try {
      await _service.subscribe(PushRepository.everyone);
    } on Object catch (error) {
      debugPrint('Push sem tópico: $error');
    }
  }

  @override
  Future<bool> requestPermission() => _service.requestPermission();

  @override
  Future<bool> permitted() async {
    try {
      return await _service.permitted();
    } on Object catch (error) {
      debugPrint('Push sem estado da permissão: $error');
      return false;
    }
  }

  @override
  bool get available => _service.available;

  @override
  Future<void> follow(Set<String> topics) async {
    if (!_service.available) return;
    final followed = await _followed();
    final changes = AlertsRules.changes(followed, topics);
    // Grava a cada tópico: se cair no meio, a próxima vez refaz só o resto.
    for (final topic in changes.unsubscribe) {
      try {
        await _service.unsubscribe(topic);
        followed.remove(topic);
        await _save(followed);
      } on Object catch (error) {
        debugPrint('Push não saiu de $topic: $error');
      }
    }
    for (final topic in changes.subscribe) {
      try {
        await _service.subscribe(topic);
        followed.add(topic);
        await _save(followed);
      } on Object catch (error) {
        debugPrint('Push não entrou em $topic: $error');
      }
    }
  }

  Future<Set<String>> _followed() async {
    final raw = await _preferences.getString(_followedKey);
    if (raw == null) return {};
    try {
      final json = jsonDecode(raw);
      return json is List ? {...json.whereType<String>()} : {};
    } on FormatException {
      return {};
    }
  }

  Future<void> _save(Set<String> topics) =>
      _preferences.setString(_followedKey, jsonEncode([...topics]));

  @override
  Future<bool> openSystemSettings() => _system.openAppNotifications();

  @override
  Stream<Uri> get openedLinks =>
      _service.opened.map(_link).where((uri) => uri != null).cast();

  @override
  Future<Uri?> initialLink() async => _link(await _service.initialOpened());

  static Uri? _link(PushMessage? message) {
    final link = message?.data['link'];
    return link == null ? null : Uri.tryParse(link);
  }
}

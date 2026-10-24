import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../../domain/models/push_alert.dart';
import '../../../domain/use_cases/alerts_rules.dart';
import '../../services/firebase/push_service.dart';
import '../../services/firebase/topic_count_service.dart';
import '../../services/image_download_service.dart';
import '../../services/notification_service.dart';
import '../../services/preferences_service.dart';
import '../../services/system_settings_service.dart';

/// O push (E1.21): campanhas pelo console do Firebase e, depois, os avisos
/// das Cloud Functions (E1.20) por tópico.
abstract class PushRepository {
  /// O tópico de todos os aparelhos.
  static const everyone = 'all';

  /// Liga o push deste aparelho: entra nos tópicos e passa a mostrar os
  /// avisos que chegam com o app aberto. Não pede permissão.
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

  /// Os avisos tocados com o app em segundo plano: a notificação do
  /// Android (campo `link` dos dados) ou a que o app mostrou (corpo, "Jogar"
  /// ou "Ver torneio").
  Stream<PushOpening> get opened;

  /// O aviso tocado que abriu o app (partida fria).
  Future<PushOpening?> initialOpening();

  /// Mostra [alert] como notificação do Lucena: imagem grande, miniatura,
  /// canal do tipo e botões (E1.19 3.8).
  Future<void> show(PushAlert alert);
}

class FirebasePushRepository implements PushRepository {
  /// [texts] dá os nomes dos canais e dos botões no idioma do app; sem ele,
  /// [show] não mostra nada. [counts] conta os aparelhos por tópico.
  FirebasePushRepository(
    this._service,
    this._preferences, {
    this._system = const SystemSettingsService(),
    this._notifications = const NoNotificationService(),
    this._images = const ImageDownloadService(),
    this._counts = const NoTopicCountService(),
    this._texts,
  });

  static const _followedKey = 'push.topics';

  final PushService _service;
  final PreferencesService _preferences;
  final SystemSettingsService _system;
  final NotificationService _notifications;
  final ImageDownloadService _images;
  final TopicCountService _counts;
  final Future<PushTexts> Function()? _texts;
  StreamSubscription<PushMessage>? _received;

  @override
  Future<void> start() async {
    // Com o app aberto o Android não mostra o aviso: o app mostra.
    _received ??= _service.received.listen((message) {
      final alert = PushAlert.fromData(
        message.data,
        title: message.title,
        body: message.body,
        image: message.image,
      );
      if (alert != null) unawaited(show(alert));
    });
    // Só no debug: o token para o tools/push_teste.py --token.
    if (kDebugMode) {
      unawaited(
        _service.token().then(
          (token) => debugPrint('Push token: $token'),
          onError: (Object _) {},
        ),
      );
    }
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
        await _count(topic, -1);
      } on Object catch (error) {
        debugPrint('Push não saiu de $topic: $error');
      }
    }
    for (final topic in changes.subscribe) {
      try {
        await _service.subscribe(topic);
        followed.add(topic);
        await _save(followed);
        await _count(topic, 1);
      } on Object catch (error) {
        debugPrint('Push não entrou em $topic: $error');
      }
    }
  }

  Future<void> _count(String topic, int delta) async {
    try {
      await _counts.changed(topic, delta);
    } on Object catch (error) {
      debugPrint('Push sem contagem de $topic: $error');
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
  Stream<PushOpening> get opened => _opened.stream;

  late final StreamController<PushOpening> _opened =
      StreamController<PushOpening>.broadcast(
        onListen: () {
          _openedSources = [
            _service.opened.listen(
              (message) => _opened.add(PushOpening.fromData(message.data)),
            ),
            _notifications.taps.listen((tap) {
              final opening = PushOpening.fromPayload(
                tap.payload,
                action: tap.action,
              );
              if (opening != null) _opened.add(opening);
            }),
          ];
        },
        onCancel: () {
          for (final source in _openedSources) {
            unawaited(source.cancel());
          }
          _openedSources = const [];
        },
      );
  List<StreamSubscription<Object>> _openedSources = const [];

  @override
  Future<PushOpening?> initialOpening() async {
    try {
      final message = await _service.initialOpened();
      if (message != null) return PushOpening.fromData(message.data);
    } on Object catch (error) {
      debugPrint('Push sem o aviso da abertura: $error');
    }
    final tap = await _notifications.launchTap();
    return tap == null
        ? null
        : PushOpening.fromPayload(tap.payload, action: tap.action);
  }

  @override
  Future<void> show(PushAlert alert) async {
    final texts = await _texts?.call();
    if (texts == null) return;
    final channel = texts.channel(alert.kind);
    final picture = await _download(alert.image);
    final thumbnail = alert.thumbnail == null
        ? null
        : await _download(alert.thumbnail);
    await _notifications.show(
      ShownNotification(
        id: alert.notificationId,
        channel: NotificationChannelSpec(id: channel.id, name: channel.name),
        title: alert.title,
        body: alert.body,
        payload: alert.payload,
        subText: channel.name,
        picture: picture,
        thumbnail: thumbnail,
        actions: [
          for (final action in alert.actions)
            (id: action, label: texts.action(action)),
        ],
      ),
    );
  }

  Future<Uint8List?> _download(String? url) async {
    final uri = url == null ? null : Uri.tryParse(url);
    return uri == null ? null : _images.fetch(uri);
  }
}

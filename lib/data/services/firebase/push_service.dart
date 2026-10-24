import 'package:firebase_messaging/firebase_messaging.dart';

/// Um aviso que chegou pelo push. [data] traz o destino (por exemplo
/// `link`, com o endereço de um desafio ou final).
class PushMessage {
  const PushMessage({
    this.data = const {},
    this.title,
    this.body,
    this.image,
    this.notified = false,
  });

  final Map<String, String> data;

  /// A parte `notification` (título, texto e a imagem do Android), se veio.
  final String? title;
  final String? body;
  final String? image;

  /// Veio com `notification`: fora do app, o próprio Android mostrou.
  final bool notified;
}

/// O push pelo Firebase Cloud Messaging (E1.21).
///
/// O pedido de permissão do Android 13+ não sai na abertura do app: a tela
/// chama [requestPermission] no momento certo (seção 3.13 do E1).
abstract class PushService {
  /// Pede a permissão de notificação. Verdadeiro: pode mostrar avisos.
  Future<bool> requestPermission();

  /// Se pode mostrar avisos agora, sem perguntar nada.
  Future<bool> permitted();

  /// Falso sem o Firebase (build do F-Droid): não há push.
  bool get available;

  Future<void> subscribe(String topic);

  Future<void> unsubscribe(String topic);

  /// O aviso tocado que abriu o app (partida fria).
  Future<PushMessage?> initialOpened();

  /// Os avisos tocados com o app em segundo plano.
  Stream<PushMessage> get opened;

  /// Os avisos que chegam com o app aberto (o Android não mostra nada).
  Stream<PushMessage> get received;
}

class NoPushService implements PushService {
  const NoPushService();

  @override
  Future<bool> requestPermission() async => false;

  @override
  Future<bool> permitted() async => false;

  @override
  bool get available => false;

  @override
  Future<void> subscribe(String topic) async {}

  @override
  Future<void> unsubscribe(String topic) async {}

  @override
  Future<PushMessage?> initialOpened() async => null;

  @override
  Stream<PushMessage> get opened => const Stream.empty();

  @override
  Stream<PushMessage> get received => const Stream.empty();
}

class FirebasePushService implements PushService {
  FirebasePushService([FirebaseMessaging? messaging])
    : _messaging = messaging ?? FirebaseMessaging.instance;

  final FirebaseMessaging _messaging;

  @override
  Future<bool> requestPermission() async {
    final settings = await _messaging.requestPermission();
    return _allowed(settings.authorizationStatus);
  }

  static bool _allowed(AuthorizationStatus status) => switch (status) {
    AuthorizationStatus.authorized || AuthorizationStatus.provisional => true,
    _ => false,
  };

  @override
  Future<bool> permitted() async {
    final settings = await _messaging.getNotificationSettings();
    return _allowed(settings.authorizationStatus);
  }

  @override
  bool get available => true;

  @override
  Future<void> subscribe(String topic) => _messaging.subscribeToTopic(topic);

  @override
  Future<void> unsubscribe(String topic) =>
      _messaging.unsubscribeFromTopic(topic);

  @override
  Future<PushMessage?> initialOpened() async {
    final message = await _messaging.getInitialMessage();
    return message == null ? null : _message(message);
  }

  @override
  Stream<PushMessage> get opened =>
      FirebaseMessaging.onMessageOpenedApp.map(_message);

  @override
  Stream<PushMessage> get received => FirebaseMessaging.onMessage.map(message);

  /// O [RemoteMessage] do FCM sem o Firebase (também no isolate de fundo).
  static PushMessage message(RemoteMessage message) {
    final notification = message.notification;
    return PushMessage(
      data: {
        for (final entry in message.data.entries)
          entry.key: entry.value.toString(),
      },
      title: notification?.title,
      body: notification?.body,
      image: notification?.android?.imageUrl,
      notified: notification != null,
    );
  }

  static PushMessage _message(RemoteMessage remote) => message(remote);
}

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

/// Um canal do Android (8+): a pessoa liga e desliga cada um nos ajustes.
class NotificationChannelSpec {
  const NotificationChannelSpec({required this.id, required this.name});

  final String id;
  final String name;
}

/// Uma notificação local agendada no aparelho.
class ScheduledNotification {
  const ScheduledNotification({
    required this.id,
    required this.channel,
    required this.title,
    required this.body,
    required this.at,
    required this.payload,
    this.action,
  });

  final int id;
  final NotificationChannelSpec channel;
  final String title;
  final String body;

  /// Quando sai (qualquer fuso: vai em UTC para o aparelho).
  final DateTime at;

  /// O que o toque abre (uma rota do app).
  final String payload;

  /// O botão da notificação, que abre o mesmo [payload].
  final String? action;
}

/// As notificações locais (E1.23), atrás de interface para o teste não
/// depender do aparelho.
abstract class NotificationService {
  /// Prepara o plugin e cria os [channels]. Só depois disso o resto vale.
  Future<void> start(List<NotificationChannelSpec> channels);

  /// Se o Android deixa o Lucena mostrar avisos agora. Não pergunta nada.
  Future<bool> permitted();

  /// Troca tudo o que estava agendado por [notifications].
  Future<void> replace(List<ScheduledNotification> notifications);

  /// O [ScheduledNotification.payload] da notificação que abriu o app.
  Future<String?> launchPayload();

  /// Os payloads das notificações tocadas com o app aberto ou em segundo
  /// plano.
  Stream<String> get taps;
}

/// Sem notificações (testes e plataformas sem o plugin).
class NoNotificationService implements NotificationService {
  const NoNotificationService();

  @override
  Future<void> start(List<NotificationChannelSpec> channels) async {}

  @override
  Future<bool> permitted() async => false;

  @override
  Future<void> replace(List<ScheduledNotification> notifications) async {}

  @override
  Future<String?> launchPayload() async => null;

  @override
  Stream<String> get taps => const Stream.empty();
}

/// O `flutter_local_notifications` no Android. O agendamento não é exato
/// (sem `SCHEDULE_EXACT_ALARM`): pode sair alguns minutos depois da hora.
class DeviceNotificationService implements NotificationService {
  DeviceNotificationService([FlutterLocalNotificationsPlugin? plugin])
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  /// O ícone pequeno (`res/drawable/ic_notification.xml`).
  static const _icon = 'ic_notification';
  static const _actionId = 'open';

  final FlutterLocalNotificationsPlugin _plugin;
  final _taps = StreamController<String>.broadcast();
  Future<bool>? _started;

  AndroidFlutterLocalNotificationsPlugin? get _android => _plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();

  @override
  Future<void> start(List<NotificationChannelSpec> channels) async {
    if (defaultTargetPlatform != TargetPlatform.android) return;
    final ready = await (_started ??= _plugin
        .initialize(
          settings: const InitializationSettings(
            android: AndroidInitializationSettings(_icon),
          ),
          onDidReceiveNotificationResponse: (response) {
            final payload = response.payload;
            if (payload != null && payload.isNotEmpty) _taps.add(payload);
          },
        )
        .then((ok) => ok ?? false));
    if (!ready) return;
    // Criar de novo só atualiza o nome (outro idioma).
    for (final channel in channels) {
      await _android?.createNotificationChannel(
        AndroidNotificationChannel(channel.id, channel.name),
      );
    }
  }

  @override
  Future<bool> permitted() async =>
      await _android?.areNotificationsEnabled() ?? false;

  @override
  Future<void> replace(List<ScheduledNotification> notifications) async {
    if (_started == null || !await _started!) return;
    await _plugin.cancelAllPendingNotifications();
    for (final notification in notifications) {
      final action = notification.action;
      await _plugin.zonedSchedule(
        id: notification.id,
        title: notification.title,
        body: notification.body,
        payload: notification.payload,
        scheduledDate: tz.TZDateTime.from(notification.at.toUtc(), tz.UTC),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            notification.channel.id,
            notification.channel.name,
            icon: _icon,
            styleInformation: BigTextStyleInformation(notification.body),
            actions: [
              if (action != null)
                AndroidNotificationAction(
                  _actionId,
                  action,
                  showsUserInterface: true,
                ),
            ],
          ),
        ),
      );
    }
  }

  @override
  Future<String?> launchPayload() async {
    if (_started == null || !await _started!) return null;
    final details = await _plugin.getNotificationAppLaunchDetails();
    if (details == null || !details.didNotificationLaunchApp) return null;
    final payload = details.notificationResponse?.payload;
    return payload == null || payload.isEmpty ? null : payload;
  }

  @override
  Stream<String> get taps => _taps.stream;
}

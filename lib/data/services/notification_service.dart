import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
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

/// Uma notificação mostrada agora (o push que o app monta, E1.19 3.8).
class ShownNotification {
  const ShownNotification({
    required this.id,
    required this.channel,
    required this.title,
    required this.body,
    required this.payload,
    this.subText,
    this.actions = const [],
  });

  final int id;
  final NotificationChannelSpec channel;
  final String title;
  final String body;
  final String payload;

  /// O texto ao lado do nome do app no cabeçalho ("Lucena · subText").
  final String? subText;

  /// Os botões: id e rótulo.
  final List<({String id, String label})> actions;
}

/// Um toque numa notificação: o [payload] dela e o botão ([action]; nulo no
/// corpo).
class NotificationTap {
  const NotificationTap(this.payload, {this.action});

  final String payload;
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

  /// Mostra [notification] agora (prepara o plugin, se preciso).
  Future<void> show(ShownNotification notification);

  /// O toque na notificação que abriu o app.
  Future<NotificationTap?> launchTap();

  /// Os toques nas notificações com o app aberto ou em segundo plano.
  Stream<NotificationTap> get taps;
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
  Future<void> show(ShownNotification notification) async {}

  @override
  Future<NotificationTap?> launchTap() async => null;

  @override
  Stream<NotificationTap> get taps => const Stream.empty();
}

/// O `flutter_local_notifications` no Android. O agendamento não é exato
/// (sem `SCHEDULE_EXACT_ALARM`): pode sair alguns minutos depois da hora.
class DeviceNotificationService implements NotificationService {
  DeviceNotificationService([FlutterLocalNotificationsPlugin? plugin])
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  /// O ícone pequeno (`res/drawable/ic_notification.xml`).
  static const _icon = 'ic_notification';
  static const _actionId = 'open';

  // Os canais de antes, com som e vibração: o Android não deixa mudar o som
  // de um canal criado, então os novos têm outro id e estes saem.
  static const _noisyChannels = [
    'lembretes',
    'resumo_semana',
    'push_torneios',
    'push_dia',
    'push_aulas',
    'push_novidades',
  ];

  final FlutterLocalNotificationsPlugin _plugin;
  final _taps = StreamController<NotificationTap>.broadcast();
  Future<bool>? _started;

  AndroidFlutterLocalNotificationsPlugin? get _android => _plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();

  // Prepara o plugin uma vez só; falso fora do Android ou se falhou.
  Future<bool> _ready() {
    if (defaultTargetPlatform != TargetPlatform.android) {
      return Future.value(false);
    }
    return _started ??= _plugin
        .initialize(
          settings: const InitializationSettings(
            android: AndroidInitializationSettings(_icon),
          ),
          onDidReceiveNotificationResponse: (response) {
            final tap = _tap(response);
            if (tap != null) _taps.add(tap);
          },
        )
        .then((ok) => ok ?? false);
  }

  static NotificationTap? _tap(NotificationResponse? response) {
    final payload = response?.payload;
    if (payload == null || payload.isEmpty) return null;
    final action = response!.actionId;
    return NotificationTap(
      payload,
      action: action == null || action.isEmpty || action == _actionId
          ? null
          : action,
    );
  }

  @override
  Future<void> start(List<NotificationChannelSpec> channels) async {
    if (!await _ready()) return;
    for (final id in _noisyChannels) {
      await _android?.deleteNotificationChannel(channelId: id);
    }
    // Criar de novo só atualiza o nome (outro idioma). Sem som e sem
    // vibração: o aviso aparece na barra e não incomoda.
    for (final channel in channels) {
      await _android?.createNotificationChannel(
        AndroidNotificationChannel(
          channel.id,
          channel.name,
          playSound: false,
          enableVibration: false,
        ),
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
            playSound: false,
            enableVibration: false,
            silent: true,
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
  Future<void> show(ShownNotification notification) async {
    if (!await _ready()) return;
    await _plugin.show(
      id: notification.id,
      title: notification.title,
      body: notification.body,
      payload: notification.payload,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          notification.channel.id,
          notification.channel.name,
          icon: _icon,
          playSound: false,
          enableVibration: false,
          silent: true,
          subText: notification.subText,
          // Só texto, como os outros apps de xadrez (Gabriel, 2026-10-24):
          // expandida, o texto inteiro.
          styleInformation: BigTextStyleInformation(notification.body),
          actions: [
            for (final action in notification.actions)
              AndroidNotificationAction(
                action.id,
                action.label,
                showsUserInterface: true,
              ),
          ],
        ),
      ),
    );
  }

  @override
  Future<NotificationTap?> launchTap() async {
    if (!await _ready()) return null;
    try {
      final details = await _plugin.getNotificationAppLaunchDetails();
      if (details == null || !details.didNotificationLaunchApp) return null;
      return _tap(details.notificationResponse);
    } on PlatformException catch (error) {
      debugPrint('Notificação sem detalhes da abertura: $error');
      return null;
    }
  }

  @override
  Stream<NotificationTap> get taps => _taps.stream;
}

import 'dart:async';

import 'package:lucena/data/services/notification_service.dart';

/// As notificações do aparelho em memória: guarda o que foi mostrado e
/// entrega os toques que o teste mandar.
class FakeNotificationService implements NotificationService {
  FakeNotificationService({
    this.launch,
    this.allowed = true,
    this.permissionResult,
  });
  bool allowed;
  bool? permissionResult;
  int permissionRequests = 0;

  /// O toque que abriu o app.
  NotificationTap? launch;
  final shown = <ShownNotification>[];
  final scheduled = <ScheduledNotification>[];
  final _taps = StreamController<NotificationTap>.broadcast();

  /// A pessoa tocou numa notificação (no corpo, ou no botão [action]).
  void tap(String payload, {String? action}) =>
      _taps.add(NotificationTap(payload, action: action));

  @override
  Future<void> start(List<NotificationChannelSpec> channels) async {}

  @override
  Future<bool> permitted() async => allowed;
  @override
  Future<bool> requestPermission() async {
    permissionRequests++;
    return allowed = permissionResult ?? allowed;
  }

  @override
  Future<void> replace(List<ScheduledNotification> notifications) async =>
      scheduled
        ..clear()
        ..addAll(notifications);

  @override
  Future<void> show(ShownNotification notification) async =>
      shown.add(notification);

  @override
  Future<NotificationTap?> launchTap() async => launch;

  @override
  Stream<NotificationTap> get taps => _taps.stream;
}

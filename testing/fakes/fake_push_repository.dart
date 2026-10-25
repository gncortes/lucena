import 'dart:async';

import 'package:lucena/data/repositories/push/push_repository.dart';
import 'package:lucena/domain/models/push_alert.dart';

/// Um push que entrega os avisos tocados que o teste mandar.
class FakePushRepository implements PushRepository {
  FakePushRepository({
    this.initial,
    this.granted = false,
    this.allowed = false,
    this.available = true,
  });

  /// O aviso que abriu o app.
  PushOpening? initial;
  bool granted;

  /// O que [permitted] responde (a permissão no Android agora).
  bool allowed;
  @override
  bool available;

  /// Os tópicos seguidos, depois do último [follow].
  Set<String> followed = {};
  int settingsOpened = 0;
  bool started = false;
  int permissionRequests = 0;
  final _opened = StreamController<PushOpening>.broadcast();

  /// Os avisos que o app mostrou ([show]).
  final shown = <PushAlert>[];

  /// A pessoa tocou num aviso com o app em segundo plano.
  void open(Uri link, {String? pushId, String? country}) =>
      _opened.add(PushOpening(link: link, pushId: pushId, country: country));

  @override
  Future<void> start() async => started = true;

  @override
  Future<bool> requestPermission() async {
    permissionRequests++;
    if (granted) allowed = true;
    return granted;
  }

  @override
  Future<bool> permitted() async => allowed;

  @override
  Future<void> follow(Set<String> topics) async => followed = {...topics};

  @override
  Future<bool> openSystemSettings() async {
    settingsOpened++;
    return true;
  }

  @override
  Stream<PushOpening> get opened => _opened.stream;

  @override
  Future<PushOpening?> initialOpening() async => initial;

  @override
  Future<void> show(PushAlert alert) async => shown.add(alert);
}

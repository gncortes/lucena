import 'dart:async';

import 'package:lucena/data/repositories/push/push_repository.dart';

/// Um push que entrega os avisos tocados que o teste mandar.
class FakePushRepository implements PushRepository {
  FakePushRepository({
    this.initial,
    this.granted = false,
    this.allowed = false,
    this.available = true,
  });

  /// O link do aviso que abriu o app.
  Uri? initial;
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
  final _opened = StreamController<Uri>.broadcast();

  /// A pessoa tocou num aviso com o app em segundo plano.
  void open(Uri link) => _opened.add(link);

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

  /// A folha "Quer receber avisos?" já apareceu.
  bool asked = false;

  @override
  Future<bool> shouldAsk() async => available && !asked && !allowed;

  @override
  Future<void> markAsked() async => asked = true;

  @override
  Future<void> follow(Set<String> topics) async => followed = {...topics};

  @override
  Future<bool> openSystemSettings() async {
    settingsOpened++;
    return true;
  }

  @override
  Stream<Uri> get openedLinks => _opened.stream;

  @override
  Future<Uri?> initialLink() async => initial;
}

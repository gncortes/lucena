import 'dart:async';

import 'package:lucena/data/repositories/push/push_repository.dart';

/// Um push que entrega os avisos tocados que o teste mandar.
class FakePushRepository implements PushRepository {
  FakePushRepository({this.initial, this.granted = false});

  /// O link do aviso que abriu o app.
  Uri? initial;
  bool granted;
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
    return granted;
  }

  @override
  Stream<Uri> get openedLinks => _opened.stream;

  @override
  Future<Uri?> initialLink() async => initial;
}

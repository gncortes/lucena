import 'dart:async';

import 'package:lucena/data/services/firebase/push_service.dart';
import 'package:lucena/domain/models/push_permission.dart';

/// O FCM de mentira dos cenários no Emulator Suite: o emulador Android não
/// registra no FCM, então o token vem daqui e a conta grava o
/// `push/device` como no aparelho.
class FakePushService extends NoPushService {
  FakePushService({this.current = 'token-emulador'});

  String? current;
  var deleted = 0;
  final changes = StreamController<String>.broadcast();

  @override
  bool get available => true;

  @override
  Future<String?> token() async => current;

  @override
  Stream<String> get tokenChanges => changes.stream;

  @override
  Future<bool> permitted() async => true;

  @override
  Future<PushPermission> permission() async => PushPermission.allowed;

  @override
  Future<void> deleteToken() async {
    deleted++;
    current = 'token-emulador-$deleted';
  }
}

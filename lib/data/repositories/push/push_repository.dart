import 'package:flutter/foundation.dart';

import '../../services/firebase/push_service.dart';

/// O push (E1.21): campanhas pelo console do Firebase e, depois, os avisos
/// das Cloud Functions (E1.20) por tópico.
abstract class PushRepository {
  /// O tópico de todos os aparelhos.
  static const everyone = 'all';

  /// Liga o push deste aparelho: entra nos tópicos. Não pede permissão.
  Future<void> start();

  /// Pede a permissão de notificação (Android 13+). Verdadeiro: concedida.
  Future<bool> requestPermission();

  /// O endereço que um aviso tocado quer abrir (campo `link` dos dados).
  Stream<Uri> get openedLinks;

  /// O endereço do aviso tocado que abriu o app.
  Future<Uri?> initialLink();
}

class FirebasePushRepository implements PushRepository {
  const FirebasePushRepository(this._service);

  final PushService _service;

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
  Stream<Uri> get openedLinks =>
      _service.opened.map(_link).where((uri) => uri != null).cast();

  @override
  Future<Uri?> initialLink() async => _link(await _service.initialOpened());

  static Uri? _link(PushMessage? message) {
    final link = message?.data['link'];
    return link == null ? null : Uri.tryParse(link);
  }
}

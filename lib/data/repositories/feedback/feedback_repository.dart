import 'dart:async';

import '../../../domain/models/app_version.dart';
import '../../../domain/models/feedback_entry.dart';
import '../../services/device_service.dart';
import '../../services/firebase/cloud_store_service.dart';

/// O "Enviar feedback" do Perfil e as respostas do "Você pagaria?" (E1.26),
/// em `feedback/{id}`, sem identificar quem mandou.
abstract class FeedbackRepository {
  /// Manda [entry] e devolve se aceitou. Não espera a rede: sem ela, o
  /// Firestore guarda e manda quando voltar. Texto livre vazio não vai.
  /// [level] é o nível ou rating do perfil, quando a pessoa já definiu.
  Future<bool> send(FeedbackEntry entry, {String? level});
}

class CloudFeedbackRepository implements FeedbackRepository {
  const CloudFeedbackRepository(
    this._store,
    this._device,
    this._version, {
    this.origin,
  });

  final CloudStoreService _store;
  final DeviceService _device;
  final AppVersion _version;

  /// De onde a pessoa veio na 1ª abertura (a `origem_primeira` da E1.03).
  final Future<String?> Function()? origin;

  @override
  Future<bool> send(FeedbackEntry entry, {String? level}) async {
    final text = entry.text;
    if (text != null && FeedbackEntry.clip(text).isEmpty) return false;
    final device = await _device.model();
    final data = entry.toJson(
      level: level,
      appVersion: _version.name,
      model: device.model,
      manufacturer: device.manufacturer,
      origin: await origin?.call(),
    );
    // Sem esperar o servidor: a pessoa já vê o agradecimento.
    unawaited(
      _store.addFeedback(data).catchError((Object _) {
        // Recusado (regra, sem permissão): não há o que mostrar.
      }),
    );
    return true;
  }
}

/// Sem Firebase (F-Droid): nada é mandado, mas a tela segue igual.
class NoFeedbackRepository implements FeedbackRepository {
  const NoFeedbackRepository();

  @override
  Future<bool> send(FeedbackEntry entry, {String? level}) async {
    final text = entry.text;
    return text == null || FeedbackEntry.clip(text).isNotEmpty;
  }
}

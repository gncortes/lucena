import 'dart:async';

import '../../../domain/models/app_version.dart';
import '../../../domain/models/feedback_entry.dart';
import '../../services/device_service.dart';
import '../../services/firebase/cloud_store_service.dart';

/// O "Enviar feedback" do Perfil (E1.26), em `feedback/{id}`, com o uid de
/// quem mandou: só com conta (proteção contra abuso, `docs/fluxos/abuso.md`).
abstract class FeedbackRepository {
  /// Manda [entry] e devolve se aceitou (texto vazio não vai). Sem rede, o
  /// Firestore guarda e manda quando voltar; recusa do servidor ou falha
  /// local lançam erro, para a tela avisar e deixar tentar de novo. Sem
  /// conta, lança [FeedbackNeedsAccount].
  /// [level] é o nível ou rating do perfil, quando a pessoa já definiu.
  Future<bool> send(FeedbackEntry entry, {String? level});
}

class CloudFeedbackRepository implements FeedbackRepository {
  const CloudFeedbackRepository(
    this._store,
    this._device,
    this._version, {
    this.origin,
    this.wait = const Duration(seconds: 4),
  });

  final CloudStoreService _store;
  final DeviceService _device;
  final AppVersion _version;

  /// De onde a pessoa veio na 1ª abertura (a `origem_primeira` da E1.03).
  final Future<String?> Function()? origin;

  /// Quanto espera a resposta do servidor. Passado o tempo (sem rede), a
  /// gravação já está na fila local do Firestore e conta como aceita.
  final Duration wait;

  @override
  Future<bool> send(FeedbackEntry entry, {String? level}) async {
    if (FeedbackEntry.clip(entry.text).isEmpty) return false;
    final device = await _device.model();
    final data = entry.toJson(
      level: level,
      appVersion: _version.name,
      model: device.model,
      manufacturer: device.manufacturer,
      origin: await origin?.call(),
    );
    // Recusa (regra, sem permissão) chega rápido e lança; sem rede, a
    // resposta não vem e o tempo esgota com o documento na fila.
    try {
      await _store.addFeedback(data).timeout(wait, onTimeout: () {});
    } on CloudStoreException catch (error) {
      if (error.code == 'unauthenticated') throw const FeedbackNeedsAccount();
      rethrow;
    }
    return true;
  }
}

/// O feedback só vai com conta: a tela oferece entrar e guarda o texto.
class FeedbackNeedsAccount implements Exception {
  const FeedbackNeedsAccount();

  @override
  String toString() => 'FeedbackNeedsAccount';
}

/// Sem Firebase (F-Droid): nada é mandado, mas a tela segue igual.
class NoFeedbackRepository implements FeedbackRepository {
  const NoFeedbackRepository();

  @override
  Future<bool> send(FeedbackEntry entry, {String? level}) async {
    return FeedbackEntry.clip(entry.text).isNotEmpty;
  }
}

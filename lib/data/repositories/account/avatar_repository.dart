import 'package:flutter/foundation.dart';

import '../../services/firebase/file_store_service.dart';

/// A foto de perfil enviada pelo usuário (§2.12). A tela já entrega o JPEG
/// reduzido (até 1 MB); a regra do Storage recusa o que passar disso.
abstract class AvatarRepository {
  /// Envia a foto da conta [uid] e devolve o endereço dela. Lança
  /// [FileStoreException] sem rede ou sem permissão.
  Future<Uri> upload(String uid, Uint8List jpeg);

  /// O endereço da foto da conta [uid]. Nulo: a conta não enviou foto.
  Future<Uri?> url(String uid);

  /// Apaga a foto da conta [uid] (trocar para sem foto, apagar a conta).
  /// Sem foto não é erro.
  Future<void> delete(String uid);
}

class CloudAvatarRepository implements AvatarRepository {
  const CloudAvatarRepository(this._store);

  final FileStoreService _store;

  static String path(String uid) => 'users/$uid/avatar.jpg';

  @override
  Future<Uri> upload(String uid, Uint8List jpeg) =>
      _store.put(path(uid), jpeg, contentType: 'image/jpeg');

  @override
  Future<Uri?> url(String uid) => _store.url(path(uid));

  @override
  Future<void> delete(String uid) => _store.delete(path(uid));
}

/// Sem Firebase: não há foto enviada.
class NoAvatarRepository extends CloudAvatarRepository {
  const NoAvatarRepository() : super(const NoFileStoreService());
}

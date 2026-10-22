import 'package:flutter/foundation.dart';
import 'package:lucena/data/repositories/account/avatar_repository.dart';
import 'package:lucena/data/services/firebase/file_store_service.dart';

/// As fotos na memória. Com [offline], enviar falha como sem rede.
class FakeAvatarRepository implements AvatarRepository {
  final photos = <String, Uint8List>{};
  final deleted = <String>[];
  bool offline = false;

  Uri _url(String uid) =>
      Uri.parse('https://storage.test/users/$uid/avatar.jpg');

  @override
  Future<Uri> upload(String uid, Uint8List jpeg) async {
    if (offline) throw const FileStoreException('unavailable');
    photos[uid] = jpeg;
    return _url(uid);
  }

  @override
  Future<Uri?> url(String uid) async =>
      photos.containsKey(uid) ? _url(uid) : null;

  @override
  Future<void> delete(String uid) async {
    if (offline) throw const FileStoreException('unavailable');
    photos.remove(uid);
    deleted.add(uid);
  }
}

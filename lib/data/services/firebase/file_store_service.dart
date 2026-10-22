import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

/// Os arquivos de cada conta no Firebase Storage. As regras estão em
/// `firebase/storage.rules`: só `users/{uid}/avatar.jpg`, só o dono, imagem
/// até 1 MB.
abstract class FileStoreService {
  /// Grava [bytes] em [path] e devolve o endereço para baixar.
  Future<Uri> put(String path, Uint8List bytes, {required String contentType});

  /// O endereço para baixar [path]. Nulo: o arquivo não existe.
  Future<Uri?> url(String path);

  /// Apaga [path]. Arquivo que não existe não é erro.
  Future<void> delete(String path);
}

/// O Storage não respondeu (sem rede, sem permissão, arquivo grande demais).
class FileStoreException implements Exception {
  const FileStoreException(this.code);

  final String code;

  @override
  String toString() => 'FileStoreException($code)';
}

/// Sem Firebase: nada a guardar na nuvem.
class NoFileStoreService implements FileStoreService {
  const NoFileStoreService();

  @override
  Future<Uri> put(
    String path,
    Uint8List bytes, {
    required String contentType,
  }) async => throw const FileStoreException('unavailable');

  @override
  Future<Uri?> url(String path) async => null;

  @override
  Future<void> delete(String path) async {}
}

class FirebaseFileStoreService implements FileStoreService {
  FirebaseFileStoreService({FirebaseStorage? storage})
    : _storage = storage ?? FirebaseStorage.instance;

  final FirebaseStorage _storage;

  static const _notFound = 'object-not-found';

  @override
  Future<Uri> put(
    String path,
    Uint8List bytes, {
    required String contentType,
  }) async {
    try {
      final ref = _storage.ref(path);
      await ref.putData(bytes, SettableMetadata(contentType: contentType));
      return Uri.parse(await ref.getDownloadURL());
    } on FirebaseException catch (error) {
      throw FileStoreException(error.code);
    }
  }

  @override
  Future<Uri?> url(String path) async {
    try {
      return Uri.parse(await _storage.ref(path).getDownloadURL());
    } on FirebaseException catch (error) {
      if (error.code == _notFound) return null;
      throw FileStoreException(error.code);
    }
  }

  @override
  Future<void> delete(String path) async {
    try {
      await _storage.ref(path).delete();
    } on FirebaseException catch (error) {
      if (error.code == _notFound) return;
      throw FileStoreException(error.code);
    }
  }
}

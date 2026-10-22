import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/data/repositories/account/avatar_repository.dart';
import 'package:lucena/data/services/firebase/file_store_service.dart';

/// O Storage na memória, para ver o caminho e o tipo que o repositório usa.
class _MemoryFileStore implements FileStoreService {
  final files = <String, Uint8List>{};
  final types = <String, String>{};

  @override
  Future<Uri> put(
    String path,
    Uint8List bytes, {
    required String contentType,
  }) async {
    files[path] = bytes;
    types[path] = contentType;
    return Uri.parse('https://storage.test/$path');
  }

  @override
  Future<Uri?> url(String path) async =>
      files.containsKey(path) ? Uri.parse('https://storage.test/$path') : null;

  @override
  Future<void> delete(String path) async => files.remove(path);
}

void main() {
  final jpeg = Uint8List.fromList([0xFF, 0xD8, 0xFF]);

  group('CloudAvatarRepository', () {
    test('envia a foto em users/{uid}/avatar.jpg como JPEG', () async {
      final store = _MemoryFileStore();
      final repository = CloudAvatarRepository(store);

      final url = await repository.upload('u1', jpeg);

      expect(store.files['users/u1/avatar.jpg'], jpeg);
      expect(store.types['users/u1/avatar.jpg'], 'image/jpeg');
      expect(url, Uri.parse('https://storage.test/users/u1/avatar.jpg'));
    });

    test('sem foto enviada, o endereço é nulo', () async {
      final repository = CloudAvatarRepository(_MemoryFileStore());

      expect(await repository.url('u1'), isNull);
    });

    test('apagar tira a foto; apagar de novo não é erro', () async {
      final store = _MemoryFileStore();
      final repository = CloudAvatarRepository(store);
      await repository.upload('u1', jpeg);

      await repository.delete('u1');
      await repository.delete('u1');

      expect(store.files, isEmpty);
      expect(await repository.url('u1'), isNull);
    });
  });

  group('NoAvatarRepository', () {
    test('sem Firebase, enviar falha e não há foto', () async {
      const repository = NoAvatarRepository();

      await expectLater(
        repository.upload('u1', jpeg),
        throwsA(isA<FileStoreException>()),
      );
      expect(await repository.url('u1'), isNull);
      await repository.delete('u1');
    });
  });
}

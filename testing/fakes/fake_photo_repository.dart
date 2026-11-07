import 'package:flutter/foundation.dart';
import 'package:lucena/data/repositories/photo/photo_repository.dart';

/// Devolve [photo] (nulo: a pessoa desistiu) e guarda de onde pediu.
class FakePhotoRepository implements PhotoRepository {
  FakePhotoRepository([this.photo]);

  Uint8List? photo;
  final sources = <PhotoSource>[];

  /// Erro ao abrir a câmera ou a galeria (permissão negada, sem câmera).
  Object? error;

  @override
  Future<Uint8List?> pick(PhotoSource source) async {
    sources.add(source);
    if (error case final error?) throw error;
    return photo;
  }
}

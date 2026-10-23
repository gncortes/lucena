import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

import '../../services/photo_picker_service.dart';

export '../../services/photo_picker_service.dart' show PhotoSource;

/// A foto do perfil tirada ou escolhida no aparelho (§2.12).
abstract class PhotoRepository {
  /// A foto já quadrada, com até [side] px de lado, em JPEG. Nulo: a pessoa
  /// desistiu ou a imagem não abriu.
  Future<Uint8List?> pick(PhotoSource source);

  /// O lado da foto enviada.
  static const side = 512;
}

class DevicePhotoRepository implements PhotoRepository {
  DevicePhotoRepository([PhotoPickerService? picker])
    : _picker = picker ?? PhotoPickerService();

  final PhotoPickerService _picker;

  @override
  Future<Uint8List?> pick(PhotoSource source) async {
    // O lado menor precisa ter 512 px depois do recorte: o sistema reduz a
    // foto até caber em 2 × 512 (de pé ou deitada) e o recorte faz o resto.
    final bytes = await _picker.pick(
      source,
      maxSide: PhotoRepository.side * 2.0,
    );
    if (bytes == null) return null;
    return compute(squareJpeg, bytes);
  }
}

/// O quadrado do meio da imagem, com até [PhotoRepository.side] px, em JPEG.
/// Nulo: os bytes não são uma imagem.
Uint8List? squareJpeg(Uint8List bytes) {
  final img.Image? decoded;
  try {
    decoded = img.decodeImage(bytes);
  } on Object {
    // Alguns decodificadores estouram com bytes curtos em vez de dar nulo.
    return null;
  }
  if (decoded == null) return null;
  final image = img.bakeOrientation(decoded);
  final side = image.width < image.height ? image.width : image.height;
  final square = img.copyCrop(
    image,
    x: (image.width - side) ~/ 2,
    y: (image.height - side) ~/ 2,
    width: side,
    height: side,
  );
  final resized = side > PhotoRepository.side
      ? img.copyResize(
          square,
          width: PhotoRepository.side,
          height: PhotoRepository.side,
          interpolation: img.Interpolation.average,
        )
      : square;
  return img.encodeJpg(resized, quality: 85);
}

/// Sem câmera nem galeria (testes, outras plataformas).
class NoPhotoRepository implements PhotoRepository {
  const NoPhotoRepository();

  @override
  Future<Uint8List?> pick(PhotoSource source) async => null;
}

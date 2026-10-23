import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

/// De onde vem a foto do perfil.
enum PhotoSource { camera, gallery }

/// A câmera e a galeria do aparelho (`image_picker`).
class PhotoPickerService {
  PhotoPickerService([ImagePicker? picker]) : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  /// Os bytes da foto tirada ou escolhida, já reduzida pelo sistema. Nulo: a
  /// pessoa desistiu ou não deu para abrir.
  Future<Uint8List?> pick(PhotoSource source, {required double maxSide}) async {
    try {
      final file = await _picker.pickImage(
        source: source == PhotoSource.camera
            ? ImageSource.camera
            : ImageSource.gallery,
        maxWidth: maxSide,
        maxHeight: maxSide,
        preferredCameraDevice: CameraDevice.front,
      );
      return await file?.readAsBytes();
    } on Object catch (error) {
      debugPrint('PhotoPickerService.pick: $error');
      return null;
    }
  }
}

import 'dart:typed_data';

import '../../services/share_service.dart';
import 'share_repository.dart';

/// O menu de compartilhar do aparelho.
class DeviceShareRepository implements ShareRepository {
  const DeviceShareRepository(this._share);

  final ShareService _share;

  @override
  Future<bool> shareImage(
    Uint8List png, {
    required String name,
    String? text,
  }) => _share.shareImage(png, name: name, text: text);
}

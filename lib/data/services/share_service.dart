import 'dart:typed_data';

import 'package:share_plus/share_plus.dart';

/// O menu de compartilhar do sistema.
class ShareService {
  const ShareService();

  /// Abre o menu com só o texto [text] (um link, por exemplo).
  Future<bool> shareText(String text) async {
    final result = await SharePlus.instance.share(ShareParams(text: text));
    return result.status == ShareResultStatus.success;
  }

  /// Abre o menu com a imagem [png] (chamada [name]) e o texto [text].
  /// Devolve se a pessoa escolheu para onde mandar.
  Future<bool> shareImage(
    Uint8List png, {
    required String name,
    String? text,
  }) async {
    final result = await SharePlus.instance.share(
      ShareParams(
        files: [XFile.fromData(png, name: name, mimeType: 'image/png')],
        fileNameOverrides: [name],
        text: text,
      ),
    );
    return result.status == ShareResultStatus.success;
  }
}

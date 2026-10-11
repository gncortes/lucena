import 'dart:typed_data';

/// Compartilhar uma conquista nas redes: uma imagem e um texto.
abstract class ShareRepository {
  /// Compartilha a imagem [png] com o texto [text]. Devolve se foi enviada.
  Future<bool> shareImage(Uint8List png, {required String name, String? text});
}

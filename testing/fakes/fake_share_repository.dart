import 'dart:typed_data';

import 'package:lucena/data/repositories/share/share_repository.dart';

/// Não abre o menu do sistema: só guarda o que foi compartilhado.
class FakeShareRepository implements ShareRepository {
  final shared = <({Uint8List png, String name, String? text})>[];

  final texts = <String>[];

  @override
  Future<bool> shareText(String text) async {
    texts.add(text);
    return true;
  }

  @override
  Future<bool> shareImage(
    Uint8List png, {
    required String name,
    String? text,
  }) async {
    shared.add((png: png, name: name, text: text));
    return true;
  }
}

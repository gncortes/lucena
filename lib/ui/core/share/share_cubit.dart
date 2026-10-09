import 'dart:typed_data';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/share/share_repository.dart';

/// Compartilhar uma conquista: enquanto o menu do sistema está aberto, o
/// botão fica ocupado (sem dois toques abrindo dois menus).
class ShareCubit extends Cubit<bool> {
  ShareCubit(this._share) : super(false);

  final ShareRepository _share;

  /// Compartilha a imagem [png] (chamada [name]) com o texto [text].
  Future<void> share(
    Uint8List png, {
    required String name,
    String? text,
  }) async {
    if (state) return;
    emit(true);
    try {
      await _share.shareImage(png, name: name, text: text);
    } finally {
      if (!isClosed) emit(false);
    }
  }
}

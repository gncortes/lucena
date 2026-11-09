import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/push/push_repository.dart';

/// Se o Android deixa o Lucena mostrar avisos (o aviso da aba Guia). Começa
/// verdadeiro: sem permissão conhecida, o aviso não aparece.
class PushPermissionCubit extends Cubit<bool> {
  PushPermissionCubit(this._push) : super(true);

  /// Nulo sem push na árvore (por exemplo, em teste de tela).
  final PushRepository? _push;

  Future<void> check() async {
    final push = _push;
    if (push == null) return;
    try {
      final allowed = await push.permitted();
      if (!isClosed) emit(allowed);
    } on Object {
      // Sem permissão conhecida, o aviso não aparece.
    }
  }

  /// Pede a permissão; negada, abre os ajustes do sistema.
  Future<void> enable() async {
    final push = _push;
    if (push == null) return;
    if (!await push.requestPermission()) await push.openSystemSettings();
    await check();
  }
}

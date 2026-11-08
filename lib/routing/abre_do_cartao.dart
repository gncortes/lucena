import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../ui/core/motion/rota_que_abre.dart';

/// H-ANI-04: `extra` de quem abre a aula pelo cartão (Escola). A rota cresce
/// do cartão marcado com `OrigemQueAbre(id:)`; a lição segue junto.
class AbreDoCartao {
  const AbreDoCartao({required this.id, this.lesson});

  /// Id da origem na tela de baixo.
  final String id;

  /// O `extra` de antes (a lição), para quem lê o destino.
  final Object? lesson;

  /// Id da origem do cartão de uma lição.
  static String daAula(String lessonId) => 'aula.$lessonId';

  /// A lição de um `extra`, venha ela embrulhada ou não.
  static Object? licaoDe(Object? extra) =>
      extra is AbreDoCartao ? extra.lesson : extra;
}

/// A página que cresce do cartão quando o `extra` é [AbreDoCartao]; `null`
/// para o chamador seguir com a página de sempre.
Page<void>? paginaQueAbre(
  BuildContext context,
  GoRouterState state,
  Widget child,
) {
  final extra = state.extra;
  if (extra is! AbreDoCartao) return null;
  return RotaQueAbre<void>(
    context: context,
    id: extra.id,
    key: state.pageKey,
    child: child,
  );
}

import 'package:flutter/material.dart';

import '../keys/motion_keys.dart';
import '../theme/app_sheet.dart';
import 'lucena_motion.dart';
import 'movimento_reduzido.dart';

/// A folha de baixo sobre o véu (H-ANI-06): sobe em 400 ms
/// (`emphasizedDecelerate`) sobre o véu preto de 32% e desce no mesmo tempo
/// ao fechar. Com [filtro], a folha do filtro da app bar (H-ANI-23): 350 ms.
/// Com movimento reduzido, aparece pronta.
///
/// É o único lugar do app que chama `showModalBottomSheet` (teste
/// `tokens_soltos_test.dart`). As telas abrem a folha pelo `showLucenaSheet`,
/// que dá a moldura (alça, raio e ✕) e chama esta.
abstract final class FolhaLucena {
  static Future<T?> mostrar<T>(
    BuildContext context, {
    required WidgetBuilder builder,
    bool isScrollControlled = true,
    bool enableDrag = true,
    bool isDismissible = true,
    bool useSafeArea = true,
    Color? backgroundColor = Colors.transparent,
    double? elevation = 0,
    Key? chave,
    bool filtro = false,
  }) {
    final reduzido = MovimentoReduzido.of(context);
    final duracao = filtro ? LucenaMotion.folhaDoFiltro : LucenaMotion.folha;
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: isScrollControlled,
      enableDrag: enableDrag,
      isDismissible: isDismissible,
      useSafeArea: useSafeArea,
      backgroundColor: backgroundColor,
      elevation: elevation,
      barrierColor: AppSheet.scrim,
      sheetAnimationStyle: reduzido
          ? AnimationStyle.noAnimation
          : AnimationStyle(
              duration: duracao,
              reverseDuration: duracao,
              curve: LucenaMotion.emphasizedDecelerate,
              reverseCurve: LucenaMotion.emphasizedAccelerate,
            ),
      builder: (context) =>
          KeyedSubtree(key: chave ?? MotionKeys.folha, child: builder(context)),
    );
  }
}

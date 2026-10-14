import 'package:flutter/material.dart';

import '../../core/theme/app_motion.dart';
import '../../core/theme/app_shape.dart';
import '../../core/widgets/sheet_close_button.dart';

/// Abre uma folha da lição roteirizada (a fala inteira e as Curiosidades)
/// numa rota transparente que imita a bottom sheet: o fundo escurece, a folha
/// sobe de baixo e o ✕ fica fora dela, acima do canto direito
/// ([SheetCloseButton]). Sendo uma `PageRoute`, o retrato do Viktor pode voar
/// da faixa até a folha como `Hero` (canvas `T70-etapa1-estados`, Gabriel
/// 14/10/2026).
Future<void> showScriptSheet(
  BuildContext context, {
  required WidgetBuilder builder,
  required double maxHeightFactor,
  Key? closeKey,
  String? closeTooltip,
}) {
  final barrier = MaterialLocalizations.of(context).modalBarrierDismissLabel;
  return Navigator.of(context).push<void>(
    PageRouteBuilder<void>(
      opaque: false,
      barrierDismissible: true,
      barrierLabel: barrier,
      barrierColor: Colors.black.withValues(alpha: 0.32),
      transitionDuration: AppMotion.of(context).panel,
      reverseTransitionDuration: AppMotion.of(context).panel,
      pageBuilder: (context, _, _) => ScriptSheetFrame(
        maxHeightFactor: maxHeightFactor,
        closeKey: closeKey,
        closeTooltip: closeTooltip,
        child: builder(context),
      ),
      transitionsBuilder: (context, animation, _, child) => SlideTransition(
        position: Tween(begin: const Offset(0, 1), end: Offset.zero).animate(
          CurvedAnimation(
            parent: animation,
            curve: AppMotion.enter,
            reverseCurve: AppMotion.exit,
          ),
        ),
        child: child,
      ),
    ),
  );
}

/// A folha em si: alça, raio 28 em cima, o ✕ flutuando acima dela e o
/// conteúdo. Arrastar para baixo fecha, como na bottom sheet.
class ScriptSheetFrame extends StatelessWidget {
  const ScriptSheetFrame({
    required this.child,
    required this.maxHeightFactor,
    this.closeKey,
    this.closeTooltip,
    super.key,
  });

  final Widget child;

  /// A altura máxima da folha, em fração da tela (sem o ✕).
  final double maxHeightFactor;
  final Key? closeKey;
  final String? closeTooltip;

  /// A velocidade do arrasto para baixo que fecha a folha.
  static const _dismissVelocity = 300.0;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final height = MediaQuery.sizeOf(context).height;
    void close() => Navigator.of(context).maybePop();
    return Align(
      alignment: Alignment.bottomCenter,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: Padding(
              padding: const EdgeInsetsDirectional.only(
                end: SheetCloseButton.margin,
                bottom: SheetCloseButton.gap,
              ),
              child: SheetCloseButton(
                key: closeKey,
                tooltip: closeTooltip,
                onPressed: close,
              ),
            ),
          ),
          GestureDetector(
            onVerticalDragEnd: (details) {
              if ((details.primaryVelocity ?? 0) > _dismissVelocity) close();
            },
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: height * maxHeightFactor),
              child: Material(
                color: colors.surfaceContainerLowest,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(AppShape.extraLarge),
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 32,
                        height: 4,
                        margin: const EdgeInsets.only(top: 12),
                        decoration: BoxDecoration(
                          color: colors.outlineVariant,
                          borderRadius: BorderRadius.circular(
                            AppShape.hairline,
                          ),
                        ),
                      ),
                    ),
                    Flexible(child: child),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

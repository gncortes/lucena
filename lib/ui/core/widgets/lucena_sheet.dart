import 'package:flutter/material.dart';

import '../keys/sheet_keys.dart';
import '../theme/app_shape.dart';
import '../theme/app_sheet.dart';
import 'sheet_close_button.dart';

/// O único jeito de abrir uma folha de baixo no app (T73, D7; canvas 79d4acc):
/// raio 28, alça 32×4 e o ✕ redondo por fora, acima do canto final
/// ([SheetCloseButton]). O fundo escurecido vem de [AppSheet.scrim]. O ✕ fecha
/// sem resultado (`null`); quem precisa de outro valor ao fechar passa
/// [onClose].
Future<T?> showLucenaSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  Key? sheetKey,
  Key? closeKey,
  Color? color,
  VoidCallback? onClose,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    elevation: 0,
    barrierColor: AppSheet.scrim,
    builder: (context) => LucenaSheetFrame(
      sheetKey: sheetKey,
      closeKey: closeKey,
      color: color,
      onClose: onClose ?? () => Navigator.of(context).pop(),
      child: builder(context),
    ),
  );
}

/// A moldura da folha: o ✕ por fora, a superfície com raio 28 e a alça.
class LucenaSheetFrame extends StatelessWidget {
  const LucenaSheetFrame({
    required this.child,
    required this.onClose,
    this.sheetKey,
    this.closeKey,
    this.color,
    super.key,
  });

  final Widget child;
  final VoidCallback onClose;
  final Key? sheetKey;
  final Key? closeKey;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sheet = theme.bottomSheetTheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.only(
            end: SheetCloseButton.margin,
            bottom: SheetCloseButton.gap,
          ),
          child: Align(
            alignment: AlignmentDirectional.centerEnd,
            child: SheetCloseButton(
              key: closeKey ?? SheetKeys.close,
              onPressed: onClose,
            ),
          ),
        ),
        Flexible(
          child: Material(
            key: sheetKey ?? SheetKeys.surface,
            color:
                color ??
                sheet.modalBackgroundColor ??
                theme.colorScheme.surfaceContainerLow,
            shape: AppSheet.shape,
            clipBehavior: Clip.antiAlias,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: AppSheet.handleStrip,
                  child: Center(
                    child: Container(
                      key: SheetKeys.handle,
                      width: AppSheet.handleSize.width,
                      height: AppSheet.handleSize.height,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.onSurfaceVariant.withValues(
                          alpha: .4,
                        ),
                        borderRadius: BorderRadius.circular(AppShape.hairline),
                      ),
                    ),
                  ),
                ),
                Flexible(child: child),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

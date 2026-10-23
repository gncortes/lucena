import 'package:flutter/material.dart';
import 'package:lucena_ui/lucena_ui.dart';

import 'sheet_close_button.dart';
import 'sheet_header.dart';

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
  bool enableDrag = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    enableDrag: enableDrag,
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
    final surface =
        color ??
        sheet.modalBackgroundColor ??
        theme.colorScheme.surfaceContainerLow;
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
            color: surface,
            shape: AppSheet.shape,
            clipBehavior: Clip.antiAlias,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(
                  height: AppSheet.handleStrip,
                  child: Center(child: SheetHandle(key: SheetKeys.handle)),
                ),
                // O `useSafeArea` da folha só guarda o topo e os lados: com a
                // tela de ponta a ponta, a barra de navegação cobria o fim
                // da folha ("Som e voz" cortada, Gabriel 16/10/2026). A
                // superfície desce por trás da barra e o conteúdo para
                // acima dela; o SafeArea de dentro de cada folha vira no-op.
                Flexible(
                  child: SafeArea(
                    top: false,
                    child: ChipSurface(color: surface, child: child),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

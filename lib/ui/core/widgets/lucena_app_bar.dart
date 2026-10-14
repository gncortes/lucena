import 'package:flutter/material.dart';

/// A barra superior padrão do app. Sem ações (ou com a lista vazia), o título
/// fica centralizado; com ação, fica à esquerda, como no Material. Quem precisa
/// de outra coisa passa `centerTitle` explicitamente.
///
/// Por dentro é um [AppBar] comum, então `find.byType(AppBar)` nos testes e o
/// tamanho preferido (com `bottom`) funcionam como antes.
class LucenaAppBar extends StatelessWidget implements PreferredSizeWidget {
  LucenaAppBar({
    super.key,
    Widget? leading,
    bool automaticallyImplyLeading = true,
    Widget? title,
    List<Widget>? actions,
    PreferredSizeWidget? bottom,
    Color? backgroundColor,
    Color? foregroundColor,
    double? elevation,
    double? scrolledUnderElevation,
    ShapeBorder? shape,
    double? toolbarHeight,
    double? leadingWidth,
    double? titleSpacing,
    Widget? flexibleSpace,
    bool? centerTitle,
  }) : _bar = AppBar(
         leading: leading,
         automaticallyImplyLeading: automaticallyImplyLeading,
         title: title,
         actions: actions,
         bottom: bottom,
         backgroundColor: backgroundColor,
         foregroundColor: foregroundColor,
         elevation: elevation,
         scrolledUnderElevation: scrolledUnderElevation,
         shape: shape,
         toolbarHeight: toolbarHeight,
         leadingWidth: leadingWidth,
         titleSpacing: titleSpacing,
         flexibleSpace: flexibleSpace,
         centerTitle: centerTitle ?? (actions == null || actions.isEmpty),
       );

  final AppBar _bar;

  @override
  Size get preferredSize => _bar.preferredSize;

  @override
  Widget build(BuildContext context) => _bar;
}

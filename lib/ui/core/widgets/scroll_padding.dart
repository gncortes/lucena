import 'package:flutter/widgets.dart';

/// O espaço de uma lista que rola até o fim da tela: o pedido mais a barra de
/// navegação do sistema, para o último item não ficar atrás dela.
EdgeInsets scrollPadding(
  BuildContext context, {
  double left = 0,
  double top = 0,
  double right = 0,
  double bottom = 24,
}) => EdgeInsets.fromLTRB(
  left,
  top,
  right,
  bottom + MediaQuery.paddingOf(context).bottom,
);

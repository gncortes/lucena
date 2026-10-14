import 'package:flutter/material.dart';

/// O texto dos botões (CompBotao). O botão primário do rodapé é 16/24; o de
/// dentro de cartão continua no `labelLarge` do tema (14/20).
abstract final class AppButtonText {
  static const footerSize = 16.0;
  static const footerLineHeight = 24.0;

  /// 16 com linha de 24, para o botão primário de rodapé.
  static TextStyle? footer(BuildContext context) => Theme.of(context)
      .textTheme
      .labelLarge
      ?.copyWith(fontSize: footerSize, height: footerLineHeight / footerSize);
}

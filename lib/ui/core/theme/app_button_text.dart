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

/// Põe o texto de 16/24 nos botões de 52 de tudo o que estiver dentro (o
/// rodapé de ações e as folhas): preenchido, contornado e de texto, somando
/// ao estilo que o tema já dá (altura mínima, forma).
class FooterButtonTheme extends StatelessWidget {
  const FooterButtonTheme({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text = ButtonStyle(
      textStyle: WidgetStatePropertyAll(AppButtonText.footer(context)),
    );
    return FilledButtonTheme(
      data: FilledButtonThemeData(
        style: theme.filledButtonTheme.style?.merge(text) ?? text,
      ),
      child: OutlinedButtonTheme(
        data: OutlinedButtonThemeData(
          style: theme.outlinedButtonTheme.style?.merge(text) ?? text,
        ),
        child: TextButtonTheme(
          data: TextButtonThemeData(
            style: theme.textButtonTheme.style?.merge(text) ?? text,
          ),
          child: child,
        ),
      ),
    );
  }
}

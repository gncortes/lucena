import 'package:flutter/material.dart';

import 'app_colors.dart';

/// As três sombras do app (D34). Nenhuma tela escreve `BoxShadow` à mão.
abstract final class AppShadow {
  /// Brilho em volta do que está em destaque (degrau, nó da Escola).
  static BoxShadow glow(ColorScheme colors) =>
      BoxShadow(color: colors.primary.withValues(alpha: .35), blurRadius: 12);

  /// Sombra do retrato no confronto.
  static const portrait = BoxShadow(color: AppColors.black38, blurRadius: 12);

  /// Painel que flutua sobre o conteúdo, vindo de baixo.
  static BoxShadow floating(ColorScheme colors) => BoxShadow(
    color: colors.shadow.withValues(alpha: .12),
    blurRadius: 12,
    offset: const Offset(0, -2),
  );
}

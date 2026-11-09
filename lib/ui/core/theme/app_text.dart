import 'package:flutter/material.dart';

/// Título de cartão para quem só tem o [ThemeData] (medida de altura sem
/// contexto): o mesmo de `context.cardTitle`.
extension AppTextOnTheme on ThemeData {
  TextStyle? get cardTitle =>
      textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700);
}

/// Os três estilos de texto do app além dos do Material 3 (D28).
extension AppText on BuildContext {
  /// Título de cartão: `titleMedium` em 700.
  TextStyle? get cardTitle => Theme.of(this).cardTitle;

  /// Número grande (nível, recorde, placar): `headlineMedium` em 800.
  TextStyle? get bigNumber =>
      Theme.of(this).textTheme.headlineMedium
          ?.copyWith(fontWeight: FontWeight.w800);

  /// Título de tela: `headlineSmall` em 700.
  TextStyle? get screenTitle =>
      Theme.of(this).textTheme.headlineSmall
          ?.copyWith(fontWeight: AppWeight.strong);

  /// Título de seção: `titleSmall` em `onSurfaceVariant`.
  TextStyle? get sectionTitle {
    final theme = Theme.of(this);
    return theme.textTheme.titleSmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
  }
}

/// Peso de fonte para o que não parte de um estilo do tema: trecho em
/// destaque dentro de um texto corrido, número de selo e relógio. `regular` e
/// `medium` são os pesos 400 e 500 da tipografia M3 do design system
/// (`design/CONVENCOES.md`).
abstract final class AppWeight {
  static const regular = FontWeight.w400;
  static const medium = FontWeight.w500;
  static const strong = FontWeight.w700;
  static const heavy = FontWeight.w800;
}

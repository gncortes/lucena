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
/// destaque dentro de um texto corrido, número de selo e relógio.
abstract final class AppWeight {
  static const strong = FontWeight.w700;
  static const heavy = FontWeight.w800;
}

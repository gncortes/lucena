import 'package:flutter/material.dart';

/// Link de texto (T70): cor `primary`, sublinhado, mesmo estilo do texto em
/// volta e alvo de toque de 48 dp. Serve ao "Ver resposta", ao "Ver enunciado
/// completo" ↔ "Ocultar enunciado" (um widget, o texto troca) e ao "Ver
/// explicação completa".
class TextLink extends StatelessWidget {
  const TextLink({
    required this.label,
    required this.onTap,
    this.style,
    super.key,
  });

  /// Alvo mínimo de toque.
  static const minTarget = 48.0;

  final String label;
  final VoidCallback onTap;

  /// O estilo do texto onde o link entra; sem ele, `bodyMedium`.
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final base = style ?? Theme.of(context).textTheme.bodyMedium;
    return Semantics(
      link: true,
      label: label,
      excludeSemantics: true,
      onTap: onTap,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: minTarget,
              minWidth: minTarget,
            ),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              widthFactor: 1,
              child: Text(
                label,
                style: base?.copyWith(
                  color: colors.primary,
                  decoration: TextDecoration.underline,
                  decorationColor: colors.primary,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

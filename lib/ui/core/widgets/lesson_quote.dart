import 'package:flutter/material.dart';

import '../../wiki/widgets/linked_text.dart';
import '../keys/explanation_keys.dart';
import '../theme/app_spacing.dart';

/// Contexto e história da lição V2 (LICOES-V2 §10): uma citação com barra
/// lateral, texto menor e apagado, sem rótulo nem ícone. Os nomes marcados
/// continuam links sublinhados (via [LinkedText]).
class LessonQuote extends StatelessWidget {
  const LessonQuote({required this.id, required this.texts, super.key});

  /// O bloco de explicação que a citação representa (chave de teste).
  final String id;
  final List<String> texts;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    // Um toque na citação não abre o painel recolhido: o toque sem alvo é
    // consumido aqui (os links dentro dela continuam vencendo).
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {},
      child: Container(
        key: ExplanationKeys.quote(id),
        padding: const EdgeInsetsDirectional.only(start: AppSpacing.md),
        decoration: BoxDecoration(
          border: BorderDirectional(
            start: BorderSide(
              color: theme.colorScheme.outlineVariant,
              width: 3,
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [for (final text in texts) LinkedText(text, style: style)],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../domain/models/endgame_lesson.dart';
import '../l10n/l10n.dart';
import '../theme/app_shape.dart';

/// Um link discreto para a referência de onde vem uma posição: a partida no
/// Lichess (parada na posição), o estudo ou a página. Abre no navegador do
/// aparelho. Sem `url`, não aparece.
class ReferenceLink extends StatelessWidget {
  const ReferenceLink({super.key, required this.reference});

  final Reference reference;

  @override
  Widget build(BuildContext context) {
    final url = reference.url;
    final uri = url == null ? null : Uri.tryParse(url);
    if (uri == null) return const SizedBox.shrink();
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final color = theme.colorScheme.primary;
    final label = switch (reference.kind) {
      'game' => l10n.referenceLinkGame,
      'study' => l10n.referenceLinkStudy,
      _ => l10n.referenceLinkWeb,
    };
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppShape.small),
        onTap: () => launchUrl(uri, mode: LaunchMode.externalApplication),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.open_in_new, size: 16, color: color),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: color,
                    decoration: TextDecoration.underline,
                    decorationColor: color,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

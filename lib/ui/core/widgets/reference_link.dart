import 'package:flutter/material.dart';
import 'package:lucena_ui/lucena_ui.dart';

import '../../../domain/models/endgame_lesson.dart';
import '../l10n/l10n.dart';
import 'external_page_sheet.dart';

/// Um link discreto para a referência de onde vem uma posição. Abre dentro do
/// app, na folha da página ([showExternalPage]). Sem `url`, não aparece.
class ReferenceLink extends StatelessWidget {
  const ReferenceLink({
    super.key,
    required this.reference,
    this.blackBelow = false,
  });

  final Reference reference;

  /// O aluno joga de pretas: o Lichess abre o tabuleiro do lado dele.
  final bool blackBelow;

  /// O link do Lichess virado para as pretas: a partida ganha `/black` (o
  /// lance, depois do `#`, fica) e a análise ganha `?color=black`. Outros
  /// sites, intactos.
  static Uri forBlack(Uri uri) {
    if (!uri.host.toLowerCase().endsWith('lichess.org')) return uri;
    final path = uri.pathSegments.where((p) => p.isNotEmpty).toList();
    if (path.isEmpty) return uri;
    if (path.first == 'analysis') {
      return uri.replace(
        queryParameters: {...uri.queryParameters, 'color': 'black'},
      );
    }
    final game = RegExp(r'^[A-Za-z0-9]{8,12}$');
    if (game.hasMatch(path.first) &&
        (path.length == 1 ||
            (path.length == 2 && (path[1] == 'white' || path[1] == 'black')))) {
      return uri.replace(pathSegments: [path.first, 'black']);
    }
    return uri;
  }

  static String labelFor(BuildContext context, Reference reference, Uri uri) {
    final host = uri.host.toLowerCase();
    final l10n = context.l10n;
    if (host == 'wikipedia.org' || host.endsWith('.wikipedia.org')) {
      return l10n.referenceLinkWikipedia;
    }
    if (host == 'lichess.org' || host.endsWith('.lichess.org')) {
      if (reference.kind == 'study' && uri.path.startsWith('/study')) {
        return l10n.referenceLinkStudy;
      }
      if (reference.kind == 'game' && !uri.path.startsWith('/analysis')) {
        return l10n.referenceLinkGame;
      }
      return l10n.referenceLinkLichess;
    }
    return l10n.referenceLinkWeb;
  }

  @override
  Widget build(BuildContext context) {
    final url = reference.url;
    final uri = url == null ? null : Uri.tryParse(url);
    if (uri == null) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final color = theme.colorScheme.primary;
    final label = labelFor(context, reference, uri);
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppShape.small),
        onTap: () =>
            showExternalPage(context, blackBelow ? forBlack(uri) : uri),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xs,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.open_in_new, size: AppIconSize.small, color: color),
              const SizedBox(width: AppSpacing.sm),
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

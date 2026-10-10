import 'package:flutter/material.dart';

import '../keys/external_page_keys.dart';
import '../l10n/l10n.dart';
import 'web_pages.dart';

/// Abre uma página da web dentro do app (a Wikipedia de um nome da fala, a
/// partida ou o estudo no Lichess): uma folha alta com a página, o título
/// dela e o domínio no topo e um ✕. Sem internet, a folha só avisa; a aula
/// atrás fica como estava.
Future<void> showExternalPage(BuildContext context, Uri url) {
  final pages = WebPages.of(context);
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    // A página rola na vertical: arrastar não fecha a folha (o ✕ fecha).
    enableDrag: false,
    showDragHandle: false,
    builder: (context) => FractionallySizedBox(
      heightFactor: 0.94,
      child: ExternalPageSheet(url: url, pages: pages),
    ),
  );
}

/// A folha com a página.
class ExternalPageSheet extends StatefulWidget {
  const ExternalPageSheet({required this.url, required this.pages, super.key});

  final Uri url;
  final WebPages pages;

  /// O domínio, sem `www.` nem `m.`: `pt.wikipedia.org`, `lichess.org`.
  static String domainOf(Uri url) =>
      url.host.replaceFirst(RegExp(r'^(www|m)\.'), '');

  @override
  State<ExternalPageSheet> createState() => _ExternalPageSheetState();
}

enum _Phase { loading, loaded, failed }

class _ExternalPageSheetState extends State<ExternalPageSheet> {
  var _phase = _Phase.loading;
  String? _title;

  // A página é criada uma vez: a troca de fase não a recarrega.
  late final Widget _page = widget.pages.page(
    widget.url,
    onLoaded: (title) {
      if (!mounted || _phase == _Phase.failed) return;
      setState(() {
        _phase = _Phase.loaded;
        _title = title?.trim();
      });
    },
    onFailed: () {
      if (!mounted || _phase == _Phase.failed) return;
      setState(() => _phase = _Phase.failed);
    },
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final domain = ExternalPageSheet.domainOf(widget.url);
    final title = _title;
    final hasTitle = title != null && title.isNotEmpty && title != domain;
    return Column(
      key: ExternalPageKeys.sheet,
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(16, 8, 4, 8),
          child: Row(
            children: [
              Icon(Icons.public, size: 20, color: colors.onSurfaceVariant),
              const SizedBox(width: 12),
              // O título da página (quando abriu) e o domínio embaixo; antes,
              // só o domínio.
              Expanded(
                child: Column(
                  key: ExternalPageKeys.title,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      hasTitle ? title : domain,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (hasTitle)
                      Text(
                        domain,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
              IconButton(
                key: ExternalPageKeys.close,
                tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: _phase == _Phase.failed
              ? _Offline(theme: theme)
              : Stack(
                  children: [
                    Positioned.fill(
                      child: KeyedSubtree(
                        key: ExternalPageKeys.page,
                        child: _page,
                      ),
                    ),
                    if (_phase == _Phase.loading)
                      const Align(
                        alignment: AlignmentDirectional.topCenter,
                        child: LinearProgressIndicator(
                          key: ExternalPageKeys.loading,
                        ),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

class _Offline extends StatelessWidget {
  const _Offline({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Center(
      key: ExternalPageKeys.offline,
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.wifi_off_rounded,
              size: 48,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.externalPageOfflineTitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.externalPageOfflineBody,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

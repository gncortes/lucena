import 'package:flutter/material.dart';

import '../../core/keys/wiki_keys.dart';
import '../../core/l10n/l10n.dart';
import 'web_pages.dart';

/// Abre, dentro do app, a página da Wikipedia de um nome da fala: uma folha
/// alta com a página e um ✕. Sem internet, a folha só avisa; a aula atrás
/// fica como estava.
Future<void> showWikiPage(BuildContext context, Uri url) {
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
      child: WikiSheet(url: url, pages: pages),
    ),
  );
}

/// A folha com a página da Wikipedia.
class WikiSheet extends StatefulWidget {
  const WikiSheet({required this.url, required this.pages, super.key});

  final Uri url;
  final WebPages pages;

  @override
  State<WikiSheet> createState() => _WikiSheetState();
}

enum _Phase { loading, loaded, failed }

class _WikiSheetState extends State<WikiSheet> {
  var _phase = _Phase.loading;

  // A página é criada uma vez: a troca de fase não a recarrega.
  late final Widget _page = widget.pages.page(
    widget.url,
    onLoaded: () => _set(_Phase.loaded),
    onFailed: () => _set(_Phase.failed),
  );

  void _set(_Phase phase) {
    if (!mounted || _phase == phase || _phase == _Phase.failed) return;
    setState(() => _phase = phase);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Column(
      key: WikiKeys.sheet,
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(16, 4, 4, 0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  l10n.wikiTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              IconButton(
                key: WikiKeys.close,
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
                      child: KeyedSubtree(key: WikiKeys.page, child: _page),
                    ),
                    if (_phase == _Phase.loading)
                      const Align(
                        alignment: AlignmentDirectional.topCenter,
                        child: LinearProgressIndicator(key: WikiKeys.loading),
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
      key: WikiKeys.offline,
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
              l10n.wikiOfflineTitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.wikiOfflineBody,
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

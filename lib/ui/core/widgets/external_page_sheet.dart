import 'package:flutter/material.dart';
import 'package:lucena_ui/lucena_ui.dart';

import '../keys/external_page_keys.dart';
import '../l10n/l10n.dart';
import 'animated_progress.dart';
import 'lucena_sheet.dart';
import 'sheet_header.dart';
import 'web_pages.dart';

/// Abre uma página da web dentro do app (a Wikipedia de um nome da fala, a
/// partida ou o estudo no Lichess): uma folha alta com a página, o título
/// dela e o domínio no topo, e o ✕ flutuando acima dela, fora, como o da
/// fala do Viktor ([SheetCloseButton]). Sem internet, a folha só avisa; a
/// aula atrás fica como estava.
Future<void> showExternalPage(BuildContext context, Uri url) {
  final pages = WebPages.of(context);
  // A página rola na vertical: arrastar não fecha a folha (o ✕ fecha).
  return showLucenaSheet<void>(
    context,
    enableDrag: false,
    sheetKey: ExternalPageKeys.sheet,
    closeKey: ExternalPageKeys.close,
    builder: (context) => SizedBox(
      // Folha alta: o que sobra abaixo do ✕ e da alça.
      height: MediaQuery.sizeOf(context).height * 0.96,
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
    final domain = ExternalPageSheet.domainOf(widget.url);
    final title = _title;
    final hasTitle = title != null && title.isNotEmpty && title != domain;
    return _content(theme, domain, hasTitle ? title : null);
  }

  Widget _content(ThemeData theme, String domain, String? title) {
    return Column(
      children: [
        // O título da página (quando abriu) e o domínio embaixo; antes, só o
        // domínio.
        KeyedSubtree(
          key: ExternalPageKeys.title,
          child: SheetHeader(
            title: title ?? domain,
            hint: title == null ? null : domain,
            titleMaxLines: 2,
          ),
        ),
        const Divider(),
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
                        child: AnimatedProgress(
                          key: ExternalPageKeys.loading,
                          value: null,
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
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.wifi_off_rounded,
              size: AppIconSize.illustration,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              l10n.externalPageOfflineTitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
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

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/models/glossary_term.dart';
import '../../core/keys/glossary_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_icon_size.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/external_page_sheet.dart';
import '../../core/widgets/lucena_sheet.dart';
import '../../core/widgets/sheet_header.dart';
import '../view_models/glossary_cubit.dart';

/// Abre a Wikipédia do termo: a folha de página externa do app (título,
/// domínio e o ✕ por fora). Sem verbete, nada.
Future<void> showGlossaryWiki(BuildContext context, GlossaryTerm term) async {
  final url = term.wikiUrl;
  if (url == null) return;
  await showExternalPage(context, url);
}

/// A folha do termo (protótipo `glossarioK`, aba "termo"): o nome, a
/// definição e, embaixo, "Ler na Wikipédia · pt.wikipedia.org" ou, sem
/// internet, o aviso de que a definição continua aqui. ✕ por fora.
Future<void> showGlossaryTermSheet(BuildContext context, GlossaryTerm term) {
  final cubit = context.read<GlossaryCubit>();
  if (term.wikiUrl != null) cubit.checkOnline();
  return showLucenaSheet<void>(
    context,
    sheetKey: GlossaryKeys.sheet,
    closeKey: GlossaryKeys.sheetClose,
    builder: (sheetContext) => BlocProvider.value(
      value: cubit,
      child: GlossaryTermSheet(
        term: term,
        onWiki: () {
          Navigator.of(sheetContext).pop();
          showGlossaryWiki(context, term);
        },
      ),
    ),
  );
}

class GlossaryTermSheet extends StatelessWidget {
  const GlossaryTermSheet({
    required this.term,
    required this.onWiki,
    super.key,
  });

  final GlossaryTerm term;
  final VoidCallback onWiki;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final url = term.wikiUrl;
    final online = context.select((GlossaryCubit c) => c.state.online);
    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SheetHeader(title: term.name, titleMaxLines: 2),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: Text(term.definition, style: theme.textTheme.bodyLarge),
          ),
          if (url != null) ...[
            const SizedBox(height: AppSpacing.lg),
            const Divider(
              height: 1,
              indent: AppSpacing.xl,
              endIndent: AppSpacing.xl,
            ),
            online
                ? _Row(
                    key: GlossaryKeys.wiki,
                    icon: Icons.menu_book_outlined,
                    title: context.l10n.glossaryReadOnWikipedia,
                    subtitle: ExternalPageSheet.domainOf(url),
                    onTap: onWiki,
                  )
                : _Row(
                    key: GlossaryKeys.offline,
                    icon: Icons.wifi_off_rounded,
                    title: context.l10n.glossaryOfflineTitle,
                    subtitle: context.l10n.glossaryOfflineBody,
                  ),
          ],
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}

/// Uma linha de 64 com ícone, título e linha de apoio (CompReferencia).
class _Row extends StatelessWidget {
  const _Row({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
    super.key,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 64),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: [
              Icon(icon, color: colors.onSurfaceVariant),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.bodyLarge),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (onTap != null)
                Icon(
                  Icons.open_in_new,
                  size: AppIconSize.button,
                  color: colors.primary,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

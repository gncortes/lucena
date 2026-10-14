import 'package:flutter/material.dart';

import '../../../domain/models/endgame_lesson.dart';
import '../../../domain/models/lesson_script.dart';
import '../../core/keys/curiosities_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_shape.dart';
import '../../core/widgets/external_page_sheet.dart';

/// Abre a folha Curiosidades do exemplo (o livro da barra da lição): o texto
/// sobre a posição, a citação (se houver) e, no fim, as referências. Toda
/// referência com link abre dentro do app ([showExternalPage]); a de jogador
/// mostra o círculo com as iniciais e leva à Wikipédia.
///
/// [texts] resolve as chaves de fala de [curiosities]; [lessonRefs] são as
/// referências da lição, para os ids que a folha cita.
Future<void> showCuriositiesSheet(
  BuildContext context,
  Curiosities curiosities, {
  required ScriptTexts texts,
  List<Reference> lessonRefs = const [],
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    constraints: BoxConstraints(
      maxHeight: MediaQuery.sizeOf(context).height * 0.92,
    ),
    builder: (context) => CuriositiesSheet(
      curiosities: curiosities,
      texts: texts,
      lessonRefs: lessonRefs,
    ),
  );
}

/// O conteúdo da folha (público para os testes).
class CuriositiesSheet extends StatelessWidget {
  const CuriositiesSheet({
    required this.curiosities,
    required this.texts,
    this.lessonRefs = const [],
    super.key,
  });

  final Curiosities curiosities;
  final ScriptTexts texts;
  final List<Reference> lessonRefs;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final quote = curiosities.quote;
    final refs = [
      for (final ref in curiosities.references)
        if (ref.resolve(lessonRefs) case final r? when r.isLearnerFacing) r,
    ];
    return Column(
      key: CuriositiesKeys.sheet,
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.only(start: 24, end: 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  l10n.curiositiesTitle,
                  key: CuriositiesKeys.title,
                  style: theme.textTheme.titleLarge,
                ),
              ),
              IconButton(
                key: CuriositiesKeys.close,
                tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.of(context).maybePop(),
              ),
            ],
          ),
        ),
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsetsDirectional.fromSTEB(24, 8, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _SectionLabel(l10n.curiositiesAbout),
                const SizedBox(height: 8),
                Text(
                  texts.say(curiosities.t),
                  key: CuriositiesKeys.about,
                  style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
                ),
                if (quote != null) ...[
                  const SizedBox(height: 24),
                  _QuoteCard(
                    text: texts.say(quote),
                    author: curiosities.quoteAuthor,
                  ),
                ],
                if (refs.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  _SectionLabel(l10n.curiositiesReferences),
                  const SizedBox(height: 8),
                  Column(
                    key: CuriositiesKeys.references,
                    children: [
                      for (final ref in refs) _ReferenceTile(reference: ref),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      header: true,
      child: Text(
        text,
        style: theme.textTheme.titleSmall?.copyWith(
          color: theme.colorScheme.primary,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

class _QuoteCard extends StatelessWidget {
  const _QuoteCard({required this.text, this.author});

  final String text;
  final String? author;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final author = this.author;
    return DecoratedBox(
      key: CuriositiesKeys.quote,
      decoration: BoxDecoration(
        color: colors.primaryContainer,
        borderRadius: BorderRadius.circular(AppShape.large),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(
              Icons.format_quote_rounded,
              size: 32,
              color: colors.onPrimaryContainer.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 4),
            Text(
              text,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontStyle: FontStyle.italic,
                height: 1.5,
                color: colors.onPrimaryContainer,
              ),
            ),
            if (author != null && author.isNotEmpty) ...[
              const SizedBox(height: 12),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: Text(
                  context.l10n.curiositiesQuoteBy(author),
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: colors.onPrimaryContainer,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ReferenceTile extends StatelessWidget {
  const _ReferenceTile({required this.reference});

  final Reference reference;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final l10n = context.l10n;
    final url = reference.url;
    final uri = url == null ? null : Uri.tryParse(url);
    final isPlayer = reference.kind == 'player';
    final title = switch (reference.kind) {
      'book' => l10n.endgameReferenceBook(
        reference['author'] ?? '',
        reference.title,
        reference['publisher'] ?? '',
        reference['year'] ?? '',
      ),
      'study' => l10n.endgameReferenceStudy(
        reference['author'] ?? '',
        reference.title,
      ),
      'game' => l10n.endgameReferenceGame(
        reference['white'] ?? '',
        reference['black'] ?? '',
        reference['event'] ?? '',
        reference['year'] ?? '',
      ),
      _ => reference.title,
    };
    final dates = reference['dates'];
    final leading = isPlayer
        ? CircleAvatar(
            key: CuriositiesKeys.playerAvatar(reference.id),
            radius: 22,
            backgroundColor: colors.tertiaryContainer,
            foregroundColor: colors.onTertiaryContainer,
            child: Text(
              reference.initials,
              style: theme.textTheme.titleSmall?.copyWith(
                color: colors.onTertiaryContainer,
              ),
            ),
          )
        : CircleAvatar(
            radius: 22,
            backgroundColor: colors.secondaryContainer,
            foregroundColor: colors.onSecondaryContainer,
            child: Icon(_icon(reference.kind), size: 22),
          );
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppShape.large),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: CuriositiesKeys.reference(reference.id),
          onTap: uri == null ? null : () => showExternalPage(context, uri),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 64),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  leading,
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: theme.textTheme.bodyMedium),
                        if (isPlayer && dates != null && dates.isNotEmpty)
                          Text(
                            dates,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                        if (uri != null) ...[
                          const SizedBox(height: 8),
                          _SourceChip(reference: reference, uri: uri),
                        ],
                      ],
                    ),
                  ),
                  if (uri != null) ...[
                    const SizedBox(width: 8),
                    Icon(Icons.open_in_new, size: 18, color: colors.primary),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static IconData _icon(String kind) => switch (kind) {
    'book' => Icons.menu_book_outlined,
    'study' => Icons.library_books_outlined,
    'game' => Icons.sports_esports_outlined,
    'tablebase' => Icons.table_chart_outlined,
    _ => Icons.link,
  };
}

/// O chip com o domínio da página (`lichess.org`, `en.wikipedia.org`).
class _SourceChip extends StatelessWidget {
  const _SourceChip({required this.reference, required this.uri});

  final Reference reference;
  final Uri uri;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final host = uri.host.toLowerCase();
    final icon = host.endsWith('wikipedia.org')
        ? Icons.public
        : host.endsWith('lichess.org')
        ? Icons.sports_esports_outlined
        : Icons.language;
    return DecoratedBox(
      key: CuriositiesKeys.source(reference.id),
      decoration: BoxDecoration(
        color: colors.secondaryContainer,
        borderRadius: BorderRadius.circular(AppShape.full),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: colors.onSecondaryContainer),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                ExternalPageSheet.domainOf(uri),
                style: theme.textTheme.labelMedium?.copyWith(
                  color: colors.onSecondaryContainer,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

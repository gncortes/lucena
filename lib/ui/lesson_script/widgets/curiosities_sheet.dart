import 'package:flutter/material.dart';

import '../../../domain/models/endgame_lesson.dart';
import '../../../domain/models/lesson_script.dart';
import '../../core/keys/curiosities_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/widgets/external_page_sheet.dart';

/// Abre a folha Curiosidades do exemplo (o livro da barra da lição): o texto
/// sobre a posição, a citação (se houver) e, no fim, as referências. Visual do
/// canvas `T70-curiosidades`, variante A (Gabriel, 14/10/2026): rótulos em
/// caixa-alta, citação com barra lateral e referências em linhas com filete.
/// Toda referência com link abre dentro do app ([showExternalPage]).
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
                  _Quote(
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
                      for (final (i, ref) in refs.indexed)
                        _ReferenceRow(
                          reference: ref,
                          last: i == refs.length - 1,
                        ),
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

/// O rótulo de seção: caixa-alta, pequeno, em cinza.
class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      header: true,
      child: Text(
        text.toUpperCase(),
        style: theme.textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w600,
          letterSpacing: 0.8,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

/// A citação: barra azul de 4 dp à esquerda, texto em itálico e o autor
/// embaixo, em cinza.
class _Quote extends StatelessWidget {
  const _Quote({required this.text, this.author});

  final String text;
  final String? author;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final author = this.author;
    return Container(
      key: CuriositiesKeys.quote,
      padding: const EdgeInsetsDirectional.fromSTEB(16, 4, 0, 4),
      decoration: BoxDecoration(
        border: BorderDirectional(
          start: BorderSide(color: colors.primary, width: 4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            context.l10n.curiositiesQuoted(text),
            style: theme.textTheme.bodyLarge?.copyWith(
              fontSize: 17,
              height: 26 / 17,
              fontStyle: FontStyle.italic,
              color: colors.onSurface,
            ),
          ),
          if (author != null && author.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              author,
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 13,
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Uma referência: ícone neutro do tipo, título, a linha de detalhe (autor,
/// ano, datas, domínio) e o ícone de abrir; filete em cima (e embaixo na
/// última).
class _ReferenceRow extends StatelessWidget {
  const _ReferenceRow({required this.reference, required this.last});

  final Reference reference;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final l10n = context.l10n;
    final url = reference.url;
    final uri = url == null ? null : Uri.tryParse(url);
    final (title, details) = switch (reference.kind) {
      'book' => (reference.title, [reference['author'], reference['year']]),
      'study' => (reference.title, [reference['author']]),
      'game' => (
        l10n.endgameReferenceGame(
          reference['white'] ?? '',
          reference['black'] ?? '',
          reference['event'] ?? '',
          reference['year'] ?? '',
        ),
        const <String?>[],
      ),
      'player' => (reference.title, [reference['dates']]),
      _ => (reference.title, const <String?>[]),
    };
    final detail = [
      for (final d in details)
        if (d != null && d.isNotEmpty) d,
      if (uri != null) ExternalPageSheet.domainOf(uri),
    ].join(' · ');
    final line = BorderSide(color: colors.outlineVariant);
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(top: line, bottom: last ? line : BorderSide.none),
      ),
      child: InkWell(
        key: CuriositiesKeys.reference(reference.id),
        onTap: uri == null ? null : () => showExternalPage(context, uri),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 64),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                Icon(
                  reference.kind == 'book'
                      ? Icons.menu_book_outlined
                      : Icons.link_rounded,
                  size: 24,
                  color: colors.onSurfaceVariant,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontSize: 15,
                          height: 20 / 15,
                        ),
                      ),
                      if (detail.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          detail,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontSize: 13,
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (uri != null) ...[
                  const SizedBox(width: 16),
                  Icon(Icons.open_in_new, size: 20, color: colors.primary),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

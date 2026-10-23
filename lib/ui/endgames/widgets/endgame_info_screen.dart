import 'package:flutter/material.dart';
import 'package:lucena/ui/core/widgets/lucena_app_bar.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucena_ui/lucena_ui.dart';

import '../../../domain/models/endgame_lesson.dart';
import '../../core/keys/endgames_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/widgets/external_page_sheet.dart';
import '../../core/widgets/position_board.dart';
import '../../core/widgets/reference_link.dart';
import '../../core/widgets/scroll_padding.dart';
import '../../wiki/widgets/linked_text.dart';
import '../view_models/endgame_lesson_cubit.dart';
import '../../core/widgets/info_chip.dart';

/// As informações de uma aula de final: a história, as posições-base com o
/// crédito de quem as achou e as referências (com link quando há).
class EndgameInfoScreen extends StatelessWidget {
  const EndgameInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final state = context.watch<EndgameLessonCubit>().state;
    final lesson = state.lesson;
    final texts = state.texts;
    return Scaffold(
      key: EndgameInfoKeys.screen,
      // O título da aula pode ser longo: ele vem no corpo, inteiro.
      appBar: LucenaAppBar(title: Text(l10n.endgameInfoTooltip)),
      body: lesson == null
          ? const SizedBox.shrink()
          : ListView(
              padding: scrollPadding(
                context,
                left: 16,
                top: 8,
                right: 16,
                bottom: 32,
              ),
              children: [
                Text(texts.lessonTitle(lesson.id), style: context.screenTitle),
                _header(context, l10n.endgameInfoHistory),
                LinkedText(
                  texts.say('${lesson.id}.history') ?? '',
                  key: EndgameInfoKeys.history,
                  style: theme.textTheme.bodyMedium,
                ),
                _header(context, l10n.endgameInfoKeyPositions),
                for (final position in lesson.keyPositions)
                  Padding(
                    key: EndgameInfoKeys.keyPosition(position.id),
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        PositionBoard(fen: position.fen, size: 120),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              LinkedText(
                                texts.say('${lesson.id}.key.${position.id}') ??
                                    '',
                                style: theme.textTheme.bodyMedium,
                              ),
                              // A partida ou o estudo de onde ela vem.
                              if (lesson.reference(position.ref)
                                  case final reference?
                                  when reference.url != null)
                                ReferenceLink(
                                  key: EndgameInfoKeys.keyPositionLink(
                                    position.id,
                                  ),
                                  reference: reference,
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                _header(context, l10n.endgameInfoReferences),
                for (final reference in lesson.references.where(
                  (reference) => reference.isLearnerFacing,
                ))
                  _ReferenceTile(reference: reference),
              ],
            ),
    );
  }

  Widget _header(BuildContext context, String text) => Padding(
    padding: const EdgeInsetsDirectional.fromSTEB(
      0,
      AppSpacing.lg,
      0,
      AppSpacing.sm,
    ),
    child: Text(text, style: context.sectionTitle),
  );
}

class _ReferenceTile extends StatelessWidget {
  const _ReferenceTile({required this.reference});

  final Reference reference;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final url = reference.url;
    final text = switch (reference.kind) {
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
    final icon = switch (reference.kind) {
      'book' => Icons.menu_book_outlined,
      'study' => Icons.library_books_outlined,
      'game' => Icons.sports_esports_outlined,
      'tablebase' => Icons.table_chart_outlined,
      _ => Icons.link,
    };
    // Com link, a referência abre dentro do app, na folha da página.
    final uri = url == null ? null : Uri.tryParse(url);
    return ListTile(
      key: EndgameInfoKeys.reference(reference.id),
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: colors.onSurfaceVariant),
      title: Text(text),
      subtitle: uri == null
          ? null
          : Align(
              alignment: AlignmentDirectional.centerStart,
              child: InfoChip(
                key: EndgameInfoKeys.referenceSource(reference.id),
                compact: true,
                icon: _sourceIcon(uri),
                label: ExternalPageSheet.domainOf(uri),
              ),
            ),
      trailing: uri == null
          ? null
          : Icon(
              Icons.open_in_new,
              size: AppIconSize.button,
              color: colors.primary,
            ),
      onTap: uri == null ? null : () => showExternalPage(context, uri),
    );
  }

  IconData _sourceIcon(Uri uri) {
    final host = uri.host.toLowerCase();
    if (host == 'lichess.org' || host.endsWith('.lichess.org')) {
      return Icons.sports_esports_outlined;
    }
    if (host == 'wikipedia.org' || host.endsWith('.wikipedia.org')) {
      return Icons.menu_book_outlined;
    }
    return Icons.open_in_new;
  }
}

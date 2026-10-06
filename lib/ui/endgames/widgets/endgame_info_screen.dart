import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/models/endgame_lesson.dart';
import '../../core/keys/endgames_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/widgets/position_board.dart';
import '../../core/widgets/scroll_padding.dart';
import '../view_models/endgame_lesson_cubit.dart';

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
      appBar: AppBar(
        title: Text(lesson == null ? '' : texts.lessonTitle(lesson.id)),
      ),
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
                _header(theme, l10n.endgameInfoHistory),
                Text(
                  texts.say('${lesson.id}.history') ?? '',
                  key: EndgameInfoKeys.history,
                  style: theme.textTheme.bodyMedium,
                ),
                _header(theme, l10n.endgameInfoKeyPositions),
                for (final position in lesson.keyPositions)
                  Padding(
                    key: EndgameInfoKeys.keyPosition(position.id),
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        PositionBoard(fen: position.fen, size: 120, radius: 6),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            texts.say('${lesson.id}.key.${position.id}') ?? '',
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                _header(theme, l10n.endgameInfoReferences),
                for (final reference in lesson.references)
                  _ReferenceTile(reference: reference),
              ],
            ),
    );
  }

  Widget _header(ThemeData theme, String text) => Padding(
    padding: const EdgeInsetsDirectional.fromSTEB(0, 20, 0, 8),
    child: Text(
      text,
      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
    ),
  );
}

class _ReferenceTile extends StatelessWidget {
  const _ReferenceTile({required this.reference});

  final Reference reference;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = Theme.of(context).colorScheme;
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
      'study' => Icons.school_outlined,
      'game' => Icons.sports_esports_outlined,
      'tablebase' => Icons.table_chart_outlined,
      _ => Icons.link,
    };
    return ListTile(
      key: EndgameInfoKeys.reference(reference.id),
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: colors.onSurfaceVariant),
      title: Text(text),
      // O link fica para copiar: o app não abre o navegador.
      subtitle: url == null ? null : SelectableText(url),
    );
  }
}

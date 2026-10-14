import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';

import '../../core/keys/lesson_script_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_shape.dart';
import '../../core/widgets/figurine.dart';
import '../view_models/lesson_script_state.dart';

/// A lista de lances embaixo do tabuleiro, no estilo da tabela da tela de
/// detalhes da partida: número, brancas, pretas, linhas alternadas. Só traz o
/// que o aluno já viu; a variante vem numa linha cinza recuada, depois da
/// linha do lance que ela troca. Tocar num lance chama [onTap].
class ScriptMoveList extends StatefulWidget {
  const ScriptMoveList({
    required this.moves,
    required this.currentId,
    required this.onTap,
    super.key,
  });

  final List<ScriptMoveEntry> moves;
  final String? currentId;
  final ValueChanged<String> onTap;

  @override
  State<ScriptMoveList> createState() => _ScriptMoveListState();
}

class _Row {
  _Row(this.number);

  final int number;
  ScriptMoveEntry? white;
  ScriptMoveEntry? black;
  final variants = <List<ScriptMoveEntry>>[];
}

class _ScriptMoveListState extends State<ScriptMoveList> {
  final _currentKey = GlobalKey();

  /// Junta os lances em linhas; a variante vai para a linha do lance
  /// principal que a antecede.
  List<_Row> _rows() {
    final rows = <_Row>[];
    _Row? last;
    ScriptMoveEntry? previous;
    for (final entry in widget.moves) {
      if (entry.variant) {
        last ??= _Row(entry.number);
        if (!rows.contains(last)) rows.add(last);
        final runs = last.variants;
        final continues =
            previous != null &&
            previous.variant &&
            entry.id.startsWith('${previous.id}-');
        if (runs.isEmpty || !continues) {
          runs.add([entry]);
        } else {
          runs.last.add(entry);
        }
      } else {
        if (last == null || last.number != entry.number) {
          // O lance das pretas na linha do mesmo número.
          final same = rows.where((r) => r.number == entry.number);
          last = same.isEmpty ? _Row(entry.number) : same.last;
          if (!rows.contains(last)) rows.add(last);
        }
        if (entry.side == Side.white) {
          last.white = entry;
        } else {
          last.black = entry;
        }
      }
      previous = entry;
    }
    return rows;
  }

  @override
  void didUpdateWidget(ScriptMoveList old) {
    super.didUpdateWidget(old);
    if (old.currentId != widget.currentId ||
        old.moves.length != widget.moves.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final context = _currentKey.currentContext;
        if (context == null || !context.mounted) return;
        Scrollable.ensureVisible(
          context,
          duration: AppMotion.of(context).state,
          alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final rows = _rows();
    if (rows.isEmpty) return const SizedBox.shrink();
    return Semantics(
      label: context.l10n.lessonMoveList,
      container: true,
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
          child: DecoratedBox(
            key: LessonScriptKeys.moveList,
            decoration: BoxDecoration(
              color: colors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(AppShape.large),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppShape.large),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: rows.length,
                itemBuilder: (context, index) =>
                    _rowView(context, rows[index], index),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _rowView(BuildContext context, _Row row, int index) {
    final colors = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    return Container(
      color: index.isOdd ? colors.onSurface.withValues(alpha: 0.04) : null,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: [
          if (row.white != null || row.black != null)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 36,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 14),
                    child: Text(
                      '${row.number}.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
                Expanded(child: _cell(context, row.white, empty: '…')),
                Expanded(child: _cell(context, row.black)),
              ],
            ),
          for (final run in row.variants) _variant(context, run),
        ],
      ),
    );
  }

  TextSpan _notation(String san) => TextSpan(
    children: [
      for (final char in san.split(''))
        if (Figurine.ofLetter[char] case final figurine?)
          TextSpan(
            text: figurine,
            style: const TextStyle(
              fontFamily: Figurine.fontFamily,
              fontWeight: FontWeight.w400,
            ),
          )
        else
          TextSpan(text: char),
    ],
  );

  Widget _cell(BuildContext context, ScriptMoveEntry? entry, {String? empty}) {
    final theme = Theme.of(context);
    if (entry == null) {
      return SizedBox(
        height: 44,
        child: empty == null
            ? null
            : Padding(
                padding: const EdgeInsets.fromLTRB(10, 14, 0, 0),
                child: Text(
                  empty,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
      );
    }
    return _button(
      context,
      entry,
      minHeight: 44,
      margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
      style: theme.textTheme.titleSmall!.copyWith(
        fontWeight: FontWeight.w700,
        height: 1.4,
        color: theme.colorScheme.onSurface,
      ),
    );
  }

  Widget _button(
    BuildContext context,
    ScriptMoveEntry entry, {
    required double minHeight,
    required EdgeInsets margin,
    required TextStyle style,
    String? prefix,
  }) {
    final colors = Theme.of(context).colorScheme;
    final selected = entry.id == widget.currentId;
    return Semantics(
      label: entry.san,
      button: true,
      selected: selected,
      excludeSemantics: true,
      onTap: () => widget.onTap(entry.id),
      child: InkWell(
        key: LessonScriptKeys.move(entry.id),
        borderRadius: BorderRadius.circular(AppShape.small),
        onTap: () => widget.onTap(entry.id),
        child: AnimatedContainer(
          key: selected ? _currentKey : null,
          duration: AppMotion.of(context).state,
          constraints: BoxConstraints(minHeight: minHeight),
          margin: margin,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          alignment: AlignmentDirectional.centerStart,
          decoration: BoxDecoration(
            color: selected ? colors.secondaryContainer : Colors.transparent,
            borderRadius: BorderRadius.circular(AppShape.small),
            border: Border.all(
              color: selected ? colors.outline : Colors.transparent,
            ),
          ),
          child: Text.rich(
            TextSpan(
              children: [
                if (prefix != null) TextSpan(text: prefix),
                _notation(entry.san),
              ],
            ),
            style: style,
          ),
        ),
      ),
    );
  }

  /// A variante: uma linha de lances em cinza, recuada 48.
  Widget _variant(BuildContext context, List<ScriptMoveEntry> run) {
    final theme = Theme.of(context);
    final style = theme.textTheme.bodyMedium!.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 40, bottom: 4),
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            for (var i = 0; i < run.length; i++)
              _button(
                context,
                run[i],
                minHeight: 32,
                margin: const EdgeInsets.symmetric(horizontal: 1),
                style: style,
                prefix: run[i].side == Side.white
                    ? '${run[i].number}. '
                    : (i == 0 ? '${run[i].number}… ' : null),
              ),
          ],
        ),
      ),
    );
  }
}

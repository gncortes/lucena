import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';

import '../../core/board/board_settings_ui.dart';
import '../../core/keys/lesson_script_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_shape.dart';
import '../../core/theme/lesson_text_colors.dart';
import '../view_models/lesson_script_state.dart';

/// A lista de lances embaixo do tabuleiro, em notação corrida como a aba
/// Lances dos detalhes da partida (`CompNotacao` do canvas, estilo Lichess):
/// direto na superfície, sem caixa; letras das peças do idioma (Re4); número
/// em cinza, lance num chip de 30 dp, o atual em azul cheio; a variante
/// vem entre parênteses, cinza e menor, logo depois do lance que ela troca
/// (no jogo livre, a sublinha que o aluno abriu); "?"/"!" e o resultado. Só
/// traz o que o aluno já viu. Tocar num lance chama [onTap]. Não rola
/// sozinha: quando passa do fundo, a tela toda rola (Gabriel, 14/10/2026).
class ScriptMoveList extends StatelessWidget {
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
  Widget build(BuildContext context) {
    if (moves.isEmpty) return const SizedBox.shrink();
    return Semantics(
      label: context.l10n.lessonMoveList,
      container: true,
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Padding(
          key: LessonScriptKeys.moveList,
          padding: const EdgeInsets.fromLTRB(12, 6, 12, 16),
          child: SizedBox(
            width: double.infinity,
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              runSpacing: 2,
              children: _items(context),
            ),
          ),
        ),
      ),
    );
  }

  /// Os itens da notação: número, lance e parênteses das variantes. O lance
  /// das pretas leva "N..." no começo, depois de uma variante e logo depois
  /// dela, como no Lichess. O resultado fecha a linha em que a partida
  /// acabou.
  List<Widget> _items(BuildContext context) {
    final items = <Widget>[];
    var depth = 0;
    var needsNumber = true;
    for (final entry in moves) {
      while (depth > entry.depth) {
        items.add(_paren(context, ')'));
        depth--;
        needsNumber = true;
      }
      if (entry.startsVariant && depth == entry.depth && depth > 0) {
        items.add(_paren(context, ')'));
        depth--;
      }
      while (depth < entry.depth) {
        items.add(_paren(context, '('));
        depth++;
        needsNumber = true;
      }
      final white = entry.side == Side.white;
      final number = white
          ? '${entry.number}.'
          : (needsNumber ? '${entry.number}...' : null);
      items.add(_move(context, entry, number: number));
      if (entry.result != null) items.add(_result(context, entry));
      needsNumber = false;
    }
    for (; depth > 0; depth--) {
      items.add(_paren(context, ')'));
    }
    return items;
  }

  Widget _result(BuildContext context, ScriptMoveEntry entry) => Padding(
    padding: const EdgeInsets.only(left: 8, right: 6),
    child: Text(
      entry.result!,
      key: LessonScriptKeys.moveResult(entry.id),
      style: TextStyle(
        fontSize: entry.depth > 0 ? 14 : 15,
        fontWeight: FontWeight.w800,
        color: Theme.of(context).colorScheme.onSurface,
      ),
    ),
  );

  Widget _paren(BuildContext context, String text) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 1),
      child: Text(
        text,
        style: TextStyle(fontSize: 15, height: 2, color: colors.outline),
      ),
    );
  }

  Widget _move(BuildContext context, ScriptMoveEntry entry, {String? number}) {
    final colors = Theme.of(context).colorScheme;
    final selected = entry.id == currentId;
    final variant = entry.depth > 0;
    final style = TextStyle(
      fontSize: variant ? 14 : 15,
      height: 1.2,
      fontWeight: selected
          ? FontWeight.w800
          : (variant ? FontWeight.w400 : FontWeight.w500),
      color: selected
          ? colors.onPrimary
          : (variant ? colors.onSurfaceVariant : colors.onSurface),
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (number != null)
          Padding(
            padding: const EdgeInsets.only(left: 5, right: 1),
            child: Text(
              number,
              style: TextStyle(
                fontSize: variant ? 13 : 14,
                color: colors.onSurfaceVariant,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        Semantics(
          label: localizedSan(context.l10n, entry.san),
          button: true,
          selected: selected,
          excludeSemantics: true,
          onTap: () => onTap(entry.id),
          child: InkWell(
            key: LessonScriptKeys.move(entry.id),
            borderRadius: BorderRadius.circular(AppShape.small),
            onTap: () => onTap(entry.id),
            child: AnimatedContainer(
              duration: AppMotion.of(context).state,
              height: 30,
              padding: const EdgeInsets.symmetric(horizontal: 6),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? colors.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(AppShape.small),
              ),
              child: Text(
                '${localizedSan(context.l10n, entry.san)}${entry.symbol ?? ''}',
                style: style.copyWith(
                  color: selected ? null : _symbolColor(entry.symbol),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Color? _symbolColor(String? symbol) => switch (symbol) {
    '?' => LessonTextColors.mistake,
    '!' => LessonTextColors.goodMove,
    _ => null,
  };
}

import 'package:chessground/chessground.dart';
import 'package:flutter/material.dart';

import '../../../domain/models/rating_level.dart';
import '../../core/keys/profile_keys.dart';
import '../../core/l10n/l10n.dart';
import 'rating_level_ui.dart';

/// Abre o painel de escolha da faixa de rating. Devolve a faixa confirmada,
/// ou nulo se o painel for fechado sem confirmar.
Future<RatingLevel?> showRatingLevelSheet(
  BuildContext context, {
  required RatingLevel selected,
}) {
  return showModalBottomSheet<RatingLevel>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    useSafeArea: true,
    // O botão de confirmar fica acima da barra de gestos do sistema.
    builder: (context) =>
        SafeArea(top: false, child: _RatingLevelSheet(initial: selected)),
  );
}

class _RatingLevelSheet extends StatefulWidget {
  const _RatingLevelSheet({required this.initial});

  final RatingLevel initial;

  @override
  State<_RatingLevelSheet> createState() => _RatingLevelSheetState();
}

class _RatingLevelSheetState extends State<_RatingLevelSheet> {
  // A faixa marcada no painel; só vale depois de confirmar.
  late RatingLevel _marked = widget.initial;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    return Column(
      key: ProfileKeys.levelSheet,
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.profileRating, style: theme.textTheme.titleLarge),
              const SizedBox(height: 4),
              Text(
                l10n.profileRatingSheetHint,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        // Em tela pequena a lista rola; o botão de confirmar fica sempre à vista.
        Flexible(
          child: SingleChildScrollView(
            child: Column(
              children: [
                for (final level in RatingLevel.values)
                  _LevelOption(
                    key: ProfileKeys.levelOption(level),
                    level: level,
                    selected: level == _marked,
                    onTap: () => setState(() => _marked = level),
                  ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
          child: FilledButton(
            key: ProfileKeys.levelConfirmButton,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
            onPressed: () => Navigator.of(context).pop(_marked),
            child: Text(l10n.profileLevelConfirm),
          ),
        ),
      ],
    );
  }
}

class _LevelOption extends StatelessWidget {
  const _LevelOption({
    required this.level,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final RatingLevel level;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        selected: selected,
        selectedTileColor: colors.secondaryContainer,
        selectedColor: colors.onSecondaryContainer,
        leading: LevelBadge(level: level, highlighted: selected),
        title: Text(level.name(l10n)),
        subtitle: Text(level.range(l10n)),
        trailing: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          transitionBuilder: (child, animation) =>
              ScaleTransition(scale: animation, child: child),
          child: selected
              ? const Icon(Icons.check_circle, key: ValueKey('selected'))
              : const SizedBox.square(dimension: 24, key: ValueKey('empty')),
        ),
        onTap: onTap,
      ),
    );
  }
}

/// A peça da faixa, centralizada num círculo: peão para iniciante, rei para
/// mestre.
class LevelBadge extends StatelessWidget {
  const LevelBadge({required this.level, this.highlighted = false, super.key});

  final RatingLevel level;
  final bool highlighted;

  static const _size = 44.0;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: _size,
      height: _size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: highlighted ? colors.primary : colors.surfaceContainerHighest,
      ),
      // A imagem da peça já vem centralizada no próprio quadro.
      child: ExcludeSemantics(
        child: Image(
          image: PieceSet.cburnettAssets[level.piece]!,
          width: _size * 0.72,
          height: _size * 0.72,
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../theme/app_motion.dart';
import '../theme/app_shape.dart';

/// Uma opção do painel de escolha.
class ChoiceSheetOption<T> {
  const ChoiceSheetOption({
    required this.value,
    required this.label,
    required this.key,
    this.description,
    this.descriptionStyle,
    this.icon,
  });

  final T value;
  final String label;
  final Key key;

  /// Explicação curta, embaixo do nome.
  final String? description;

  /// Estilo a mais da explicação (por exemplo, a fonte dos figurinos).
  final TextStyle? descriptionStyle;
  final IconData? icon;
}

/// Abre um painel que sobe de baixo com opções de escolha única. Tocar numa
/// opção só marca; a escolha vale ao confirmar. Devolve a opção confirmada, ou
/// nulo se o painel for fechado sem confirmar.
Future<T?> showChoiceSheet<T>(
  BuildContext context, {
  required String title,
  required List<ChoiceSheetOption<T>> options,
  required T selected,
  required String confirmLabel,
  Key? sheetKey,
  Key? confirmKey,
}) {
  return showModalBottomSheet<T>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    useSafeArea: true,
    // O botão de confirmar fica acima da barra de gestos do sistema.
    builder: (context) => SafeArea(
      top: false,
      child: _ChoiceSheet<T>(
        key: sheetKey,
        title: title,
        options: options,
        initial: selected,
        confirmLabel: confirmLabel,
        confirmKey: confirmKey,
      ),
    ),
  );
}

class _ChoiceSheet<T> extends StatefulWidget {
  const _ChoiceSheet({
    required this.title,
    required this.options,
    required this.initial,
    required this.confirmLabel,
    this.confirmKey,
    super.key,
  });

  final String title;
  final List<ChoiceSheetOption<T>> options;
  final T initial;
  final String confirmLabel;
  final Key? confirmKey;

  @override
  State<_ChoiceSheet<T>> createState() => _ChoiceSheetState<T>();
}

class _ChoiceSheetState<T> extends State<_ChoiceSheet<T>> {
  // A opção marcada no painel; só vale depois de confirmar.
  late T _marked = widget.initial;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
          child: Text(widget.title, style: theme.textTheme.titleLarge),
        ),
        // Em tela pequena a lista rola; o botão de confirmar fica sempre à vista.
        Flexible(
          child: SingleChildScrollView(
            child: Column(
              children: [
                for (final option in widget.options)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 2,
                    ),
                    child: ListTile(
                      key: option.key,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppShape.large),
                      ),
                      selected: option.value == _marked,
                      selectedTileColor: colors.secondaryContainer,
                      selectedColor: colors.onSecondaryContainer,
                      leading: option.icon == null ? null : Icon(option.icon),
                      title: Text(option.label),
                      subtitle: option.description == null
                          ? null
                          : Text(
                              option.description!,
                              style: option.descriptionStyle,
                            ),
                      trailing: AnimatedSwitcher(
                        duration: AppMotion.state,
                        transitionBuilder: (child, animation) =>
                            ScaleTransition(scale: animation, child: child),
                        child: option.value == _marked
                            ? const Icon(Icons.check, key: ValueKey('selected'))
                            : const SizedBox.square(
                                dimension: 24,
                                key: ValueKey('empty'),
                              ),
                      ),
                      onTap: () => setState(() => _marked = option.value),
                    ),
                  ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
          child: FilledButton(
            key: widget.confirmKey,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
            onPressed: () => Navigator.of(context).pop(_marked),
            child: Text(widget.confirmLabel),
          ),
        ),
      ],
    );
  }
}

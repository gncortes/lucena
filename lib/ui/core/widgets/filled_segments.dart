import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import 'one_line.dart';

/// Um seletor segmentado (período, filtro): rótulos numa linha só (a letra diminui
/// se não couber) e o escolhido preenchido com a cor principal, para ficar
/// claro qual está valendo.
class FilledSegments<T> extends StatelessWidget {
  const FilledSegments({
    required this.values,
    required this.selected,
    required this.label,
    required this.onChanged,
    this.labelKey,
    super.key,
  });

  final List<T> values;
  final T selected;
  final String Function(T value) label;
  final Key Function(T value)? labelKey;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SegmentedButton<T>(
      showSelectedIcon: false,
      style: ButtonStyle(
        visualDensity: VisualDensity.compact,
        tapTargetSize: MaterialTapTargetSize.padded,
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: AppSpacing.xs),
        ),
        backgroundColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected) ? colors.primary : null,
        ),
        foregroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? colors.onPrimary
              : colors.onSurface,
        ),
      ),
      segments: [
        for (final value in values)
          ButtonSegment(
            value: value,
            label: OneLine(label(value), key: labelKey?.call(value)),
          ),
      ],
      selected: {selected},
      onSelectionChanged: (selection) => onChanged(selection.single),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:lucena_ui/lucena_ui.dart';

/// O título de uma seção (canvas `CompSecao`): `titleSmall` em cinza, com um
/// valor opcional à direita e uma ação de texto opcional.
class SectionTitle extends StatelessWidget {
  const SectionTitle(
    this.text, {
    this.value,
    this.action,
    this.valueKey,
    this.textKey,
    this.inset = AppSpacing.lg,
    super.key,
  });

  /// A altura mínima da linha.
  static const minHeight = 40.0;

  final String text;
  final String? value;
  final SectionAction? action;
  final Key? valueKey;
  final Key? textKey;

  /// A margem dos lados: 16; 0 quando a lista em volta já a dá.
  final double inset;

  @override
  Widget build(BuildContext context) {
    final style = context.sectionTitle;
    final action = this.action;
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: minHeight),
      child: Padding(
        key: CoreKeys.sectionTitle,
        padding: EdgeInsetsDirectional.fromSTEB(
          inset,
          AppSpacing.lg,
          inset,
          AppSpacing.sm,
        ),
        child: Row(
          children: [
            Expanded(
              child: Semantics(
                header: true,
                child: Text(text, key: textKey, style: style),
              ),
            ),
            if (value != null) Text(value!, key: valueKey, style: style),
            if (action != null)
              TextButton.icon(
                key: action.key,
                onPressed: action.onPressed,
                icon: action.icon == null
                    ? null
                    : Icon(action.icon, size: AppIconSize.button),
                label: Text(action.label),
              ),
          ],
        ),
      ),
    );
  }
}

/// A ação de texto à direita de um [SectionTitle].
class SectionAction {
  const SectionAction({
    required this.label,
    required this.onPressed,
    this.icon,
    this.key,
  });

  final String label;
  final VoidCallback onPressed;
  final IconData? icon;
  final Key? key;
}

import 'package:flutter/material.dart';

/// Canvas compact pill inside a 44 dp keyboard/semantics/touch target.
class CompactCourseAction extends StatelessWidget {
  const CompactCourseAction({
    required this.label,
    required this.onPressed,
    this.filled = false,
    this.visualHeight = 28,
    super.key,
  });
  final String label;
  final VoidCallback? onPressed;
  final bool filled;
  final double visualHeight;
  @override
  Widget build(BuildContext context) {
    final style = ButtonStyle(
      minimumSize: WidgetStatePropertyAll(Size(0, visualHeight)),
      maximumSize: WidgetStatePropertyAll(Size(double.infinity, visualHeight)),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: 12),
      ),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      textStyle: WidgetStatePropertyAll(Theme.of(context).textTheme.labelLarge),
    );
    return Semantics(
      button: true,
      enabled: onPressed != null,
      label: label,
      child: InkWell(
        onTap: onPressed,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
          child: Center(
            widthFactor: 1,
            heightFactor: 1,
            child: ExcludeSemantics(
              child: ExcludeFocus(
                child: IgnorePointer(
                  child: filled
                      ? FilledButton(
                          style: style,
                          onPressed: onPressed,
                          child: Text(label),
                        )
                      : OutlinedButton(
                          style: style,
                          onPressed: onPressed,
                          child: Text(label),
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

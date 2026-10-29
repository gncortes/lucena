import 'package:flutter/material.dart';

import '../actions_footer.dart';

/// O rodapé com o destaque único das telas do curso (canvas
/// `CompRodapeAcoes` degrade): um botão cheio com o play.
class CourseContinueFooter extends StatelessWidget {
  const CourseContinueFooter({
    required this.label,
    required this.onPressed,
    this.buttonKey,
    this.icon = Icons.play_arrow_rounded,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final Key? buttonKey;
  final IconData icon;

  @override
  Widget build(BuildContext context) => ActionsFooter(
    fade: true,
    children: [
      FilledButton.icon(
        key: buttonKey,
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
      ),
    ],
  );
}

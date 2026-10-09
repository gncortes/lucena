import 'package:flutter/material.dart';

import '../theme/app_motion.dart';

/// Opção de uma lista de escolha única (idioma, tema): a escolhida ganha a
/// marca, que troca com animação.
class ChoiceTile extends StatelessWidget {
  const ChoiceTile({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    super.key,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final icon = this.icon;
    return ListTile(
      leading: icon == null ? null : Icon(icon),
      title: Text(label),
      selected: selected,
      trailing: AnimatedSwitcher(
        duration: AppMotion.state,
        transitionBuilder: (child, animation) =>
            ScaleTransition(scale: animation, child: child),
        child: selected
            ? const Icon(Icons.check, key: ValueKey('selected'))
            : const SizedBox.square(dimension: 24, key: ValueKey('empty')),
      ),
      onTap: onTap,
    );
  }
}

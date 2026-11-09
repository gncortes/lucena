import 'package:flutter/material.dart';

import '../theme/app_icon_size.dart';

/// O ícone num círculo cinza de 48, que abre o cartão de resultado (fim do
/// speedrun e da maratona). Decorativo: fica fora da leitura de tela.
class StatusCircleIcon extends StatelessWidget {
  const StatusCircleIcon({required this.icon, super.key});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: colors.surfaceContainerHigh,
        shape: BoxShape.circle,
      ),
      child: ExcludeSemantics(
        child: Icon(
          icon,
          size: AppIconSize.large,
          color: colors.onSurfaceVariant,
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../../domain/models/endgame_position.dart';

/// As cores e o ícone de cada objetivo, iguais no catálogo, na Jornada e na
/// configuração: verde com troféu para ganhar e azul com escudo para defender
/// (vermelho pareceria erro ou derrota).
class GoalStyle {
  const GoalStyle._({
    required this.icon,
    required this.color,
    required this.container,
    required this.onContainer,
  });

  factory GoalStyle.of(BuildContext context, PositionGoal goal) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return switch (goal) {
      PositionGoal.win => GoalStyle._(
        icon: Icons.emoji_events_outlined,
        color: dark ? const Color(0xFF7BD88F) : const Color(0xFF2E7D32),
        container: dark ? const Color(0xFF1F4A2A) : const Color(0xFFDCF2DF),
        onContainer: dark ? const Color(0xFFC8F2CF) : const Color(0xFF1B4D20),
      ),
      PositionGoal.draw => GoalStyle._(
        icon: Icons.shield_outlined,
        color: dark ? const Color(0xFF8CC4FF) : const Color(0xFF1565C0),
        container: dark ? const Color(0xFF1D3A5C) : const Color(0xFFDDEBFB),
        onContainer: dark ? const Color(0xFFD3E6FF) : const Color(0xFF0D3C78),
      ),
    };
  }

  final IconData icon;

  /// Texto e ícone sobre o fundo da tela.
  final Color color;

  /// Fundo de selo e a cor do texto sobre ele.
  final Color container;
  final Color onContainer;
}

/// O verde e o vermelho da variação do rating.
abstract final class ChangeColors {
  static Color of(BuildContext context, {required bool up}) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return up
        ? (dark ? const Color(0xFF3FA55A) : const Color(0xFF2E7D32))
        : (dark ? const Color(0xFFD9534F) : const Color(0xFFC62828));
  }
}

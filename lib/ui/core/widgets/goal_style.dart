import 'package:flutter/material.dart';
import 'package:lucena_ui/lucena_ui.dart';

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
        color: dark ? AppColors.goalWinDk : AppColors.goalWin,
        container: dark ? AppColors.goalWinBgDk : AppColors.goalWinBg,
        onContainer: dark ? AppColors.goalWinOnDk : AppColors.goalWinOn,
      ),
      PositionGoal.draw => GoalStyle._(
        icon: Icons.shield_outlined,
        color: dark ? AppColors.goalDrawDk : AppColors.goalDraw,
        container: dark ? AppColors.goalDrawBgDk : AppColors.goalDrawBg,
        onContainer: dark ? AppColors.goalDrawOnDk : AppColors.goalDrawOn,
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
        ? (dark ? AppColors.resultUpDk : AppColors.goalWin)
        : (dark ? AppColors.resultDownDk : AppColors.errorColor);
  }
}

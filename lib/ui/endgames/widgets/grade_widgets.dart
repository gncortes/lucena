import 'package:flutter/material.dart';

import '../../../domain/use_cases/endgame_lesson_rules.dart';
import '../../core/l10n/l10n.dart';
import 'stars_row.dart';

/// O nome de uma faixa da nota dos exercícios.
String gradeName(AppLocalizations l10n, ExerciseGrade grade) => switch (grade) {
  ExerciseGrade.passed => l10n.exerciseGradePassed,
  ExerciseGrade.good => l10n.exerciseGradeGood,
  ExerciseGrade.excellent => l10n.exerciseGradeExcellent,
  ExerciseGrade.perfect => l10n.exerciseGradePerfect,
  ExerciseGrade.below => '',
};

/// A cor da estrela de cada faixa: dourada no perfeito e no excelente,
/// prata no bom, bronze no aprovado.
Color? gradeColor(ExerciseGrade grade) => switch (grade) {
  ExerciseGrade.perfect || ExerciseGrade.excellent => StarsRow.gold,
  ExerciseGrade.good => StarsRow.silver,
  ExerciseGrade.passed => StarsRow.bronze,
  ExerciseGrade.below => null,
};

/// A "medalha" da faixa: três estrelas douradas (a do meio maior) no
/// perfeito, uma dourada no excelente, prata no bom, bronze no aprovado e
/// uma vazia abaixo do mínimo. [size] é a estrela principal.
class GradeMedal extends StatelessWidget {
  const GradeMedal({required this.grade, this.size = 80, super.key});

  final ExerciseGrade grade;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final color = gradeColor(grade) ?? colors.outlineVariant;
    return switch (grade) {
      ExerciseGrade.perfect => Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Icon(Icons.star_rounded, size: size * 0.6, color: color),
          Icon(Icons.star_rounded, size: size, color: color),
          Icon(Icons.star_rounded, size: size * 0.6, color: color),
        ],
      ),
      ExerciseGrade.below => Icon(
        Icons.star_outline_rounded,
        size: size,
        color: colors.outline,
      ),
      _ => Icon(Icons.star_rounded, size: size, color: color),
    };
  }
}

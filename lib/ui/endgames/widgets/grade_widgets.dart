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
///
/// [sideRatio] é o tamanho das laterais do perfeito em relação à do meio.
/// O padrão (0,6) é a medalha grande das telas de exercício. A M2 dos cursos
/// (CompEstrelas proporcao=0.5) usa 0,5: as laterais ficam coladas na do meio
/// (avançam 0,21 × [size] sobre ela: os -3 px em 20 do canvas mais a folga
/// lateral, maior no glifo `star_rounded` que no do canvas) e sobem
/// 0,1 × [size], para a base do desenho ficar na linha da base das pernas da
/// do meio (o glifo tem uma folga embaixo que encolhe com o tamanho).
class GradeMedal extends StatelessWidget {
  const GradeMedal({
    required this.grade,
    this.size = 80,
    this.sideRatio = defaultSideRatio,
    super.key,
  });

  /// A proporção das laterais da medalha grande.
  static const defaultSideRatio = 0.6;

  /// A proporção da M2 dos cursos.
  static const compactSideRatio = 0.5;

  final ExerciseGrade grade;
  final double size;
  final double sideRatio;

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
          _side(color, Alignment.centerLeft),
          Icon(Icons.star_rounded, size: size, color: color),
          _side(color, Alignment.centerRight),
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

  /// Uma lateral; [outer] é o lado de fora, que fica dentro da caixa: só o
  /// lado de dentro avança sobre a do meio.
  Widget _side(Color color, Alignment outer) {
    final side = size * sideRatio;
    final star = Icon(Icons.star_rounded, size: side, color: color);
    if (sideRatio == defaultSideRatio) return star;
    final overlap = size * 0.21;
    return Transform.translate(
      offset: Offset(0, -0.1 * size),
      child: SizedBox(
        width: side - overlap,
        height: side,
        child: OverflowBox(
          minWidth: side,
          maxWidth: side,
          alignment: outer,
          child: star,
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../keys/training_keys.dart';
import '../theme/app_colors.dart';
import '../theme/app_icon_size.dart';

/// A marca única de acerto (`check_circle`) e de erro (`cancel`) de todo tipo
/// de exercício: treino, lição e prática (H-LIC-42). Vai nas ações da barra.
class ExerciseResultMark extends StatelessWidget {
  const ExerciseResultMark({required this.correct, super.key});

  final bool correct;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsetsDirectional.only(end: 16),
    child: Icon(
      correct ? Icons.check_circle : Icons.cancel,
      key: TrainingKeys.exerciseResultMark,
      size: AppIconSize.standard,
      color: correct ? AppColors.successColor : AppColors.errorColor,
    ),
  );
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/models/training/training_content.dart';
import '../../core/keys/treinador_seu_jogo_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_icon_size.dart';
import '../../core/theme/app_shape.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/course/course_item_tile.dart';
import '../../course_guide/view_models/course_guide_cubit.dart';

/// No alto das Metas de hoje: a lição do Pilares que o Treinador de partidas
/// mandou estudar, com o aviso de onde ela veio.
class MetasDestaqueTreinador extends StatelessWidget {
  const MetasDestaqueTreinador({
    required this.lessonId,
    required this.onOpen,
    super.key,
  });

  final String lessonId;
  final ValueChanged<TrainingLesson> onOpen;

  @override
  Widget build(BuildContext context) {
    final lesson = context.select<CourseGuideCubit, TrainingLesson?>(
      (c) =>
          c.state.resources?.lessons.where((l) => l.id == lessonId).firstOrNull,
    );
    if (lesson == null) return const SizedBox.shrink();
    final t = context.l10n;
    final theme = Theme.of(context);
    return Column(
      key: SeuJogoKeys.metasDestaque,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(AppShape.large),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline,
                  size: AppIconSize.compact,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    t.sjMetasDestaqueAviso(lesson.title),
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          t.sjMetasDestaqueSecao,
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        CourseItemTile(
          key: SeuJogoKeys.metasDestaqueParte,
          state: CourseItemState.next,
          title: lesson.title,
          summary: lesson.summary.isEmpty ? null : lesson.summary,
          onTap: () => onOpen(lesson),
        ),
      ],
    );
  }
}

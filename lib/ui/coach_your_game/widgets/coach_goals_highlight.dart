import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/models/training/training_content.dart';
import '../../../domain/models/training/training_resources.dart';
import '../../../domain/use_cases/coach/opening_in_course.dart';
import '../../../domain/use_cases/coach/opening_in_pilares.dart';
import '../../core/keys/coach_your_game_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/course/course_item_tile.dart';
import '../../core/widgets/tip_box.dart';
import '../../course_guide/view_models/course_guide_cubit.dart';

/// A abertura e o número da parte da lição [lessonId] no Pilares, quando ela
/// é parte de uma abertura do curso.
({String slot, int number})? _lessonPart(
  String lessonId,
  TrainingResources resources,
) {
  final lessonEntry = resources.lessons
      .where((l) => l.id == lessonId)
      .firstOrNull;
  if (lessonEntry == null) return null;
  final slot =
      resources.openings[lessonId]?.firstOrNull?.openingId ??
      lessonSlot(lessonId);
  final opening = openingInPilares(slot: slot, resources: resources);
  final part = opening?.parts
      .where((p) => p.lessonEntry.id == lessonId)
      .firstOrNull;
  if (part == null) return null;
  return (slot: slot, number: part.number);
}

/// No alto das Metas de hoje: a lição do Pilares que o Treinador de partidas
/// mandou estudar, com o aviso de onde ela veio.
class CoachGoalsHighlight extends StatelessWidget {
  const CoachGoalsHighlight({
    required this.lessonId,
    required this.onOpen,
    super.key,
  });

  final String lessonId;
  final ValueChanged<TrainingLesson> onOpen;

  @override
  Widget build(BuildContext context) {
    final resources = context.select<CourseGuideCubit, TrainingResources?>(
      (c) => c.state.resources,
    );
    final lesson = resources?.lessons
        .where((l) => l.id == lessonId)
        .firstOrNull;
    if (resources == null || lesson == null) return const SizedBox.shrink();
    final t = context.l10n;
    final theme = Theme.of(context);
    // Canvas DMetasEslava: "{abertura} · Parte {n}" e, embaixo, só o título
    // curto da lição (1 linha), para não empurrar o resto das metas.
    final part = _lessonPart(lessonId, resources);
    return Column(
      key: YourGameKeys.goalsHighlight,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TipBox(
          key: YourGameKeys.goalsHighlightNotice,
          text: t.sjMetasDestaqueAviso,
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
          key: YourGameKeys.goalsHighlightPart,
          state: CourseItemState.next,
          title: part == null
              ? lesson.title
              : t.sjMetasDestaqueTitulo(t.sjSlotNome(part.slot), part.number),
          summary: part == null ? null : lesson.title,
          onTap: () => onOpen(lesson),
        ),
      ],
    );
  }
}

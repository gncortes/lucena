import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/use_cases/endgame_lesson_rules.dart';
import '../../../routing/routes.dart';
import '../../core/keys/course_preview_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/course/course_continue_card.dart';
import '../../core/widgets/course/course_item_tile.dart';
import '../../core/widgets/course/course_part_header.dart';
import '../../core/widgets/lucena_app_bar.dart';
import '../../core/widgets/placement_test_card.dart';
import '../../core/widgets/scroll_padding.dart';
import '../../endgames/widgets/grade_widgets.dart';
import '../view_models/course_preview_cubit.dart';

/// O mapa do Pilares do Xadrez (canvas `PropV2CursoMapa`), com os mesmos
/// componentes do Curso de finais. Prévia: só o Continuar navega (ao
/// capítulo); lições e teste de nível não fazem nada.
class CourseMapPreviewScreen extends StatelessWidget {
  const CourseMapPreviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocBuilder<CoursePreviewCubit, CoursePreviewState>(
      builder: (context, state) {
        final preview = state.preview;
        final map = preview?.map;
        return Scaffold(
          key: CoursePreviewKeys.map,
          appBar: LucenaAppBar(title: Text(preview?.sale.title ?? '')),
          body: map == null
              ? const SizedBox.shrink()
              : ListView(
                  // v2_cursos_padrao: corpo 8 16 0 16; o fim respira 32.
                  padding: scrollPadding(
                    context,
                    left: AppSpacing.lg,
                    top: AppSpacing.sm,
                    right: AppSpacing.lg,
                    bottom: AppSpacing.xxl,
                  ),
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      // v2_cursos_padrao: 12 entre os blocos.
                      spacing: AppSpacing.md,
                      children: [
                        CourseContinueCard(
                          label: l10n.courseChapterPlace(
                            map.continuePart,
                            map.continueNumber,
                          ),
                          title: map.continueTitle,
                          summary: map.continueSummary,
                          buttonLabel: l10n.homeContinue,
                          buttonKey: CoursePreviewKeys.mapContinue,
                          onPressed: () => context.push(Routes.pilaresChapter),
                        ),
                        PlacementTestCard(
                          label: map.test,
                          tapKey: CoursePreviewKeys.mapTest,
                          onTap: () {},
                        ),
                        CoursePartHeader(
                          label: map.partLabel,
                          title: map.partTitle,
                          count: l10n.coursePartProgress(map.done, map.total),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          // lista(): 8 entre os capítulos.
                          spacing: AppSpacing.sm,
                          children: [
                            for (final chapter in map.chapters)
                              CourseItemTile(
                                key: CoursePreviewKeys.mapChapter(chapter.id),
                                state: CourseItemState.values.byName(
                                  chapter.state,
                                ),
                                title: chapter.title,
                                summary: chapter.summary,
                                medal: chapter.medal == null
                                    ? null
                                    : GradeMedal(
                                        grade: ExerciseGrade.values.byName(
                                          chapter.medal!,
                                        ),
                                        size: CourseItemTile.medalSize,
                                        sideRatio: GradeMedal.compactSideRatio,
                                      ),
                                onTap: () {},
                              ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
        );
      },
    );
  }
}

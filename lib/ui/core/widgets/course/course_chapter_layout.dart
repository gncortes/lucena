import 'package:flutter/material.dart';

import '../../theme/app_spacing.dart';
import '../../theme/app_text.dart';
import '../scroll_padding.dart';

/// O corpo da tela de um capítulo (canvas `tela_licao` de
/// `v2_cursos_padrao.py`, padrão T1 dos cursos): a parte e o título, um aviso
/// opcional, o cartão com as lições e o botão fixo embaixo, por onde a lista
/// passa.
class CourseChapterLayout extends StatelessWidget {
  const CourseChapterLayout({
    required this.place,
    required this.title,
    required this.list,
    required this.footer,
    this.notice,
    this.listKey,
    super.key,
  });

  /// "Finais de peão · capítulo 2 de 3".
  final String place;
  final String title;

  /// O aviso entre o título e a lista (o capítulo em revisão).
  final Widget? notice;

  /// O `ChapterLessonList`.
  final Widget list;

  /// O `CourseContinueFooter`.
  final Widget footer;
  final Key? listKey;

  /// A altura do botão fixo embaixo, com a margem.
  static const footerHeight = 80.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final notice = this.notice;
    return Stack(
      children: [
        ListView(
          key: listKey,
          padding: scrollPadding(
            context,
            left: AppSpacing.screen,
            top: AppSpacing.sm,
            right: AppSpacing.screen,
            bottom: footerHeight + AppSpacing.lg,
          ),
          children: [
            Padding(
              // tela_licao: cabeçalho 0 4, gap 2.
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 2,
                children: [
                  Text(
                    place,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  Text(
                    title,
                    // tela_licao: 26/32 em 700.
                    style: context.screenTitle?.copyWith(
                      fontSize: 26,
                      height: 32 / 26,
                    ),
                  ),
                ],
              ),
            ),
            if (notice != null) ...[
              const SizedBox(height: AppSpacing.md),
              notice,
            ],
            const SizedBox(height: AppSpacing.md),
            list,
          ],
        ),
        PositionedDirectional(start: 0, end: 0, bottom: 0, child: footer),
      ],
    );
  }
}

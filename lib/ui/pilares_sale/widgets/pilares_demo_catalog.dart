import 'package:flutter/material.dart';

import '../../../domain/models/training/training_content.dart';
import '../../../domain/models/training/training_course.dart';
import '../../../domain/use_cases/ad_policy.dart';
import '../../core/keys/course_guide_keys.dart';
import '../../core/keys/purchase_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_icon_size.dart';
import '../../core/theme/app_shape.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/course/course_item_tile.dart';
import '../../core/widgets/course/course_part_header.dart';
import '../../course_guide/widgets/course_guide_copy.dart';
import 'pilares_demo_tabs.dart';
import 'pilares_sale_parts.dart';

/// O Catálogo de quem está na demonstração do Pilares (H-VEN-11, quadro
/// `PropV2DemoCatalogoCompra`). O Capítulo 1 vem aberto, com o selo "Grátis"
/// e "Começa com um anúncio" em cada item. Os outros capítulos aparecem
/// por parte, com cadeado; o toque neles vai a [onChapter], que mostra a
/// folha de compra. No fim, "Conhecer o Pilares" abre a apresentação.
/// O Catálogo do comprador é o da frente Treino; este fica na Venda.
class PilaresDemoCatalog extends StatelessWidget {
  const PilaresDemoCatalog({
    required this.lessons,
    required this.completed,
    required this.nextLessonId,
    required this.onLesson,
    required this.onChapter,
    super.key,
  });

  /// Todas as lições do curso, inclusive as dos capítulos não publicados
  /// (que só dão o título da linha trancada).
  final List<TrainingLesson> lessons;
  final Set<String> completed;
  final String? nextLessonId;
  final ValueChanged<TrainingLesson> onLesson;
  final ValueChanged<String> onChapter;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final free = [
      for (final lesson in lessons)
        if (DemoAdPolicy.chapterOf(lesson.groupId) == 1 &&
            lesson.visible &&
            lesson.published)
          lesson,
    ];
    final done = free.where((l) => completed.contains(l.id)).length;
    // Uma linha por capítulo trancado, na ordem do conteúdo, agrupada por
    // parte; os blocos de aberturas ficam fora.
    final parts = <String, List<(int, String, String)>>{};
    final seen = <String>{};
    for (final lesson in lessons) {
      final number = DemoAdPolicy.chapterOf(lesson.groupId);
      if (number == null || number == 1 || !seen.add(lesson.groupId)) {
        continue;
      }
      final title = lesson.group.isNotEmpty ? lesson.group : lesson.title;
      (parts[lesson.partId] ??= []).add((number, lesson.groupId, title));
    }
    final partOrder = <String>[];
    for (final lesson in lessons) {
      if (!partOrder.contains(lesson.partId)) partOrder.add(lesson.partId);
    }
    final label = theme.textTheme.labelMedium?.copyWith(
      fontSize: 12,
      height: 16 / 12,
      fontWeight: FontWeight.w500,
      color: colors.primary,
    );
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      children: [
        _Banner(done: done, total: free.length),
        const SizedBox(height: AppSpacing.sm),
        Padding(
          padding: const EdgeInsets.fromLTRB(4, AppSpacing.sm, 4, 0),
          child: Row(
            spacing: AppSpacing.sm,
            children: [
              Expanded(
                child: CoursePartHeader(
                  label: l10n.trainingChapterLabel(1),
                  title: free.firstOrNull?.group ?? '',
                  titleWeight: FontWeight.w500,
                  padding: EdgeInsets.zero,
                ),
              ),
              PilaresBadge(text: l10n.venDemoCatalogFree),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        for (final lesson in free) ...[
          CourseItemTile(
            key: CourseGuideKeys.chapterLesson(lesson.id),
            state: completed.contains(lesson.id)
                ? CourseItemState.approved
                : lesson.id == nextLessonId
                ? CourseItemState.next
                : CourseItemState.open,
            title: lesson.kind == TrainingLessonKind.test
                ? l10n.trainingChapterTestTitle
                : lesson.title,
            summary: l10n.venDemoCatalogAdFirst,
            onTap: () => onLesson(lesson),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
          child: Text(
            l10n.venDemoCatalogFull.toUpperCase(),
            style: label?.copyWith(
              height: 20 / 12,
              color: colors.onSurfaceVariant,
            ),
          ),
        ),
        for (final part in partOrder)
          if (parts[part] case final chapters?) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(4, AppSpacing.sm, 4, 0),
              child: Text(
                l10n.trainingPartLabel(
                  courseGuideRoman(
                    _partNumber(part) ?? partOrder.indexOf(part) + 1,
                  ),
                ),
                style: label,
              ),
            ),
            for (final (number, id, title) in chapters)
              _LockedRow(
                key: PurchaseKeys.demoCatalogLockedChapter(number),
                text: '${l10n.trainingChapterLabel(number)} · $title',
                onTap: () => onChapter(id),
              ),
          ],
        const SizedBox(height: AppSpacing.sm),
        PilaresDemoCallout(
          text: l10n.venDemoCatalogClosing,
          buttonKey: PurchaseKeys.demoCatalogLearnMore,
          origin: 'catalogo',
        ),
      ],
    );
  }
}

/// O número da parte pelo id (`pilares.p3` → 3): o Catálogo da demo pula
/// partes sem capítulo trancado, então a posição na lista não serve.
int? _partNumber(String partId) =>
    int.tryParse(RegExp(r'\.p(\d+)$').firstMatch(partId)?.group(1) ?? '');

/// O cartão do topo: presente, "Capítulo 1 liberado para você", quantos dos
/// itens já foram feitos, o texto do anúncio e a barra de progresso.
class _Banner extends StatelessWidget {
  const _Banner({required this.done, required this.total});

  final int done;
  final int total;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return DecoratedBox(
      key: PurchaseKeys.demoCatalogBanner,
      decoration: BoxDecoration(
        color: colors.primaryContainer,
        borderRadius: BorderRadius.circular(AppShape.card),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 10,
          children: [
            Row(
              spacing: AppSpacing.md,
              children: [
                Icon(
                  Icons.card_giftcard,
                  size: AppIconSize.standard,
                  color: colors.primary,
                ),
                Expanded(
                  child: Text(
                    l10n.venDemoCatalogTitle,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontSize: 16,
                      height: 24 / 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Text(
                  l10n.venDemoCatalogDone(done, total),
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontSize: 14,
                    height: 20 / 14,
                    fontWeight: FontWeight.w500,
                    color: colors.primary,
                  ),
                ),
              ],
            ),
            Text(
              l10n.venDemoCatalogText,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: 14,
                height: 20 / 14,
                letterSpacing: 0,
                color: colors.onSurface,
              ),
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppShape.full),
              child: LinearProgressIndicator(
                value: total == 0 ? 0 : done / total,
                minHeight: 6,
                color: colors.primary,
                backgroundColor: colors.outlineVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Um capítulo trancado: o texto em cinza e o cadeado, com a linha de cima.
class _LockedRow extends StatelessWidget {
  const _LockedRow({required this.text, required this.onTap, super.key});

  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return InkWell(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 48),
        padding: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: colors.outlineVariant)),
        ),
        child: Row(
          spacing: AppSpacing.md,
          children: [
            Expanded(
              child: Text(
                text,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontSize: 14,
                  height: 20 / 14,
                  letterSpacing: 0,
                  color: colors.onSurfaceVariant,
                ),
              ),
            ),
            Icon(
              Icons.lock,
              size: AppIconSize.standard,
              color: colors.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

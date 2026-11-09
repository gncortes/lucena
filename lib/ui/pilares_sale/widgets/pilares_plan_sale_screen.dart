import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/models/analytics_event.dart';
import '../../../domain/models/course_preview.dart';
import '../../../domain/models/training/training_course.dart';
import '../../../routing/frentes/d2_routes.dart';
import '../../../routing/routes.dart';
import '../../core/analytics/analytics_context.dart';
import '../../core/keys/purchase_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/motion/entrada_em_cascata.dart';
import '../../core/motion/entradas_vistas.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_icon_size.dart';
import '../../core/theme/app_shape.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/actions_footer.dart';
import '../../core/widgets/busy_button.dart';
import '../../core/widgets/load_error.dart';
import '../../core/widgets/load_skeleton.dart';
import '../../core/widgets/lucena_app_bar.dart';
import '../../course_preview/view_models/course_preview_cubit.dart';
import '../../course_preview/widgets/course_sale_parts.dart';
import 'pilares_sale_parts.dart';

/// O plano como venda (H-VEN-14, quadro `PropV2VendaPlano`): o que o plano
/// faz, os 20 capítulos em ordem, o comparativo de custo e o Capítulo 1
/// liberado. "Começar pelo Capítulo 1" abre o Catálogo da demonstração e
/// "Ver o curso completo" a oferta do fim da demonstração (H-VEN-04).
class PilaresPlanSaleScreen extends StatelessWidget {
  const PilaresPlanSaleScreen({super.key});

  static String get _guide => Routes.training(TrainingCourse.pilares.name);

  void _back(BuildContext context) =>
      context.canPop() ? context.pop() : context.go(_guide);

  @override
  Widget build(BuildContext context) {
    final loadState = context.watch<CoursePreviewCubit>().state;
    if (!loadState.ready && loadState.failure == null) {
      return const LoadSkeletonScreen();
    }
    if (loadState.failure case final failure?) {
      return LoadErrorScreen(
        kind: LoadErrorKind.fromFailure(failure),
        onAction: context.read<CoursePreviewCubit>().retryLoad,
        onBack: () => _back(context),
      );
    }
    final sale = loadState.preview?.sale;
    final l10n = context.l10n;
    return EntradaDaTela(
      id: 'PropV2VendaPlano',
      child: Scaffold(
        key: PurchaseKeys.planSaleScreen,
        appBar: LucenaAppBar(
          leading: BackButton(onPressed: () => _back(context)),
          title: Text(sale?.title ?? l10n.venCourseName),
        ),
        body: sale == null ? null : _Body(sale: sale),
        bottomNavigationBar: ActionsFooter(
          stacked: true,
          children: [
            BusyButton(
              buttonKey: PurchaseKeys.planSaleStart,
              label: l10n.venPlanSaleStart,
              onPressed: () {
                context.analytics.log(
                  AnalyticsEvents.demoInicio(capituloId: '1'),
                );
                context.go(Routes.trainingCatalog(TrainingCourse.pilares.name));
              },
            ),
            BusyButton(
              buttonKey: PurchaseKeys.planSaleFull,
              label: l10n.venPlanSaleFull,
              style: BusyButtonStyle.text,
              onPressed: () => context.push(D2Paths.pilaresDemoEnd),
            ),
          ],
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.sale});

  final CourseSale sale;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final chapters = [for (final part in sale.parts) ...part.chapters]
      ..sort((a, b) => a.number.compareTo(b.number));
    final label = theme.textTheme.titleSmall?.copyWith(
      fontSize: 14,
      height: 20 / 14,
      fontWeight: FontWeight.w500,
      color: colors.onSurfaceVariant,
    );
    // H-ANI-16: o bloco do plano, os números contando, as listas e o fim, em
    // ordem. O botão fixo fica no rodapé, fora da cascata.
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      child: EntradaEmCascata(
        montar: (itens) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: AppSpacing.lg,
          children: itens,
        ),
        itens: [
          ItemDaCascata.titulo(_PlanIntro(sale: sale)),
          ItemDaCascata.numero(
            Row(
              spacing: AppSpacing.sm,
              children: [
                _Number(
                  value: '${sale.chapters}',
                  label: l10n.venPlanSaleChapters,
                ),
                _Number(
                  value: '${sale.lessons}',
                  label: l10n.courseLessonsLabel,
                ),
                _Number(
                  value: sale.exercises,
                  label: l10n.courseExercisesLabel,
                ),
              ],
            ),
          ),
          ItemDaCascata.texto(const _PlanTake()),
          ItemDaCascata.texto(
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: AppSpacing.sm,
              children: [
                Text(l10n.venPlanSaleLearn, style: label),
                Wrap(
                  key: PurchaseKeys.planSaleChapters,
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    for (final chapter in chapters) _Chip(text: chapter.title),
                  ],
                ),
              ],
            ),
          ),
          // Os preços do comparativo vêm da rota (PilaresPricesCubit).
          ItemDaCascata.texto(
            SaleCostCompare(key: PurchaseKeys.planSaleCompare, sale: sale),
          ),
          ItemDaCascata.texto(const _PlanTry()),
          ItemDaCascata.texto(
            Text(
              l10n.venPlanSaleClosing,
              style: theme.textTheme.titleMedium?.copyWith(
                fontSize: 16,
                height: 24 / 16,
                fontWeight: FontWeight.w500,
                color: colors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// O bloco em `primaryContainer` (raio 20, margem 16, 8 entre as linhas).
class _Container extends StatelessWidget {
  const _Container({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.primaryContainer,
      borderRadius: BorderRadius.circular(AppShape.card),
    ),
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: AppSpacing.sm,
        children: children,
      ),
    ),
  );
}

/// Um número do topo: 24/32 negrito em azul e o rótulo 12/16.
class _Number extends StatelessWidget {
  const _Number({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Expanded(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.cardSurface,
          borderRadius: BorderRadius.circular(AppShape.large),
          border: Border.all(color: AppColors.cardOutline),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.md,
            horizontal: AppSpacing.sm,
          ),
          child: Column(
            children: [
              saleCount(
                value,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontSize: 24,
                  height: 32 / 24,
                  fontWeight: FontWeight.w700,
                  color: colors.primary,
                ),
              ),
              Text(
                label,
                textAlign: TextAlign.center,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontSize: 12,
                  height: 16 / 12,
                  fontWeight: FontWeight.w500,
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Um capítulo na lista (pílula clara com contorno).
class _Chip extends StatelessWidget {
  const _Chip({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(AppShape.full),
        border: Border.all(color: AppColors.cardOutline),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: 6,
          horizontal: AppSpacing.md,
        ),
        child: Text(
          text,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontSize: 14,
            height: 20 / 14,
            letterSpacing: 0,
            color: theme.colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}

/// O bloco de abertura: ícone, título e texto do plano.
class _PlanIntro extends StatelessWidget {
  const _PlanIntro({required this.sale});

  final CourseSale sale;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return _Container(
      children: [
        Icon(Icons.explore, size: AppIconSize.large, color: colors.primary),
        Text(
          l10n.venPlanSaleTitle,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontSize: 24,
            height: 32 / 24,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          l10n.venPlanSaleText(sale.lessons),
          style: theme.textTheme.bodyLarge?.copyWith(
            fontSize: 16,
            height: 24 / 16,
          ),
        ),
      ],
    );
  }
}

/// Os benefícios que o plano leva.
class _PlanTake extends StatelessWidget {
  const _PlanTake();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return PilaresBenefitSection(
      compact: true,
      label: l10n.venPlanSaleTake,
      items: [
        (Icons.quiz, l10n.venBenefitLevel, l10n.venPlanSaleLevelText),
        (
          Icons.stadium,
          l10n.venBenefitTournament,
          l10n.venBenefitTournamentText,
        ),
        (Icons.task_alt, l10n.venBenefitGoals, l10n.venPlanSaleGoalsText),
        (
          Icons.event_repeat,
          l10n.venPlanSaleFollow,
          l10n.venPlanSaleFollowText,
        ),
        (Icons.insights, l10n.venBenefitProgress, l10n.venPlanSaleProgressText),
        (Icons.history, l10n.venPlanSaleReview, l10n.venPlanSaleReviewText),
      ],
    );
  }
}

/// O bloco que convida a experimentar o Capítulo 1.
class _PlanTry extends StatelessWidget {
  const _PlanTry();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return _Container(
      children: [
        Row(
          spacing: AppSpacing.lg,
          children: [
            Icon(
              Icons.card_giftcard,
              size: AppIconSize.standard,
              color: colors.primary,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 2,
                children: [
                  Text(
                    l10n.venPlanSaleTry,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontSize: 16,
                      height: 24 / 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    l10n.venPlanSaleTryText,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: 14,
                      height: 20 / 14,
                      letterSpacing: 0,
                      color: colors.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

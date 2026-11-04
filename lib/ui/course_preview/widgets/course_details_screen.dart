import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/models/course_preview.dart';
import '../../../domain/models/training/training_course.dart';
import '../../../routing/frentes/d2_routes.dart';
import '../../../routing/routes.dart';
import '../../core/keys/course_preview_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_icon_size.dart';
import '../../core/theme/app_shape.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/load_error.dart';
import '../../core/widgets/load_skeleton.dart';
import '../view_models/course_preview_cubit.dart';
import 'course_sale_parts.dart';

/// "Sobre o Pilares" (H-VEN-02, quadros `PropV1CursoDetalhes`, `…Conteudo` e
/// `…Duvidas`): como o curso funciona, o sumário e as dúvidas, o mesmo para
/// demo e comprador. A aba e os acordeões abertos não persistem; a seta volta
/// sempre a "Como funciona".
class CourseDetailsScreen extends StatelessWidget {
  const CourseDetailsScreen({this.fromHelp = false, super.key});

  /// Aberta pelo cartão de "Como funciona": a seta só fecha esta tela.
  final bool fromHelp;

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
    final preview = loadState.preview;
    if (preview == null) return const Scaffold(key: CoursePreviewKeys.details);
    return _DetailsPage(preview: preview, onBack: () => _back(context));
  }

  void _back(BuildContext context) {
    if (fromHelp && context.canPop()) {
      context.pop();
    } else {
      context.go('${Routes.training(TrainingCourse.pilares.name)}/help');
    }
  }
}

class _DetailsPage extends StatefulWidget {
  const _DetailsPage({required this.preview, required this.onBack});

  final CoursePreview preview;
  final VoidCallback onBack;

  @override
  State<_DetailsPage> createState() => _DetailsPageState();
}

class _DetailsPageState extends State<_DetailsPage>
    with SingleTickerProviderStateMixin {
  late final _tabs = TabController(length: 3, vsync: this)
    ..addListener(_tabChanged);
  final _scroll = ScrollController();

  @override
  void dispose() {
    _tabs.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _tabChanged() {
    if (_tabs.indexIsChanging) return;
    setState(() {});
    // A aba nova começa do início dela.
    if (_scroll.hasClients) _scroll.jumpTo(0);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final page = Theme.of(context).scaffoldBackgroundColor;
    final sale = widget.preview.sale;
    final details = widget.preview.details;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) widget.onBack();
      },
      child: Scaffold(
        key: CoursePreviewKeys.details,
        body: CustomScrollView(
          controller: _scroll,
          slivers: [
            SliverAppBar(
              pinned: true,
              centerTitle: true,
              backgroundColor: page,
              surfaceTintColor: AppColors.clear,
              scrolledUnderElevation: 0,
              leading: BackButton(onPressed: widget.onBack),
              title: Text(l10n.venAboutTitle),
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: SaleTabsHeader(
                controller: _tabs,
                color: page,
                keyOf: CoursePreviewKeys.detailsTab,
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                0,
                AppSpacing.lg,
                AppSpacing.xxl,
              ),
              sliver: SliverToBoxAdapter(
                child: switch (_tabs.index) {
                  0 => _Overview(details: details),
                  1 => _Content(sale: sale, details: details),
                  _ => SaleFaq(
                    items: details.faq,
                    keyOf: CoursePreviewKeys.detailsFaq,
                  ),
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Visão geral: os 5 passos, o que o curso cobre, aberturas, testes e
/// progresso e o "Para quem é".
class _Overview extends StatelessWidget {
  const _Overview({required this.details});

  final CourseDetails details;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SaleSection(l10n.venAboutHow),
        SaleSteps(steps: details.steps),
        SaleSection(l10n.venAboutCovers),
        SaleCard(
          spacing: AppSpacing.lg,
          children: [
            Text(details.coverLine, style: saleBody(context)),
            for (final item in details.parts) SaleIconLine(item: item),
          ],
        ),
        SaleSection(l10n.venAboutOpenings),
        SaleCard(
          spacing: AppSpacing.lg,
          children: [
            for (final item in details.openings) SaleIconLine(item: item),
          ],
        ),
        SaleSection(l10n.venAboutProgress),
        SaleCard(
          spacing: AppSpacing.lg,
          children: [
            for (final item in details.progress) SaleIconLine(item: item),
          ],
        ),
        SaleSection(l10n.courseSaleAudience),
        SaleAudienceCard(
          item: details.audience,
          tapKey: CoursePreviewKeys.detailsAudience,
        ),
      ],
    );
  }
}

/// Conteúdo: o formato do resultado do teste e o sumário (Parte I aberta).
class _Content extends StatelessWidget {
  const _Content({required this.sale, required this.details});

  final CourseSale sale;
  final CourseDetails details;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppSpacing.lg),
        SaleLevelCard(item: details.result, examples: sale.levelExamples),
        SaleSection(l10n.courseSaleSummary),
        Text(details.summaryLine, style: saleBody(context)),
        const SizedBox(height: AppSpacing.md),
        SaleSummary(
          parts: sale.parts,
          openings: sale.openings,
          keyOf: CoursePreviewKeys.detailsPart,
        ),
      ],
    );
  }
}

/// O cartão "Sobre o Pilares" no fim de "Como funciona" (quadro
/// `PropV1TreinoAjuda`): abre os detalhes por cima da Ajuda.
class CourseAboutTile extends StatelessWidget {
  const CourseAboutTile({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final radius = BorderRadius.circular(AppShape.card);
    return Material(
      color: AppColors.cardSurface,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: const BorderSide(color: AppColors.cardOutline),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: CoursePreviewKeys.aboutTile,
        onTap: () => context.push(D2Paths.about(fromHelp: true)),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            spacing: AppSpacing.lg,
            children: [
              Icon(
                Icons.article,
                size: AppIconSize.standard,
                color: colors.primary,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 2,
                  children: [
                    Text(
                      l10n.venAboutTitle,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontSize: 16,
                        height: 24 / 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      l10n.venAboutCardLine,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: 14,
                        height: 20 / 14,
                        letterSpacing: 0,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                size: AppIconSize.standard,
                color: colors.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

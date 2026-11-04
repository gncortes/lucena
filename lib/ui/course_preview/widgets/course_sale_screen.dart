import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/models/character.dart';
import '../../../domain/models/course_preview.dart';
import '../../../domain/models/pilares_access.dart';
import '../../../routing/frentes/d2_routes.dart';
import '../../../routing/routes.dart';
import '../../core/keys/course_preview_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_button.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_icon_size.dart';
import '../../core/theme/app_shape.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/character_avatar.dart';
import '../../core/widgets/load_error.dart';
import '../../core/widgets/load_skeleton.dart';
import '../../core/widgets/teacher_speech.dart';
import '../../pilares_sale/view_models/pilares_prices_cubit.dart';
import '../view_models/course_preview_cubit.dart';
import 'course_sale_parts.dart';

/// A apresentação do Pilares do Xadrez (H-VEN-01, canvas
/// `PropV2CursoApresentacao`, `…VendaRecolhida`, `…VendaConteudo` e
/// `…VendaDuvidas`): o nome sempre na barra, o topo com os números, o que vem
/// além do curso, o preço da loja, o comparativo de custo e o Viktor; as abas
/// fixas filtram o miolo e "Ver opções de compra" abre a oferta.
class CourseSaleScreen extends StatelessWidget {
  const CourseSaleScreen({this.origin, super.key});

  /// De onde a apresentação foi aberta (vai à oferta, para o analytics).
  final String? origin;

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
    if (sale == null) return const Scaffold(key: CoursePreviewKeys.sale);
    return _SalePage(sale: sale, viktor: loadState.viktor, origin: origin);
  }
}

void _back(BuildContext context) =>
    context.canPop() ? context.pop() : context.go(Routes.home);

class _SalePage extends StatefulWidget {
  const _SalePage({required this.sale, required this.viktor, this.origin});

  final CourseSale sale;
  final Character? viktor;
  final String? origin;

  @override
  State<_SalePage> createState() => _SalePageState();
}

class _SalePageState extends State<_SalePage>
    with SingleTickerProviderStateMixin {
  late final _tabs = TabController(length: 3, vsync: this)
    ..addListener(_tabChanged);
  final _scroll = ScrollController();
  final _hero = GlobalKey();

  @override
  void dispose() {
    _tabs.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _tabChanged() {
    if (_tabs.indexIsChanging) return;
    setState(() {});
    // Com as abas já grudadas no alto, a aba nova começa do início dela.
    final hero = _hero.currentContext?.size?.height;
    if (hero != null && _scroll.hasClients && _scroll.offset > hero) {
      _scroll.jumpTo(hero);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final sale = widget.sale;
    final page = theme.scaffoldBackgroundColor;
    return Scaffold(
      key: CoursePreviewKeys.sale,
      // rodape_fixo: 16 16 24 no fundo da página.
      bottomNavigationBar: ColoredBox(
        color: page,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.xl,
            ),
            child: SizedBox(
              height: kButtonHeight,
              child: FilledButton(
                key: CoursePreviewKeys.buy,
                onPressed: () =>
                    context.push(D2Paths.offer(origin: widget.origin)),
                child: Text(l10n.venSaleBuy),
              ),
            ),
          ),
        ),
      ),
      body: CustomScrollView(
        key: CoursePreviewKeys.saleScroll,
        controller: _scroll,
        slivers: [
          // O nome sempre na barra, sem subtítulo e com os mesmos ícones.
          SliverAppBar(
            pinned: true,
            centerTitle: true,
            backgroundColor: page,
            surfaceTintColor: AppColors.clear,
            scrolledUnderElevation: 0,
            leading: BackButton(onPressed: () => _back(context)),
            title: Text(sale.title),
          ),
          SliverToBoxAdapter(
            child: Padding(
              key: _hero,
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                AppSpacing.lg,
              ),
              child: _Hero(sale: sale, viktor: widget.viktor),
            ),
          ),
          SliverPersistentHeader(
            pinned: true,
            delegate: _TabsHeader(
              color: page,
              tabs: TabBar(
                controller: _tabs,
                dividerHeight: 0,
                indicatorSize: TabBarIndicatorSize.tab,
                // abas_venda: indicador de 3 com 12 de recuo.
                indicator: UnderlineTabIndicator(
                  borderSide: BorderSide(
                    width: 3,
                    color: theme.colorScheme.primary,
                  ),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppShape.tiny),
                  ),
                  insets: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                ),
                labelColor: theme.colorScheme.primary,
                unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
                labelStyle: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                tabs: [
                  for (final (i, label) in [
                    l10n.courseSaleOverview,
                    l10n.courseSaleContent,
                    l10n.courseSaleFaq,
                  ].indexed)
                    Tab(key: CoursePreviewKeys.tab(i), text: label),
                ],
              ),
              line: theme.colorScheme.outlineVariant,
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
                0 => _Overview(sale: sale),
                1 => _Content(sale: sale),
                _ => SaleFaq(items: sale.faq, keyOf: CoursePreviewKeys.faq),
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// As abas grudadas embaixo da barra: 48 e a linha fina (abas_venda).
class _TabsHeader extends SliverPersistentHeaderDelegate {
  const _TabsHeader({
    required this.tabs,
    required this.color,
    required this.line,
  });

  final TabBar tabs;
  final Color color;
  final Color line;

  static const _height = 48.0 + 1;

  @override
  double get minExtent => _height;

  @override
  double get maxExtent => _height;

  @override
  Widget build(BuildContext context, double shrink, bool overlaps) =>
      DecoratedBox(
        decoration: BoxDecoration(
          color: color,
          border: Border(bottom: BorderSide(color: line)),
        ),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 1),
          child: SizedBox(height: 48, child: tabs),
        ),
      );

  @override
  bool shouldRebuild(_TabsHeader old) =>
      old.tabs != tabs || old.color != color || old.line != line;
}

/// O topo (quadro PropV2CursoApresentacao): a linha, os números, o que vem
/// além do curso, o preço, o comparativo e a fala do Viktor.
class _Hero extends StatelessWidget {
  const _Hero({required this.sale, required this.viktor});

  final CourseSale sale;
  final Character? viktor;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final viktor = this.viktor;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          sale.line,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontSize: 15,
            height: 22 / 15,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Row(
          spacing: AppSpacing.sm,
          children: [
            _Number(value: '${sale.lessons}', label: l10n.courseLessonsLabel),
            _Number(value: sale.exercises, label: l10n.courseExercisesLabel),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        _Benefits(sale: sale),
        const SizedBox(height: AppSpacing.md),
        _PriceCard(sale: sale),
        const SizedBox(height: AppSpacing.md),
        _CostCompare(sale: sale),
        if (viktor != null) ...[
          const SizedBox(height: AppSpacing.md),
          TeacherSpeech(
            teacher: viktor,
            text: sale.speech,
            speechContext: SpeechContext.teaching,
            avatarSize: CharacterAvatar.speech,
          ),
        ],
      ],
    );
  }
}

/// Um número do topo: o valor grande em azul e o rótulo embaixo (#FAFBF9,
/// borda #E1E5DF, cantos de 16, 12 8 de respiro).
class _Number extends StatelessWidget {
  const _Number({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: SaleCard(
        color: AppColors.cardSurface,
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.md,
          horizontal: AppSpacing.sm,
        ),
        spacing: 2,
        children: [
          Text(
            value,
            textAlign: TextAlign.center,
            style: saleStrong(
              context,
              size: AppIconSize.standard,
              line: 30,
            )?.copyWith(color: theme.colorScheme.primary),
          ),
          Text(
            label,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 13,
              height: 18 / 13,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// "Mais que um curso de xadrez": o título, a linha e os 8 itens (azul e
/// verde alternados).
class _Benefits extends StatelessWidget {
  const _Benefits({required this.sale});

  final CourseSale sale;

  @override
  Widget build(BuildContext context) => SaleCard(
    spacing: 14,
    children: [
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: AppSpacing.xs,
        children: [
          Text(
            sale.benefitsTitle,
            style: saleStrong(context, size: 20, line: 26),
          ),
          Text(sale.benefitsLine, style: saleBody(context)),
        ],
      ),
      for (final (i, item) in sale.benefits.indexed)
        SaleIconLine(
          key: CoursePreviewKeys.benefit(i),
          item: item,
          green: i.isOdd,
        ),
    ],
  );
}

/// O preço (preco_topo): o vitalício da loja, a nota, o mensal num quadro
/// claro e os capítulos liberados embaixo da linha.
class _PriceCard extends StatelessWidget {
  const _PriceCard({required this.sale});

  final CourseSale sale;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final on = theme.colorScheme.onPrimary;
    final prices = context.watch<PilaresPricesCubit>().state;
    return DecoratedBox(
      key: CoursePreviewKeys.priceCard,
      decoration: BoxDecoration(
        color: theme.colorScheme.primary,
        borderRadius: BorderRadius.circular(AppShape.large),
      ),
      child: Padding(
        // preco_topo: 18 18 14.
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 2,
          children: [
            Text(
              sale.lifetimeTitle,
              style: theme.textTheme.labelMedium?.copyWith(
                fontSize: 13,
                height: 18 / 13,
                fontWeight: FontWeight.w600,
                color: on.withValues(alpha: 0.8),
              ),
            ),
            Text(
              prices[PilaresPlan.lifetime] ?? l10n.venRefLifetime,
              style: saleStrong(
                context,
                size: 32,
                line: 38,
              )?.copyWith(color: on),
            ),
            Text(
              sale.lifetimeNote,
              style: saleBody(context, color: on.withValues(alpha: 0.87)),
            ),
            const SizedBox(height: AppSpacing.md),
            DecoratedBox(
              key: CoursePreviewKeys.planMonthly,
              decoration: BoxDecoration(
                color: on.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(AppShape.medium),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: AppSpacing.md,
                ),
                child: Row(
                  spacing: AppSpacing.sm,
                  children: [
                    Expanded(
                      child: Text(
                        sale.monthlyQuestion,
                        style: saleBody(context, color: on),
                      ),
                    ),
                    Text(
                      l10n.venPerMonth(
                        prices[PilaresPlan.monthly] ?? l10n.venRefMonthly,
                      ),
                      style: saleStrong(
                        context,
                        size: 15,
                        line: 20,
                      )?.copyWith(color: on),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.md),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: on.withValues(alpha: 0.25)),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.md),
                  child: Row(
                    spacing: AppSpacing.sm,
                    children: [
                      // #BFE3C6 no canvas: o verde claro das metas.
                      const Icon(
                        Icons.lock_open_rounded,
                        size: AppIconSize.button,
                        color: AppColors.goalWinBg,
                      ),
                      Expanded(
                        child: Text(
                          sale.unlock,
                          style: saleBody(context, color: on),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// O maior valor em reais de um texto ("R$ 700 a R$ 1.080" → 1080).
double? _largestReais(String text) {
  double? largest;
  for (final match in RegExp(r'\d[\d.]*(,\d+)?').allMatches(text)) {
    final value = double.tryParse(
      match.group(0)!.replaceAll('.', '').replaceAll(',', '.'),
    );
    if (value != null && (largest == null || value > largest)) {
      largest = value;
    }
  }
  return largest;
}

/// "Quanto custa estudar xadrez por 3 meses" (data-comparativo): as linhas
/// de custo, a soma com a barra cheia e o Pilares com a barra do tamanho do
/// preço.
class _CostCompare extends StatelessWidget {
  const _CostCompare({required this.sale});

  final CourseSale sale;

  /// A proporção do quadro (R$ 99,90 de R$ 1.080) quando falta um preço.
  static const _fallbackRatio = 0.092;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = Theme.of(context).colorScheme;
    final price =
        context.watch<PilaresPricesCubit>().state[PilaresPlan.lifetime] ??
        l10n.venRefLifetime;
    final costs = sale.costs;
    final total = costs.isEmpty ? null : _largestReais(costs.last.value);
    final ours = _largestReais(price);
    final ratio = total != null && ours != null && total > 0
        ? (ours / total).clamp(0.02, 1.0)
        : _fallbackRatio;
    final rowStyle = saleBody(
      context,
      color: colors.onSurface,
    )?.copyWith(fontWeight: FontWeight.w500);
    final noteStyle = saleBody(context)
        ?.copyWith(fontSize: 13, height: 18 / 13);
    Widget row(CourseSaleCost cost) => Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      spacing: AppSpacing.sm,
      children: [
        Expanded(child: Text(cost.title, style: rowStyle)),
        Text(cost.value, textAlign: TextAlign.end, style: rowStyle),
      ],
    );
    return DecoratedBox(
      key: CoursePreviewKeys.costCompare,
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        border: Border.all(color: AppColors.cardOutline),
        borderRadius: BorderRadius.circular(AppShape.card),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: AppSpacing.md,
          children: [
            Text(
              sale.costTitle,
              style: saleStrong(
                context,
                size: 18,
                line: 24,
              )?.copyWith(fontWeight: FontWeight.w600),
            ),
            for (final (i, cost) in costs.indexed)
              if (i < costs.length - 1)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: 2,
                  children: [
                    row(cost),
                    if (cost.note case final note?)
                      Text(note, style: noteStyle),
                  ],
                )
              else ...[
                const Divider(
                  height: 1,
                  thickness: 1,
                  color: AppColors.cardOutline,
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: AppSpacing.xs,
                  children: [
                    row(cost),
                    _Bar(
                      height: 10,
                      track: colors.primary.withValues(alpha: 0.1),
                      fill: AppColors.costBar,
                      ratio: 1,
                    ),
                  ],
                ),
              ],
            DecoratedBox(
              decoration: BoxDecoration(
                color: colors.primary,
                borderRadius: BorderRadius.circular(AppShape.large),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: AppSpacing.sm,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      spacing: AppSpacing.sm,
                      children: [
                        Expanded(
                          child: Text(
                            sale.ours.title,
                            style: saleStrong(context)
                                ?.copyWith(color: colors.onPrimary),
                          ),
                        ),
                        Text(
                          price,
                          style: saleStrong(
                            context,
                            size: 18,
                            line: 24,
                          )?.copyWith(color: colors.onPrimary),
                        ),
                      ],
                    ),
                    _Bar(
                      height: 14,
                      track: colors.onPrimary.withValues(alpha: 0.22),
                      fill: AppColors.goalWinBg,
                      ratio: ratio,
                    ),
                    if (sale.ours.summary case final summary?)
                      Text(
                        summary,
                        style: saleBody(
                          context,
                          color: AppColors.onPrimarySoft,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Text(
              sale.costSource,
              style: saleBody(context)?.copyWith(fontSize: 12, height: 16 / 12),
            ),
          ],
        ),
      ),
    );
  }
}

/// Uma barra do comparativo: o trilho e o preenchimento na proporção.
class _Bar extends StatelessWidget {
  const _Bar({
    required this.height,
    required this.track,
    required this.fill,
    required this.ratio,
  });

  final double height;
  final Color track;
  final Color fill;
  final double ratio;

  @override
  Widget build(BuildContext context) => Container(
    height: height,
    decoration: BoxDecoration(
      color: track,
      borderRadius: BorderRadius.circular(AppShape.full),
    ),
    alignment: AlignmentDirectional.centerStart,
    child: FractionallySizedBox(
      widthFactor: ratio,
      heightFactor: 1,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(AppShape.full),
        ),
      ),
    ),
  );
}

/// A aba Visão geral: o que aprende, para quem é e o que vem no curso.
class _Overview extends StatelessWidget {
  const _Overview({required this.sale});

  final CourseSale sale;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SaleSection(l10n.courseSaleLearn),
        // lista_check: check verde, título e frase, 14 entre os itens.
        SaleCard(
          spacing: 14,
          children: [
            for (final item in sale.learn)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: AppSpacing.md,
                children: [
                  const Icon(
                    Icons.check_circle,
                    size: AppIconSize.standard,
                    color: saleGreen,
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 2,
                      children: [
                        Text(item.title, style: saleStrong(context)),
                        if (item.summary case final summary?)
                          Text(summary, style: saleBody(context)),
                      ],
                    ),
                  ),
                ],
              ),
          ],
        ),
        SaleSection(l10n.courseSaleAudience),
        // cartao_faixa: abre a tela "Para quem é" (PropV2CursoFaixa).
        Material(
          color: colors.primaryContainer,
          borderRadius: BorderRadius.circular(AppShape.large),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            key: CoursePreviewKeys.audience,
            onTap: () => context.push(D2Paths.pilaresForWhom),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                spacing: AppSpacing.md,
                children: [
                  Icon(
                    Icons.groups_rounded,
                    size: AppIconSize.standard,
                    color: colors.primary,
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 2,
                      children: [
                        Text(sale.audience.title, style: saleStrong(context)),
                        if (sale.audience.summary case final summary?)
                          Text(
                            summary,
                            style: saleBody(context, color: colors.onSurface),
                          ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: AppIconSize.standard,
                    color: colors.primary,
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        SaleCard(
          children: [
            for (final item in sale.audienceItems) SaleIconLine(item: item),
          ],
        ),
        SaleSection(l10n.courseSaleIncluded),
        SaleCard(
          spacing: AppSpacing.lg,
          children: [
            for (final item in sale.included) SaleIconLine(item: item),
          ],
        ),
      ],
    );
  }
}

/// A aba Conteúdo: o teste de nível e o sumário por parte (a primeira
/// aberta).
class _Content extends StatelessWidget {
  const _Content({required this.sale});

  final CourseSale sale;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppSpacing.lg),
        // destaque_nivel.
        SaleCard(
          color: colors.primaryContainer,
          spacing: 10,
          children: [
            Row(
              spacing: 10,
              children: [
                Icon(
                  Icons.insights_rounded,
                  size: AppIconSize.standard,
                  color: colors.primary,
                ),
                Expanded(
                  child: Text(
                    sale.level.title,
                    style: saleStrong(context, size: 17),
                  ),
                ),
              ],
            ),
            if (sale.level.summary case final summary?)
              Text(summary, style: saleBody(context, color: colors.onSurface)),
            SaleCard(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 14),
              spacing: 0,
              children: [
                for (final example in sale.levelExamples)
                  ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 36),
                    child: Row(
                      spacing: AppSpacing.md,
                      children: [
                        Expanded(
                          child: Text(
                            example.title,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontSize: 15,
                              height: 20 / 15,
                            ),
                          ),
                        ),
                        SalePill(text: example.status, tone: example.tone),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
        SaleSection(l10n.courseSaleSummary),
        Text(sale.summaryNote, style: saleBody(context)),
        const SizedBox(height: AppSpacing.md),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: AppSpacing.sm,
          children: [
            for (final (i, part) in sale.parts.indexed)
              SalePartTile(
                key: CoursePreviewKeys.part(i),
                part: part,
                initiallyOpen: i == 0,
                openings: sale.openings,
              ),
          ],
        ),
      ],
    );
  }
}

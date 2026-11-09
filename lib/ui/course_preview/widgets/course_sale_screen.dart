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
import '../../core/motion/entrada_em_cascata.dart';
import '../../core/motion/entradas_vistas.dart';
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
    if (sale == null) {
      // Sem o conteúdo da venda (repositório devolveu nulo): nunca uma tela
      // em branco sem saída.
      return LoadErrorScreen(
        kind: LoadErrorKind.unavailable,
        onAction: context.read<CoursePreviewCubit>().retryLoad,
        onBack: () => _back(context),
      );
    }
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
  // O índice muda na hora: quem cruza as abas é o AbasFadeThrough (450 ms).
  late final _tabs = TabController(
    length: 3,
    vsync: this,
    animationDuration: Duration.zero,
  )..addListener(_tabChanged);
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
    return EntradaDaTela(
      id: 'PropV2CursoApresentacao',
      child: Scaffold(
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
              delegate: SaleTabsHeader(
                controller: _tabs,
                color: page,
                keyOf: CoursePreviewKeys.tab,
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
                child: SaleTabBody(
                  index: _tabs.index,
                  child: switch (_tabs.index) {
                    0 => _Overview(sale: sale),
                    1 => _Content(sale: sale),
                    _ => SaleFaq(items: sale.faq, keyOf: CoursePreviewKeys.faq),
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
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
    final benefits = sale.benefits;
    // H-ANI-16 (01b): subtítulo, números, a lista item a item, o preço, o
    // comparativo e o Viktor. O título fica na app bar e não entra.
    return EntradaEmCascata(
      montar: (itens) {
        final tail = itens.sublist(3 + benefits.length);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            itens[0],
            const SizedBox(height: AppSpacing.lg),
            itens[1],
            const SizedBox(height: AppSpacing.md),
            SaleCard(
              spacing: 14,
              children: itens.sublist(2, 3 + benefits.length),
            ),
            for (final item in tail) ...[
              const SizedBox(height: AppSpacing.md),
              item,
            ],
          ],
        );
      },
      itens: [
        ItemDaCascata.texto(
          Text(
            sale.line,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontSize: 15,
              height: 22 / 15,
            ),
          ),
        ),
        ItemDaCascata.numero(
          Row(
            spacing: AppSpacing.sm,
            children: [
              _Number(value: '${sale.lessons}', label: l10n.courseLessonsLabel),
              _Number(value: sale.exercises, label: l10n.courseExercisesLabel),
            ],
          ),
        ),
        ItemDaCascata.texto(_BenefitsHeader(sale: sale)),
        for (final (i, item) in benefits.indexed)
          ItemDaCascata.texto(
            SaleIconLine(
              key: CoursePreviewKeys.benefit(i),
              item: item,
              green: i.isOdd,
            ),
          ),
        ItemDaCascata.texto(_PriceCard(sale: sale)),
        ItemDaCascata.texto(SaleCostCompare(sale: sale)),
        if (viktor != null)
          ItemDaCascata.texto(
            TeacherSpeech(
              teacher: viktor,
              text: sale.speech,
              speechContext: SpeechContext.teaching,
              avatarSize: CharacterAvatar.speech,
            ),
          ),
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
          saleCount(
            value,
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

/// "Mais que um curso de xadrez": o título e a linha do cartão; os 8 itens
/// (azul e verde alternados) entram um a um na cascata do topo.
class _BenefitsHeader extends StatelessWidget {
  const _BenefitsHeader({required this.sale});

  final CourseSale sale;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    spacing: AppSpacing.xs,
    children: [
      Text(sale.benefitsTitle, style: saleStrong(context, size: 20, line: 26)),
      Text(sale.benefitsLine, style: saleBody(context)),
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

/// A aba Visão geral: o que aprende, para quem é e o que vem no curso.
class _Overview extends StatelessWidget {
  const _Overview({required this.sale});

  final CourseSale sale;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
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
        SaleAudienceCard(
          item: sale.audience,
          tapKey: CoursePreviewKeys.audience,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppSpacing.lg),
        SaleLevelCard(item: sale.level, examples: sale.levelExamples),
        SaleSection(l10n.courseSaleSummary),
        Text(sale.summaryNote, style: saleBody(context)),
        const SizedBox(height: AppSpacing.md),
        SaleSummary(
          parts: sale.parts,
          openings: sale.openings,
          keyOf: CoursePreviewKeys.part,
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/models/course_preview.dart';
import '../../../domain/models/pilares_access.dart';
import '../../../routing/frentes/d2_routes.dart';
import '../../core/keys/course_preview_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_icon_size.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_shape.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text.dart';
import '../../pilares_sale/view_models/pilares_prices_cubit.dart';

/// As peças comuns da venda (H-VEN-01) e do Sobre o Pilares (H-VEN-02):
/// cartão, seção, linha com ícone, passos, sumário por parte e dúvidas. Um
/// componente só para as duas telas.

/// Quantos exercícios tem o teste de cada capítulo (quadros do Sumário).
const saleChapterTestCount = 12;

/// O ícone do item pelo nome do Material Symbols que vem do canvas (os
/// quadros usam o cheio, `FILL 1`).
IconData saleIcon(String? name) => switch (name) {
  'warning' => Icons.warning_rounded,
  'trending_flat' => Icons.trending_flat_rounded,
  'help' => Icons.help_rounded,
  'auto_stories' => Icons.auto_stories_rounded,
  'school' => Icons.school_rounded,
  'menu_book' => Icons.menu_book_rounded,
  'emoji_events' => Icons.emoji_events_rounded,
  'rule' => Icons.rule_rounded,
  'tune' => Icons.tune_rounded,
  'event_repeat' => Icons.event_repeat_rounded,
  'how_to_reg' => Icons.how_to_reg_rounded,
  'avg_pace' => Icons.timer_rounded,
  'vpn_key' => Icons.vpn_key_rounded,
  'bolt' => Icons.bolt_rounded,
  'checklist' => Icons.checklist_rounded,
  'insights' => Icons.insights_rounded,
  'flag' => Icons.flag_rounded,
  'notifications' => Icons.notifications_rounded,
  'explore' => Icons.explore_rounded,
  'edit_calendar' => Icons.edit_calendar_rounded,
  'stadium' => Icons.stadium_rounded,
  'quiz' => Icons.quiz_rounded,
  'groups' => Icons.groups_rounded,
  'lock_open' => Icons.lock_open_rounded,
  'payments' => Icons.payments_rounded,
  'event_busy' => Icons.event_busy_rounded,
  'verified' => Icons.verified_rounded,
  'travel_explore' => Icons.travel_explore_rounded,
  'grid_view' => Icons.grid_view_rounded,
  'swap_horiz' => Icons.swap_horiz_rounded,
  'calculate' => Icons.calculate_rounded,
  'layers' => Icons.layers_rounded,
  'article' => Icons.article_rounded,
  _ => Icons.circle,
};

/// O verde de "feito" (#2E6B3A) e o fundo claro dele no canvas (#E2F0E4).
const saleGreen = AppColors.record;
final saleGreenSoft = AppColors.record.withValues(alpha: 0.12);

TextStyle? saleStrong(
  BuildContext context, {
  double size = 16,
  double line = 22,
}) => Theme.of(context).textTheme.titleMedium?.copyWith(
  fontSize: size,
  height: line / size,
  fontWeight: AppWeight.strong,
);

TextStyle? saleBody(BuildContext context, {Color? color}) =>
    Theme.of(context).textTheme.bodyMedium?.copyWith(
      fontSize: 14,
      height: 20 / 14,
      color: color ?? Theme.of(context).colorScheme.onSurfaceVariant,
    );

/// Um cartão branco da página (cartao: 16 de respiro, cantos de 16).
class SaleCard extends StatelessWidget {
  const SaleCard({
    required this.children,
    this.spacing = AppSpacing.md,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.color,
    super.key,
  });

  final List<Widget> children;
  final double spacing;
  final EdgeInsetsGeometry padding;
  final Color? color;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: color ?? Theme.of(context).colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(AppShape.large),
      // #E1E5DF nos quadros: a borda fina dos cartões claros.
      border: color == null
          ? Border.all(color: Theme.of(context).colorScheme.outlineVariant)
          : null,
    ),
    child: Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: spacing,
        children: children,
      ),
    ),
  );
}

/// O título de seção da venda (CompSecao tamanho="titulo": 20, 16 acima e 4
/// abaixo).
class SaleSection extends StatelessWidget {
  const SaleSection(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: AppSpacing.lg, bottom: AppSpacing.xs),
    child: ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 40),
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: Text(text, style: saleStrong(context, size: 20, line: 26)),
      ),
    ),
  );
}

/// "Como você aprende" (ciclo): os passos ligados por uma linha vertical.
class SaleSteps extends StatelessWidget {
  const SaleSteps({required this.steps, super.key});

  final List<CourseSaleItem> steps;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return SaleCard(
      spacing: 0,
      children: [
        for (final (i, step) in steps.indexed)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 14,
              children: [
                SizedBox(
                  width: 32,
                  child: Column(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: colors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${i + 1}',
                          style: saleStrong(
                            context,
                            size: 15,
                            line: 20,
                          )?.copyWith(color: colors.onPrimary),
                        ),
                      ),
                      if (i < steps.length - 1)
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: AppSpacing.xs,
                            ),
                            child: SizedBox(
                              width: 2,
                              child: ColoredBox(color: colors.primaryContainer),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      top: 5,
                      bottom: i < steps.length - 1 ? AppSpacing.lg : 0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 2,
                      children: [
                        Text(step.title, style: saleStrong(context)),
                        if (step.summary != null)
                          Text(step.summary!, style: saleBody(context)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Uma linha com ícone num círculo (linha_recurso); sem frase, centrada.
class SaleIconLine extends StatelessWidget {
  const SaleIconLine({required this.item, this.green = false, super.key});

  final CourseSaleItem item;
  final bool green;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final summary = item.summary;
    return Row(
      crossAxisAlignment: summary == null
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      spacing: 14,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: green ? saleGreenSoft : colors.primaryContainer,
            shape: BoxShape.circle,
          ),
          child: Icon(
            saleIcon(item.icon),
            size: AppIconSize.standard,
            color: green ? saleGreen : colors.primary,
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 2,
            children: [
              Text(item.title, style: saleStrong(context)),
              if (summary != null) Text(summary, style: saleBody(context)),
            ],
          ),
        ),
      ],
    );
  }
}

/// A situação do exemplo do teste de nível.
class SalePill extends StatelessWidget {
  const SalePill({required this.text, required this.tone, super.key});

  final String text;
  final String tone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final (foreground, background) = switch (tone) {
      'mastered' => (saleGreen, saleGreenSoft),
      // #8A5A00 sobre #FBEFD6 no canvas: o âmbar das estrelas.
      'review' => (
        AppColors.goldInk,
        AppColors.goldColor.withValues(alpha: 0.2),
      ),
      _ => (colors.primary, colors.primaryContainer),
    };
    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppShape.full),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 10),
        child: Text(
          text,
          style: theme.textTheme.labelMedium?.copyWith(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: foreground,
          ),
        ),
      ),
    );
  }
}

/// Uma parte do sumário (parte_fechada e parte_aberta, Sumário B): tocar no
/// cabeçalho abre todos os capítulos de uma vez, sem expansível por capítulo.
class SalePartTile extends StatefulWidget {
  const SalePartTile({
    required this.part,
    required this.initiallyOpen,
    required this.openings,
    super.key,
  });

  final CourseSalePart part;
  final bool initiallyOpen;

  /// As aberturas, no fim de cada parte aberta.
  final ({String title, String line, List<String> items}) openings;

  @override
  State<SalePartTile> createState() => _SalePartTileState();
}

class _SalePartTileState extends State<SalePartTile> {
  late bool _open = widget.initiallyOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final part = widget.part;
    return Material(
      color: colors.surfaceContainerLow,
      borderRadius: BorderRadius.circular(AppShape.large),
      clipBehavior: Clip.antiAlias,
      child: AnimatedSize(
        duration: AppMotion.panel,
        alignment: Alignment.topCenter,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InkWell(
              key: CoursePreviewKeys.partHeader(part.number),
              onTap: () => setState(() => _open = !_open),
              child: Padding(
                padding: EdgeInsetsDirectional.fromSTEB(
                  16,
                  14,
                  8,
                  _open ? 6 : 14,
                ),
                child: _header(context),
              ),
            ),
            if (_open) ...[
              for (final chapter in part.chapters)
                SaleSummaryChapter(chapter: chapter),
              SaleOpenings(openings: widget.openings),
            ],
          ],
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final part = widget.part;
    return Row(
      spacing: AppSpacing.md,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.l10n.coursePartLessons(part.number, part.lessons),
                style: theme.textTheme.labelMedium?.copyWith(
                  fontSize: 13,
                  height: 18 / 13,
                  color: colors.primary,
                ),
              ),
              Text(part.title, style: saleStrong(context, size: 17)),
            ],
          ),
        ),
        SizedBox(
          width: 48,
          height: 48,
          child: Icon(
            _open ? Icons.expand_less_rounded : Icons.expand_more_rounded,
            size: AppIconSize.standard,
            color: colors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

/// Um capítulo da parte aberta: "N · Título" em negrito e as linhas
/// numeradas (as lições e, por último, o teste do capítulo) com o número em
/// cinza.
class SaleSummaryChapter extends StatelessWidget {
  const SaleSummaryChapter({required this.chapter, super.key});

  final CourseSaleChapter chapter;

  @override
  Widget build(BuildContext context) {
    final n = chapter.number;
    return _SaleTopBorderBlock(
      key: CoursePreviewKeys.summaryChapter(n),
      children: [
        Text('$n · ${chapter.title}', style: saleStrong(context, size: 15)),
        for (final (j, lesson) in chapter.lessons.indexed)
          _SaleNumberedRow(mark: '$n.${j + 1}', text: lesson),
        _SaleNumberedRow(
          mark: '$n.${chapter.lessons.length + 1}',
          text: context.l10n.venChapterTest(saleChapterTestCount),
        ),
      ],
    );
  }
}

/// As aberturas no fim da parte aberta: título, a linha e os itens com
/// marcador.
class SaleOpenings extends StatelessWidget {
  const SaleOpenings({required this.openings, super.key});

  final ({String title, String line, List<String> items}) openings;

  @override
  Widget build(BuildContext context) => _SaleTopBorderBlock(
    children: [
      Text(openings.title, style: saleStrong(context, size: 15)),
      Text(openings.line, style: saleBody(context)),
      for (final item in openings.items)
        _SaleNumberedRow(mark: '·', text: item),
    ],
  );
}

class _SaleTopBorderBlock extends StatelessWidget {
  const _SaleTopBorderBlock({required this.children, super.key});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      border: Border(
        top: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.md,
        horizontal: AppSpacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 6,
        children: children,
      ),
    ),
  );
}

class _SaleNumberedRow extends StatelessWidget {
  const _SaleNumberedRow({required this.mark, required this.text});

  final String mark;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    spacing: 10,
    children: [
      SizedBox(width: 28, child: Text(mark, style: saleBody(context))),
      Expanded(
        child: Text(
          text,
          style: saleBody(
            context,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ),
    ],
  );
}

/// A aba Dúvidas (FAQ D3): cada pergunta num `ExpansionTile` com o ícone do
/// assunto; a primeira aberta.
class SaleFaq extends StatefulWidget {
  const SaleFaq({required this.items, required this.keyOf, super.key});

  final List<CourseSaleFaq> items;

  /// A key de cada pergunta (a venda e o Sobre o Pilares têm as suas).
  final Key Function(int i) keyOf;

  @override
  State<SaleFaq> createState() => _SaleFaqState();
}

class _SaleFaqState extends State<SaleFaq> {
  final _open = <int>{0};

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.lg),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(AppShape.large),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          child: Column(
            children: [
              for (final (i, item) in widget.items.indexed) ...[
                if (i > 0)
                  Divider(
                    height: 1,
                    thickness: 1,
                    indent: AppSpacing.lg,
                    endIndent: AppSpacing.lg,
                    color: colors.outlineVariant,
                  ),
                ExpansionTile(
                  key: widget.keyOf(i),
                  initiallyExpanded: _open.contains(i),
                  onExpansionChanged: (open) =>
                      setState(() => open ? _open.add(i) : _open.remove(i)),
                  shape: const Border(),
                  collapsedShape: const Border(),
                  minTileHeight: 56,
                  tilePadding: const EdgeInsetsDirectional.only(
                    start: AppSpacing.lg,
                    end: AppSpacing.sm,
                  ),
                  // A resposta recuada até o texto da pergunta (16 + 24 + 16).
                  childrenPadding: const EdgeInsetsDirectional.fromSTEB(
                    56,
                    0,
                    AppSpacing.lg,
                    AppSpacing.lg,
                  ),
                  expandedAlignment: AlignmentDirectional.centerStart,
                  leading: Icon(
                    saleIcon(item.icon),
                    size: AppIconSize.standard,
                    color: _open.contains(i)
                        ? colors.primary
                        : colors.onSurfaceVariant,
                  ),
                  trailing: Icon(
                    _open.contains(i)
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    color: colors.onSurfaceVariant,
                  ),
                  textColor: colors.primary,
                  title: Text(item.question, style: saleStrong(context)),
                  children: [Text(item.answer, style: saleBody(context))],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// As abas grudadas embaixo da barra (abas_venda): 48 de altura, indicador de
/// 3 com 12 de recuo e a linha fina. Visão geral, Conteúdo e Dúvidas.
class SaleTabsHeader extends SliverPersistentHeaderDelegate {
  const SaleTabsHeader({
    required this.controller,
    required this.color,
    required this.keyOf,
  });

  final TabController controller;
  final Color color;
  final Key Function(int i) keyOf;

  static const _height = 48.0 + 1;

  @override
  double get minExtent => _height;

  @override
  double get maxExtent => _height;

  @override
  Widget build(BuildContext context, double shrink, bool overlaps) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        border: Border(bottom: BorderSide(color: colors.outlineVariant)),
      ),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 1),
        child: SizedBox(
          height: 48,
          child: TabBar(
            controller: controller,
            dividerHeight: 0,
            indicatorSize: TabBarIndicatorSize.tab,
            indicator: UnderlineTabIndicator(
              borderSide: BorderSide(width: 3, color: colors.primary),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppShape.tiny),
              ),
              insets: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            ),
            labelColor: colors.primary,
            unselectedLabelColor: colors.onSurfaceVariant,
            labelStyle: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            tabs: [
              for (final (i, label) in [
                l10n.courseSaleOverview,
                l10n.courseSaleContent,
                l10n.courseSaleFaq,
              ].indexed)
                Tab(key: keyOf(i), text: label),
            ],
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(SaleTabsHeader old) =>
      old.controller != controller || old.color != color;
}

/// O cartão "Para quem é" (cartao_faixa): abre a tela da faixa
/// (PropV2CursoFaixa).
class SaleAudienceCard extends StatelessWidget {
  const SaleAudienceCard({required this.item, this.tapKey, super.key});

  final CourseSaleItem item;
  final Key? tapKey;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: colors.primaryContainer,
      borderRadius: BorderRadius.circular(AppShape.large),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: tapKey,
        onTap: () => context.push(D2Paths.pilaresForWhom),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            spacing: AppSpacing.md,
            children: [
              Icon(
                saleIcon(item.icon ?? 'groups'),
                size: AppIconSize.standard,
                color: colors.primary,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 2,
                  children: [
                    Text(item.title, style: saleStrong(context)),
                    if (item.summary case final summary?)
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
    );
  }
}

/// O destaque do teste de nível (destaque_nivel): a pergunta, a frase e o
/// exemplo de cada parte com a pílula.
class SaleLevelCard extends StatelessWidget {
  const SaleLevelCard({required this.item, required this.examples, super.key});

  final CourseSaleItem item;
  final List<({String title, String status, String tone})> examples;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return SaleCard(
      color: colors.primaryContainer,
      spacing: 10,
      children: [
        Row(
          spacing: 10,
          children: [
            Icon(
              saleIcon(item.icon ?? 'insights'),
              size: AppIconSize.standard,
              color: colors.primary,
            ),
            Expanded(
              child: Text(item.title, style: saleStrong(context, size: 17)),
            ),
          ],
        ),
        if (item.summary case final summary?)
          Text(summary, style: saleBody(context, color: colors.onSurface)),
        SaleCard(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 14),
          spacing: 0,
          children: [
            for (final example in examples)
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
    );
  }
}

/// O sumário por parte: cada parte é um acordeão e a primeira vem aberta.
class SaleSummary extends StatelessWidget {
  const SaleSummary({
    required this.parts,
    required this.openings,
    required this.keyOf,
    super.key,
  });

  final List<CourseSalePart> parts;
  final ({String title, String line, List<String> items}) openings;
  final Key Function(int i) keyOf;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    spacing: AppSpacing.sm,
    children: [
      for (final (i, part) in parts.indexed)
        SalePartTile(
          key: keyOf(i),
          part: part,
          initiallyOpen: i == 0,
          openings: openings,
        ),
    ],
  );
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

/// "Quanto custa estudar xadrez por 3 meses" (data-comparativo, H-VEN-01 e
/// H-VEN-14): as linhas
/// de custo, a soma com a barra cheia e o Pilares com a barra do tamanho do
/// preço.
class SaleCostCompare extends StatelessWidget {
  const SaleCostCompare({required this.sale, super.key});

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

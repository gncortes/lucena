import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/models/character.dart';
import '../../../domain/models/course_preview.dart';
import '../../../routing/routes.dart';
import '../../core/keys/course_preview_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_button.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_icon_size.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_shape.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/character_avatar.dart';
import '../../core/widgets/teacher_speech.dart';
import '../view_models/course_preview_cubit.dart';

/// A página de venda do Pilares do Xadrez (canvas `PropV2CursoApresentacao`,
/// `PropV2CursoVendaRecolhida`, `…Conteudo` e `…Duvidas`): a barra que
/// recolhe (o nome aparece no centro quando o topo some), o topo com os
/// números, o preço e o Viktor, as abas fixas que filtram o miolo e o botão
/// "Comprar" fixo embaixo. Prévia: comprar não faz nada.
class CourseSaleScreen extends StatelessWidget {
  const CourseSaleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CoursePreviewCubit, CoursePreviewState>(
      builder: (context, state) {
        final sale = state.preview?.sale;
        if (sale == null) {
          return const Scaffold(key: CoursePreviewKeys.sale);
        }
        return _SalePage(sale: sale, viktor: state.viktor);
      },
    );
  }
}

class _SalePage extends StatefulWidget {
  const _SalePage({required this.sale, required this.viktor});

  final CourseSale sale;
  final Character? viktor;

  @override
  State<_SalePage> createState() => _SalePageState();
}

class _SalePageState extends State<_SalePage>
    with SingleTickerProviderStateMixin {
  late final _tabs = TabController(length: 3, vsync: this)
    ..addListener(_tabChanged);
  final _scroll = ScrollController();
  final _hero = GlobalKey();
  var _collapsed = false;

  /// apresentacao_corpo: 8 de respiro + sobretítulo (20) + 4 + nome (32).
  static const _titleBottom = 64.0;

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

  bool _onScroll(ScrollNotification notification) {
    if (notification.depth != 0) return false;
    final collapsed = notification.metrics.pixels > _titleBottom;
    if (collapsed != _collapsed) setState(() => _collapsed = collapsed);
    return false;
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
                // Prévia: a compra (Play Billing) fica fora da T82.
                onPressed: () {},
                child: Text(l10n.courseBuy(sale.price)),
              ),
            ),
          ),
        ),
      ),
      body: NotificationListener<ScrollNotification>(
        onNotification: _onScroll,
        child: CustomScrollView(
          key: CoursePreviewKeys.saleScroll,
          controller: _scroll,
          slivers: [
            SliverAppBar(
              pinned: true,
              centerTitle: true,
              backgroundColor: page,
              surfaceTintColor: AppColors.clear,
              scrolledUnderElevation: 0,
              // Expandida sem título; recolhida, o nome no centro.
              title: AnimatedOpacity(
                opacity: _collapsed ? 1 : 0,
                duration: AppMotion.state,
                child: Text(sale.title),
              ),
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
                  // abas_venda: indicador de 3 com 12 de recuo (cantos no token de 4).
                  indicator: UnderlineTabIndicator(
                    borderSide: BorderSide(
                      width: 3,
                      color: theme.colorScheme.primary,
                    ),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(AppShape.tiny),
                    ),
                    insets: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                    ),
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
                  _ => _Faq(items: sale.faq),
                },
              ),
            ),
          ],
        ),
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

/// O ícone do item pelo nome do Material Icons que vem do canvas.
IconData _icon(String? name) => switch (name) {
  'warning' => Icons.warning_amber_rounded,
  'trending_flat' => Icons.trending_flat_rounded,
  'help' => Icons.help_outline_rounded,
  'auto_stories' => Icons.auto_stories_outlined,
  'school' => Icons.school_outlined,
  'menu_book' => Icons.menu_book_outlined,
  'emoji_events' => Icons.emoji_events_outlined,
  'record_voice_over' => Icons.record_voice_over_outlined,
  'smart_toy' => Icons.smart_toy_outlined,
  'rule' => Icons.rule_rounded,
  'tune' => Icons.tune_rounded,
  'event_repeat' => Icons.event_repeat_rounded,
  'cloud_off' => Icons.cloud_off_outlined,
  'how_to_reg' => Icons.how_to_reg_outlined,
  'avg_pace' => Icons.timer_outlined,
  'stacked_line_chart' => Icons.stacked_line_chart_rounded,
  'vpn_key' => Icons.vpn_key_outlined,
  'currency_exchange' => Icons.currency_exchange_rounded,
  _ => Icons.circle_outlined,
};

/// O verde de "feito" (#2E6B3A) e o fundo claro dele no canvas (#E2F0E4).
const _green = AppColors.record;
final _greenSoft = AppColors.record.withValues(alpha: 0.12);

TextStyle? _strong(
  BuildContext context, {
  double size = 16,
  double line = 22,
}) => Theme.of(context).textTheme.titleMedium?.copyWith(
  fontSize: size,
  height: line / size,
  fontWeight: AppWeight.strong,
);

TextStyle? _body(BuildContext context, {Color? color}) =>
    Theme.of(context).textTheme.bodyMedium?.copyWith(
      fontSize: 14,
      height: 20 / 14,
      color: color ?? Theme.of(context).colorScheme.onSurfaceVariant,
    );

/// Um cartão branco da página (cartao: 16 de respiro, cantos de 16).
class _Card extends StatelessWidget {
  const _Card({
    required this.children,
    this.spacing = AppSpacing.md,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.color,
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
class _Section extends StatelessWidget {
  const _Section(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: AppSpacing.lg, bottom: AppSpacing.xs),
    child: ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 40),
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: Text(text, style: _strong(context, size: 20, line: 26)),
      ),
    ),
  );
}

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
          sale.overline,
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(sale.title, style: _strong(context, size: 24, line: 32)),
        const SizedBox(height: AppSpacing.xs),
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
        _PriceCard(sale: sale),
        if (viktor != null) ...[
          const SizedBox(height: AppSpacing.md),
          TeacherSpeech(
            teacher: viktor,
            text: sale.speech,
            speechContext: SpeechContext.teaching,
            avatarSize: CharacterAvatar.speech,
          ),
        ],
        _Section(l10n.courseSaleHow),
        _Steps(steps: sale.how),
      ],
    );
  }
}

/// Um número do topo (numeros): o valor grande em azul e o rótulo embaixo.
class _Number extends StatelessWidget {
  const _Number({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: _Card(
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.md,
          horizontal: AppSpacing.sm,
        ),
        spacing: 2,
        children: [
          Text(
            value,
            textAlign: TextAlign.center,
            style: _strong(
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

/// O preço no topo (preco_topo, variante A): cartão azul cheio, o valor em
/// branco e o reembolso embaixo da linha.
class _PriceCard extends StatelessWidget {
  const _PriceCard({required this.sale});

  final CourseSale sale;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final on = theme.colorScheme.onPrimary;
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
              l10n.courseSalePrice,
              style: theme.textTheme.labelMedium?.copyWith(
                fontSize: 13,
                height: 18 / 13,
                fontWeight: FontWeight.w600,
                color: on.withValues(alpha: 0.8),
              ),
            ),
            Text(
              sale.price,
              style: _strong(context, size: 32, line: 38)?.copyWith(color: on),
            ),
            Text(
              sale.priceNote,
              style: _body(context, color: on.withValues(alpha: 0.87)),
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
                      Icon(
                        Icons.verified_user_outlined,
                        size: AppIconSize.button,
                        color: AppColors.goalWinBg,
                      ),
                      Expanded(
                        child: Text(
                          l10n.courseSaleRefund,
                          style: _body(context, color: on),
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

/// "Como você aprende" (ciclo): os passos ligados por uma linha vertical.
class _Steps extends StatelessWidget {
  const _Steps({required this.steps});

  final List<CourseSaleItem> steps;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return _Card(
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
                          style: _strong(
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
                        Text(step.title, style: _strong(context)),
                        if (step.summary != null)
                          Text(step.summary!, style: _body(context)),
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
class _IconLine extends StatelessWidget {
  const _IconLine({required this.item, this.green = false});

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
            color: green ? _greenSoft : colors.primaryContainer,
            shape: BoxShape.circle,
          ),
          child: Icon(
            _icon(item.icon),
            size: AppIconSize.standard,
            color: green ? _green : colors.primary,
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 2,
            children: [
              Text(item.title, style: _strong(context)),
              if (summary != null) Text(summary, style: _body(context)),
            ],
          ),
        ),
      ],
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
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Section(l10n.courseSaleLearn),
        // lista_check: check verde, título e frase, 14 entre os itens.
        _Card(
          spacing: 14,
          children: [
            for (final item in sale.learn)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: AppSpacing.md,
                children: [
                  Icon(
                    Icons.check_circle,
                    size: AppIconSize.standard,
                    color: _green,
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 2,
                      children: [
                        Text(item.title, style: _strong(context)),
                        if (item.summary != null)
                          Text(item.summary!, style: _body(context)),
                      ],
                    ),
                  ),
                ],
              ),
          ],
        ),
        _Section(l10n.courseSaleAudience),
        // cartao_faixa: sem destino na prévia (a tela da faixa fica fora).
        _Card(
          color: colors.primaryContainer,
          children: [
            Row(
              spacing: AppSpacing.md,
              children: [
                Icon(
                  Icons.groups_outlined,
                  size: AppIconSize.standard,
                  color: colors.primary,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 2,
                    children: [
                      Text(sale.audience.title, style: _strong(context)),
                      if (sale.audience.summary != null)
                        Text(
                          sale.audience.summary!,
                          style: _body(context, color: colors.onSurface),
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
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        _Card(
          children: [
            for (final item in sale.audienceItems) _IconLine(item: item),
          ],
        ),
        _Section(l10n.courseSaleIncluded),
        // card_recursos: o que vem no curso (azul), a linha e o que o app faz
        // no treino (verde).
        _Card(
          spacing: AppSpacing.lg,
          children: [
            for (final item in sale.included) _IconLine(item: item),
            Divider(height: 1, thickness: 1, color: colors.outlineVariant),
            for (final item in sale.app) _IconLine(item: item, green: true),
          ],
        ),
      ],
    );
  }
}

/// A aba Conteúdo: o atalho dos exercícios (teste de nível) e o sumário.
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
        _Card(
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
                    style: _strong(context, size: 17),
                  ),
                ),
              ],
            ),
            if (sale.level.summary != null)
              Text(
                sale.level.summary!,
                style: _body(context, color: colors.onSurface),
              ),
            _Card(
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
                        _Pill(text: example.status, tone: example.tone),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
        _Section(l10n.courseSaleSummary),
        Text(sale.summaryNote, style: _body(context)),
        const SizedBox(height: AppSpacing.md),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: AppSpacing.sm,
          children: [
            for (final (i, part) in sale.parts.indexed)
              _PartTile(key: CoursePreviewKeys.part(i), part: part),
          ],
        ),
      ],
    );
  }
}

/// A situação do exemplo do teste de nível.
class _Pill extends StatelessWidget {
  const _Pill({required this.text, required this.tone});

  final String text;
  final String tone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final (foreground, background) = switch (tone) {
      'mastered' => (_green, _greenSoft),
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

/// Uma parte do sumário, fechada (parte_fechada). Na prévia, tocar abre o
/// mapa (a Parte I com os capítulos).
class _PartTile extends StatelessWidget {
  const _PartTile({required this.part, super.key});

  final CourseSalePart part;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Material(
      color: colors.surfaceContainerLow,
      borderRadius: BorderRadius.circular(AppShape.large),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push(Routes.pilaresMap),
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(16, 14, 8, 14),
          child: Row(
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
                    Text(part.title, style: _strong(context, size: 17)),
                  ],
                ),
              ),
              SizedBox(
                width: 48,
                height: 48,
                child: Icon(
                  Icons.expand_more_rounded,
                  size: AppIconSize.standard,
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

/// A aba Dúvidas (FAQ D3): cada pergunta num `ExpansionTile` com o ícone do
/// assunto; a primeira aberta.
class _Faq extends StatefulWidget {
  const _Faq({required this.items});

  final List<CourseSaleFaq> items;

  @override
  State<_Faq> createState() => _FaqState();
}

class _FaqState extends State<_Faq> {
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
                  key: CoursePreviewKeys.faq(i),
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
                    _icon(item.icon),
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
                  title: Text(item.question, style: _strong(context)),
                  children: [Text(item.answer, style: _body(context))],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

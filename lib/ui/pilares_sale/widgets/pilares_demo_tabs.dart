import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/models/analytics_event.dart';
import '../../../domain/models/training/training_course.dart';
import '../../../routing/frentes/d2_routes.dart';
import '../../../routing/route_names.dart';
import '../../core/analytics/analytics_context.dart';
import '../../core/keys/purchase_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/motion/cartao_pressionavel.dart';
import '../../core/motion/rota_que_abre.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_icon_size.dart';
import '../../core/theme/app_shape.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/actions_footer.dart';
import '../../core/widgets/busy_button.dart';
import '../../lesson_ad/widgets/lesson_entry.dart';
import 'pilares_sale_parts.dart';

/// A demonstração do Pilares nas abas do curso (H-VEN-11 e H-VEN-12): quem
/// só tem o Capítulo 1 vê o Catálogo da demo, o Guia de exemplo, as Metas
/// com cadeado e uma chamada no fim das Estatísticas. O comprador vê as
/// abas reais da Treino, sem nada disto.
abstract final class PilaresDemo {
  /// O curso [course] está na demonstração para quem está no contexto?
  static bool isActive(BuildContext context, TrainingCourse course) =>
      course == TrainingCourse.pilares &&
      LessonEntry.isLocked(context, 'pilares.c2');

  /// O toque numa meta trancada: a folha "Metas fazem parte do Pilares";
  /// "Conhecer o Pilares" abre a apresentação, "Agora não" só fecha.
  static Future<void> openLockedGoal(BuildContext context) async {
    final l10n = context.l10n;
    final learn = await LessonEntry.showLockedFeature(
      context,
      title: l10n.venDemoGoalsLockTitle,
      body: l10n.venDemoGoalsLockText,
      primary: l10n.licaoAdLearnMore,
      sheetKey: PurchaseKeys.demoGoalsLockSheet,
      primaryKey: PurchaseKeys.demoGoalsLockSheetLearn,
      laterKey: PurchaseKeys.demoGoalsLockSheetLater,
    );
    if (learn && context.mounted) _presentation(context, 'metas');
  }

  static void _presentation(BuildContext context, String origin) =>
      context.pushNamed(
        RouteNames.pilaresPresentation,
        queryParameters: {'origem': origin},
      );
}

/// A chamada no fim de cada aba da demo: o texto do que o Pilares traz e o
/// botão "Conhecer o Pilares", que abre a apresentação. Ao aparecer, conta a
/// oferta vista com a [origin] e o [highlight] da aba.
class PilaresDemoCallout extends StatefulWidget {
  const PilaresDemoCallout({
    required this.text,
    required this.buttonKey,
    required this.origin,
    this.highlight,
    super.key,
  });

  final String text;
  final Key buttonKey;
  final String origin;

  /// O `destaque` do `pilares_oferta_vista`; sem ele, a chamada não conta
  /// a oferta (o Catálogo da demo, que já conta pelo cartão do topo).
  final String? highlight;

  @override
  State<PilaresDemoCallout> createState() => _PilaresDemoCalloutState();
}

class _PilaresDemoCalloutState extends State<PilaresDemoCallout> {
  @override
  void initState() {
    super.initState();
    if (widget.highlight case final highlight?) {
      context.analytics.log(
        AnalyticsEvents.pilaresOfertaVista(
          origem: widget.origin,
          destaque: highlight,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // H-ANI-04: a apresentação (`/pilares`) cresce deste cartão.
    return OrigemQueAbre(id: pilaresSaleOrigin, child: _card(context, theme));
  }

  Widget _card(BuildContext context, ThemeData theme) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(AppShape.large),
        border: Border.all(color: AppColors.cardOutline),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: AppSpacing.md,
          children: [
            Text(
              widget.text,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: 14,
                height: 20 / 14,
                letterSpacing: 0,
                color: theme.colorScheme.onSurface,
              ),
            ),
            BusyButton(
              buttonKey: widget.buttonKey,
              label: context.l10n.licaoAdLearnMore,
              style: BusyButtonStyle.outlined,
              onPressed: () =>
                  PilaresDemo._presentation(context, widget.origin),
            ),
          ],
        ),
      ),
    );
  }
}

/// O fim das Metas da demo (quadros `PropV2MetaSemCompraCompra` e
/// `PropV2MetaSemCompraDemoCadeado`).
class PilaresDemoGoalsCallout extends StatelessWidget {
  const PilaresDemoGoalsCallout({super.key});

  @override
  Widget build(BuildContext context) => PilaresDemoCallout(
    text: context.l10n.venDemoGoalsClosing,
    buttonKey: PurchaseKeys.demoGoalsLearnMore,
    origin: 'metas',
    highlight: 'meta_capitulo_1',
  );
}

/// O fim das Estatísticas da demo (quadro `PropV1TreinoProgressoDemoCompra`).
class PilaresDemoStatsCallout extends StatelessWidget {
  const PilaresDemoStatsCallout({super.key});

  @override
  Widget build(BuildContext context) => PilaresDemoCallout(
    text: context.l10n.venDemoStatsClosing,
    buttonKey: PurchaseKeys.demoStatsLearnMore,
    origin: 'estatisticas',
    highlight: 'dominio',
  );
}

/// O Guia da demo (H-VEN-12, quadro `PropV2DestinoSemCompraCompra`): o
/// plano até o torneio num exemplo fixo, com selo "Exemplo" e 6 semanas.
/// As linhas são ilustrativas (não são dados do aluno). Cada linha e o
/// rodapé "Conhecer o plano" abrem a venda do plano.
class PilaresDemoGuide extends StatelessWidget {
  const PilaresDemoGuide({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    void plan() => context.push(D2Paths.plan(origin: 'destino'));
    final weeks = [
      l10n.venDemoGuideWeek1,
      l10n.venDemoGuideWeek2,
      l10n.venDemoGuideWeek3,
      l10n.venDemoGuideWeek4,
      l10n.venDemoGuideWeek5,
      l10n.venDemoGuideWeek6,
    ];
    final body = theme.textTheme.bodyMedium?.copyWith(
      fontSize: 14,
      height: 20 / 14,
      letterSpacing: 0,
      color: colors.onSurface,
    );
    return Column(
      key: PurchaseKeys.demoGuide,
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              AppSpacing.lg,
            ),
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.primaryContainer,
                  borderRadius: BorderRadius.circular(AppShape.card),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: AppSpacing.sm,
                    children: [
                      Icon(
                        Icons.stadium,
                        size: AppIconSize.standard,
                        color: colors.primary,
                      ),
                      Text(
                        l10n.venDemoGuideTitle,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontSize: 20,
                          height: 28 / 20,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(l10n.venDemoGuideText, style: body),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(4, AppSpacing.lg, 4, 0),
                child: Row(
                  spacing: AppSpacing.sm,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.venDemoGuideEvent,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontSize: 16,
                              height: 24 / 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            l10n.venDemoGuideDate,
                            style: body?.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    PilaresBadge(
                      text: l10n.venDemoGuideExample,
                      background: colors.surfaceContainerHighest,
                      foreground: colors.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              // H-ANI-20: toda linha leva ao plano; o cartão inteiro afunda.
              CartaoPressionavel(
                child: DecoratedBox(
                  key: PurchaseKeys.demoGuideWeeks,
                  decoration: BoxDecoration(
                    color: AppColors.cardSurface,
                    borderRadius: BorderRadius.circular(AppShape.card),
                    border: Border.all(color: AppColors.cardOutline),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      children: [
                        for (final (index, text) in weeks.indexed)
                          _WeekRow(
                            number: index + 1,
                            label: l10n.venDemoGuideWeek(index + 1),
                            text: text,
                            onTap: plan,
                          ),
                        _WeekRow(
                          text: l10n.venDemoGuideEnd(
                            l10n.venDemoGuideDate,
                            l10n.venDemoGuideEvent,
                          ),
                          onTap: plan,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              PilaresDemoCallout(
                text: l10n.venDemoGuideClosing,
                buttonKey: PurchaseKeys.demoGuideLearnMore,
                origin: 'destino',
                highlight: 'plano_exemplo',
              ),
            ],
          ),
        ),
        ActionsFooter(
          children: [
            BusyButton(
              buttonKey: PurchaseKeys.demoGuidePlan,
              label: l10n.venDemoGuidePlan,
              onPressed: plan,
            ),
          ],
        ),
      ],
    );
  }
}

/// Uma semana na linha do tempo: o trilho de 28 com o número (ou o estádio,
/// na última linha) e a ligação, e o texto "Semana N" sobre o capítulo.
class _WeekRow extends StatelessWidget {
  const _WeekRow({
    required this.text,
    required this.onTap,
    this.number,
    this.label,
  });

  final int? number;
  final String? label;
  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final last = number == null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppShape.medium),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: 28,
              child: Column(
                children: [
                  const SizedBox(height: AppSpacing.sm),
                  Container(
                    width: 24,
                    height: 24,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: last
                          ? colors.primaryContainer
                          : colors.outlineVariant,
                    ),
                    child: last
                        ? Icon(
                            Icons.stadium,
                            size: AppIconSize.compact,
                            color: colors.primary,
                          )
                        : Text(
                            '$number',
                            style: theme.textTheme.labelLarge?.copyWith(
                              fontSize: 14,
                              height: 20 / 14,
                              fontWeight: FontWeight.w500,
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                  ),
                  if (!last)
                    Expanded(
                      child: Container(width: 2, color: colors.outlineVariant),
                    ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 4,
                  horizontal: AppSpacing.md,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (label case final label?)
                        Text(
                          label,
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontSize: 12,
                            height: 16 / 12,
                            fontWeight: FontWeight.w400,
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      Text(
                        text,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontSize: 14,
                          height: 20 / 14,
                          letterSpacing: 0,
                          fontWeight: last ? FontWeight.w500 : null,
                          color: colors.onSurface,
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

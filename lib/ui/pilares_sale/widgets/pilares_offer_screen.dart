import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../domain/models/offer_discount.dart';
import '../../../domain/models/pilares_access.dart';
import '../../../routing/frentes/d2_routes.dart';
import '../../../routing/routes.dart';
import '../../core/keys/purchase_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/motion/aviso_que_abre.dart';
import '../../core/motion/cartao_de_plano.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_icon_size.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_shape.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/canvas_symbols.dart';
import '../../core/widgets/actions_footer.dart';
import '../../core/widgets/busy_button.dart';
import '../../core/widgets/lucena_app_bar.dart';
import '../../core/widgets/lucena_snack_bar.dart';
import '../view_models/pilares_offer_cubit.dart';
import 'pilares_sale_parts.dart';

/// A oferta do Pilares (H-VEN-03): o que o curso traz, os dois planos e o
/// botão que acompanha o plano marcado. Os fins da compra que não terminou
/// (H-VEN-06) aparecem aqui: aviso no topo, snackbar ou a tela Pendente.
class PilaresOfferScreen extends StatelessWidget {
  const PilaresOfferScreen({super.key});

  void _back(BuildContext context) {
    context.read<PilaresOfferCubit>().leave();
    context.canPop() ? context.pop() : context.go(Routes.home);
  }

  Future<void> _buy(BuildContext context) async {
    final cubit = context.read<PilaresOfferCubit>();
    final step = await cubit.buy();
    if (step != OfferBuyStep.needsAccount || !context.mounted) return;
    // A compra é da conta (H-CON-05): ela volta para esta oferta, com o
    // mesmo plano marcado.
    final from = D2Paths.offer(plan: cubit.state.plan);
    unawaited(context.push(Routes.accountEnterFrom(from)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final state = context.watch<PilaresOfferCubit>().state;
    final lifetimePrice =
        state.priceOf(PilaresPlan.lifetime) ?? l10n.venRefLifetime;
    final monthlyPrice =
        state.priceOf(PilaresPlan.monthly) ?? l10n.venRefMonthly;
    final locked = state.processing;
    final monthly = state.plan == PilaresPlan.monthly;
    // O desconto só aparece com o preço da loja (regras 2 e 10).
    final discount = state.discount;
    final buyLifetimePrice = discount?.price ?? lifetimePrice;
    return BlocListener<PilaresOfferCubit, PilaresOfferState>(
      listenWhen: (a, b) => a.signalId != b.signalId,
      listener: (context, state) {
        switch (state.signal) {
          case OfferSignal.canceled:
            showLucenaSnackBar(
              context,
              l10n.venCanceled,
              key: PurchaseKeys.canceled,
            );
          case OfferSignal.pending:
            context.pushReplacement(D2Paths.pilaresPurchasePending);
          case null:
            break;
        }
      },
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop && !locked) _back(context);
        },
        child: Scaffold(
          key: PurchaseKeys.offerScreen,
          appBar: LucenaAppBar(
            leading: BackButton(
              onPressed: locked ? null : () => _back(context),
            ),
            title: Text(l10n.venOfferBar),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              AppSpacing.xl,
            ),
            children: [
              Text(l10n.venOfferHeadline, style: theme.textTheme.headlineSmall),
              const SizedBox(height: AppSpacing.sm),
              // Com aviso (PropV2CompraErro, PropV2CompraSemInternet), ele toma
              // o lugar da introdução: erro em vermelho, sem rede em amarelo.
              _OfferNotice(banner: state.banner),
              const SizedBox(height: AppSpacing.xl),
              const _OfferBenefits(),
              const SizedBox(height: AppSpacing.xl),
              // O link guardado não vale mais (PropV2OfertaLinkSemValer): o
              // aviso acima das opções, uma vez, com o preço cheio.
              if (state.linkGone) ...[
                const _LinkGoneNotice(),
                const SizedBox(height: AppSpacing.sm),
              ],
              Text(
                l10n.venOfferChoose,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              _PlanoDaOferta(
                key: PurchaseKeys.planLifetime,
                title: l10n.venPlanLifetime,
                badge: l10n.venPlanBest,
                badgeKey: PurchaseKeys.planBest,
                text: l10n.venPlanLifetimeText,
                price: l10n.venPlanLifetimePrice(lifetimePrice),
                discount: discount,
                loading: state.loadingPrices,
                selected: !monthly,
                onTap: locked
                    ? null
                    : () => context.read<PilaresOfferCubit>().select(
                        PilaresPlan.lifetime,
                      ),
              ),
              const SizedBox(height: AppSpacing.md),
              _PlanoDaOferta(
                key: PurchaseKeys.planMonthly,
                title: l10n.venPlanMonthly,
                text: l10n.venPlanMonthlyText,
                price: l10n.venPerMonth(monthlyPrice),
                loading: state.loadingPrices,
                selected: monthly,
                onTap: locked
                    ? null
                    : () => context.read<PilaresOfferCubit>().select(
                        PilaresPlan.monthly,
                      ),
              ),
              if (monthly) ...[
                const SizedBox(height: AppSpacing.md),
                const _SubscriptionInfo(),
              ],
            ],
          ),
          bottomNavigationBar: _OfferFooter(
            state: state,
            monthlyPrice: monthlyPrice,
            buyLifetimePrice: buyLifetimePrice,
            onBuy: () => _buy(context),
          ),
        ),
      ),
    );
  }
}

/// O plano da oferta (H-VEN-03) no [CartaoDePlano]: a seleção passa de um
/// ao outro em 250 ms (H-ANI-26).
class _PlanoDaOferta extends StatelessWidget {
  const _PlanoDaOferta({
    required this.title,
    required this.text,
    required this.price,
    required this.selected,
    required this.onTap,
    this.badge,
    this.badgeKey,
    this.loading = false,
    this.discount,
    super.key,
  });

  final String title;
  final String text;
  final String price;
  final bool selected;
  final VoidCallback? onTap;
  final String? badge;
  final Key? badgeKey;
  final bool loading;

  /// O desconto (PropV2OfertaPromocao, PropV2OfertaLink): o selo ao lado
  /// do "Melhor escolha", o prazo e o preço cheio riscado.
  final OfferDiscount? discount;

  String _deadline(BuildContext context, OfferDiscount discount) {
    final l10n = context.l10n;
    final name = switch (discount.kind) {
      DiscountKind.link => l10n.venDiscountLink,
      DiscountKind.everyone => discount.name ?? l10n.venDiscountPromo,
    };
    final end = discount.endsAt;
    if (end == null) return name;
    final locale = Localizations.localeOf(context).toLanguageTag();
    return l10n.venDiscountUntil(name, DateFormat('dd/MM', locale).format(end));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final l10n = context.l10n;
    final discount = this.discount;
    return CartaoDePlano(
      selecionado: selected,
      aoTocar: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleMedium),
                if (badge != null || discount != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.xs,
                    children: [
                      if (badge case final badge?)
                        _OfferChip(
                          chipKey: badgeKey,
                          text: badge,
                          background: colors.primaryContainer,
                          foreground: colors.primary,
                        ),
                      if (discount != null)
                        _OfferChip(
                          chipKey: PurchaseKeys.discountBadge,
                          text: l10n.venDiscountPercent(discount.percent),
                          background: AppColors.successSurface,
                          foreground: AppColors.successOnSurface,
                          weight: FontWeight.w600,
                        ),
                    ],
                  ),
                ],
                const SizedBox(height: AppSpacing.xs),
                Text(
                  text,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
                if (discount != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    key: PurchaseKeys.discountDeadline,
                    children: [
                      const Icon(
                        Icons.sell,
                        size: 18,
                        color: AppColors.successOnSurface,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Flexible(
                        child: Text(
                          _deadline(context, discount),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppColors.successOnSurface,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          AnimatedOpacity(
            opacity: loading ? 0.3 : 1,
            duration: AppMotion.state,
            child: discount == null
                ? Text(
                    price,
                    textAlign: TextAlign.end,
                    style: theme.textTheme.titleSmall,
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        discount.fullPrice,
                        key: PurchaseKeys.fullPrice,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colors.onSurfaceVariant,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                      Text(
                        discount.price,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: AppColors.successOnSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        l10n.venDiscountOnce,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _OfferChip extends StatelessWidget {
  const _OfferChip({
    required this.chipKey,
    required this.text,
    required this.background,
    required this.foreground,
    this.weight,
  });

  final Key? chipKey;
  final String text;
  final Color background;
  final Color foreground;
  final FontWeight? weight;

  @override
  Widget build(BuildContext context) => Container(
    key: chipKey,
    height: 22,
    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
    alignment: Alignment.center,
    decoration: ShapeDecoration(
      color: background,
      shape: const StadiumBorder(),
    ),
    child: Text(
      text,
      style: Theme.of(context).textTheme.labelMedium?.copyWith(
        color: foreground,
        fontSize: 12,
        height: 1,
        fontWeight: weight,
      ),
    ),
  );
}

/// Com aviso (PropV2CompraErro, PropV2CompraSemInternet), ele toma o lugar da
/// introdução: erro em vermelho, sem rede em amarelo.
class _OfferNotice extends StatelessWidget {
  const _OfferNotice({required this.banner});

  final OfferBanner? banner;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final banner = this.banner;
    return banner != null
        ? AvisoQueAbre(
            key: banner == OfferBanner.error
                ? PurchaseKeys.errorBanner
                : PurchaseKeys.offlineBanner,
            decoracao: BoxDecoration(
              color: banner == OfferBanner.error
                  ? AppColors.errorSurface
                  : AppColors.waitingSurface,
              borderRadius: BorderRadius.circular(AppShape.large),
            ),
            icone: Icon(
              banner == OfferBanner.error
                  ? CanvasSymbols.error
                  : CanvasSymbols.cloudOff,
              size: AppIconSize.standard,
              color: banner == OfferBanner.error
                  ? colors.error
                  : AppColors.waitingOnSurface,
            ),
            child: Text(
              banner == OfferBanner.error
                  ? l10n.venErrorBanner
                  : l10n.venOfflineBanner,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onSurface,
              ),
            ),
          )
        : Text(
            l10n.venOfferIntro,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          );
  }
}

/// O que o Pilares traz: os seis benefícios.
class _OfferBenefits extends StatelessWidget {
  const _OfferBenefits();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return PilaresBenefitSection(
      label: l10n.venOfferTake,
      items: [
        (Icons.school, l10n.venBenefitChapters, l10n.venBenefitChaptersText),
        (
          Icons.extension,
          l10n.venBenefitExercises,
          l10n.venBenefitExercisesText,
        ),
        (Icons.quiz, l10n.venBenefitLevel, l10n.venBenefitLevelText),
        (
          Icons.edit_calendar,
          l10n.venBenefitTournament,
          l10n.venBenefitTournamentText,
        ),
        (Icons.task_alt, l10n.venBenefitGoals, l10n.venBenefitGoalsText),
        (Icons.insights, l10n.venBenefitProgress, l10n.venBenefitProgressText),
      ],
    );
  }
}

/// O link guardado não vale mais (PropV2OfertaLinkSemValer): o aviso acima das
/// opções, uma vez, com o preço cheio.
class _LinkGoneNotice extends StatelessWidget {
  const _LinkGoneNotice();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Container(
      key: PurchaseKeys.linkGone,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppShape.large),
      ),
      child: Row(
        children: [
          Icon(
            CanvasSymbols.info,
            size: AppIconSize.standard,
            color: colors.onSurfaceVariant,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              l10n.venLinkGone,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// O botão que acompanha o plano marcado e o "Restaurar compra".
class _OfferFooter extends StatelessWidget {
  const _OfferFooter({
    required this.state,
    required this.monthlyPrice,
    required this.buyLifetimePrice,
    required this.onBuy,
  });

  final PilaresOfferState state;
  final String monthlyPrice;
  final String buyLifetimePrice;
  final VoidCallback onBuy;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locked = state.processing;
    final monthly = state.plan == PilaresPlan.monthly;
    return ActionsFooter(
      stacked: true,
      children: [
        BusyButton(
          buttonKey: PurchaseKeys.buy,
          busy: locked,
          icon: state.banner == null ? null : Icons.refresh,
          label: locked
              ? l10n.venProcessing
              : state.banner != null
              ? l10n.loadErrorRetry
              : monthly
              ? l10n.venBuyMonthly(monthlyPrice)
              : l10n.venBuyLifetime(buyLifetimePrice),
          onPressed: state.loadingPrices || state.pending ? null : onBuy,
        ),
        TextButton.icon(
          key: PurchaseKeys.restore,
          onPressed: locked
              ? null
              : () => unawaited(
                  context.push(
                    context.read<PilaresOfferCubit>().needsAccount
                        ? Routes.accountEnterFrom(D2Paths.pilaresRestore)
                        : D2Paths.pilaresRestore,
                  ),
                ),
          icon: const Icon(Icons.history),
          label: Text(l10n.venRestore),
        ),
      ],
    );
  }
}

/// As regras da assinatura mensal, abaixo do plano marcado.
class _SubscriptionInfo extends StatelessWidget {
  const _SubscriptionInfo();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return PilaresInfoCard(
      key: PurchaseKeys.subscriptionInfo,
      title: l10n.venSubscriptionInfo,
      lines: [
        l10n.venSubscriptionRenew,
        l10n.venSubscriptionCancel,
        l10n.venSubscriptionEnd,
        l10n.venSubscriptionRefund,
      ],
    );
  }
}

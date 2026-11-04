import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

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
              if (state.banner case final banner?) ...[
                AvisoQueAbre(
                  key: banner == OfferBanner.error
                      ? PurchaseKeys.errorBanner
                      : PurchaseKeys.offlineBanner,
                  decoracao: BoxDecoration(
                    color: AppColors.errorSurface,
                    borderRadius: BorderRadius.circular(AppShape.large),
                  ),
                  icone: Icon(
                    banner == OfferBanner.error
                        ? CanvasSymbols.error
                        : CanvasSymbols.wifiOff,
                    size: AppIconSize.standard,
                    color: colors.error,
                  ),
                  child: Text(
                    banner == OfferBanner.error
                        ? l10n.venErrorBanner
                        : l10n.venOfflineBanner,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colors.onSurface,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
              Text(l10n.venOfferHeadline, style: theme.textTheme.headlineSmall),
              const SizedBox(height: AppSpacing.sm),
              Text(
                l10n.venOfferIntro,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              PilaresBenefitSection(
                label: l10n.venOfferTake,
                items: [
                  (
                    Icons.school,
                    l10n.venBenefitChapters,
                    l10n.venBenefitChaptersText,
                  ),
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
                  (
                    Icons.task_alt,
                    l10n.venBenefitGoals,
                    l10n.venBenefitGoalsText,
                  ),
                  (
                    Icons.insights,
                    l10n.venBenefitProgress,
                    l10n.venBenefitProgressText,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
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
                PilaresInfoCard(
                  key: PurchaseKeys.subscriptionInfo,
                  title: l10n.venSubscriptionInfo,
                  lines: [
                    l10n.venSubscriptionRenew,
                    l10n.venSubscriptionCancel,
                    l10n.venSubscriptionEnd,
                    l10n.venSubscriptionRefund,
                  ],
                ),
              ],
            ],
          ),
          bottomNavigationBar: ActionsFooter(
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
                    : l10n.venBuyLifetime(lifetimePrice),
                onPressed: state.loadingPrices || state.pending
                    ? null
                    : () => _buy(context),
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
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
                if (badge case final badge?) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Container(
                    key: badgeKey,
                    height: 22,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                    ),
                    alignment: Alignment.center,
                    decoration: ShapeDecoration(
                      color: colors.primaryContainer,
                      shape: const StadiumBorder(),
                    ),
                    child: Text(
                      badge,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: colors.primary,
                        fontSize: 12,
                        height: 1,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.xs),
                Text(
                  text,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          AnimatedOpacity(
            opacity: loading ? 0.3 : 1,
            duration: AppMotion.state,
            child: Text(
              price,
              textAlign: TextAlign.end,
              style: theme.textTheme.titleSmall,
            ),
          ),
        ],
      ),
    );
  }
}

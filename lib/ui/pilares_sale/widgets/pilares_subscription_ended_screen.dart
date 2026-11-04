import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/models/pilares_access.dart';
import '../../../routing/frentes/d2_routes.dart';
import '../../../routing/routes.dart';
import '../../core/keys/purchase_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/actions_footer.dart';
import '../../core/widgets/busy_button.dart';
import '../../core/widgets/lucena_app_bar.dart';
import '../view_models/pilares_prices_cubit.dart';
import 'pilares_sale_parts.dart';

/// "Sua assinatura terminou" (H-VEN-10): o que continua e o que fica em
/// pausa. Os botões abrem a oferta com o plano já escolhido.
class PilaresSubscriptionEndedScreen extends StatelessWidget {
  const PilaresSubscriptionEndedScreen({super.key});

  void _back(BuildContext context) =>
      context.canPop() ? context.pop() : context.go(Routes.home);

  void _offer(BuildContext context, PilaresPlan plan) =>
      context.pushReplacement(D2Paths.offer(plan: plan, origin: 'encerrada'));

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final prices = context.watch<PilaresPricesCubit>().state;
    final monthly = prices[PilaresPlan.monthly] ?? l10n.venRefMonthly;
    final lifetime = prices[PilaresPlan.lifetime] ?? l10n.venRefLifetime;
    return Scaffold(
      key: PurchaseKeys.endedScreen,
      appBar: LucenaAppBar(
        leading: BackButton(onPressed: () => _back(context)),
        title: Text(l10n.venEndedBar),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        children: [
          Text(l10n.venEndedTitle, style: theme.textTheme.headlineSmall),
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.venEndedText,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          PilaresBenefitSection(
            label: l10n.venEndedKeep,
            items: [
              (
                Icons.insights,
                l10n.venEndedProgress,
                l10n.venEndedProgressText,
              ),
              (
                Icons.lock_open,
                l10n.venEndedChapter1,
                l10n.venEndedChapter1Text,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          PilaresBenefitSection(
            label: l10n.venEndedPaused,
            items: [
              (Icons.lock, l10n.venEndedChapters, l10n.venEndedChaptersText),
              (Icons.pause_circle, l10n.venEndedPlan, l10n.venEndedPlanText),
            ],
          ),
        ],
      ),
      bottomNavigationBar: ActionsFooter(
        stacked: true,
        children: [
          BusyButton(
            buttonKey: PurchaseKeys.endedRenew,
            label: l10n.venEndedRenew(monthly),
            onPressed: () => _offer(context, PilaresPlan.monthly),
          ),
          BusyButton(
            buttonKey: PurchaseKeys.endedLifetime,
            style: BusyButtonStyle.outlined,
            label: l10n.venEndedLifetime(lifetime),
            onPressed: () => _offer(context, PilaresPlan.lifetime),
          ),
        ],
      ),
    );
  }
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../routing/frentes/d2_routes.dart';
import '../../../routing/routes.dart';
import '../../core/keys/purchase_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_shape.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/canvas_symbols.dart';
import '../../core/widgets/actions_footer.dart';
import '../../core/widgets/busy_button.dart';
import '../../core/widgets/load_error.dart';
import '../../core/widgets/lucena_app_bar.dart';
import '../view_models/pilares_restore_cubit.dart';
import 'pilares_purchase_result_screens.dart';
import 'pilares_sale_parts.dart';

/// Restaurar compra (H-VEN-08): procura na conta; achou vira "Compra
/// restaurada", não achou mostra o aviso e "Entrar com outra conta".
class PilaresRestoreScreen extends StatelessWidget {
  const PilaresRestoreScreen({super.key});

  void _back(BuildContext context) =>
      context.canPop() ? context.pop() : context.go(D2Paths.offer());

  @override
  Widget build(BuildContext context) {
    final state = context.watch<PilaresRestoreCubit>().state;
    final cubit = context.read<PilaresRestoreCubit>();
    return switch (state.step) {
      RestoreStep.found => PilaresRestoredView(site: state.site),
      RestoreStep.offline || RestoreStep.error => LoadErrorScreen(
        kind: state.step == RestoreStep.offline
            ? LoadErrorKind.offline
            : LoadErrorKind.generic,
        onAction: () => unawaited(cubit.search()),
        onBack: cubit.reset,
      ),
      _ => _RestoreView(state: state, onBack: () => _back(context)),
    };
  }
}

class _RestoreView extends StatelessWidget {
  const _RestoreView({required this.state, required this.onBack});

  final PilaresRestoreState state;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final cubit = context.read<PilaresRestoreCubit>();
    final notFound = state.step == RestoreStep.notFound;
    return PopScope(
      canPop: !state.searching,
      child: Scaffold(
        key: PurchaseKeys.restoreScreen,
        appBar: LucenaAppBar(
          leading: BackButton(onPressed: state.searching ? null : onBack),
          title: Text(l10n.venRestore),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          children: [
            Text(
              l10n.venRestoreText(state.email ?? ''),
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.cardSurface,
                borderRadius: BorderRadius.circular(AppShape.card),
                border: Border.all(color: AppColors.cardOutline),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Row(
                  children: [
                    Icon(Icons.account_circle, color: colors.primary),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.venRestoreAccount,
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                          Text(
                            state.email ?? '',
                            key: PurchaseKeys.restoreEmail,
                            style: theme.textTheme.bodyLarge,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (notFound) ...[
              const SizedBox(height: AppSpacing.lg),
              PilaresNotice(
                key: PurchaseKeys.restoreNotFound,
                icon: CanvasSymbols.info,
                text: l10n.venNotFound,
              ),
            ],
          ],
        ),
        bottomNavigationBar: ActionsFooter(
          stacked: true,
          children: notFound
              ? [
                  BusyButton(
                    buttonKey: PurchaseKeys.restoreOtherAccount,
                    label: l10n.venOtherAccount,
                    onPressed: () => unawaited(
                      context.push(D2Paths.pilaresRestoreSite, extra: cubit),
                    ),
                  ),
                  BusyButton(
                    buttonKey: PurchaseKeys.restoreSeeFull,
                    style: BusyButtonStyle.text,
                    label: l10n.venSeeFull,
                    onPressed: () => context.canPop()
                        ? context.pop()
                        : context.go(D2Paths.offer()),
                  ),
                ]
              : [
                  BusyButton(
                    buttonKey: PurchaseKeys.restoreSearch,
                    label: l10n.venRestoreSearch,
                    busy: state.searching,
                    onPressed: cubit.search,
                  ),
                ],
        ),
      ),
    );
  }
}

/// "Compra restaurada" (H-VEN-08), do aparelho ou do site.
class PilaresRestoredView extends StatelessWidget {
  const PilaresRestoredView({required this.site, super.key});

  final bool site;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return KeyedSubtree(
      key: PurchaseKeys.restoredScreen,
      child: PilaresResultScreen(
        icon: CanvasSymbols.check,
        title: l10n.venRestoredTitle,
        text: site ? l10n.venRestoredSite : l10n.venRestoredText,
        textKey: PurchaseKeys.restoredText,
        onBack: () => context.go(Routes.home),
        actions: pilaresOwnedActions(
          context,
          goalFirst: false,
          goalKey: PurchaseKeys.restoredGoal,
          otherKey: PurchaseKeys.restoredContinue,
          other: l10n.venContinueCourse,
        ),
      ),
    );
  }
}

/// "Comprou pelo site?" (H-VEN-08): entra com a conta da compra e procura
/// de novo. Usa o mesmo view model da tela Restaurar.
class PilaresRestoreSiteScreen extends StatelessWidget {
  const PilaresRestoreSiteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final cubit = context.read<PilaresRestoreCubit>();
    final state = context.watch<PilaresRestoreCubit>().state;
    if (state.step == RestoreStep.found) {
      return PilaresRestoredView(site: state.site);
    }
    return Scaffold(
      key: PurchaseKeys.siteScreen,
      appBar: LucenaAppBar(title: Text(l10n.venSiteBar)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        children: [
          Text(l10n.venSiteTitle, style: theme.textTheme.headlineSmall),
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.venSiteText,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (state.step == RestoreStep.notFound) ...[
            const SizedBox(height: AppSpacing.lg),
            PilaresNotice(icon: CanvasSymbols.info, text: l10n.venNotFound),
          ],
          const SizedBox(height: AppSpacing.xl),
          BusyButton(
            buttonKey: PurchaseKeys.siteGoogle,
            style: BusyButtonStyle.outlined,
            label: l10n.venSiteGoogle,
            busy: state.searching,
            onPressed: cubit.signInWithGoogle,
          ),
          const SizedBox(height: AppSpacing.md),
          BusyButton(
            buttonKey: PurchaseKeys.siteEmail,
            style: BusyButtonStyle.outlined,
            icon: Icons.mail_outline,
            label: l10n.venSiteEmail,
            onPressed: state.searching
                ? null
                : () async {
                    await cubit.signOut();
                    if (!context.mounted) return;
                    // A conta volta para Restaurar, já com o e-mail novo.
                    unawaited(
                      context.push(
                        Routes.accountEmailFrom(
                          D2Paths.pilaresRestore,
                          signIn: true,
                        ),
                      ),
                    );
                  },
          ),
        ],
      ),
    );
  }
}

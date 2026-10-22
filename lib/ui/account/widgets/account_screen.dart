import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../data/repositories/account/account_repository.dart';
import '../../../domain/models/account.dart';
import '../../../routing/routes.dart';
import '../../core/keys/level_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_icon_size.dart';
import '../../core/theme/app_shape.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/actions_footer.dart';
import '../../core/widgets/lucena_app_bar.dart';
import '../../core/widgets/lucena_snack_bar.dart';
import '../view_models/account_cubit.dart';

/// A conta, opcional (canvas `PropV1LinkConta`), entre o tour e "Seu nível".
/// O Google entra pelo Firebase (E1.02); o e-mail ainda só avisa que vem aí
/// (o formulário espera o canvas). Sem Firebase no build, os dois avisam.
class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (context) => AccountCubit(context.read<AccountRepository>()),
    child: const _AccountView(),
  );
}

class _AccountView extends StatelessWidget {
  const _AccountView();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    void next() => context.go(Routes.level);
    void soon() => showLucenaSnackBar(context, l10n.accountSoon);
    final busy = context.select((AccountCubit cubit) => cubit.state.busy);
    final benefits = [
      (Icons.cloud_done, l10n.accountBenefitSaved),
      (Icons.devices_other, l10n.accountBenefitDevices),
      (Icons.wifi_off, l10n.accountBenefitOffline),
    ];
    return BlocListener<AccountCubit, AccountState>(
      listener: (context, state) {
        if (state.done) return next();
        final failure = state.failure;
        if (failure == null) return;
        showLucenaSnackBar(context, switch (failure) {
          AccountFailure.unavailable => l10n.accountSoon,
          AccountFailure.network => l10n.accountFailedNetwork,
          _ => l10n.accountFailed,
        });
      },
      child: Scaffold(
        key: AccountKeys.screen,
        appBar: LucenaAppBar(
          automaticallyImplyLeading: false,
          leading: IconButton(
            key: AccountKeys.close,
            icon: const Icon(Icons.close),
            tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
            onPressed: next,
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.lg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: colors.primaryContainer,
                    borderRadius: BorderRadius.circular(AppShape.extraLarge),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Icon(
                      Icons.cloud_sync,
                      size: AppIconSize.illustration,
                      color: colors.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                l10n.accountTitle,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                l10n.accountHint,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              for (final (icon, text) in benefits)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                  child: Row(
                    children: [
                      Icon(
                        icon,
                        size: AppIconSize.large,
                        color: colors.primary,
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Text(text, style: theme.textTheme.bodyLarge),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        bottomNavigationBar: ActionsFooter(
          stacked: true,
          children: [
            OutlinedButton.icon(
              key: AccountKeys.google,
              onPressed: busy
                  ? null
                  : () => context.read<AccountCubit>().signInWithGoogle(),
              icon: const Icon(Icons.account_circle_outlined),
              label: Text(l10n.accountGoogle),
            ),
            OutlinedButton.icon(
              key: AccountKeys.email,
              onPressed: soon,
              icon: const Icon(Icons.mail),
              label: Text(l10n.accountEmail),
            ),
            TextButton(
              key: AccountKeys.later,
              onPressed: busy ? null : next,
              child: Text(l10n.accountLater),
            ),
          ],
        ),
      ),
    );
  }
}

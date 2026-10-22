import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../data/repositories/account/account_repository.dart';
import '../../../data/repositories/onboarding/onboarding_repository.dart';
import '../../../data/repositories/sync/sync_scheduler.dart';
import '../../../routing/routes.dart';
import '../../core/keys/account_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_icon_size.dart';
import '../../core/theme/app_shape.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/actions_footer.dart';
import '../../core/widgets/lucena_app_bar.dart';
import '../../core/widgets/lucena_snack_bar.dart';
import '../view_models/account_cubit.dart';
import 'account_flow.dart';

/// A conta, opcional. Com [enter] falso, o convite em tela cheia (canvas
/// `PropV1LinkConta`): vindo de um link, entre o tour e "O que você quer
/// fazer?". Com [enter], "Criar conta ou entrar" (`PropV1PerfilEntrar`),
/// aberto pelo Perfil ou pelo "Já tenho conta" da pergunta. [from] diz para
/// onde seguir no fim (`tour` ou `profile`).
class AccountScreen extends StatelessWidget {
  const AccountScreen({this.from = 'tour', this.enter = false, super.key});

  final String from;
  final bool enter;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (context) => AccountCubit(
      context.read<AccountRepository>(),
      onboarding: enter ? null : context.read<OnboardingRepository>(),
      sync: context.read<SyncScheduler>(),
    )..enter(),
    child: _AccountView(from: from, enter: enter),
  );
}

class _AccountView extends StatelessWidget {
  const _AccountView({required this.from, required this.enter});

  final String from;
  final bool enter;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    // Aberta por cima (Perfil ou "Já tenho conta"), fechar volta.
    void next() => enter && context.canPop()
        ? context.pop()
        : context.go(Routes.afterAccount(from));
    final busy = context.select((AccountCubit cubit) => cubit.state.busy);
    final benefits = [
      (Icons.cloud_done, l10n.accountBenefitSaved),
      (Icons.devices_other, l10n.accountBenefitDevices),
      (Icons.wifi_off, l10n.accountBenefitOffline),
    ];
    return BlocListener<AccountCubit, AccountState>(
      listener: (context, state) {
        if (state.done) return continueAfterSignIn(context, state, from);
        final failure = state.failure;
        if (failure == null) return;
        showLucenaSnackBar(context, accountFailureText(l10n, failure));
      },
      child: Scaffold(
        key: enter ? AccountKeys.enterScreen : AccountKeys.screen,
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
                enter ? l10n.accountEnterTitle : l10n.accountTitle,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                enter ? l10n.accountEnterText : l10n.accountHint,
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
              onPressed: busy
                  ? null
                  : () => context.push(Routes.accountEmailFrom(from)),
              icon: const Icon(Icons.mail),
              label: Text(l10n.accountEmail),
            ),
            if (!enter)
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

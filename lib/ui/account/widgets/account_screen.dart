import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../data/repositories/account/account_repository.dart';
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
import 'account_widgets.dart';

/// "Guarde o seu progresso" (`V1ContaEntrada`, §2.12), aberto pelo Perfil ou
/// pelo "Já tenho conta" da pergunta. Google, criar conta com e-mail ou "Já
/// tem conta? Entrar", cada um na sua tela. [from] diz para onde seguir no
/// fim (`tour` ou `profile`). O convite fora daqui é só o de depois da 1ª
/// vitória.
class AccountScreen extends StatelessWidget {
  const AccountScreen({this.from = 'tour', super.key});

  final String from;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (context) => AccountCubit(
      context.read<AccountRepository>(),
      sync: context.read<SyncScheduler>(),
    ),
    child: _AccountView(from: from),
  );
}

class _AccountView extends StatelessWidget {
  const _AccountView({required this.from});

  final String from;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    // Aberta por cima (Perfil ou "Já tenho conta"), fechar volta.
    void next() => context.canPop()
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
        key: AccountKeys.enterScreen,
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
                    borderRadius: BorderRadius.circular(AppShape.large),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
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
                l10n.accountEntryTitle,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                l10n.accountEntryText,
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
                        size: AppIconSize.standard,
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
          note: const AccountLegalNote(),
          children: [
            FilledButton.icon(
              key: AccountKeys.google,
              onPressed: busy
                  ? null
                  : () => context.read<AccountCubit>().signInWithGoogle(),
              icon: const Icon(Icons.account_circle),
              label: Text(l10n.accountGoogle),
            ),
            OutlinedButton.icon(
              key: AccountKeys.email,
              onPressed: busy
                  ? null
                  : () => context.push(Routes.accountEmailFrom(from)),
              icon: const Icon(Icons.mail),
              label: Text(l10n.accountCreateWithEmail),
            ),
            AccountSwitchLink(
              key: AccountKeys.toSignIn,
              question: l10n.accountHaveAccount,
              action: l10n.accountSignIn,
              onPressed: busy
                  ? null
                  : () => context.push(
                      Routes.accountEmailFrom(from, signIn: true),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

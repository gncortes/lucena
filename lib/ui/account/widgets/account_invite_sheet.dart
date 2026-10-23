import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lucena_ui/lucena_ui.dart';

import '../../../data/repositories/account/account_repository.dart';
import '../../../data/repositories/sync/sync_scheduler.dart';
import '../../../routing/routes.dart';
import '../../core/keys/account_keys.dart';
import '../../core/l10n/l10n.dart';
import '../view_models/account_cubit.dart';
import 'account_flow.dart';

/// De onde vem a conta aberta pelo convite: no fim, segue para o início.
const accountInviteFrom = 'game';

/// O convite para criar conta no fim da 1ª partida (canvas
/// `PropV1PerfilConvite`): Google, e-mail ou "Agora não", que só fecha. As
/// telas seguintes abrem a partir de [context], a tela por baixo.
Future<void> showAccountInviteSheet(BuildContext context) =>
    showLucenaSheet<void>(
      context,
      sheetKey: AccountKeys.inviteSheet,
      builder: (_) => BlocProvider(
        create: (_) => AccountCubit(
          context.read<AccountRepository>(),
          sync: context.read<SyncScheduler>(),
        ),
        child: SafeArea(top: false, child: _InviteSheet(screen: context)),
      ),
    );

class _InviteSheet extends StatelessWidget {
  const _InviteSheet({required this.screen});

  final BuildContext screen;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final busy = context.select((AccountCubit cubit) => cubit.state.busy);
    return BlocListener<AccountCubit, AccountState>(
      listener: (context, state) {
        if (state.done) {
          Navigator.of(context).pop();
          if (screen.mounted) {
            continueAfterSignIn(screen, state, accountInviteFrom);
          }
          return;
        }
        final failure = state.failure;
        if (failure == null) return;
        showLucenaSnackBar(context, accountFailureText(l10n, failure));
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.lg,
              AppSpacing.xl,
              0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: colors.primaryContainer,
                    borderRadius: BorderRadius.circular(AppShape.large),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Icon(
                      Icons.cloud_sync,
                      size: AppIconSize.large,
                      color: colors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  l10n.accountTitle,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  l10n.accountInviteTextSheet,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          ActionsFooter(
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
                    : () {
                        Navigator.of(context).pop();
                        screen.push(Routes.accountEmailFrom(accountInviteFrom));
                      },
                icon: const Icon(Icons.mail),
                label: Text(l10n.accountEmail),
              ),
              TextButton(
                key: AccountKeys.notNow,
                onPressed: busy ? null : () => Navigator.of(context).pop(),
                child: Text(l10n.accountLater),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

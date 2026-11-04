import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../data/repositories/account/account_repository.dart';
import '../../../data/repositories/sync/sync_scheduler.dart';
import '../../../domain/models/account.dart';
import '../../../routing/routes.dart';
import '../../account/view_models/account_cubit.dart';
import '../../account/widgets/account_flow.dart';
import '../../core/analytics/analytics_context.dart';
import '../../core/keys/tour_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_icon_size.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/actions_footer.dart';
import '../../core/widgets/lucena_snack_bar.dart';
import '../view_models/tour_cubit.dart';

/// O momento do convite no evento `conta_convite`.
const _moment = 'tour';

/// O passo "Conta" do tour (canvas `PropV1AbEstConta`): o convite para salvar
/// o progresso, sem "Pular" nem "Continuar". Sair daqui ("Agora não" ou a conta
/// criada) é o que termina o tour. Quem já tem conta não vê o convite. As
/// telas da conta são as da frente Conta; este passo só navega para elas.
class TourAccountStep extends StatelessWidget {
  const TourAccountStep({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => AccountCubit(
      context.read<AccountRepository>(),
      sync: context.read<SyncScheduler>(),
      analytics: context.analytics,
      moment: _moment,
      campaigns: context.campaigns,
    ),
    child: const _AccountBody(),
  );
}

class _AccountBody extends StatefulWidget {
  const _AccountBody();

  @override
  State<_AccountBody> createState() => _AccountBodyState();
}

class _AccountBodyState extends State<_AccountBody> {
  bool _offline = false;

  @override
  void initState() {
    super.initState();
    // Ao refazer o tour com conta, não há o que convidar: vai ao Início.
    if (context.read<AccountRepository>().current != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(context.read<TourCubit>().finish());
      });
    }
  }

  /// A pessoa saiu do tour para a conta: o tour conta como visto e o fim da
  /// conta leva ao Início.
  Future<void> _leave() => context.read<TourCubit>().finish(leave: false);

  Future<void> _email({bool signIn = false}) async {
    context.read<AccountCubit>().inviteAnswered(accepted: true);
    await _leave();
    if (!mounted) return;
    unawaited(
      context.push(Routes.accountEmailFrom(Routes.home, signIn: signIn)),
    );
  }

  Future<void> _later() async {
    context.read<AccountCubit>().inviteAnswered(accepted: false);
    await context.read<TourCubit>().finish();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<AccountCubit>();
    return BlocListener<AccountCubit, AccountState>(
      listener: (context, state) async {
        if (state.done) {
          await _leave();
          if (context.mounted) {
            continueAfterSignIn(context, state, Routes.home);
          }
          return;
        }
        switch (state.failure) {
          case null:
            return;
          case AccountFailure.network:
            setState(() => _offline = true);
          case final failure:
            showLucenaSnackBar(context, accountFailureText(l10n, failure));
        }
      },
      child: _offline
          ? _Offline(onBack: () => setState(() => _offline = false))
          : _Invite(
              busy: context.select((AccountCubit c) => c.state.busy),
              onGoogle: () {
                cubit.inviteAnswered(accepted: true);
                unawaited(cubit.signInWithGoogle());
              },
              onEmail: _email,
              onLogin: () => _email(signIn: true),
              onLater: _later,
            ),
    );
  }
}

class _Invite extends StatelessWidget {
  const _Invite({
    required this.busy,
    required this.onGoogle,
    required this.onEmail,
    required this.onLogin,
    required this.onLater,
  });

  final bool busy;
  final VoidCallback onGoogle;
  final VoidCallback onEmail;
  final VoidCallback onLogin;
  final VoidCallback onLater;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    Widget line(IconData icon, String text) => Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: AppIconSize.standard, color: colors.primary),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: Text(text, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          line(Icons.cloud_done, l10n.tourAccountSaved),
          line(Icons.wifi_off, l10n.tourAccountNoAccount),
          const SizedBox(height: AppSpacing.md),
          // O rodapé empilhado do canvas, dentro do passo (o botão da base
          // do tour é o dos outros passos).
          ActionsFooter(
            stacked: true,
            margin: 0,
            children: [
              OutlinedButton.icon(
                key: TourKeys.accountGoogle,
                onPressed: busy ? null : onGoogle,
                icon: const Icon(Icons.account_circle_outlined),
                label: Text(l10n.tourAccountGoogle),
              ),
              OutlinedButton.icon(
                key: TourKeys.accountEmail,
                onPressed: busy ? null : onEmail,
                icon: const Icon(Icons.mail),
                label: Text(l10n.tourAccountEmail),
              ),
              TextButton(
                key: TourKeys.accountLater,
                onPressed: busy ? null : onLater,
                child: Text(l10n.accountLater),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(l10n.accountHaveAccount, style: theme.textTheme.bodyMedium),
              TextButton(
                key: TourKeys.accountLogin,
                onPressed: busy ? null : onLogin,
                child: Text(l10n.accountSignIn),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// "Sem internet": criar a conta pede conexão. "Tentar novamente" e "Voltar"
/// voltam ao passo Conta.
class _Offline extends StatelessWidget {
  const _Offline({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Padding(
      key: TourKeys.accountOffline,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(
            Icons.wifi_off,
            size: AppIconSize.illustration,
            color: colors.onSurfaceVariant,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            l10n.loadErrorOfflineTitle,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.tourAccountNoNetText,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
          ActionsFooter(
            stacked: true,
            margin: 0,
            children: [
              FilledButton(
                key: TourKeys.accountRetry,
                onPressed: onBack,
                child: Text(l10n.tourAccountRetry),
              ),
              TextButton(
                key: TourKeys.accountBack,
                onPressed: onBack,
                child: Text(l10n.tourAccountBack),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

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
import '../../account/widgets/account_invite.dart';
import '../../core/analytics/analytics_context.dart';
import '../../core/keys/tour_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/motion/entrada_em_cascata.dart';
import '../../core/theme/app_icon_size.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/actions_footer.dart';
import '../../core/widgets/lucena_snack_bar.dart';
import '../view_models/tour_cubit.dart';

/// O momento do convite no evento `conta_convite`.
const _moment = 'tour';

/// O "Sem internet" do passo Conta: o passo troca o convite pelo aviso e o
/// rodapé some.
/// (Um invólucro: o Provider não aceita um `Listenable` direto.)
class TourAccountOffline {
  final shown = ValueNotifier<bool>(false);

  void dispose() => shown.dispose();
}

/// O que o passo "Conta" e o rodapé dele dividem: a conta (criada só quando
/// o passo abre) e o "Sem internet". Fica em volta do corpo do tour, porque
/// as ações ficam fixas no pé da tela, fora da rolagem (canvas
/// `PropV2TourBConta`).
class TourAccountScope extends StatefulWidget {
  const TourAccountScope({required this.child, super.key});

  final Widget child;

  @override
  State<TourAccountScope> createState() => _TourAccountScopeState();
}

class _TourAccountScopeState extends State<TourAccountScope> {
  final _offline = TourAccountOffline();

  @override
  void dispose() {
    _offline.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RepositoryProvider.value(
    value: _offline,
    child: BlocProvider(
      create: (_) => AccountCubit(
        context.read<AccountRepository>(),
        sync: context.read<SyncScheduler>(),
        analytics: context.analytics,
        moment: _moment,
        campaigns: context.campaigns,
      ),
      child: widget.child,
    ),
  );
}

/// O passo "Conta" do tour (canvas `PropV2TourBConta`): o convite para salvar
/// o progresso, sem "Pular" nem "Continuar"; as ações ficam no
/// [TourAccountFooter]. Sair daqui ("Agora não" ou a conta criada) é o que
/// termina o tour. Quem já tem conta não vê o convite. As telas da conta são
/// as da frente Conta; este passo só navega para elas.
class TourAccountStep extends StatefulWidget {
  const TourAccountStep({super.key});

  @override
  State<TourAccountStep> createState() => _TourAccountStepState();
}

class _TourAccountStepState extends State<TourAccountStep> {
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

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final offline = context.read<TourAccountOffline>().shown;
    return BlocListener<AccountCubit, AccountState>(
      listener: (context, state) async {
        if (state.done) {
          await _leave(context);
          if (context.mounted) {
            continueAfterSignIn(context, state, Routes.home);
          }
          return;
        }
        switch (state.failure) {
          case null:
            return;
          case AccountFailure.network:
            offline.value = true;
          case final failure:
            showLucenaSnackBar(context, accountFailureText(l10n, failure));
        }
      },
      child: ValueListenableBuilder(
        valueListenable: offline,
        builder: (context, isOffline, _) => isOffline
            ? _Offline(onBack: () => offline.value = false)
            : const _Invite(),
      ),
    );
  }
}

/// A pessoa saiu do tour para a conta: o tour conta como visto e o fim da
/// conta leva ao Início.
Future<void> _leave(BuildContext context) =>
    context.read<TourCubit>().finish(leave: false);

/// As ações do convite, fixas no pé da tela (o rodapé empilhado do canvas).
/// São as do convite da Conta (H-CON-01), com as keys do tour. No "Sem
/// internet", somem: o aviso tem os botões dele.
class TourAccountFooter extends StatelessWidget {
  const TourAccountFooter({super.key});

  Future<void> _email(BuildContext context, {bool signIn = false}) async {
    context.read<AccountCubit>().inviteAnswered(accepted: true);
    await _leave(context);
    if (!context.mounted) return;
    unawaited(
      context.push(Routes.accountEmailFrom(Routes.home, signIn: signIn)),
    );
  }

  Future<void> _later(BuildContext context) async {
    context.read<AccountCubit>().inviteAnswered(accepted: false);
    await context.read<TourCubit>().finish();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<AccountCubit>();
    final busy = context.select((AccountCubit c) => c.state.busy);
    return ValueListenableBuilder(
      valueListenable: context.read<TourAccountOffline>().shown,
      builder: (context, offline, _) => offline
          ? const SizedBox.shrink()
          : ActionsFooter(
              stacked: true,
              children: accountInviteActions(
                context,
                onGoogle: () {
                  cubit.inviteAnswered(accepted: true);
                  return cubit.signInWithGoogle();
                },
                onEmail: () => _email(context),
                onSignIn: () => _email(context, signIn: true),
                onLater: () => _later(context),
                busy: busy,
                googleKey: TourKeys.accountGoogle,
                emailKey: TourKeys.accountEmail,
                signInKey: TourKeys.accountLogin,
                laterKey: TourKeys.accountLater,
              ),
            ),
    );
  }
}

/// O texto do convite; as ações ficam no [TourAccountFooter].
class _Invite extends StatelessWidget {
  const _Invite();

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
    // H-ANI-16: o texto que explica entra em cascata.
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: EntradaEmCascata(
        itens: [
          ItemDaCascata.texto(line(Icons.cloud_done, l10n.tourAccountSaved)),
          ItemDaCascata.texto(line(Icons.wifi_off, l10n.tourAccountNoAccount)),
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

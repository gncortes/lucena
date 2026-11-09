import 'dart:async';

import '../../core/analytics/analytics_context.dart';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../data/repositories/legal/legal_consent_repository.dart';
import '../../../data/repositories/account/account_repository.dart';
import '../../../data/repositories/onboarding/onboarding_repository.dart';
import '../../../data/repositories/sync/sync_scheduler.dart';
import '../../../routing/routes.dart';
import '../../core/keys/account_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/actions_footer.dart';
import '../../core/widgets/lucena_app_bar.dart';
import '../view_models/account_cubit.dart';
import 'account_failure_gate.dart';
import 'account_flow.dart';
import 'account_invite.dart';

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
      analytics: context.analytics,
      campaigns: context.campaigns,
      consent: context.read<LegalConsentRepository>(),
      // Vinda do link (H-CON-04): o convite conta no `conta_convite`.
      moment: Routes.isRouteFrom(from) ? accountInviteAfterLink : null,
      onboarding: _onboarding(context),
    ),
    child: _AccountView(from: from),
  );
}

/// O tour, quando o app o oferece (os testes antigos da conta não oferecem).
OnboardingRepository? _onboarding(BuildContext context) {
  try {
    return context.read<OnboardingRepository>();
  } on ProviderNotFoundException {
    return null;
  }
}

/// O convite do link abre antes da lição (`conta_convite`).
const accountInviteAfterLink = 'pos_desafio_link';

class _AccountView extends StatelessWidget {
  const _AccountView({required this.from});

  final String from;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<AccountCubit>();
    // Aberta de uma rota (o link, H-CON-04): é o convite, com "Agora não";
    // a tela seguinte toma o lugar desta, e voltar do fim volta para quem
    // abriu a conta.
    final purchase = isPurchase(from);
    final invite = Routes.isRouteFrom(from) && !purchase;
    // Aberta por cima (Perfil ou "Já tenho conta"), fechar volta.
    void close() => context.canPop()
        ? context.pop()
        : context.go(Routes.afterAccount(from));
    // "Agora não", o X e o voltar do convite: sem o tour feito, a pergunta
    // do objetivo; com ele, volta para quem abriu (ou o início).
    Future<void> later() async {
      cubit.inviteAnswered(accepted: false);
      final goal = await cubit.needsGoal();
      if (!context.mounted) return;
      if (goal) return context.go(Routes.goal);
      context.canPop() ? context.pop() : context.go(Routes.home);
    }

    void open(String route) => invite
        ? context.pushReplacement(route)
        : unawaited(context.push(route));
    final busy = context.select((AccountCubit cubit) => cubit.state.busy);
    return BlocListener<AccountCubit, AccountState>(
      listener: (context, state) {
        if (state.done) {
          return continueAfterSignIn(context, state, from, replace: invite);
        }
        final failure = state.failure;
        if (failure == null || state.screenFailure != null) return;
        showAccountFailure(
          context,
          failure,
          onRetry: () => unawaited(context.read<AccountCubit>().retry()),
        );
      },
      child: AccountFailureGate(
        message: l10n.conSemRedeCreate,
        child: PopScope(
          canPop: !invite,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop && !busy) unawaited(later());
          },
          child: Scaffold(
            key: purchase
                ? AccountKeys.purchaseScreen
                : AccountKeys.enterScreen,
            appBar: purchase
                // A compra exige conta: voltar leva à oferta (H-CON-05).
                ? LucenaAppBar(
                    leading: BackButton(
                      key: AccountKeys.purchaseBack,
                      onPressed: close,
                    ),
                    title: Text(l10n.accountCreate),
                  )
                : LucenaAppBar(
                    automaticallyImplyLeading: false,
                    leading: IconButton(
                      key: AccountKeys.close,
                      icon: const Icon(Icons.close),
                      tooltip: MaterialLocalizations.of(context)
                          .closeButtonTooltip,
                      onPressed: invite ? () => unawaited(later()) : close,
                    ),
                  ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xl,
                vertical: AppSpacing.lg,
              ),
              child: _AccountHeader(purchase: purchase, invite: invite),
            ),
            bottomNavigationBar: ActionsFooter(
              stacked: true,
              children: accountInviteActions(
                context,
                busy: busy,
                onGoogle: () {
                  cubit.inviteAnswered(accepted: true);
                  return cubit.signInWithGoogle();
                },
                onEmail: () {
                  cubit.inviteAnswered(accepted: true);
                  open(Routes.accountEmailFrom(from));
                },
                onSignIn: () =>
                    open(Routes.accountEmailFrom(from, signIn: true)),
                onLater: invite ? () => unawaited(later()) : null,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// O cabeçalho da conta: compra, convite ou entrada.
class _AccountHeader extends StatelessWidget {
  const _AccountHeader({required this.purchase, required this.invite});

  final bool purchase;
  final bool invite;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return purchase
        ? AccountInviteHeader(
            icon: Icons.school,
            title: l10n.conCompraTitle,
            text: l10n.conCompraText,
            titleKey: AccountKeys.enterTitle,
            textKey: AccountKeys.enterText,
            benefits: [
              (Icons.devices, l10n.conCompraDevices),
              (Icons.cloud_done, l10n.conCompraSaved),
              (Icons.sync, l10n.conCompraSync),
            ],
          )
        : AccountInviteHeader(
            title: invite ? l10n.conConviteTitle : l10n.conEntradaTitle,
            text: invite ? l10n.conConviteLater : l10n.accountEntryText,
            titleKey: AccountKeys.enterTitle,
            textKey: AccountKeys.enterText,
            benefits: [
              (Icons.cloud_done, l10n.conEntradaSaved),
              (Icons.wifi_off, l10n.conEntradaOffline),
            ],
          );
  }
}

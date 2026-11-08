import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../data/repositories/account/account_repository.dart';
import '../../../data/repositories/sync/sync_scheduler.dart';
import '../../../routing/frentes/d2_routes.dart';
import '../../../routing/routes.dart';
import '../../account/view_models/account_cubit.dart';
import '../../account/widgets/account_flow.dart';
import '../../core/analytics/analytics_context.dart';
import '../../core/keys/gift_opening_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/widgets/busy_button.dart';
import '../../core/widgets/lucena_app_bar.dart';
import '../../core/widgets/lucena_snack_bar.dart';
import '../view_models/gift_opening_cubit.dart';

/// O toque no push do presente (H-R5-63, canvas `PropV2PresenteAbrindo` e
/// `PropV2PresenteSemConta`): "Abrindo o seu presente…" até o acesso
/// sincronizar, depois o Curso liberado no lugar desta tela. Sem conta,
/// entrar para ver o presente ([account]: o e-mail mascarado da conta dele).
/// Em outra conta, o catálogo do curso. Se o Curso liberado deste acesso já
/// saiu, só volta: um por acesso.
class GiftOpeningScreen extends StatelessWidget {
  const GiftOpeningScreen({required this.course, this.account, super.key});

  final String course;
  final String? account;

  static void _close(BuildContext context) =>
      context.canPop() ? context.pop() : context.go(Routes.home);

  @override
  Widget build(BuildContext context) =>
      BlocConsumer<GiftOpeningCubit, GiftOpeningState>(
        listenWhen: (a, b) => a.phase != b.phase,
        listener: (context, state) => switch (state.phase) {
          GiftOpeningPhase.open => context.pushReplacement(
            state.gift ? D2Paths.pilaresGiftDone : D2Paths.pilaresPurchaseDone,
          ),
          GiftOpeningPhase.shown => _close(context),
          GiftOpeningPhase.otherAccount => context.pushReplacement(
            Routes.trainingCatalog(course),
          ),
          _ => null,
        },
        builder: (context, state) => switch (state.phase) {
          GiftOpeningPhase.signIn => BlocProvider(
            create: (context) => AccountCubit(
              context.read<AccountRepository>(),
              sync: context.read<SyncScheduler>(),
              analytics: context.analytics,
              campaigns: context.campaigns,
            ),
            child: _SignIn(account: account, onBack: () => _close(context)),
          ),
          GiftOpeningPhase.failed => _Waiting(failed: true),
          _ => _Waiting(failed: false),
        },
      );
}

/// O presente no círculo azul, o texto e o carregando (ou a falha com
/// "Tentar novamente").
class _Waiting extends StatelessWidget {
  const _Waiting({required this.failed});

  final bool failed;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Scaffold(
      key: failed ? GiftOpeningKeys.failed : GiftOpeningKeys.opening,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              spacing: 24,
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: scheme.primaryContainer,
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.card_giftcard,
                    size: 56,
                    color: scheme.primary,
                  ),
                ),
                Text(
                  failed ? l.giftFailed : l.giftOpening,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontSize: 24,
                    height: 32 / 24,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (failed)
                  BusyButton(
                    buttonKey: GiftOpeningKeys.retry,
                    label: l.loadErrorRetry,
                    onPressed: () => context.read<GiftOpeningCubit>().retry(),
                  )
                else
                  SizedBox.square(
                    dimension: 40,
                    child: CircularProgressIndicator(
                      strokeWidth: 6,
                      color: scheme.primary,
                      backgroundColor: scheme.primaryContainer,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Entrar para ver o presente: a tela Entrar com o parâmetro presente.
class _SignIn extends StatelessWidget {
  const _SignIn({required this.account, required this.onBack});

  final String? account;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final busy = context.select((AccountCubit cubit) => cubit.state.busy);
    final mask = account;
    return BlocListener<AccountCubit, AccountState>(
      listener: (context, state) {
        if (state.failure case final failure?) {
          showLucenaSnackBar(context, accountFailureText(l, failure));
        }
      },
      child: Scaffold(
        key: GiftOpeningKeys.signIn,
        appBar: LucenaAppBar(
          centerTitle: true,
          leading: BackButton(
            key: GiftOpeningKeys.signInBack,
            onPressed: onBack,
          ),
          title: Text(l.accountSignIn),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 8,
            children: [
              Text(
                l.giftSignInTitle,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontSize: 24,
                  height: 32 / 24,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                mask == null
                    ? l.giftSignInNoAccount
                    : l.giftSignInAccount(mask),
                key: GiftOpeningKeys.signInText,
                style: theme.textTheme.bodyLarge,
              ),
            ],
          ),
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 8,
              children: [
                BusyButton(
                  buttonKey: GiftOpeningKeys.google,
                  icon: Icons.login,
                  label: l.accountGoogle,
                  onPressed: busy
                      ? null
                      : () => context.read<AccountCubit>().signInWithGoogle(),
                ),
                BusyButton(
                  buttonKey: GiftOpeningKeys.email,
                  icon: Icons.mail_outline,
                  style: BusyButtonStyle.outlined,
                  label: l.trainingEntryEmail,
                  onPressed: busy
                      ? null
                      : () => unawaited(
                          context.push(
                            Routes.accountEmailFrom(
                              GoRouterState.of(context).uri.toString(),
                            ),
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

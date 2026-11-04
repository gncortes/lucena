import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../data/repositories/account/account_repository.dart';
import '../../../data/repositories/legal/legal_consent_repository.dart';
import '../../../data/repositories/sync/sync_scheduler.dart';
import '../../../routing/routes.dart';
import '../../core/analytics/analytics_context.dart';
import '../../core/keys/account_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_button.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/lucena_snack_bar.dart';
import '../view_models/account_cubit.dart';
import 'account_flow.dart';
import 'account_invite.dart';
import 'account_invite_sheet.dart';

/// O convite como cartão dentro de uma tela (PropV2UxConclusaoConta,
/// PropV2UxProgresso; H-CON-02/03): X no canto, o convite compacto com três
/// benefícios e Google, e-mail e "Já tem conta? Entrar" (sem "Agora não": o
/// X vale por ele). Quem coloca o cartão decide quando ele aparece (sem conta,
/// fora da suspensão de 7 dias) e, no [onClose], suspende o convite
/// (`AccountInviteRepository.markShown`) e o tira da tela.
class AccountInviteCard extends StatelessWidget {
  const AccountInviteCard({
    required this.title,
    required this.onClose,
    this.from = accountInviteFrom,
    this.moment = accountInviteAfterWin,
    this.cardKey = AccountKeys.inviteCard,
    this.closeKey = AccountKeys.inviteCardClose,
    super.key,
  });

  /// "Salve suas conquistas" (fim da partida) ou "Salve seu progresso".
  final String title;
  final VoidCallback onClose;

  /// Para onde a conta segue no fim (`Routes.afterAccount`).
  final String from;

  /// O `momento` do `conta_convite`.
  final String moment;
  final Key cardKey;
  final Key closeKey;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => AccountCubit(
      context.read<AccountRepository>(),
      sync: context.read<SyncScheduler>(),
      analytics: context.analytics,
      moment: moment,
      campaigns: context.campaigns,
      consent: _consent(context),
    ),
    child: _Card(
      title: title,
      onClose: onClose,
      from: from,
      cardKey: cardKey,
      closeKey: closeKey,
    ),
  );
}

LegalConsentRepository _consent(BuildContext context) {
  try {
    return context.read<LegalConsentRepository>();
  } on ProviderNotFoundException {
    return const NoLegalConsentRepository();
  }
}

class _Card extends StatelessWidget {
  const _Card({
    required this.title,
    required this.onClose,
    required this.from,
    required this.cardKey,
    required this.closeKey,
  });

  final String title;
  final VoidCallback onClose;
  final String from;
  final Key cardKey;
  final Key closeKey;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<AccountCubit>();
    final busy = context.select((AccountCubit cubit) => cubit.state.busy);
    final actions = accountInviteActions(
      context,
      busy: busy,
      onGoogle: () {
        cubit.inviteAnswered(accepted: true);
        return cubit.signInWithGoogle();
      },
      onEmail: () {
        cubit.inviteAnswered(accepted: true);
        unawaited(context.push(Routes.accountEmailFrom(from)));
      },
      onSignIn: () =>
          unawaited(context.push(Routes.accountEmailFrom(from, signIn: true))),
    );
    return BlocListener<AccountCubit, AccountState>(
      listener: (context, state) {
        if (state.done) return continueAfterSignIn(context, state, from);
        final failure = state.failure;
        if (failure == null) return;
        showLucenaSnackBar(context, accountFailureText(l10n, failure));
      },
      child: Card(
        key: cardKey,
        margin: EdgeInsets.zero,
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AccountInviteHeader(
                    compact: true,
                    title: title,
                    text: l10n.accountEntryText,
                    benefits: [
                      (Icons.emoji_events, l10n.conCartaoGames),
                      (Icons.school, l10n.conCartaoLessons),
                      (Icons.devices, l10n.conCartaoDevices),
                    ],
                  ),
                  for (final (index, action) in actions.indexed) ...[
                    if (index > 0) const SizedBox(height: AppSpacing.sm),
                    SizedBox(height: kButtonHeight, child: action),
                  ],
                ],
              ),
            ),
            PositionedDirectional(
              top: AppSpacing.xs,
              end: AppSpacing.xs,
              child: SizedBox.square(
                dimension: 40,
                child: IconButton(
                  key: closeKey,
                  padding: EdgeInsets.zero,
                  icon: const Icon(Icons.close),
                  tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                  onPressed: busy ? null : onClose,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

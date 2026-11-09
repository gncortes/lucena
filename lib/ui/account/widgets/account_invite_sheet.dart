import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../config/view_models/account.dart';
import '../../../routing/routes.dart';
import '../../core/keys/account_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/actions_footer.dart';
import '../../core/widgets/lucena_sheet.dart';
import '../../core/widgets/lucena_snack_bar.dart';
import '../view_models/account_cubit.dart';
import 'account_flow.dart';
import 'account_invite.dart';

/// De onde vem a conta aberta pelo convite: no fim, segue para o início.
const accountInviteFrom = 'game';

/// O convite abre depois da 1ª vitória (T83 A3).
const accountInviteAfterWin = 'pos_vitoria';

/// O convite abre depois de usar o rating do Lichess, sem conta (T83).
const accountInviteAfterLichess = 'pos_lichess';

/// O convite para criar conta (canvas `PropV1PerfilConvite`): Google, e-mail,
/// "Já tem conta? Entrar" ou "Agora não", que só fecha. As telas seguintes abrem a partir de
/// [context], a tela por baixo, e terminam em `Routes.afterAccount([from])`.
/// [moment] vai no evento `conta_convite` (`pos_vitoria|pos_lichess`); [text]
/// troca a frase do ganho (padrão: a do fim da partida).
///
/// Verdadeiro: a pessoa escolheu Google ou e-mail e a conta seguiu por outras
/// telas. Falso: "Agora não" ou o X; quem abriu segue o próprio caminho.
Future<bool> showAccountInviteSheet(
  BuildContext context, {
  String moment = accountInviteAfterWin,
  String? text,
  String from = accountInviteFrom,
}) async =>
    await showLucenaSheet<bool>(
      context,
      sheetKey: AccountKeys.inviteSheet,
      builder: (_) => BlocProvider(
        create: (_) =>
            createAccountCubit(context, moment: moment, consent: true),
        child: SafeArea(
          top: false,
          child: _InviteSheet(screen: context, text: text, from: from),
        ),
      ),
    ) ??
    false;

class _InviteSheet extends StatelessWidget {
  const _InviteSheet({
    required this.screen,
    required this.text,
    required this.from,
  });

  final BuildContext screen;
  final String? text;
  final String from;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<AccountCubit>();
    final busy = context.select((AccountCubit cubit) => cubit.state.busy);
    void openAfter(String route) {
      Navigator.of(context).pop(true);
      screen.push(route);
    }

    return BlocListener<AccountCubit, AccountState>(
      listener: (context, state) {
        if (state.done) {
          Navigator.of(context).pop(true);
          if (screen.mounted) continueAfterSignIn(screen, state, from);
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
            child: AccountInviteHeader(
              compact: true,
              title: l10n.conConviteTitle,
              text: text ?? l10n.conConviteSheetText,
            ),
          ),
          ActionsFooter(
            margin: AppSpacing.xl,
            stacked: true,
            children: accountInviteActions(
              context,
              busy: busy,
              laterKey: AccountKeys.notNow,
              onGoogle: () {
                cubit.inviteAnswered(accepted: true);
                return cubit.signInWithGoogle();
              },
              onEmail: () {
                cubit.inviteAnswered(accepted: true);
                openAfter(Routes.accountEmailFrom(from));
              },
              onSignIn: () =>
                  openAfter(Routes.accountEmailFrom(from, signIn: true)),
              onLater: () {
                cubit.inviteAnswered(accepted: false);
                Navigator.of(context).pop(false);
              },
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../data/repositories/account/account_repository.dart';
import '../../../data/repositories/profile/profile_repository.dart';
import '../../../routing/routes.dart';
import '../../core/analytics/analytics_context.dart';
import '../../core/keys/account_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_shape.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/actions_footer.dart';
import '../../core/widgets/busy_button.dart';
import '../../core/widgets/lucena_sheet.dart';
import '../../core/widgets/lucena_snack_bar.dart';
import '../../core/widgets/sheet_header.dart';
import '../view_models/account_delete_cubit.dart';

/// Abre "Excluir sua conta?" (H-CON-14, quadro PropV1PerfilApagar) para a
/// conta [uid], a partir do Perfil ou da Privacidade ([from]).
///
/// Conta de e-mail sem login recente: a folha fecha, a tela da senha abre e
/// a folha volta para terminar (ou com o aviso, se a pessoa desistiu). O fim
/// (conta excluída ou outra conta no novo login) é avisado por quem abriu.
Future<void> showAccountDeleteSheet(
  BuildContext context, {
  required String uid,
  required String from,
}) async {
  final accounts = context.read<AccountRepository>();
  final profile = context.read<ProfileRepository>();
  final analytics = context.analytics;
  bool? signedIn;
  while (true) {
    if (!context.mounted) return;
    final cubit = AccountDeleteCubit(
      uid: uid,
      accounts: accounts,
      profile: profile,
      analytics: analytics,
    );
    final resume = signedIn;
    final step = await showLucenaSheet<AccountDeleteStep>(
      context,
      sheetKey: AccountKeys.deleteSheet,
      closeKey: AccountKeys.deleteClose,
      enableDrag: false,
      onClose: () {
        if (!cubit.state.busy) Navigator.of(context).pop();
      },
      builder: (_) => BlocProvider.value(
        value: cubit,
        child: AccountDeleteSheet(resume: resume),
      ),
    ).whenComplete(cubit.close);
    if (!context.mounted) return;
    switch (step) {
      case AccountDeleteStep.relogin:
        final ok = await context.push<bool>(
          Routes.accountEmailFrom(from, reauth: true),
        );
        signedIn = ok ?? false;
      case AccountDeleteStep.deleted:
        showLucenaSnackBar(context, context.l10n.accountDeleted);
        return;
      case AccountDeleteStep.differentAccount:
        showLucenaSnackBar(context, context.l10n.conApagarDifferent);
        return;
      case _:
        return;
    }
  }
}

class AccountDeleteSheet extends StatefulWidget {
  const AccountDeleteSheet({this.resume, super.key});

  /// A volta do novo login com e-mail: true entrou, false desistiu.
  final bool? resume;

  @override
  State<AccountDeleteSheet> createState() => _AccountDeleteSheetState();
}

class _AccountDeleteSheetState extends State<AccountDeleteSheet> {
  @override
  void initState() {
    super.initState();
    if (widget.resume case final signedIn?) {
      context.read<AccountDeleteCubit>().afterSignIn(signedIn: signedIn);
    }
  }

  static const _endSteps = {
    AccountDeleteStep.relogin,
    AccountDeleteStep.deleted,
    AccountDeleteStep.differentAccount,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocConsumer<AccountDeleteCubit, AccountDeleteState>(
      listenWhen: (before, now) => _endSteps.contains(now.step),
      listener: (context, state) => Navigator.of(context).pop(state.step),
      builder: (context, state) {
        final cubit = context.read<AccountDeleteCubit>();
        final failed = state.notice == AccountDeleteNotice.failed;
        final notice = switch (state.notice) {
          AccountDeleteNotice.offline => l10n.accountDeleteOffline,
          AccountDeleteNotice.failed => l10n.conApagarFailed,
          AccountDeleteNotice.cancelled => l10n.conApagarCancelled,
          null => null,
        };
        return PopScope(
          canPop: !state.busy,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SheetHeader(title: l10n.conApagarTitle, hint: l10n.conApagarHint),
              _DeleteBody(notice: notice),
              ActionsFooter(
                stacked: true,
                margin: AppSpacing.xl,
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl,
                  AppSpacing.sm,
                  AppSpacing.xl,
                  AppSpacing.xl,
                ),
                children: [
                  BusyButton(
                    buttonKey: AccountKeys.deleteConfirm,
                    style: BusyButtonStyle.destructive,
                    busy: state.busy,
                    icon: failed ? Icons.refresh : Icons.delete,
                    label: failed ? l10n.conApagarRetry : l10n.conApagarConfirm,
                    onPressed: cubit.confirm,
                  ),
                  OutlinedButton(
                    key: AccountKeys.deleteCancel,
                    onPressed: state.busy
                        ? null
                        : () => Navigator.of(context).pop(),
                    child: Text(l10n.accountDeleteCancel),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

/// O corpo da folha: o que se perde, o aviso do Play e o último aviso.
class _DeleteBody extends StatelessWidget {
  const _DeleteBody({required this.notice});

  final String? notice;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final notice = this.notice;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        0,
        AppSpacing.xl,
        AppSpacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.conApagarLose,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: _gap),
          KeyedSubtree(
            key: AccountKeys.deleteLose,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _LoseItem(Icons.school, l10n.conApagarLoseLessons),
                const SizedBox(height: _gap),
                _LoseItem(Icons.trending_up, l10n.conApagarLoseRating),
                const SizedBox(height: _gap),
                _LoseItem(Icons.person, l10n.conApagarLoseProfile),
              ],
            ),
          ),
          const SizedBox(height: _gap),
          _PlayWarning(text: l10n.conApagarPlay),
          const SizedBox(height: _gap),
          Text(
            l10n.conApagarDevice,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
          if (notice != null) ...[
            const SizedBox(height: _gap),
            Row(
              key: AccountKeys.deleteNotice,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.error, color: colors.error),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    notice,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colors.error,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

const _gap = 14.0;

/// Um item de "Você perde": ícone vermelho preenchido e o texto.
class _LoseItem extends StatelessWidget {
  const _LoseItem(this.icon, this.text);

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: theme.colorScheme.error),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodyLarge?.copyWith(fontSize: 15),
          ),
        ),
      ],
    );
  }
}

/// O aviso da assinatura: caixa âmbar (terciária) com `warning`.
class _PlayWarning extends StatelessWidget {
  const _PlayWarning({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return DecoratedBox(
      key: AccountKeys.deletePlayWarning,
      decoration: BoxDecoration(
        color: colors.tertiaryContainer,
        borderRadius: BorderRadius.circular(AppShape.medium),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.warning, color: colors.tertiary),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                text,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.onTertiaryContainer,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

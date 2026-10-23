import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucena_ui/lucena_ui.dart';

import '../../../data/repositories/account/mail_app_repository.dart';
import '../../../domain/models/account.dart';
import '../../core/keys/account_keys.dart';
import '../../core/l10n/l10n.dart';
import '../view_models/account_cubit.dart';
import 'account_flow.dart';

/// "Esqueceu a senha?" (canvas `V1ContaSenha`, §2.12): o e-mail já vem do
/// campo de Entrar. Mandou o link, troca por "Confira o seu e-mail".
Future<void> showPasswordResetSheet(
  BuildContext context, {
  required String email,
}) async {
  final cubit = context.read<AccountCubit>();
  final sent = await showLucenaSheet<String>(
    context,
    sheetKey: AccountKeys.resetSheet,
    builder: (sheet) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(sheet).bottom),
      child: _ResetSheet(email: email.trim(), send: cubit.sendPasswordReset),
    ),
  );
  if (sent == null || !context.mounted) return;
  final mail = context.read<MailAppRepository>();
  final canOpen = await mail.available();
  if (!context.mounted) return;
  await showLucenaSheet<void>(
    context,
    sheetKey: AccountKeys.resetSentSheet,
    builder: (sheet) => _SentSheet(
      email: sent,
      onOpenMail: canOpen
          ? () {
              Navigator.of(sheet).pop();
              mail.open();
            }
          : null,
    ),
  );
}

/// O ícone num quadrado, o título e o texto do alto das duas folhas.
class _SheetHeader extends StatelessWidget {
  const _SheetHeader({
    required this.icon,
    required this.title,
    required this.text,
    this.color,
    this.background,
  });

  final IconData icon;
  final String title;
  final Widget text;
  final Color? color;
  final Color? background;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: background ?? colors.primaryContainer,
              borderRadius: BorderRadius.circular(AppShape.large),
            ),
            child: SizedBox.square(
              dimension: 56,
              child: Icon(
                icon,
                size: AppIconSize.large,
                color: color ?? colors.primary,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          title,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        DefaultTextStyle.merge(
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colors.onSurfaceVariant,
          ),
          child: text,
        ),
      ],
    );
  }
}

class _ResetSheet extends StatefulWidget {
  const _ResetSheet({required this.email, required this.send});

  final String email;
  final Future<AccountFailure?> Function(String email) send;

  @override
  State<_ResetSheet> createState() => _ResetSheetState();
}

class _ResetSheetState extends State<_ResetSheet> {
  late final _email = TextEditingController(text: widget.email);
  AccountFailure? _failure;
  bool _busy = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    setState(() => _busy = true);
    final email = _email.text.trim();
    final failure = await widget.send(email);
    if (!mounted) return;
    if (failure == null) return Navigator.of(context).pop(email);
    setState(() {
      _busy = false;
      _failure = failure;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final failure = _failure;
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
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
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _SheetHeader(
                    icon: Icons.lock_reset,
                    title: l10n.accountResetTitle,
                    text: Text(l10n.accountResetText),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  TextField(
                    key: AccountKeys.resetEmail,
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    autocorrect: false,
                    textInputAction: TextInputAction.send,
                    autofillHints: const [AutofillHints.email],
                    onSubmitted: _busy ? null : (_) => _send(),
                    onChanged: (_) {
                      if (_failure != null) setState(() => _failure = null);
                    },
                    decoration: InputDecoration(
                      labelText: l10n.accountEmailField,
                      hintText: l10n.accountEmailHint,
                      prefixIcon: const Icon(Icons.mail),
                      errorText: failure == null
                          ? null
                          : accountFailureText(l10n, failure),
                      errorMaxLines: 2,
                    ),
                  ),
                ],
              ),
            ),
            ActionsFooter(
              stacked: true,
              margin: AppSpacing.xl,
              children: [
                FilledButton(
                  key: AccountKeys.resetSend,
                  onPressed: _busy ? null : _send,
                  child: Text(l10n.accountResetSend),
                ),
                TextButton(
                  key: AccountKeys.resetCancel,
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(l10n.accountResetCancel),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SentSheet extends StatelessWidget {
  const _SentSheet({required this.email, required this.onOpenMail});

  final String email;
  final VoidCallback? onOpenMail;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    // O e-mail em negrito no meio do texto traduzido.
    final parts = l10n.accountResetSentText('\u0001').split('\u0001');
    return SafeArea(
      top: false,
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
            child: _SheetHeader(
              icon: Icons.mark_email_read,
              color: AppColors.record,
              background: AppColors.goalWinBg,
              title: l10n.accountResetSentTitle,
              text: Text.rich(
                TextSpan(
                  children: [
                    for (var i = 0; i < parts.length; i++) ...[
                      if (i > 0)
                        TextSpan(
                          text: email,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      TextSpan(text: parts[i]),
                    ],
                  ],
                ),
              ),
            ),
          ),
          ActionsFooter(
            stacked: true,
            margin: AppSpacing.xl,
            children: [
              if (onOpenMail != null)
                FilledButton.icon(
                  key: AccountKeys.resetOpenMail,
                  onPressed: onOpenMail,
                  icon: const Icon(Icons.open_in_new),
                  label: Text(l10n.accountResetOpenMail),
                ),
              // Sem app de e-mail, "Entendi" é o botão principal.
              if (onOpenMail != null)
                TextButton(
                  key: AccountKeys.resetOk,
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(l10n.accountResetOk),
                )
              else
                FilledButton(
                  key: AccountKeys.resetOk,
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(l10n.accountResetOk),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../data/repositories/account/account_repository.dart';
import '../../../data/repositories/sync/sync_scheduler.dart';
import '../../../routing/routes.dart';
import '../../core/keys/account_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/actions_footer.dart';
import '../../core/widgets/lucena_app_bar.dart';
import '../../core/widgets/lucena_snack_bar.dart';
import '../view_models/account_cubit.dart';
import 'account_flow.dart';
import 'account_password_sheets.dart';
import 'account_widgets.dart';

/// "Criar conta" (canvas `V1ContaCriar`) ou, com [signIn], "Entrar"
/// (`V1ContaEntrar`, com "Esqueci a senha"), por e-mail e senha (§2.12).
/// Cada uma leva à outra pelo link do fim. Com [reauth], só entra de novo
/// (apagar a conta pediu um login recente) e volta `true`.
class AccountEmailScreen extends StatelessWidget {
  const AccountEmailScreen({
    required this.from,
    this.signIn = false,
    this.reauth = false,
    super.key,
  });

  final String from;
  final bool signIn;
  final bool reauth;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (context) => AccountCubit(
      context.read<AccountRepository>(),
      sync: reauth ? null : context.read<SyncScheduler>(),
    ),
    child: _EmailView(from: from, create: !signIn && !reauth, reauth: reauth),
  );
}

class _EmailView extends StatefulWidget {
  const _EmailView({
    required this.from,
    required this.create,
    required this.reauth,
  });

  final String from;
  final bool create;
  final bool reauth;

  @override
  State<_EmailView> createState() => _EmailViewState();
}

class _EmailViewState extends State<_EmailView> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _hidden = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    final cubit = context.read<AccountCubit>();
    FocusScope.of(context).unfocus();
    if (widget.create) {
      cubit.createWithEmail(_email.text, _password.text);
    } else {
      cubit.signInWithEmail(_email.text, _password.text);
    }
  }

  void _done(AccountState state) {
    if (widget.reauth) return context.pop(true);
    continueAfterSignIn(context, state, widget.from);
  }

  // Criar conta e Entrar trocam de lugar: voltar sai das duas.
  void _switch() => context.pushReplacement(
    Routes.accountEmailFrom(widget.from, signIn: widget.create),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final create = widget.create;
    final busy = context.select((AccountCubit cubit) => cubit.state.busy);
    return BlocListener<AccountCubit, AccountState>(
      listener: (context, state) {
        if (state.done) return _done(state);
        final failure = state.failure;
        if (failure != null) {
          showLucenaSnackBar(context, accountFailureText(l10n, failure));
        }
      },
      child: Scaffold(
        key: create ? AccountKeys.createScreen : AccountKeys.signInScreen,
        appBar: LucenaAppBar(
          title: Text(create ? l10n.accountCreate : l10n.accountSignIn),
        ),
        body: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            TextField(
              key: AccountKeys.emailField,
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
              decoration: InputDecoration(
                labelText: l10n.accountEmailField,
                hintText: l10n.accountEmailHint,
                prefixIcon: const Icon(Icons.mail),
              ),
            ),
            SizedBox(height: create ? AppSpacing.lg : AppSpacing.md),
            TextField(
              key: AccountKeys.passwordField,
              controller: _password,
              obscureText: _hidden,
              autocorrect: false,
              enableSuggestions: false,
              textInputAction: TextInputAction.done,
              autofillHints: [
                create ? AutofillHints.newPassword : AutofillHints.password,
              ],
              onSubmitted: busy ? null : (_) => _submit(),
              decoration: InputDecoration(
                labelText: l10n.accountPasswordField,
                helperText: create ? l10n.accountPasswordHelp : null,
                prefixIcon: const Icon(Icons.lock),
                suffixIcon: IconButton(
                  key: AccountKeys.passwordEye,
                  tooltip: _hidden
                      ? l10n.accountShowPassword
                      : l10n.accountHidePassword,
                  icon: Icon(_hidden ? Icons.visibility : Icons.visibility_off),
                  onPressed: () => setState(() => _hidden = !_hidden),
                ),
              ),
            ),
            if (create) ...[
              const SizedBox(height: AppSpacing.lg),
              Text(
                l10n.accountEmailNote,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ] else
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: TextButton(
                  key: AccountKeys.forgotPassword,
                  onPressed: busy
                      ? null
                      : () =>
                            showPasswordResetSheet(context, email: _email.text),
                  child: Text(l10n.accountForgotPassword),
                ),
              ),
          ],
        ),
        bottomNavigationBar: ActionsFooter(
          stacked: true,
          note: create ? const AccountLegalNote(create: true) : null,
          children: [
            FilledButton(
              key: AccountKeys.emailSubmit,
              onPressed: busy ? null : _submit,
              child: Text(create ? l10n.accountCreate : l10n.accountSignIn),
            ),
            if (!widget.reauth)
              AccountSwitchLink(
                key: create ? AccountKeys.toSignIn : AccountKeys.toCreate,
                question: create
                    ? l10n.accountHaveAccount
                    : l10n.accountNoAccount,
                action: create ? l10n.accountSignIn : l10n.accountCreate,
                onPressed: busy ? null : _switch,
              ),
          ],
        ),
      ),
    );
  }
}

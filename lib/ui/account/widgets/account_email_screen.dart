import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../data/repositories/account/account_repository.dart';
import '../../../data/repositories/sync/sync_scheduler.dart';
import '../../core/keys/account_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/actions_footer.dart';
import '../../core/widgets/lucena_app_bar.dart';
import '../../core/widgets/lucena_snack_bar.dart';
import '../view_models/account_cubit.dart';
import 'account_flow.dart';

/// "Continuar com e-mail" (canvas `PropV1PerfilEmail`): criar a conta ou
/// entrar. Com [reauth], só entra de novo (apagar a conta pediu um login
/// recente) e volta `true`.
class AccountEmailScreen extends StatelessWidget {
  const AccountEmailScreen({
    required this.from,
    this.reauth = false,
    super.key,
  });

  final String from;
  final bool reauth;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (context) => AccountCubit(
      context.read<AccountRepository>(),
      sync: reauth ? null : context.read<SyncScheduler>(),
    ),
    child: _EmailView(from: from, reauth: reauth),
  );
}

class _EmailView extends StatefulWidget {
  const _EmailView({required this.from, required this.reauth});

  final String from;
  final bool reauth;

  @override
  State<_EmailView> createState() => _EmailViewState();
}

class _EmailViewState extends State<_EmailView> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  late bool _create = !widget.reauth;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    final cubit = context.read<AccountCubit>();
    FocusScope.of(context).unfocus();
    if (_create) {
      cubit.createWithEmail(_email.text, _password.text);
    } else {
      cubit.signInWithEmail(_email.text, _password.text);
    }
  }

  void _done(AccountState state) {
    if (widget.reauth) return context.pop(true);
    continueAfterSignIn(context, state, widget.from);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
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
        key: AccountKeys.emailScreen,
        appBar: LucenaAppBar(
          centerTitle: true,
          title: Text(l10n.accountEmailTitle),
        ),
        body: ListView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          children: [
            if (!widget.reauth) ...[
              SegmentedButton<bool>(
                showSelectedIcon: false,
                segments: [
                  ButtonSegment(
                    value: true,
                    label: Text(
                      l10n.accountSegCreate,
                      key: AccountKeys.emailSegCreate,
                    ),
                  ),
                  ButtonSegment(
                    value: false,
                    label: Text(
                      l10n.accountSegSignIn,
                      key: AccountKeys.emailSegSignIn,
                    ),
                  ),
                ],
                selected: {_create},
                onSelectionChanged: (value) =>
                    setState(() => _create = value.single),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
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
            const SizedBox(height: AppSpacing.lg),
            TextField(
              key: AccountKeys.passwordField,
              controller: _password,
              obscureText: true,
              autocorrect: false,
              enableSuggestions: false,
              textInputAction: TextInputAction.done,
              autofillHints: [
                _create ? AutofillHints.newPassword : AutofillHints.password,
              ],
              onSubmitted: busy ? null : (_) => _submit(),
              decoration: InputDecoration(
                labelText: l10n.accountPasswordField,
                helperText: _create ? l10n.accountPasswordHelp : null,
                prefixIcon: const Icon(Icons.lock),
              ),
            ),
            if (_create) ...[
              const SizedBox(height: AppSpacing.lg),
              Text(
                l10n.accountEmailNote,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
        bottomNavigationBar: ActionsFooter(
          stacked: true,
          children: [
            FilledButton(
              key: AccountKeys.emailSubmit,
              onPressed: busy ? null : _submit,
              child: Text(_create ? l10n.accountCreate : l10n.accountSegSignIn),
            ),
            if (_create)
              TextButton(
                key: AccountKeys.emailHaveAccount,
                onPressed: busy ? null : () => setState(() => _create = false),
                child: Text(l10n.accountHaveAccountSignIn),
              ),
          ],
        ),
      ),
    );
  }
}

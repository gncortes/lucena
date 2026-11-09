import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../config/view_models/account.dart';
import '../../../routing/routes.dart';
import '../../core/keys/account_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/actions_footer.dart';
import '../../core/widgets/busy_button.dart';
import '../../core/widgets/lucena_app_bar.dart';
import '../../core/widgets/lucena_card.dart';
import '../../core/widgets/lucena_snack_bar.dart';
import '../view_models/account_consent_cubit.dart';
import 'account_flow.dart';
import 'account_widgets.dart';

/// "Termos e privacidade" (H-CON-08, quadros PropV1ContaAceite e
/// PropV1ContaAceiteMarcado): logo depois de criar a conta, o que fica salvo,
/// os direitos e a caixa "Li e aceito"; "Continuar" só liga com ela.
/// [from] é de onde a conta foi aberta; [offline]: a conta não foi lida.
class AccountConsentScreen extends StatelessWidget {
  const AccountConsentScreen({
    required this.from,
    this.offline = false,
    super.key,
  });

  final String from;
  final bool offline;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: createAccountConsentCubit,
    child: _ConsentView(from: from, offline: offline),
  );
}

class _ConsentView extends StatelessWidget {
  const _ConsentView({required this.from, required this.offline});

  final String from;
  final bool offline;

  // Voltar cancela o fluxo e volta à entrada; a conta criada fica.
  void _back(BuildContext context) {
    final router = GoRouter.of(context);
    if (router.canPop()) {
      router.pop();
    } else {
      router.go(Routes.accountEnterFrom(from));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final note = theme.textTheme.bodyMedium?.copyWith(
      color: colors.onSurfaceVariant,
    );
    return BlocConsumer<AccountConsentCubit, AccountConsentState>(
      listenWhen: (before, now) =>
          now.done != before.done || now.failed != before.failed,
      listener: (context, state) {
        if (state.done) {
          context.pushReplacement(afterConsent(from, offline: offline));
        } else {
          showLucenaSnackBar(context, l10n.conPerfilFailed);
        }
      },
      builder: (context, state) {
        final cubit = context.read<AccountConsentCubit>();
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop && !state.busy) _back(context);
          },
          child: Scaffold(
            key: AccountKeys.acceptScreen,
            appBar: LucenaAppBar(
              centerTitle: true,
              leading: BackButton(
                onPressed: state.busy ? null : () => _back(context),
              ),
              title: Text(l10n.conAceiteTitle),
            ),
            body: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                AppSpacing.lg,
              ),
              children: [
                _Card(
                  title: l10n.conAceiteSavedTitle,
                  items: [
                    (Icons.badge, l10n.conAceiteSavedIdentity),
                    (Icons.school, l10n.conAceiteSavedProgress),
                    (Icons.insights, l10n.conAceiteSavedUsage),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                _Card(
                  title: l10n.conAceiteRightsTitle,
                  items: [
                    (Icons.visibility, l10n.conAceiteRightsSee),
                    (Icons.edit, l10n.conAceiteRightsEdit),
                    (Icons.delete, l10n.conAceiteRightsDelete),
                  ],
                  note: l10n.conAceiteRightsWhere,
                ),
                const SizedBox(height: AppSpacing.lg),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xs,
                  ),
                  child: Text(
                    l10n.conAceiteUsage,
                    key: AccountKeys.acceptUsage,
                    style: note,
                  ),
                ),
              ],
            ),
            bottomNavigationBar: ActionsFooter(
              stacked: true,
              noteAfter: -1,
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.xl,
              ),
              note: _CheckRow(
                checked: state.checked,
                onToggle: state.busy ? null : cubit.toggle,
              ),
              children: [
                BusyButton(
                  buttonKey: AccountKeys.acceptContinue,
                  busy: state.busy,
                  label: l10n.conAceiteContinue,
                  onPressed: state.checked ? cubit.accept : null,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Um cartão do aceite: título 16 negrito e itens com ícone azul.
class _Card extends StatelessWidget {
  const _Card({required this.title, required this.items, this.note});

  final String title;
  final List<(IconData, String)> items;
  final String? note;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final body = theme.textTheme.bodyLarge?.copyWith(
      fontSize: 15,
      height: 22 / 15,
    );
    return LucenaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          for (final (icon, text) in items) ...[
            const SizedBox(height: AppSpacing.md),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: colors.primary),
                const SizedBox(width: AppSpacing.md),
                Expanded(child: Text(text, style: body)),
              ],
            ),
          ],
          if (note case final note?) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              note,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// A caixa (alvo 48) e "Li e aceito os Termos de uso e a Política de
/// privacidade", com os dois nomes abrindo as folhas dos textos.
class _CheckRow extends StatelessWidget {
  const _CheckRow({required this.checked, required this.onToggle});

  final bool checked;
  final VoidCallback? onToggle;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 56),
      child: Row(
        children: [
          IconButton(
            key: AccountKeys.acceptCheck,
            onPressed: onToggle,
            isSelected: checked,
            color: colors.onSurfaceVariant,
            icon: const Icon(Icons.check_box_outline_blank),
            selectedIcon: Icon(Icons.check_box, color: colors.primary),
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: LegalLinksText(
              key: AccountKeys.acceptTerms,
              underline: true,
              text: l10n.conAceiteCheck(
                LegalLinksText.terms,
                LegalLinksText.privacy,
              ),
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

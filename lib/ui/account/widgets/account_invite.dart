import 'package:flutter/material.dart';

import '../../core/keys/account_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_icon_size.dart';
import '../../core/theme/app_shape.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/busy_button.dart';
import 'account_widgets.dart';

/// Um benefício do convite: o ícone e a frase.
typedef AccountBenefit = (IconData icon, String text);

/// O convite para criar conta, o componente único de todas as entradas
/// (H-CON-01 a 05): ícone num quadrado, título, texto e os benefícios. As
/// telas (entrada, folha, cartão, compra, passo do tour) mudam só os
/// parâmetros; as ações ficam em [AccountInviteActions].
class AccountInviteHeader extends StatelessWidget {
  const AccountInviteHeader({
    required this.title,
    this.text,
    this.icon = Icons.cloud_sync,
    this.benefits = const [],
    this.titleKey,
    this.textKey,
    this.compact = false,
    super.key,
  });

  final IconData icon;
  final String title;
  final String? text;
  final List<AccountBenefit> benefits;
  final Key? titleKey;
  final Key? textKey;

  /// No cartão e na folha: ícone e título menores.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final text = this.text;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: colors.primaryContainer,
              borderRadius: BorderRadius.circular(AppShape.large),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Icon(
                icon,
                size: compact ? AppIconSize.large : AppIconSize.illustration,
                color: colors.primary,
              ),
            ),
          ),
        ),
        SizedBox(height: compact ? AppSpacing.lg : AppSpacing.xl),
        Text(
          title,
          key: titleKey,
          style:
              (compact
                      ? theme.textTheme.titleLarge
                      : theme.textTheme.headlineMedium)
                  ?.copyWith(fontWeight: FontWeight.w700),
        ),
        if (text != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            text,
            key: textKey,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
        if (benefits.isNotEmpty)
          SizedBox(height: compact ? AppSpacing.lg : AppSpacing.xl),
        for (final (icon, benefit) in benefits)
          Padding(
            padding: EdgeInsets.only(
              bottom: compact ? AppSpacing.md : AppSpacing.lg,
            ),
            child: Row(
              children: [
                Icon(icon, size: AppIconSize.standard, color: colors.primary),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    benefit,
                    style: compact
                        ? theme.textTheme.bodyMedium
                        : theme.textTheme.bodyLarge,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// As ações do convite, para o `ActionsFooter` empilhado (ou uma coluna):
/// "Criar conta com Google" (carregando no próprio botão enquanto entra; os
/// outros travam), "Criar conta com e-mail", "Já tem conta? Entrar" e,
/// quando há [onLater], "Agora não". Sem "Agora não": a compra exige conta
/// (H-CON-05).
List<Widget> accountInviteActions(
  BuildContext context, {
  required Future<void> Function() onGoogle,
  required VoidCallback onEmail,
  required VoidCallback onSignIn,
  VoidCallback? onLater,
  bool busy = false,
  Key googleKey = AccountKeys.google,
  Key emailKey = AccountKeys.email,
  Key signInKey = AccountKeys.toSignIn,
  Key laterKey = AccountKeys.later,
}) {
  final l10n = context.l10n;
  return [
    BusyButton(
      buttonKey: googleKey,
      style: BusyButtonStyle.outlined,
      icon: Icons.account_circle,
      label: l10n.conEntradaGoogle,
      busy: busy,
      onPressed: onGoogle,
    ),
    OutlinedButton.icon(
      key: emailKey,
      onPressed: busy ? null : onEmail,
      icon: const Icon(Icons.mail),
      label: Text(l10n.accountCreateWithEmail),
    ),
    AccountSwitchLink(
      key: signInKey,
      question: l10n.accountHaveAccount,
      action: l10n.accountSignIn,
      onPressed: busy ? null : onSignIn,
    ),
    if (onLater != null)
      TextButton(
        key: laterKey,
        onPressed: busy ? null : onLater,
        child: Text(l10n.accountLater),
      ),
  ];
}

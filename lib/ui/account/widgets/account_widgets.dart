import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/keys/account_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../settings/widgets/about_screen.dart';

/// "Ao continuar, você concorda com os Termos de uso e a Política de
/// privacidade." (§2.12), com os dois nomes abrindo as páginas no site.
/// Com [create], "Ao criar a conta...".
class AccountLegalNote extends StatefulWidget {
  const AccountLegalNote({this.create = false, super.key});

  final bool create;

  @override
  State<AccountLegalNote> createState() => _AccountLegalNoteState();
}

class _AccountLegalNoteState extends State<AccountLegalNote> {
  final _terms = TapGestureRecognizer();
  final _privacy = TapGestureRecognizer();

  // Marcam onde entram os links no texto traduzido.
  static const _termsMark = '\u0001';
  static const _privacyMark = '\u0002';

  @override
  void dispose() {
    _terms.dispose();
    _privacy.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final language = Localizations.localeOf(context).languageCode;
    _terms.onTap = () => launchUrl(
      AboutScreen.termsFor(language),
      mode: LaunchMode.externalApplication,
    );
    _privacy.onTap = () => launchUrl(
      AboutScreen.privacyFor(language),
      mode: LaunchMode.externalApplication,
    );
    final text = widget.create
        ? l10n.accountLegalCreate(_termsMark, _privacyMark)
        : l10n.accountLegalContinue(_termsMark, _privacyMark);
    final link = TextStyle(color: colors.primary, fontWeight: FontWeight.w600);
    final spans = <InlineSpan>[];
    var rest = text;
    while (rest.isNotEmpty) {
      final terms = rest.indexOf(_termsMark);
      final marks = [terms, rest.indexOf(_privacyMark)].where((i) => i >= 0);
      if (marks.isEmpty) {
        spans.add(TextSpan(text: rest));
        break;
      }
      final next = marks.reduce(math.min);
      if (next > 0) spans.add(TextSpan(text: rest.substring(0, next)));
      final isTerms = next == terms;
      spans.add(
        TextSpan(
          text: isTerms ? l10n.aboutTerms : l10n.aboutPrivacy,
          style: link,
          recognizer: isTerms ? _terms : _privacy,
        ),
      );
      rest = rest.substring(next + 1);
    }
    return Text.rich(
      TextSpan(children: spans),
      key: AccountKeys.legal,
      textAlign: TextAlign.center,
      style: theme.textTheme.bodySmall?.copyWith(
        color: colors.onSurfaceVariant,
      ),
    );
  }
}

/// "Já tem conta? **Entrar**" e "Não tem conta? **Criar conta**": a
/// pergunta em cinza e a ação em azul.
class AccountSwitchLink extends StatelessWidget {
  const AccountSwitchLink({
    required this.question,
    required this.action,
    required this.onPressed,
    super.key,
  });

  final String question;
  final String action;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return TextButton(
      onPressed: onPressed,
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '$question ',
              style: TextStyle(
                color: colors.onSurfaceVariant,
                fontWeight: FontWeight.w400,
              ),
            ),
            TextSpan(
              text: action,
              style: TextStyle(
                color: colors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

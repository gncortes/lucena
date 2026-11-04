import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../../domain/models/legal_document.dart';

import '../../core/keys/account_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../settings/widgets/about_screen.dart';
import '../../legal/widgets/legal_sheet.dart';

/// "Ao continuar, você concorda com os Termos de uso e a Política de
/// privacidade." (§2.12), com os dois nomes abrindo as páginas no site.
/// Com [create], "Ao criar a conta...".
class AccountLegalNote extends StatelessWidget {
  const AccountLegalNote({this.create = false, super.key});

  final bool create;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return LegalLinksText(
      key: AccountKeys.legal,
      text: create
          ? l10n.accountLegalCreate(
              LegalLinksText.terms,
              LegalLinksText.privacy,
            )
          : l10n.accountLegalContinue(
              LegalLinksText.terms,
              LegalLinksText.privacy,
            ),
      textAlign: TextAlign.center,
      style: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}

/// Um texto com "Termos de uso" e "Política de privacidade" em link (azul,
/// 600, [underline]), cada um abrindo a folha do texto (H-CON-22). O [text]
/// traduzido marca onde entram os nomes com [terms] e [privacy].
class LegalLinksText extends StatefulWidget {
  const LegalLinksText({
    required this.text,
    this.style,
    this.textAlign = TextAlign.start,
    this.underline = false,
    super.key,
  });

  static const terms = '\u0001';
  static const privacy = '\u0002';

  final String text;
  final TextStyle? style;
  final TextAlign textAlign;
  final bool underline;

  @override
  State<LegalLinksText> createState() => _LegalLinksTextState();
}

class _LegalLinksTextState extends State<LegalLinksText> {
  final _terms = TapGestureRecognizer();
  final _privacy = TapGestureRecognizer();

  @override
  void dispose() {
    _terms.dispose();
    _privacy.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = Theme.of(context).colorScheme;
    final language = Localizations.localeOf(context).languageCode;
    _terms.onTap = () => openLegal(
      context,
      LegalKind.terms,
      website: AboutScreen.termsFor(language),
    );
    _privacy.onTap = () => openLegal(
      context,
      LegalKind.privacy,
      website: AboutScreen.privacyFor(language),
    );
    final link = TextStyle(
      color: colors.primary,
      fontWeight: FontWeight.w600,
      decoration: widget.underline ? TextDecoration.underline : null,
      decorationColor: colors.primary,
    );
    final spans = <InlineSpan>[];
    var rest = widget.text;
    while (rest.isNotEmpty) {
      final terms = rest.indexOf(LegalLinksText.terms);
      final marks = [
        terms,
        rest.indexOf(LegalLinksText.privacy),
      ].where((i) => i >= 0);
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
      textAlign: widget.textAlign,
      style: widget.style,
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

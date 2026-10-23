import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/models/challenge_link.dart';
import '../../../routing/routes.dart';
import '../../core/keys/settings_keys.dart';
import '../../core/l10n/l10n.dart';

/// Só para build de teste: o QA cola um link de desafio e o app o abre como se
/// viesse de fora. Serve até a E1.01 ligar os App Links de verdade.
Future<void> showOpenLinkDialog(BuildContext context) async {
  final router = GoRouter.of(context);
  final link = await showDialog<ChallengeLink>(
    context: context,
    builder: (_) => const _OpenLinkDialog(),
  );
  if (link != null) router.push(Routes.challenge(link));
}

class _OpenLinkDialog extends StatefulWidget {
  const _OpenLinkDialog();

  @override
  State<_OpenLinkDialog> createState() => _OpenLinkDialogState();
}

class _OpenLinkDialogState extends State<_OpenLinkDialog> {
  final _controller = TextEditingController();
  bool _invalid = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _open() {
    final uri = Uri.tryParse(_controller.text.trim());
    final link = uri == null ? null : ChallengeLink.tryParse(uri);
    if (link == null) {
      setState(() => _invalid = true);
      return;
    }
    Navigator.of(context).pop(link);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      title: Text(l10n.devOpenLinkTitle),
      content: TextField(
        key: SettingsKeys.openLinkField,
        controller: _controller,
        autofocus: true,
        keyboardType: TextInputType.url,
        decoration: InputDecoration(
          hintText: l10n.devOpenLinkHint,
          errorText: _invalid ? l10n.devOpenLinkInvalid : null,
        ),
        onChanged: (_) {
          if (_invalid) setState(() => _invalid = false);
        },
        onSubmitted: (_) => _open(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
        ),
        FilledButton(
          key: SettingsKeys.openLinkConfirm,
          onPressed: _open,
          child: Text(l10n.devOpenLinkOpen),
        ),
      ],
    );
  }
}

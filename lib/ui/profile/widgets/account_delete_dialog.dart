import 'package:flutter/material.dart';

import '../../core/keys/account_keys.dart';
import '../../core/l10n/l10n.dart';

/// "Apagar a conta?" (canvas `PropV1ApagarConta`). Devolve `true` só com
/// "Apagar".
Future<bool> showAccountDeleteDialog(BuildContext context) async {
  final l10n = context.l10n;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      key: AccountKeys.deleteDialog,
      icon: const Icon(Icons.delete),
      title: Text(l10n.accountDeleteTitle),
      content: Text(l10n.accountDeleteText),
      actions: [
        TextButton(
          key: AccountKeys.deleteCancel,
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.accountDeleteCancel),
        ),
        TextButton(
          key: AccountKeys.deleteConfirm,
          style: TextButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.error,
          ),
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(l10n.accountDeleteConfirm),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}

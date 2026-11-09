import 'package:flutter/material.dart';

/// O diálogo de confirmação do Lucena: fundo na superfície mais clara, sem
/// tinta, título de 22/1,4 e corpo de 14/20, com a folga do canvas. Serve a
/// toda pergunta curta com ações de texto (cancelar e confirmar).
class LucenaDialog extends StatelessWidget {
  const LucenaDialog({
    required this.title,
    required this.content,
    required this.actions,
    super.key,
  });

  final Widget title;
  final Widget content;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      backgroundColor: theme.colorScheme.surfaceContainerLowest,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      titleTextStyle: theme.textTheme.titleLarge?.copyWith(
        height: 1.4,
        letterSpacing: 0,
      ),
      titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
      contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
      contentTextStyle: theme.textTheme.bodyMedium?.copyWith(
        height: 20 / 14,
        letterSpacing: 0,
      ),
      // The 48 dp touch targets add 6 dp above/below the Canvas's 36 dp
      // visual button row; those 6 dp come from its surrounding whitespace.
      actionsPadding: const EdgeInsets.fromLTRB(24, 14, 24, 18),
      title: title,
      content: content,
      actions: actions,
    );
  }
}

/// Abre um [LucenaDialog] com duas ações de texto. Devolve `true` ao
/// confirmar, `false` ao cancelar e `null` se o diálogo for dispensado.
/// [confirmKey] fica no botão de confirmar.
Future<bool?> showLucenaConfirm(
  BuildContext context, {
  required String title,
  required Widget content,
  required String cancelLabel,
  required String confirmLabel,
  Key? confirmKey,
}) => showDialog<bool>(
  context: context,
  builder: (context) => LucenaDialog(
    title: Text(title),
    content: content,
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context, false),
        child: Text(cancelLabel),
      ),
      TextButton(
        key: confirmKey,
        onPressed: () => Navigator.pop(context, true),
        child: Text(confirmLabel),
      ),
    ],
  ),
);

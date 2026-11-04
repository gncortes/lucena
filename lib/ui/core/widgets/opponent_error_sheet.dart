import 'package:flutter/material.dart';

import '../keys/opponent_error_keys.dart';
import '../l10n/l10n.dart';
import '../theme/app_button.dart';
import '../theme/app_button_text.dart';
import '../theme/app_spacing.dart';
import 'lucena_sheet.dart';
import 'sheet_header.dart';

/// A folha do adversário que não responde (H-PAR-18): aparece depois da 3ª
/// falha seguida, sem ✕ e sem fechar pelo voltar. Devolve `true` para
/// "Tentar novamente" e `false` para "Sair" (a partida continua gravada, com o
/// relógio parado).
Future<bool> showOpponentErrorSheet(BuildContext context) async {
  final retry = await showLucenaSheet<bool>(
    context,
    sheetKey: OpponentErrorKeys.sheet,
    dismissible: false,
    builder: (context) {
      final l10n = context.l10n;
      return SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SheetHeader(
                title: l10n.partidaOpponentErrorTitle,
                hint: l10n.partidaOpponentErrorHint,
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl,
                  0,
                  AppSpacing.xl,
                  AppSpacing.xl,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: AppSpacing.sm,
                  children: [
                    FilledButton(
                      key: OpponentErrorKeys.retry,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(kButtonHeight),
                        textStyle: AppButtonText.footer(context),
                      ),
                      onPressed: () => Navigator.of(context).pop(true),
                      child: Text(
                        l10n.partidaOpponentErrorRetry,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    OutlinedButton(
                      key: OpponentErrorKeys.leave,
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(kButtonHeight),
                        textStyle: AppButtonText.footer(context),
                      ),
                      onPressed: () => Navigator.of(context).pop(false),
                      child: Text(
                        l10n.partidaOpponentErrorLeave,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
  return retry ?? false;
}

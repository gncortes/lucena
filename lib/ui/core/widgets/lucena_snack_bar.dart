import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../keys/core_keys.dart';
import '../theme/app_icon_size.dart';
import '../theme/app_motion.dart';
import '../theme/app_spacing.dart';

/// O aviso do app (canvas `CompSnackbar`): fundo do tema, ícone opcional,
/// uma ação opcional e 4 s na tela. Troca o aviso que estiver aberto.
/// Com [top], sobe para logo abaixo da barra do título.
ScaffoldFeatureController<SnackBar, SnackBarClosedReason> showLucenaSnackBar(
  BuildContext context,
  String text, {
  IconData? icon,
  SnackBarAction? action,
  bool top = false,
  Key? key,
}) {
  final messenger = ScaffoldMessenger.of(context);
  final media = MediaQuery.of(context);
  final colors = Theme.of(context).colorScheme;
  messenger.hideCurrentSnackBar();
  return messenger.showSnackBar(
    SnackBar(
      key: key ?? CoreKeys.snackBar,
      duration: AppMotion.snackBar,
      dismissDirection: top ? DismissDirection.up : DismissDirection.down,
      action: action == null
          ? null
          : SnackBarAction(
              key: action.key,
              label: action.label,
              textColor: colors.inversePrimary,
              onPressed: action.onPressed,
            ),
      // No alto, logo abaixo da barra do título.
      margin: top
          ? EdgeInsets.only(
              left: AppSpacing.lg,
              right: AppSpacing.lg,
              bottom: math.max(
                AppSpacing.lg,
                media.size.height -
                    media.padding.top -
                    kToolbarHeight -
                    media.viewInsets.bottom -
                    110,
              ),
            )
          : null,
      content: Row(
        spacing: AppSpacing.md,
        children: [
          if (icon != null)
            Icon(
              icon,
              size: AppIconSize.button,
              color: colors.onInverseSurface,
            ),
          Expanded(child: Text(text)),
        ],
      ),
    ),
  );
}

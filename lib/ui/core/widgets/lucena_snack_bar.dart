import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../keys/core_keys.dart';
import '../theme/app_icon_size.dart';
import '../theme/app_motion.dart';
import '../theme/app_spacing.dart';

/// O aviso do app (canvas `CompSnackbar`): fundo do tema, ícone opcional,
/// uma ação opcional e 4 s na tela. Troca o aviso que estiver aberto.
/// Com [top], sobe para logo abaixo da barra do título e fica 3 s; com
/// [topAt] (a altura na tela em que o aviso começa), desce até ali para não
/// cobrir o que está logo abaixo da barra.
ScaffoldFeatureController<SnackBar, SnackBarClosedReason> showLucenaSnackBar(
  BuildContext context,
  String text, {
  IconData? icon,
  SnackBarAction? action,
  bool top = false,
  double? topAt,
  Key? key,
}) {
  final messenger = ScaffoldMessenger.of(context);
  final media = MediaQuery.of(context);
  final theme = Theme.of(context);
  final colors = theme.colorScheme;
  messenger.hideCurrentSnackBar();
  // O SnackBar se apoia no pé da tela: para começar em [topAt], a margem de
  // baixo desconta a altura do próprio aviso, medida pelo texto.
  double bottomFor(double y) {
    final style =
        theme.snackBarTheme.contentTextStyle ?? theme.textTheme.bodyMedium;
    final width =
        media.size.width -
        2 * AppSpacing.lg -
        2 * _snackPaddingH -
        (icon == null ? 0 : AppIconSize.button + AppSpacing.md);
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: Directionality.of(context),
      textScaler: media.textScaler,
    )..layout(maxWidth: math.max(0, width));
    final height =
        math.max(painter.height, icon == null ? 0 : AppIconSize.button) +
        2 * _snackPaddingV;
    painter.dispose();
    // O Scaffold já ergue o aviso acima da faixa de baixo do sistema.
    return media.size.height -
        y -
        height -
        media.viewInsets.bottom -
        media.padding.bottom;
  }

  return messenger.showSnackBar(
    SnackBar(
      key: key ?? CoreKeys.snackBar,
      duration: top ? AppMotion.snackBarAlto : AppMotion.snackBar,
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
                topAt != null
                    ? bottomFor(topAt)
                    : media.size.height -
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

// O recheio do SnackBar flutuante sem ação (Flutter: 16 dos lados, 14 em
// cima e embaixo).
const _snackPaddingH = 16.0;
const _snackPaddingV = 14.0;

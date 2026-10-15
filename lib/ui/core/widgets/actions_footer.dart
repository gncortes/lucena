import 'package:flutter/material.dart';

import '../theme/app_button.dart';
import '../theme/app_spacing.dart';

/// O rodapé de dois botões (canvas `CompRodapeAcoes`, `empilhado="auto"`,
/// T72): lado a lado, cada um com metade da linha, o contornado no começo e o
/// cheio no fim. Empilha (o cheio em cima, os dois na largura toda) quando um
/// rótulo tem 3 palavras ou mais, ou, de reserva, quando um não cabe na
/// metade da linha: nunca quebra o rótulo. Vão de 8 nos dois arranjos.
class ActionsFooter extends StatelessWidget {
  const ActionsFooter({
    required this.primaryLabel,
    required this.onPrimary,
    required this.secondaryLabel,
    required this.onSecondary,
    this.primaryIcon,
    this.secondaryIcon,
    this.primaryKey,
    this.secondaryKey,
    super.key,
  });

  final String primaryLabel;
  final IconData? primaryIcon;
  final VoidCallback? onPrimary;
  final Key? primaryKey;

  final String secondaryLabel;
  final IconData? secondaryIcon;
  final VoidCallback? onSecondary;
  final Key? secondaryKey;

  /// O padding do canvas (`estilo="simples"`): 8 em cima, 16 dos lados e 12
  /// embaixo.
  static const padding = EdgeInsets.fromLTRB(
    AppSpacing.screen,
    AppSpacing.sm,
    AppSpacing.screen,
    AppSpacing.md,
  );

  static const gap = AppSpacing.sm;

  /// Quantas palavras empilham os botões.
  static const stackWords = 3;

  static int _words(String text) =>
      text.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;

  /// A largura que o botão pede: o rótulo na letra do botão e o padding do
  /// Material 3 (24 dos lados; com ícone, 16 no começo, ícone 18 e 8 até o
  /// texto).
  static double _buttonWidth(BuildContext context, String label, bool icon) {
    final painter = TextPainter(
      text: TextSpan(
        text: label,
        style: Theme.of(context).textTheme.labelLarge,
      ),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: 1,
    )..layout();
    final width = painter.width;
    painter.dispose();
    return width + (icon ? 16 + 18 + 8 + 24 : 24 + 24);
  }

  /// Se os botões empilham numa linha de [width] (a largura do rodapé, com o
  /// padding).
  bool stacks(BuildContext context, double width) {
    if (_words(primaryLabel) >= stackWords ||
        _words(secondaryLabel) >= stackWords) {
      return true;
    }
    final half = (width - padding.horizontal - gap) / 2;
    return _buttonWidth(context, primaryLabel, primaryIcon != null) > half ||
        _buttonWidth(context, secondaryLabel, secondaryIcon != null) > half;
  }

  @override
  Widget build(BuildContext context) {
    const size = Size.fromHeight(kButtonHeight);
    final primaryIcon = this.primaryIcon;
    final primary = primaryIcon == null
        ? FilledButton(
            key: primaryKey,
            style: FilledButton.styleFrom(minimumSize: size),
            onPressed: onPrimary,
            child: Text(primaryLabel, maxLines: 1),
          )
        : FilledButton.icon(
            key: primaryKey,
            style: FilledButton.styleFrom(minimumSize: size),
            onPressed: onPrimary,
            icon: Icon(primaryIcon),
            label: Text(primaryLabel, maxLines: 1),
          );
    final secondaryIcon = this.secondaryIcon;
    final secondary = secondaryIcon == null
        ? OutlinedButton(
            key: secondaryKey,
            style: OutlinedButton.styleFrom(minimumSize: size),
            onPressed: onSecondary,
            child: Text(secondaryLabel, maxLines: 1),
          )
        : OutlinedButton.icon(
            key: secondaryKey,
            style: OutlinedButton.styleFrom(minimumSize: size),
            onPressed: onSecondary,
            icon: Icon(secondaryIcon),
            label: Text(secondaryLabel, maxLines: 1),
          );
    return Padding(
      padding: padding,
      child: LayoutBuilder(
        builder: (context, box) {
          if (stacks(context, box.maxWidth + padding.horizontal)) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              spacing: gap,
              children: [primary, secondary],
            );
          }
          return Row(
            spacing: gap,
            children: [
              Expanded(child: secondary),
              Expanded(child: primary),
            ],
          );
        },
      ),
    );
  }
}

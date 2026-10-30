import 'package:flutter/material.dart';

import '../keys/core_keys.dart';
import '../theme/app_button.dart';
import '../theme/app_button_text.dart';
import '../theme/app_spacing.dart';

/// O rodapé de ações das telas (E1.08, D18; canvas `CompRodapeAcoes`): na cor
/// de quem está atrás, sem sombra, faixa nem divisor, com margem 16 dos lados
/// e 8 em cima e embaixo (mais a área segura). Cada filho ganha a altura de
/// 52 dos botões de rodapé (D19) e o texto de 16/24: ninguém declara altura
/// nem letra por fora.
///
/// Os filhos ficam lado a lado, cada um com a mesma largura, ou um sobre o
/// outro ([stacked], o principal em cima). [fade] só serve à Aula de final,
/// onde o conteúdo rola por baixo: o fundo vira um degradê que some no alto.
class ActionsFooter extends StatelessWidget {
  const ActionsFooter({
    required this.children,
    this.fade = false,
    this.stacked = false,
    this.margin = AppSpacing.lg,
    this.padding,
    this.note,
    this.noteAfter,
    super.key,
  });

  final List<Widget> children;

  /// Um texto curto embaixo dos botões, na altura dele (o aviso dos termos
  /// na conta).
  final Widget? note;

  /// Com [stacked], a [note] entra logo depois deste filho em vez de no fim
  /// (o aviso que fala do botão fica colado nele).
  final int? noteAfter;
  final bool fade;
  final bool stacked;

  /// A margem dos lados: 16 na tela; 24 na folha e no painel da Nova partida.
  final double margin;

  /// Canvas variants can override the outer spacing while keeping the same buttons.
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final background = Theme.of(context).scaffoldBackgroundColor;
    final note = this.note;
    final after = stacked ? noteAfter : null;
    final items = [
      for (final (i, child) in children.indexed) ...[
        stacked
            ? SizedBox(height: kButtonHeight, child: child)
            : Expanded(
                child: SizedBox(height: kButtonHeight, child: child),
              ),
        if (note != null && i == after) note,
      ],
    ];
    final buttons = stacked
        ? Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: AppSpacing.sm,
            children: items,
          )
        : Row(spacing: AppSpacing.sm, children: items);
    return DecoratedBox(
      key: CoreKeys.actionsFooter,
      decoration: BoxDecoration(
        gradient: fade
            ? LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [background.withValues(alpha: 0), background],
                stops: const [0, 0.35],
              )
            : null,
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding:
              padding ??
              EdgeInsets.fromLTRB(
                margin,
                fade ? AppSpacing.xl : AppSpacing.sm,
                margin,
                AppSpacing.sm,
              ),
          child: FooterButtonTheme(
            child: note == null || after != null
                ? buttons
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: AppSpacing.sm,
                    children: [buttons, note],
                  ),
          ),
        ),
      ),
    );
  }
}

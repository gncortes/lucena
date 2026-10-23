import 'package:flutter/material.dart';

import '../theme/app_button.dart';
import '../theme/app_button_text.dart';
import '../theme/app_spacing.dart';
import 'round_footer_button.dart';

/// Um botão do rodapé do exercício.
class ExerciseAction {
  const ExerciseAction({
    required this.label,
    required this.onPressed,
    required this.key,
    this.primary = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final Key key;

  /// Cheio (azul); senão, só o contorno.
  final bool primary;
}

/// A Dica de sempre à esquerda: só a lâmpada, num botão redondo igual aos
/// outros ícones do rodapé (T73). [label] (o que a dica custa agora) vai no
/// tooltip e no rótulo de acessibilidade.
class ExerciseHintButton extends StatelessWidget {
  const ExerciseHintButton({
    required this.label,
    required this.onPressed,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => RoundFooterButton(
    icon: Icons.lightbulb_outline,
    tooltip: label,
    onPressed: onPressed,
  );
}

/// O rodapé do exercício: a Dica à esquerda e até dois botões de mesma
/// largura à direita; com [fill], os botões dividem a largura toda (o convite
/// "Voltar | Vamos praticar").
class ExerciseActions extends StatelessWidget {
  const ExerciseActions({
    this.hint,
    this.actions = const [],
    this.fill = false,
    this.padding = const EdgeInsetsDirectional.fromSTEB(
      AppSpacing.lg,
      AppSpacing.sm,
      AppSpacing.lg,
      AppSpacing.lg,
    ),
    this.color,
    this.leading,
    this.hug = false,
    super.key,
  }) : assert(actions.length <= 2);

  final Widget? hint;

  /// Colado à esquerda dos botões (o ↻ do fim da demonstração da lição
  /// roteirizada, T70).
  final Widget? leading;
  final List<ExerciseAction> actions;
  final bool fill;

  /// Os botões crescem até caber o rótulo numa linha só (se houver espaço),
  /// com [actionWidth] de mínimo (lição roteirizada, canvas `T70-etapa1-estados`: "Ver linha
  /// principal" não quebra).
  final bool hug;

  /// Margem lateral de 16, igual à das outras telas (Gabriel, 14/10/2026).
  final EdgeInsetsGeometry padding;

  /// O fundo do rodapé; sem ele, branco (pg. 3.1/4.7).
  final Color? color;

  /// A largura de cada botão à direita (pg. 4.7).
  static const actionWidth = 124.0;
  static const gap = 8.0;

  Widget _button(BuildContext context, ExerciseAction action) {
    final style = ButtonStyle(
      minimumSize: const WidgetStatePropertyAll(Size(0, kButtonHeightCompact)),
      // Com [hug], o botão do canvas: folga de 22 e letra 16.
      padding: WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: hug ? 22 : 8),
      ),
      // Botão de rodapé: 16/24 (CompBotao); o de cartão fica 14/20.
      textStyle: WidgetStatePropertyAll(
        AppButtonText.footer(context)
            ?.copyWith(fontWeight: hug ? FontWeight.w500 : null),
      ),
    );
    final label = Text(action.label, maxLines: 2, textAlign: TextAlign.center);
    return action.primary
        ? FilledButton(
            key: action.key,
            style: style,
            onPressed: action.onPressed,
            child: label,
          )
        : OutlinedButton(
            key: action.key,
            style: style,
            onPressed: action.onPressed,
            child: label,
          );
  }

  /// Numa linha enquanto couber; numa tela estreita, o contorno quebra em duas
  /// primeiro, e o principal só quebra se nem sozinho couber.
  Widget _hugRow() => LayoutBuilder(
    builder: (context, box) {
      final others = actions.where((a) => !a.primary).length;
      final primaryMax = (box.maxWidth - others * (actionWidth + gap)).clamp(
        actionWidth,
        double.infinity,
      );
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < actions.length; i++) ...[
            if (i > 0) const SizedBox(width: gap),
            Flexible(
              flex: actions[i].primary ? 0 : 1,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minWidth: actionWidth,
                  maxWidth: actions[i].primary ? primaryMax : double.infinity,
                ),
                child: _button(context, actions[i]),
              ),
            ),
          ],
        ],
      );
    },
  );

  @override
  Widget build(BuildContext context) {
    final buttons = <Widget>[
      for (var i = 0; i < actions.length; i++) ...[
        if (i > 0) const SizedBox(width: gap),
        Expanded(child: _button(context, actions[i])),
      ],
    ];
    final row = hug && actions.isNotEmpty ? _hugRow() : null;
    final maxWidth =
        actions.length * actionWidth + (actions.length - 1).clamp(0, 1) * gap;
    final colors = Theme.of(context).colorScheme;
    // Rodapé sobre superfície branca, sem linha em cima (Gabriel, 14/10/2026).
    return DecoratedBox(
      decoration: BoxDecoration(color: color ?? colors.surfaceContainerLowest),
      child: Padding(
        padding: padding,
        child: Row(
          children: [
            ?hint,
            if (fill)
              ...buttons.isEmpty
                  ? const <Widget>[]
                  : [Expanded(child: Row(children: buttons))]
            else if (buttons.isNotEmpty)
              Expanded(
                child: Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: Padding(
                    padding: EdgeInsetsDirectional.only(
                      start: hint == null ? 0 : gap,
                    ),
                    child: leading == null
                        ? row ??
                              ConstrainedBox(
                                constraints: BoxConstraints(maxWidth: maxWidth),
                                child: Row(children: buttons),
                              )
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              leading!,
                              const SizedBox(width: gap),
                              if (row != null)
                                Flexible(child: row)
                              else
                                ConstrainedBox(
                                  constraints: BoxConstraints(
                                    maxWidth: maxWidth,
                                  ),
                                  child: Row(children: buttons),
                                ),
                            ],
                          ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

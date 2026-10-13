import 'package:flutter/material.dart';

import 'one_line.dart';

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

/// A Dica de sempre à esquerda (T70, `exercise_screen.dart`): contorno com
/// lâmpada, 48 dp.
class ExerciseHintButton extends StatelessWidget {
  const ExerciseHintButton({
    required this.label,
    required this.onPressed,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
    style: OutlinedButton.styleFrom(
      minimumSize: const Size(0, 48),
      backgroundColor: Theme.of(context).colorScheme.surface,
    ),
    onPressed: onPressed,
    icon: const Icon(Icons.lightbulb_outline),
    label: OneLine(label),
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
    this.padding = const EdgeInsetsDirectional.fromSTEB(8, 8, 8, 16),
    super.key,
  }) : assert(actions.length <= 2);

  final Widget? hint;
  final List<ExerciseAction> actions;
  final bool fill;
  final EdgeInsetsGeometry padding;

  /// A largura de cada botão à direita (pg. 4.7).
  static const actionWidth = 124.0;
  static const gap = 8.0;

  Widget _button(ExerciseAction action) {
    final style = ButtonStyle(
      minimumSize: const WidgetStatePropertyAll(Size(0, 48)),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: 8),
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

  @override
  Widget build(BuildContext context) {
    final buttons = <Widget>[
      for (var i = 0; i < actions.length; i++) ...[
        if (i > 0) const SizedBox(width: gap),
        Expanded(child: _button(actions[i])),
      ],
    ];
    final maxWidth =
        actions.length * actionWidth + (actions.length - 1).clamp(0, 1) * gap;
    return Padding(
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
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxWidth),
                    child: Row(children: buttons),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

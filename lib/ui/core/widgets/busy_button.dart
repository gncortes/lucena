import 'dart:async';

import 'package:flutter/material.dart';

import '../keys/core_keys.dart';

/// O estilo do [BusyButton]: os quatro botões do Material e o destrutivo
/// (preenchido na cor de erro, "Excluir minha conta").
enum BusyButtonStyle { filled, tonal, outlined, text, destructive }

/// Botão que mostra o carregando dentro dele enquanto a ação roda (T85-D0,
/// memória carregamento-shimmer). Enquanto carrega, não aceita outro toque e
/// guarda a largura do rótulo, para nada pular; o leitor de tela continua
/// lendo o rótulo.
///
/// O carregando liga sozinho enquanto o `Future` de [onPressed] não termina,
/// ou de fora com [busy] (o view model avisa que está salvando).
class BusyButton extends StatefulWidget {
  const BusyButton({
    required this.label,
    required this.onPressed,
    this.busy,
    this.icon,
    this.style = BusyButtonStyle.filled,
    this.buttonKey,
    super.key,
  });

  final String label;
  final FutureOr<void> Function()? onPressed;
  final bool? busy;
  final IconData? icon;
  final BusyButtonStyle style;

  /// Key do botão do Material por dentro, para quem confere `onPressed`.
  final Key? buttonKey;

  @override
  State<BusyButton> createState() => _BusyButtonState();
}

class _BusyButtonState extends State<BusyButton> {
  bool _running = false;

  bool get _busy => _running || (widget.busy ?? false);

  Future<void> _run() async {
    final action = widget.onPressed;
    if (_busy || action == null) return;
    setState(() => _running = true);
    try {
      await Future<void>.sync(action);
    } finally {
      if (mounted) setState(() => _running = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final onPressed = _busy || widget.onPressed == null ? null : _run;
    final child = _BusyContent(
      label: widget.label,
      icon: widget.icon,
      busy: _busy,
    );
    return switch (widget.style) {
      BusyButtonStyle.filled => FilledButton(
        key: widget.buttonKey,
        onPressed: onPressed,
        child: child,
      ),
      BusyButtonStyle.tonal => FilledButton.tonal(
        key: widget.buttonKey,
        onPressed: onPressed,
        child: child,
      ),
      BusyButtonStyle.outlined => OutlinedButton(
        key: widget.buttonKey,
        onPressed: onPressed,
        child: child,
      ),
      BusyButtonStyle.text => TextButton(
        key: widget.buttonKey,
        onPressed: onPressed,
        child: child,
      ),
      BusyButtonStyle.destructive => FilledButton(
        key: widget.buttonKey,
        style: FilledButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.error,
          foregroundColor: Theme.of(context).colorScheme.onError,
        ),
        onPressed: onPressed,
        child: child,
      ),
    };
  }
}

/// Rótulo (e ícone) do botão; carregando, o rótulo some sem perder o espaço
/// e o círculo aparece no meio, na cor do texto do botão.
class _BusyContent extends StatelessWidget {
  const _BusyContent({
    required this.label,
    required this.icon,
    required this.busy,
  });

  final String label;
  final IconData? icon;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final style = DefaultTextStyle.of(context).style;
    final color = style.color ?? IconTheme.of(context).color;
    final text = busy
        // Invisível e fora do find.text: só guarda a largura.
        ? RichText(
            text: TextSpan(
              text: label,
              style: style.copyWith(color: Colors.transparent),
            ),
            textScaler: MediaQuery.textScalerOf(context),
            maxLines: 1,
          )
        : Text(label);
    final content = icon == null
        ? text
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: busy ? Colors.transparent : null),
              const SizedBox(width: 8),
              Flexible(child: text),
            ],
          );
    if (!busy) return content;
    return Semantics(
      label: label,
      child: ExcludeSemantics(
        child: Stack(
          alignment: Alignment.center,
          children: [
            content,
            SizedBox.square(
              key: CoreKeys.busySpinner,
              dimension: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: color),
            ),
          ],
        ),
      ),
    );
  }
}

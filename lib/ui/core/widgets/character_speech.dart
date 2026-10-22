import 'package:flutter/material.dart';

import '../theme/app_motion.dart';

/// Um texto que aparece letra por letra, como alguém falando. O espaço do
/// texto inteiro fica reservado desde o começo: o balão não muda de tamanho
/// enquanto as letras chegam.
class TypewriterText extends StatefulWidget {
  const TypewriterText(
    this.text, {
    this.style,
    this.maxLines,
    this.shrink = true,
    this.prefix,
    super.key,
  });

  final String text;
  final TextStyle? style;
  final int? maxLines;

  /// A letra diminui até a fala caber (até 60 %). Desligado, o que não cabe
  /// ganha "…".
  final bool shrink;

  /// Algo antes do texto, visível desde o começo (o selo "Dica").
  final InlineSpan? prefix;

  /// Quanto cada letra leva para aparecer.
  static const perLetter = AppMotion.typewriterLetter;

  @override
  State<TypewriterText> createState() => _TypewriterTextState();
}

class _TypewriterTextState extends State<TypewriterText>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(vsync: this);

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void didUpdateWidget(TypewriterText old) {
    super.didUpdateWidget(old);
    if (old.text != widget.text) _start();
  }

  void _start() {
    _controller
      ..duration = TypewriterText.perLetter * widget.text.length
      ..forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Com menos movimento pedido ao sistema, o texto já aparece inteiro.
    final instant = AppMotion.of(context).disabled;
    return LayoutBuilder(
      builder: (context, constraints) {
        final style = widget.shrink
            ? _fitting(context, constraints)
            : widget.style;
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, _) => _text(instant, style),
        );
      },
    );
  }

  // O estilo com a letra no maior tamanho em que a fala inteira cabe no
  // espaço dado (até 60% do tamanho normal).
  TextStyle? _fitting(BuildContext context, BoxConstraints constraints) {
    final base = widget.style ?? DefaultTextStyle.of(context).style;
    if (!constraints.hasBoundedHeight || !constraints.hasBoundedWidth) {
      return base;
    }
    final size = base.fontSize ?? 14;
    final scaler = MediaQuery.textScalerOf(context);
    for (var scale = 1.0; scale > 0.6; scale -= 0.05) {
      final style = base.copyWith(fontSize: size * scale);
      final painter = TextPainter(
        text: TextSpan(text: widget.text, style: style),
        textDirection: Directionality.of(context),
        textScaler: scaler,
        maxLines: widget.maxLines,
      )..layout(maxWidth: constraints.maxWidth);
      final fits =
          painter.height <= constraints.maxHeight && !painter.didExceedMaxLines;
      painter.dispose();
      if (fits) return style;
    }
    return base.copyWith(fontSize: size * 0.6);
  }

  Widget _text(bool instant, TextStyle? style) {
    final shown = instant
        ? widget.text.length
        : (widget.text.length * _controller.value).round();
    return Text.rich(
      TextSpan(
        children: [
          ?widget.prefix,
          TextSpan(text: widget.text.substring(0, shown)),
          // O resto, invisível, guarda o lugar das letras que faltam.
          TextSpan(
            text: widget.text.substring(shown),
            style: const TextStyle(color: Colors.transparent),
          ),
        ],
      ),
      style: style,
      maxLines: widget.maxLines,
      overflow: TextOverflow.ellipsis,
    );
  }
}

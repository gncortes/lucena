import 'package:flutter/material.dart';

/// Um rótulo que nunca quebra no meio da palavra (T51, A3): numa linha só e,
/// se não couber, a letra diminui até caber.
class OneLine extends StatelessWidget {
  const OneLine(this.text, {this.style, super.key});

  final String text;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(text, maxLines: 1, softWrap: false, style: style),
    );
  }
}

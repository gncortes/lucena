import 'package:flutter/material.dart';

/// O som desligado do canvas T70 (`mute`): o alto-falante cheio com um x ao
/// lado. O `volume_off` do Material risca o alto-falante; aqui é este o único
/// desenho de "som desligado".
class SoundOffIcon extends StatelessWidget {
  const SoundOffIcon({this.size, this.color, super.key});

  /// Sem ele, o tamanho do [IconTheme] (24 por padrão).
  final double? size;

  /// Sem ela, a cor do [IconTheme].
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = IconTheme.of(context);
    final side = size ?? theme.size ?? 24;
    return SizedBox.square(
      dimension: side,
      child: CustomPaint(
        painter: _SoundOffPainter(
          color ?? theme.color ?? Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }
}

/// O desenho na grade de 24 do canvas, com traço de 2 e cantos redondos.
class _SoundOffPainter extends CustomPainter {
  const _SoundOffPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 24, size.height / 24);
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final speaker = Path()
      ..moveTo(4, 9)
      ..lineTo(8, 9)
      ..lineTo(13, 5)
      ..lineTo(13, 19)
      ..lineTo(8, 15)
      ..lineTo(4, 15)
      ..close();
    canvas
      ..drawPath(speaker, Paint()..color = color)
      ..drawPath(speaker, stroke)
      ..drawLine(const Offset(16, 9), const Offset(21, 15), stroke)
      ..drawLine(const Offset(21, 9), const Offset(16, 15), stroke);
  }

  @override
  bool shouldRepaint(_SoundOffPainter old) => old.color != color;
}

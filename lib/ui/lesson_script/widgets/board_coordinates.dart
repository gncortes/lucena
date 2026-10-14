import 'package:chessground/chessground.dart';
import 'package:dartchess/dartchess.dart';
import 'package:flutter/widgets.dart';

/// As coordenadas da borda por cima do tabuleiro e das marcações (canvas
/// `T71-360-propostas`, 3B): o círculo verde de h5 não cobre o "5". Mesmo
/// desenho das coordenadas do chessground (negrito 10, cor da casa oposta, a
/// 2 dp da borda); o tabuleiro embaixo vai sem as dele.
class BoardCoordinates extends StatelessWidget {
  const BoardCoordinates({
    required this.orientation,
    required this.settings,
    super.key,
  });

  final Side orientation;
  final ChessboardSettings settings;

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: BrightnessHueFilter(
      brightness: settings.brightness,
      hue: settings.hue,
      child: CustomPaint(
        size: Size.infinite,
        painter: _CoordinatesPainter(
          orientation: orientation,
          light: settings.colorScheme.lightSquare,
          dark: settings.colorScheme.darkSquare,
        ),
      ),
    ),
  );
}

class _CoordinatesPainter extends CustomPainter {
  _CoordinatesPainter({
    required this.orientation,
    required this.light,
    required this.dark,
  });

  final Side orientation;
  final Color light;
  final Color dark;

  static const _edge = 2.0;

  @override
  void paint(Canvas canvas, Size size) {
    final square = size.shortestSide / 8;
    final white = orientation == Side.white;
    TextPainter label(String text, int rank, int file) => TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          inherit: false,
          fontWeight: FontWeight.bold,
          fontSize: 10,
          color: (rank + file).isEven ? dark : light,
          fontFamily: 'Roboto',
          height: 1,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    for (var rank = 0; rank < 8; rank++) {
      final number = label(white ? '${8 - rank}' : '${rank + 1}', rank, 7);
      number.paint(
        canvas,
        Offset(8 * square - number.width - _edge, rank * square + _edge),
      );
    }
    for (var file = 0; file < 8; file++) {
      final letter = label(
        String.fromCharCode(97 + (white ? file : 7 - file)),
        7,
        file,
      );
      letter.paint(
        canvas,
        Offset(file * square + _edge, 8 * square - letter.height - _edge),
      );
    }
  }

  @override
  bool shouldRepaint(_CoordinatesPainter old) =>
      old.orientation != orientation || old.light != light || old.dark != dark;
}

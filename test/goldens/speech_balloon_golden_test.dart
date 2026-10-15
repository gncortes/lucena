import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/ui/core/widgets/speech_balloon.dart';

import '../../testing/goldens/golden_harness.dart';

/// As variações do balão (T72, forma única com sombra própria): ponta em cima,
/// embaixo e ao lado; perto de um retrato à esquerda, no centro e à direita;
/// fala curta e longa; numa lista e sobre o tabuleiro. Tudo por parâmetro do
/// mesmo componente.
const _short = 'Sua vez.';
const _long =
    'Dama contra torre é vitória, mas a dama sozinha não consegue: a torre '
    'colada no rei defende tudo. Primeiro, empurre o rei para a borda.';

const _avatar = 44.0;

/// O retrato: um círculo de 44, onde a pontinha deve mirar.
Widget _face(BuildContext context) => Container(
  width: _avatar,
  height: _avatar,
  decoration: BoxDecoration(
    shape: BoxShape.circle,
    color: Theme.of(context).colorScheme.primaryContainer,
  ),
);

/// Balão e retrato, com a ponta em [tail] e o retrato em [align] (-1 começo,
/// 0 centro, 1 fim).
Widget _pair({
  required BalloonTail tail,
  required double align,
  required String text,
}) => LayoutBuilder(
  builder: (context, box) {
    final width = box.maxWidth;
    final faceLeft = (width - _avatar) * (align + 1) / 2;
    final balloon = SpeechBalloon(
      tail: tail,
      tailX: faceLeft + SpeechBalloon.tailXFor(_avatar),
      pop: false,
      child: Text(text, style: SpeechBalloon.style(context)),
    );
    final face = Padding(
      padding: EdgeInsetsDirectional.only(start: faceLeft),
      child: _face(context),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: tail == BalloonTail.up ? [face, balloon] : [balloon, face],
    );
  },
);

/// Ponta lateral: o retrato no começo, o balão ao lado.
Widget _side(String text) => Builder(
  builder: (context) => Row(
    crossAxisAlignment: CrossAxisAlignment.end,
    children: [
      _face(context),
      Expanded(
        child: SpeechBalloon(
          tail: BalloonTail.start,
          pop: false,
          child: Text(text, style: SpeechBalloon.style(context)),
        ),
      ),
    ],
  ),
);

/// Um tabuleiro de 8×8 nas cores do tema, por baixo do balão.
Widget _board(Widget child) => Builder(
  builder: (context) {
    final colors = Theme.of(context).colorScheme;
    return CustomPaint(
      painter: _Squares(colors.secondaryContainer, colors.secondary),
      child: Padding(padding: const EdgeInsets.all(12), child: child),
    );
  },
);

class _Squares extends CustomPainter {
  const _Squares(this.light, this.dark);

  final Color light;
  final Color dark;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width / 8;
    final h = size.height / 8;
    for (var r = 0; r < 8; r++) {
      for (var c = 0; c < 8; c++) {
        canvas.drawRect(
          Rect.fromLTWH(c * w, r * h, w, h),
          Paint()..color = (r + c).isEven ? light : dark,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_Squares old) => false;
}

/// Uma lista com o balão no meio de dois itens.
Widget _list(Widget child) => Builder(
  builder: (context) {
    Widget item() => Container(
      height: 48,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
      ),
    );
    return Column(
      spacing: 12,
      mainAxisSize: MainAxisSize.min,
      children: [item(), child, item()],
    );
  },
);

void main() {
  for (final tail in [BalloonTail.up, BalloonTail.down]) {
    for (final (name, align) in [
      ('start', -1.0),
      ('center', 0.0),
      ('end', 1.0),
    ]) {
      for (final (size, text) in [('short', _short), ('long', _long)]) {
        group('balão ${tail.name} · retrato $name · $size', () {
          Goldens.matrix(
            'speech_balloon/${tail.name}_${name}_$size',
            (_) => _pair(tail: tail, align: align, text: text),
            height: size == 'short' ? 160 : 220,
            only: Goldens.ptLight,
          );
        });
      }
    }
  }
  for (final (size, text) in [('short', _short), ('long', _long)]) {
    group('balão ao lado · $size', () {
      Goldens.matrix(
        'speech_balloon/start_$size',
        (_) => _side(text),
        height: size == 'short' ? 110 : 190,
        only: Goldens.ptLight,
      );
    });
  }
  group('balão numa lista', () {
    Goldens.matrix(
      'speech_balloon/in_list',
      (_) => _list(_pair(tail: BalloonTail.down, align: -1, text: _short)),
      height: 280,
      only: Goldens.ptLight,
    );
  });
  group('balão sobre o tabuleiro', () {
    Goldens.matrix(
      'speech_balloon/over_board',
      (_) => _board(_pair(tail: BalloonTail.up, align: 0, text: _long)),
      height: 300,
      only: Goldens.ptLight,
    );
  });
}

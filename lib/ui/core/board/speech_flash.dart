import 'package:chessground/chessground.dart';
import 'package:dartchess/dartchess.dart' show FenException, Setup;
import 'package:flutter/widgets.dart';

import '../../../domain/use_cases/speech_links.dart';

/// O destaque no tabuleiro da casa ou do lance tocado na fala (ou dito pela
/// voz): um anel na casa, ou a seta do lance quando dá para saber de onde a
/// peça sai, na cor primária do app. Fica até o aluno tocar de novo no mesmo
/// trecho (desmarca), tocar em outro (troca) ou o tabuleiro mudar.
class SpeechFlash extends ChangeNotifier {
  Shape? _shape;
  SpeechLink? _link;
  String? _fen;

  /// O que desenhar no tabuleiro que mostra a posição [fen]: nada, se o
  /// destaque era de outra posição.
  Set<Shape> shapesFor(String? fen) => {
    if (_shape != null && _fen == fen) _shape!,
  };

  /// O trecho destacado agora. Nulo: nenhum.
  SpeechLink? get link => _link;

  /// O toque num trecho: destaca; no mesmo trecho de novo, desmarca.
  void toggle(SpeechLink link, {required String? fen, required Color color}) {
    if (_link != null && _same(_link!, link) && _fen == fen) {
      clear();
      return;
    }
    show(link, fen: fen, color: color);
  }

  /// Destaca [link] no tabuleiro da posição [fen].
  void show(SpeechLink link, {required String? fen, required Color color}) {
    Setup? setup;
    try {
      setup = fen == null ? null : Setup.parseFen(fen);
    } on FenException {
      setup = null;
    }
    final arrow = setup == null
        ? null
        : SpeechLinks.arrowOn(setup.board, setup.turn, link);
    final square = link.square ?? arrow?.$2;
    if (square == null && arrow == null) return;
    _shape = arrow != null
        ? Arrow(color: color, orig: arrow.$1, dest: arrow.$2)
        : CustomShape(
            orig: square!,
            scale: 1,
            child: SpeechRing(color: color),
          );
    _link = link;
    _fen = fen;
    notifyListeners();
  }

  void clear() {
    if (_shape == null) return;
    _shape = null;
    _link = null;
    _fen = null;
    notifyListeners();
  }

  static bool _same(SpeechLink a, SpeechLink b) =>
      a.start == b.start && a.text == b.text;
}

/// O anel grosso e arredondado na casa citada: mais visível que o círculo
/// fino das setas, mesmo sobre uma peça.
class SpeechRing extends StatelessWidget {
  const SpeechRing({required this.color, super.key});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final side = constraints.biggest.shortestSide;
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(side * 0.18),
            border: Border.all(color: color, width: side * 0.09),
            color: color.withValues(alpha: 0.18),
          ),
        );
      },
    );
  }
}

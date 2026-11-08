import 'package:chessground/chessground.dart';
import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';

import '../keys/motion_keys.dart';
import 'casa_no_tabuleiro.dart';
import 'halo_de_xeque.dart';
import 'lucena_motion.dart';
import 'movimento_reduzido.dart';

/// O tabuleiro de toda tela em que uma peça anda (H-ANI-10): lição,
/// demonstração, exercício, partida, desafio e análise.
///
/// O deslize da peça é o do próprio `chessground`, com os 300 ms do kit (use
/// [ajustes] nas `ChessboardSettings` do [child]). Por cima dele, este
/// widget põe o que o pacote não faz:
/// - a peça capturada encolhe a 55% e some em 160 ms, quando a outra chega;
/// - o [HaloDeXeque] na casa do rei em xeque (`kingSquareInCheck`).
///
/// Com movimento reduzido, a peça aparece no destino, a capturada some na
/// hora e o halo fica aceso, sem pulsar.
class TabuleiroAnimado extends StatefulWidget {
  const TabuleiroAnimado({
    required this.controlador,
    required this.orientacao,
    required this.tamanho,
    required this.pecas,
    required this.child,
    super.key,
  });

  /// O mesmo controlador do `Chessboard` do [child].
  final ChessboardController controlador;
  final Side orientacao;

  /// Lado do tabuleiro.
  final double tamanho;

  /// O conjunto de peças do tabuleiro, para desenhar a capturada.
  final PieceAssets pecas;

  /// O `Chessboard` (ou o tabuleiro da tela que o envolve).
  final Widget child;

  /// O tempo do deslize da peça: 300 ms, ou nada com movimento reduzido.
  static Duration duracaoDoLance(BuildContext context) =>
      MovimentoReduzido.of(context) ? Duration.zero : LucenaMotion.lance;

  /// As [ajustes] do tabuleiro com o tempo do lance do kit. Quem desligou a
  /// animação das peças nas preferências (duração zero) continua sem ela.
  static ChessboardSettings ajustes(
    BuildContext context,
    ChessboardSettings ajustes,
  ) => ajustes.animationDuration == Duration.zero
      ? ajustes
      : ajustes.copyWith(animationDuration: duracaoDoLance(context));

  /// As peças que o lance de [antes] para [depois] capturou, nas casas em
  /// que estavam: as do lado que não jogou cuja casa foi tomada ou ficou
  /// vazia (en passant). Uma troca de posição em que os dois lados mudam
  /// não é lance e não tem captura.
  ///
  /// O `chessground` não expõe as peças que somem (é interno), por isso a
  /// conta é feita aqui, com as posições públicas.
  static Map<Square, Piece> capturadasNoLance(Pieces antes, Pieces depois) {
    final quemJogou = {
      for (final MapEntry(key: casa, value: peca) in depois.entries)
        if (antes[casa] != peca) peca.color,
    };
    if (quemJogou.length != 1) return const {};
    final lado = quemJogou.single;
    return {
      for (final MapEntry(key: casa, value: peca) in antes.entries)
        if (peca.color != lado && depois[casa]?.color != peca.color) casa: peca,
    };
  }

  @override
  State<TabuleiroAnimado> createState() => _TabuleiroAnimadoState();
}

class _TabuleiroAnimadoState extends State<TabuleiroAnimado>
    with SingleTickerProviderStateMixin {
  static final _total = LucenaMotion.lance + LucenaMotion.capturaSome;

  /// O trecho da captura: começa quando a outra peça chega.
  static final _encolhe = Interval(
    LucenaMotion.lance.inMicroseconds / _total.inMicroseconds,
    1,
    curve: LucenaMotion.emphasizedAccelerate,
  );

  late final _captura = AnimationController(vsync: this, duration: _total);
  Map<Square, Piece> _capturadas = const {};
  late Pieces _antes;

  @override
  void initState() {
    super.initState();
    _ouvir(widget.controlador);
  }

  @override
  void didUpdateWidget(TabuleiroAnimado oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controlador != widget.controlador) {
      _deixar(oldWidget.controlador);
      _ouvir(widget.controlador);
    }
  }

  void _ouvir(ChessboardController controlador) {
    _antes = controlador.pieces;
    controlador.addListener(_mudou);
  }

  void _deixar(ChessboardController controlador) =>
      controlador.removeListener(_mudou);

  void _mudou() {
    final depois = widget.controlador.pieces;
    if (!identical(depois, _antes)) {
      final capturadas = TabuleiroAnimado.capturadasNoLance(_antes, depois);
      _antes = depois;
      if (capturadas.isNotEmpty && !MovimentoReduzido.of(context)) {
        _capturadas = capturadas;
        _captura.forward(from: 0);
      }
    }
    setState(() {});
  }

  @override
  void dispose() {
    _deixar(widget.controlador);
    _captura.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final xeque = widget.controlador.game.kingSquareInCheck;
    final lado = widget.tamanho / 8;
    return SizedBox.square(
      dimension: widget.tamanho,
      child: Stack(
        children: [
          widget.child,
          AnimatedBuilder(
            animation: _captura,
            builder: (context, _) {
              if (_capturadas.isEmpty || _captura.value >= 1) {
                return const SizedBox.shrink();
              }
              final t = _encolhe.transform(_captura.value);
              return IgnorePointer(
                child: Stack(
                  children: [
                    for (final MapEntry(key: casa, value: peca)
                        in _capturadas.entries)
                      Positioned.fromRect(
                        rect: retanguloDaCasa(
                          casa,
                          widget.orientacao,
                          widget.tamanho,
                        ),
                        child: Opacity(
                          opacity: 1 - t,
                          child: Transform.scale(
                            key: MotionKeys.pecaCapturada,
                            scale: 1 - (1 - LucenaMotion.escalaDaCapturada) * t,
                            child: PieceWidget(
                              piece: peca,
                              size: lado,
                              pieceAssets: widget.pecas,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
          if (xeque != null)
            HaloDeXeque(
              casa: xeque,
              orientacao: widget.orientacao,
              tamanho: widget.tamanho,
            ),
        ],
      ),
    );
  }
}

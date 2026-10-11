import 'package:dartchess/dartchess.dart';
import 'package:flutter/widgets.dart';

/// A marca do tabuleiro no começo de uma partida: o da tela de antes (a
/// preparação, o desafio da Jornada), que fica no alto, desliza e cresce até
/// o centro da partida, sem girar. O lado de baixo vai na marca: se a
/// partida olha por outro lado, nada voa e a tela só aparece com o fade.
String gameBoardTag(Side orientation) => 'game.board.${orientation.name}';

/// O tabuleiro da partida como ponta de chegada do voo de [gameBoardTag]. O
/// voo é só de ida: depois que a tela termina de entrar, a marca passa a ser
/// só desta tela, e voltar dela não leva o tabuleiro (já com outros lances)
/// para a tela de antes.
///
/// Sem `flightShuttleBuilder`: quem desenha o tabuleiro no ar é a ponta de
/// saída (um `PositionBoard`), com as peças paradas.
class GameBoardHero extends StatefulWidget {
  const GameBoardHero({
    required this.orientation,
    required this.child,
    super.key,
  });

  /// O lado de baixo do tabuleiro da partida.
  final Side orientation;
  final Widget child;

  @override
  State<GameBoardHero> createState() => _GameBoardHeroState();
}

class _GameBoardHeroState extends State<GameBoardHero> {
  Animation<double>? _entrance;
  bool _landed = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final entrance = ModalRoute.of(context)?.animation;
    if (identical(entrance, _entrance) || _landed) return;
    _entrance?.removeStatusListener(_onStatus);
    _entrance = entrance;
    if (entrance == null) {
      _landed = true;
      return;
    }
    entrance.addStatusListener(_onStatus);
    // No primeiro quadro a rota ainda não diz se está entrando: a dúvida se
    // desfaz depois dele. Já de pé (o tabuleiro chegou depois da entrada),
    // nada voa até aqui.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && entrance.isCompleted) _land();
    });
  }

  void _onStatus(AnimationStatus status) {
    if (status.isCompleted) _land();
  }

  void _land() {
    if (_landed) return;
    _entrance?.removeStatusListener(_onStatus);
    setState(() => _landed = true);
  }

  @override
  void dispose() {
    _entrance?.removeStatusListener(_onStatus);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Hero(
    tag: _landed ? this : gameBoardTag(widget.orientation),
    child: widget.child,
  );
}

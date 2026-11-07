import 'package:flutter/widgets.dart';

import 'lucena_motion.dart';
import 'movimento_reduzido.dart';
import 'relogio_de_entrada.dart';

/// O motor da barra que enche e do número que conta (H-ANI-13 e H-ANI-18):
/// na primeira entrada da tela, sai de 0; numa mudança real, sai do valor de
/// agora; tela já vista ou movimento reduzido, mostra o valor final no
/// primeiro quadro.
///
/// Dentro de uma entrada em ordem ([EntradaNoTempo]), a primeira contagem
/// espera o trecho da parte ([TempoDaContagem]) e só acontece se a entrada
/// estiver animando.
class ValorQueAnima extends StatefulWidget {
  const ValorQueAnima({
    required this.valor,
    required this.duracao,
    required this.builder,
    this.curva = LucenaMotion.emphasized,
    this.contarNaEntrada = true,
    super.key,
  });

  final double valor;
  final Duration duracao;
  final Curve curva;

  /// `false` quando o número nasce no meio de uma tela já vista (um painel
  /// que troca de lugar depois de um toque): mostra o valor real no primeiro
  /// quadro, sem recomeçar a contagem do zero.
  final bool contarNaEntrada;
  final Widget Function(BuildContext context, double valor) builder;

  @override
  State<ValorQueAnima> createState() => _ValorQueAnimaState();
}

class _ValorQueAnimaState extends State<ValorQueAnima>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controle = AnimationController(
    vsync: this,
    duration: widget.duracao,
  );
  late final CurvedAnimation _curva = CurvedAnimation(
    parent: _controle,
    curve: widget.curva,
  );
  Tween<double>? _tween;

  double get _agora => _tween?.evaluate(_curva) ?? widget.valor;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_tween != null) return;
    final tempo = TempoDaContagem.maybeOf(context);
    final animar = !widget.contarNaEntrada
        ? false
        : tempo == null
        ? MovimentoReduzido.animarEntrada(context)
        : tempo.animar && !MovimentoReduzido.of(context);
    if (animar && tempo != null && tempo.atraso > Duration.zero) {
      final conta = tempo.duracao ?? widget.duracao;
      final total = tempo.atraso + conta;
      _controle.duration = total;
      _curva.curve = Interval(
        tempo.atraso.inMicroseconds / total.inMicroseconds,
        1,
        curve: widget.curva,
      );
    } else if (animar && tempo?.duracao != null) {
      _controle.duration = tempo!.duracao;
    }
    _irPara(animar ? 0 : widget.valor, widget.valor);
  }

  @override
  void didUpdateWidget(ValorQueAnima oldWidget) {
    super.didUpdateWidget(oldWidget);
    _controle.duration = widget.duracao;
    _curva.curve = widget.curva;
    if (widget.valor == oldWidget.valor) return;
    final reduzido = MovimentoReduzido.of(context);
    _irPara(reduzido ? widget.valor : _agora, widget.valor);
  }

  void _irPara(double de, double ate) {
    _tween = Tween(begin: de, end: ate);
    if (de == ate) {
      _controle.value = 1;
    } else {
      _controle.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _curva.dispose();
    _controle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _controle,
    builder: (context, _) => widget.builder(context, _agora),
  );
}

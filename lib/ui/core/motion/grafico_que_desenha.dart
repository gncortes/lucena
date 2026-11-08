import 'package:flutter/widgets.dart';

import 'lucena_motion.dart';
import 'movimento_reduzido.dart';

/// O tempo de um quadro do [GraficoQueDesenha], já dividido nas partes do
/// desenho (H-ANI-19). Tudo vai de 0 a 1; o pintor só lê.
@immutable
class TempoDoGrafico {
  const TempoDoGrafico(this.progresso);

  /// O tempo do desenho, linear: 0,5 é a metade dos 900 ms.
  final double progresso;

  static double _fracao(Duration d) =>
      d.inMicroseconds / LucenaMotion.graficoDesenha.inMicroseconds;

  double _trecho(Duration inicio, Duration duracao, Curve curva) {
    final de = _fracao(inicio);
    final ate = _fracao(inicio + duracao).clamp(de, 1.0);
    if (progresso <= de) return 0;
    if (progresso >= ate) return 1;
    return curva.transform((progresso - de) / (ate - de));
  }

  /// Quanto da linha está desenhado (`PathMetric.extractPath`), em
  /// `emphasized`. As barras crescem da base no mesmo valor.
  double get linha => LucenaMotion.emphasized.transform(progresso);

  /// A opacidade da área embaixo da linha: os últimos 300 ms.
  double get area => _trecho(
    LucenaMotion.graficoDesenha - LucenaMotion.areaDoGrafico,
    LucenaMotion.areaDoGrafico,
    LucenaMotion.linear,
  );

  /// A escala do ponto [i]: saltam um depois do outro, 40 ms entre eles,
  /// todos dentro dos 900 ms.
  double ponto(int i) {
    final fim = LucenaMotion.graficoDesenha - LucenaMotion.saltoDoPonto;
    var inicio =
        LucenaMotion.pontosDoGrafico + LucenaMotion.intervaloDosPontos * i;
    if (inicio > fim) inicio = fim;
    return _trecho(
      inicio,
      LucenaMotion.saltoDoPonto,
      LucenaMotion.emphasizedDecelerate,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is TempoDoGrafico && other.progresso == progresso;

  @override
  int get hashCode => progresso.hashCode;
}

/// O gráfico de rating que se desenha (H-ANI-19): na primeira entrada da
/// tela, a linha se desenha em 900 ms (`emphasized`), a área aparece com
/// fade no fim e os pontos saltam um a um; trocar o [periodo] redesenha o
/// gráfico em 300 ms. Os números em volta contam com o `NumeroQueConta`.
///
/// O desenho é da tela: [pintor] recebe o [TempoDoGrafico] de cada quadro.
/// Tela já vista ou movimento reduzido: o gráfico vem inteiro.
class GraficoQueDesenha extends StatefulWidget {
  const GraficoQueDesenha({
    required this.periodo,
    required this.pintor,
    this.tamanho = Size.zero,
    super.key,
  });

  /// O período mostrado; quando muda, o gráfico se redesenha.
  final Object periodo;
  final CustomPainter Function(TempoDoGrafico tempo) pintor;

  /// O tamanho do `CustomPaint` (zero: o do pai).
  final Size tamanho;

  @override
  State<GraficoQueDesenha> createState() => _GraficoQueDesenhaState();
}

class _GraficoQueDesenhaState extends State<GraficoQueDesenha>
    with SingleTickerProviderStateMixin {
  late final _tempo = AnimationController(
    vsync: this,
    duration: LucenaMotion.graficoDesenha,
  );
  var _iniciado = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_iniciado) return;
    _iniciado = true;
    if (MovimentoReduzido.animarEntrada(context)) {
      _tempo.forward();
    } else {
      _tempo.value = 1;
    }
  }

  @override
  void didUpdateWidget(GraficoQueDesenha oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.periodo == oldWidget.periodo) return;
    if (MovimentoReduzido.of(context)) {
      _tempo.value = 1;
      return;
    }
    _tempo
      ..duration = LucenaMotion.graficoRedesenha
      ..forward(from: 0);
  }

  @override
  void dispose() {
    _tempo.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _tempo,
    builder: (context, _) => CustomPaint(
      size: widget.tamanho,
      painter: widget.pintor(TempoDoGrafico(_tempo.value)),
    ),
  );
}

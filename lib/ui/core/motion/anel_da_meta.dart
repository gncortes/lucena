import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../domain/use_cases/now.dart';
import '../keys/motion_keys.dart';
import 'lucena_motion.dart';
import 'movimento_reduzido.dart';

/// A meta do dia e a sequência (H-ANI-28): quando o dia de hoje é cumprido,
/// o anel fecha em 450 ms (`emphasized`), o ✓ salta, saem 8 faíscas e o
/// contador sobe com um salto (ex.: 11 → 12). Tudo em 1,2 s.
///
/// Anima uma vez por dia cumprido: a tela guarda o dia em [aoCelebrar] e
/// devolve em [celebradoEm]; reabrir no mesmo dia (pelo [now]) mostra o anel
/// já fechado. Com movimento reduzido, anel fechado, contador no valor final
/// e sem faíscas.
///
/// O ✓ em onda dos dias anteriores fica na tela (com `ListaEmOrdem`).
class AnelDaMeta extends StatefulWidget {
  const AnelDaMeta({
    required this.feito,
    required this.sequencia,
    required this.now,
    required this.aoCelebrar,
    this.celebradoEm,
    this.tamanho = 64,
    this.estiloDoContador,
    super.key,
  });

  /// Quanto da meta de hoje foi feito, de 0 a 1.
  final double feito;

  /// A sequência de dias, já contando hoje quando [feito] é 1.
  final int sequencia;
  final Now now;

  /// O dia da última celebração, guardado pela tela.
  final DateTime? celebradoEm;

  /// Avisa que a celebração de hoje começou, com a hora do [now].
  final ValueChanged<DateTime> aoCelebrar;
  final double tamanho;
  final TextStyle? estiloDoContador;

  @override
  State<AnelDaMeta> createState() => _AnelDaMetaState();
}

class _AnelDaMetaState extends State<AnelDaMeta>
    with SingleTickerProviderStateMixin {
  late final _controle = AnimationController(
    vsync: this,
    duration: LucenaMotion.celebracaoDaMeta,
    value: 1,
  );
  var _celebrando = false;
  var _iniciado = false;

  static double _fracao(Duration d) =>
      d.inMicroseconds / LucenaMotion.celebracaoDaMeta.inMicroseconds;

  static final _fimDoAnel = _fracao(LucenaMotion.anelDaMeta);
  static final _subida = _fracao(LucenaMotion.contadorDaMeta);
  static final _fimDoSalto = _fracao(
    LucenaMotion.anelDaMeta + LucenaMotion.saltoDaMeta,
  );

  bool get _cumprida => widget.feito >= 1;

  bool _jaCelebrouHoje() {
    final dia = widget.celebradoEm;
    if (dia == null) return false;
    final hoje = widget.now();
    return dia.year == hoje.year &&
        dia.month == hoje.month &&
        dia.day == hoje.day;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_iniciado) return;
    _iniciado = true;
    _talvezCelebrar();
  }

  @override
  void didUpdateWidget(AnelDaMeta antigo) {
    super.didUpdateWidget(antigo);
    if (antigo.feito < 1 && _cumprida) _talvezCelebrar();
  }

  void _talvezCelebrar() {
    if (!_cumprida || _jaCelebrouHoje()) return;
    final agora = widget.now();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.aoCelebrar(agora);
    });
    if (MovimentoReduzido.of(context)) return;
    _celebrando = true;
    _controle.forward(from: 0).whenComplete(() {
      if (mounted) setState(() => _celebrando = false);
    });
  }

  @override
  void dispose() {
    _controle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    return AnimatedBuilder(
      animation: _controle,
      builder: (context, _) {
        final v = _controle.value;
        final tempo = (v / _fimDoAnel).clamp(0.0, 1.0);
        final salto = _cumprida
            ? LucenaMotion.salto.transform(
                ((v - _fimDoAnel) / (_fimDoSalto - _fimDoAnel)).clamp(0.0, 1.0),
              )
            : 0.0;
        final faiscas = _celebrando && v >= _fimDoAnel && v < 1;
        final valor = _celebrando && v < _subida
            ? widget.sequencia - 1
            : widget.sequencia;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox.square(
              dimension: widget.tamanho,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    key: MotionKeys.anelDaMeta,
                    size: Size.square(widget.tamanho),
                    painter: PintorDoAnel(
                      tempo: tempo,
                      feito: widget.feito.clamp(0.0, 1.0),
                      faixa: esquema.surfaceContainerHighest,
                      cor: esquema.primary,
                    ),
                  ),
                  if (_cumprida)
                    Transform.scale(
                      scale: salto,
                      child: Icon(
                        Icons.check_rounded,
                        color: esquema.primary,
                        size: widget.tamanho * .45,
                      ),
                    ),
                  if (faiscas)
                    CustomPaint(
                      key: MotionKeys.faiscasDaMeta,
                      size: Size.square(widget.tamanho),
                      painter: _Faiscas(
                        t: (v - _fimDoAnel) / (1 - _fimDoAnel),
                        cor: esquema.primary,
                      ),
                    ),
                ],
              ),
            ),
            AnimatedSwitcher(
              key: MotionKeys.contadorDaMeta,
              duration: MovimentoReduzido.of(context)
                  ? Duration.zero
                  : LucenaMotion.saltoDaMeta,
              transitionBuilder: (filho, animacao) => ScaleTransition(
                scale: CurvedAnimation(
                  parent: animacao,
                  curve: LucenaMotion.salto,
                ),
                child: filho,
              ),
              child: Text(
                '$valor',
                key: ValueKey(valor),
                style:
                    widget.estiloDoContador ??
                    Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Pinta o anel: a faixa inteira e o arco do que foi feito. [tempo] é o
/// tempo linear do fechamento (0 a 1); a curva `emphasized` é aplicada aqui.
class PintorDoAnel extends CustomPainter {
  const PintorDoAnel({
    required this.tempo,
    required this.feito,
    required this.faixa,
    required this.cor,
    this.espessura,
  });

  final double tempo;

  /// A largura do traço; sem ela, 10% do lado.
  final double? espessura;
  final double feito;
  final Color faixa;
  final Color cor;

  @override
  void paint(Canvas canvas, Size size) {
    final espessura = this.espessura ?? size.shortestSide * .1;
    final retangulo = (Offset.zero & size).deflate(espessura / 2);
    final pincel = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = espessura
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(retangulo, 0, 2 * math.pi, false, pincel..color = faixa);
    final varredura =
        2 * math.pi * feito * LucenaMotion.emphasized.transform(tempo);
    if (varredura <= 0) return;
    canvas.drawArc(
      retangulo,
      -math.pi / 2,
      varredura,
      false,
      pincel..color = cor,
    );
  }

  @override
  bool shouldRepaint(PintorDoAnel antigo) =>
      antigo.tempo != tempo ||
      antigo.feito != feito ||
      antigo.faixa != faixa ||
      antigo.cor != cor ||
      antigo.espessura != espessura;
}

/// As 8 faíscas que saem do anel e somem.
class _Faiscas extends CustomPainter {
  const _Faiscas({required this.t, required this.cor});

  final double t;
  final Color cor;

  @override
  void paint(Canvas canvas, Size size) {
    final centro = size.center(Offset.zero);
    final raio = size.shortestSide / 2;
    final saida = LucenaMotion.emphasizedDecelerate.transform(t);
    final pincel = Paint()..color = cor.withValues(alpha: 1 - t);
    for (var i = 0; i < 8; i++) {
      final angulo = -math.pi / 2 + i * math.pi / 4;
      final distancia = raio * (1 + .45 * saida);
      canvas.drawCircle(
        centro + Offset.fromDirection(angulo, distancia),
        size.shortestSide * .04 * (1 - t * .5),
        pincel,
      );
    }
  }

  @override
  bool shouldRepaint(_Faiscas antigo) => antigo.t != t || antigo.cor != cor;
}

import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'lucena_motion.dart';
import 'movimento_reduzido.dart';

/// O relógio único de uma entrada em ordem (H-ANI-16, 17, 24 e 25): um
/// `AnimationController` só para a tela, e cada parte ([NoTempo],
/// [EntradaNoTempo]) lê o seu trecho dele com um `Interval`. Assim a ordem é
/// estrita e nada depende de quando cada widget foi montado.
///
/// Anima só na primeira entrada da tela ([MovimentoReduzido.animarEntrada]),
/// ou quando [animar] manda (resultado novo). Fora disso, e sempre com
/// movimento reduzido, tudo aparece pronto no primeiro quadro. O toque fica
/// liberado desde o começo.
class RelogioDeEntrada extends StatefulWidget {
  const RelogioDeEntrada({
    required this.total,
    required this.child,
    this.animar,
    this.esperarATransicao = true,
    super.key,
  });

  /// O fim da última parte.
  final Duration total;

  /// Nulo: só na primeira entrada da tela.
  final bool? animar;

  /// `false`: começa junto com a transição da rota, com os próprios atrasos
  /// (o painel de filtro, que entra enquanto a folha sobe).
  final bool esperarATransicao;

  final Widget child;

  /// `true` quando o relógio em volta está fazendo a entrada.
  static bool animando(BuildContext context) =>
      _Relogio.of(context)?.animar ?? false;

  @override
  State<RelogioDeEntrada> createState() => _RelogioDeEntradaState();
}

class _RelogioDeEntradaState extends State<RelogioDeEntrada>
    with SingleTickerProviderStateMixin {
  late final _tempo = AnimationController(vsync: this, duration: widget.total);
  bool? _animar;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_animar != null) return;
    final animar =
        !MovimentoReduzido.of(context) &&
        (widget.animar ?? MovimentoReduzido.animarEntrada(context));
    _animar = animar;
    if (!animar || widget.total <= Duration.zero) {
      _tempo.value = 1;
      return;
    }
    // A tela que ainda está chegando (rota, cartão que abre) começa a
    // entrada só quando a transição acaba.
    final rota = ModalRoute.of(context)?.animation;
    if (widget.esperarATransicao &&
        rota != null &&
        rota.status == AnimationStatus.forward) {
      _rota = rota..addStatusListener(_rotaChegou);
    } else {
      _tempo.forward();
    }
  }

  Animation<double>? _rota;

  void _rotaChegou(AnimationStatus status) {
    if (status != AnimationStatus.completed) return;
    _rota?.removeStatusListener(_rotaChegou);
    _rota = null;
    if (mounted) _tempo.forward();
  }

  @override
  void dispose() {
    _rota?.removeStatusListener(_rotaChegou);
    _tempo.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _Relogio(
    tempo: _tempo,
    total: widget.total,
    animar: _animar!,
    child: widget.child,
  );
}

class _Relogio extends InheritedWidget {
  const _Relogio({
    required this.tempo,
    required this.total,
    required this.animar,
    required super.child,
  });

  final Animation<double> tempo;
  final Duration total;
  final bool animar;

  static _Relogio? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_Relogio>();

  @override
  bool updateShouldNotify(_Relogio oldWidget) =>
      tempo != oldWidget.tempo ||
      total != oldWidget.total ||
      animar != oldWidget.animar;
}

/// Quando o número ([NumeroQueConta]) ou a barra ([BarraQueEnche]) de dentro
/// de uma entrada em ordem começa a contar, e em quanto tempo. Posto pelo
/// [EntradaNoTempo]; o `ValorQueAnima` lê aqui.
class TempoDaContagem extends InheritedWidget {
  const TempoDaContagem({
    required this.atraso,
    required this.animar,
    required super.child,
    this.duracao,
    super.key,
  });

  final Duration atraso;

  /// Nulo: a duração do próprio número ou barra.
  final Duration? duracao;

  /// A entrada em volta está animando.
  final bool animar;

  static TempoDaContagem? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<TempoDaContagem>();

  @override
  bool updateShouldNotify(TempoDaContagem oldWidget) =>
      atraso != oldWidget.atraso ||
      duracao != oldWidget.duracao ||
      animar != oldWidget.animar;
}

/// O trecho [inicio] + [duracao] do [RelogioDeEntrada] em volta, de 0 a 1 já
/// com a [curva]. Sem relógio em volta, o valor é 1.
class NoTempo extends StatelessWidget {
  const NoTempo({
    required this.inicio,
    required this.duracao,
    required this.builder,
    this.curva = LucenaMotion.emphasizedDecelerate,
    this.child,
    super.key,
  });

  final Duration inicio;
  final Duration duracao;
  final Curve curva;
  final ValueWidgetBuilder<double> builder;
  final Widget? child;

  /// O trecho como `Interval` de um relógio de [total].
  static Interval trecho(
    Duration inicio,
    Duration duracao,
    Duration total, {
    Curve curva = LucenaMotion.emphasizedDecelerate,
  }) {
    final t = total.inMicroseconds;
    if (t == 0) return Interval(0, 1, curve: curva);
    final de = (inicio.inMicroseconds / t).clamp(0.0, 1.0);
    final ate = ((inicio + duracao).inMicroseconds / t).clamp(de, 1.0);
    return Interval(de, math.max(ate, de), curve: curva);
  }

  @override
  Widget build(BuildContext context) {
    final relogio = _Relogio.of(context);
    if (relogio == null) return builder(context, 1, child);
    final intervalo = trecho(inicio, duracao, relogio.total, curva: curva);
    return AnimatedBuilder(
      animation: relogio.tempo,
      builder: (context, child) {
        final v = relogio.tempo.value;
        final t = v >= 1 || intervalo.end <= intervalo.begin
            ? (v >= intervalo.begin ? 1.0 : 0.0)
            : intervalo.transform(v);
        return builder(context, t, child);
      },
      child: child,
    );
  }
}

/// Uma parte de uma entrada em ordem: fade, subida de [subida] px e escala a
/// partir de [escalaDe], no trecho [inicio] + [duracao] do relógio. Os
/// números e barras dentro dela começam a contar no [inicio].
///
/// Com [prontoForaDaTela], a parte que nasce abaixo da dobra entra pronta
/// (H-ANI-17): no primeiro quadro ela está fora da tela, e no seguinte já
/// está no lugar final.
class EntradaNoTempo extends StatefulWidget {
  const EntradaNoTempo({
    required this.inicio,
    required this.duracao,
    required this.child,
    this.subida = 0,
    this.escalaDe = 1,
    this.alinhamento = Alignment.center,
    this.curva = LucenaMotion.emphasizedDecelerate,
    this.duracaoDaContagem,
    this.prontoForaDaTela = false,
    super.key,
  });

  final Duration inicio;
  final Duration duracao;
  final double subida;
  final double escalaDe;
  final AlignmentGeometry alinhamento;
  final Curve curva;

  /// Quanto contam os números de dentro; nulo, o tempo deles.
  final Duration? duracaoDaContagem;
  final bool prontoForaDaTela;
  final Widget child;

  @override
  State<EntradaNoTempo> createState() => _EntradaNoTempoState();
}

class _EntradaNoTempoState extends State<EntradaNoTempo> {
  bool _pronto = false;
  bool _conferiu = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_conferiu || !widget.prontoForaDaTela) return;
    _conferiu = true;
    if (!(_Relogio.of(context)?.animar ?? false)) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final caixa = context.findRenderObject();
      if (caixa is! RenderBox || !caixa.hasSize) return;
      final topo = caixa.localToGlobal(Offset.zero).dy;
      if (topo >= MediaQuery.sizeOf(context).height) {
        setState(() => _pronto = true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final animar = !_pronto && (_Relogio.of(context)?.animar ?? false);
    final filho = TempoDaContagem(
      atraso: widget.inicio,
      duracao: widget.duracaoDaContagem,
      animar: animar,
      child: widget.child,
    );
    if (!animar) return filho;
    return NoTempo(
      inicio: widget.inicio,
      duracao: widget.duracao,
      curva: widget.curva,
      builder: (context, t, filho) => Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(0, widget.subida * (1 - t)),
          child: Transform.scale(
            scale: widget.escalaDe + (1 - widget.escalaDe) * t,
            alignment: widget.alinhamento,
            child: filho,
          ),
        ),
      ),
      child: filho,
    );
  }
}

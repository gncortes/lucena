import 'package:flutter/widgets.dart';

import '../keys/motion_keys.dart';
import 'entradas_vistas.dart';
import 'lucena_motion.dart';
import 'relogio_de_entrada.dart';
import 'selo_na_peca.dart';

Widget _coluna(List<Widget> partes) =>
    Column(mainAxisSize: MainAxisSize.min, children: partes);

Widget _fileira(List<Widget> bolinhas) => Wrap(
  alignment: WrapAlignment.center,
  spacing: 8,
  runSpacing: 8,
  children: bolinhas,
);

/// O resultado de teste, lição, lista e partida se monta em ordem
/// (H-ANI-25), em até 1,3 s:
/// 1. a [estrela] salta (0 → 1,2 → 1);
/// 2. o [titulo] e o [subtitulo] sobem;
/// 3. o [placar] conta ([NumeroQueConta] dentro dele), e termina antes dos
///    botões;
/// 4. as [bolinhas] saltam uma a uma, da esquerda para a direita;
/// 5. o cartão do [viktor] entra;
/// 6. os [botoes] deslizam 24 px de baixo, por último (280 ms, `emphasized`),
///    e aceitam toque desde o começo.
///
/// Anima sempre que o resultado é novo ([id] novo na sessão); reabrir o
/// mesmo resultado mostra tudo pronto, com o placar no valor final. Com
/// movimento reduzido, tudo pronto.
class EntradaDeResultado extends StatelessWidget {
  const EntradaDeResultado({
    required this.id,
    this.estrela,
    this.titulo,
    this.subtitulo,
    this.placar,
    this.bolinhas = const [],
    this.viktor,
    this.botoes,
    this.montarBolinhas = _fileira,
    this.montar = _coluna,
    super.key,
  });

  /// O resultado (a tentativa, não a tela): o mesmo [id] não anima duas
  /// vezes na sessão.
  final String id;
  final Widget? estrela;
  final Widget? titulo;
  final Widget? subtitulo;
  final Widget? placar;
  final List<Widget> bolinhas;
  final Widget? viktor;
  final Widget? botoes;

  /// Arruma as bolinhas já animadas (padrão: `Wrap` centrado).
  final Widget Function(List<Widget> bolinhas) montarBolinhas;

  /// Arruma as partes já animadas, na ordem acima (padrão: coluna).
  final Widget Function(List<Widget> partes) montar;

  /// O intervalo entre as bolinhas: 90 ms, ou menos para caber em 1,3 s.
  static Duration intervaloDasBolinhas(int n) {
    if (n < 2) return LucenaMotion.intervaloDosFeitos;
    final cabe =
        (LucenaMotion.totalDoResultado -
            LucenaMotion.resultadoBolinhas -
            LucenaMotion.bolinhaSalta) ~/
        (n - 1);
    return cabe < LucenaMotion.intervaloDosFeitos
        ? cabe
        : LucenaMotion.intervaloDosFeitos;
  }

  @override
  Widget build(BuildContext context) {
    final intervalo = intervaloDasBolinhas(bolinhas.length);
    final fimDasBolinhas = bolinhas.isEmpty
        ? Duration.zero
        : LucenaMotion.resultadoBolinhas +
              intervalo * (bolinhas.length - 1) +
              LucenaMotion.bolinhaSalta;
    final fimDosBotoes =
        LucenaMotion.resultadoBotoes + LucenaMotion.botoesDoResultado;
    final fimDoViktor = LucenaMotion.resultadoViktor + LucenaMotion.textoEntra;
    var total = fimDosBotoes;
    for (final fim in [fimDasBolinhas, fimDoViktor]) {
      if (fim > total) total = fim;
    }

    Widget sobe(
      String nome,
      Duration inicio,
      Duration duracao,
      double subida,
      Widget filho, {
      Curve curva = LucenaMotion.emphasizedDecelerate,
      Duration? conta,
    }) => EntradaNoTempo(
      key: MotionKeys.parteDoResultado(nome),
      inicio: inicio,
      duracao: duracao,
      subida: subida,
      curva: curva,
      duracaoDaContagem: conta,
      child: filho,
    );

    final estrela = this.estrela;
    final titulo = this.titulo;
    final subtitulo = this.subtitulo;
    final placar = this.placar;
    final viktor = this.viktor;
    final botoes = this.botoes;
    return EntradaDaTela(
      id: 'resultado-$id',
      child: RelogioDeEntrada(
        total: total,
        child: montar([
          if (estrela != null)
            _Salto(
              key: MotionKeys.parteDoResultado('estrela'),
              inicio: Duration.zero,
              child: estrela,
            ),
          if (titulo != null)
            sobe(
              'titulo',
              LucenaMotion.resultadoTitulo,
              LucenaMotion.tituloEntra,
              LucenaMotion.subidaDoTitulo,
              titulo,
            ),
          if (subtitulo != null)
            sobe(
              'subtitulo',
              LucenaMotion.resultadoSubtitulo,
              LucenaMotion.textoEntra,
              LucenaMotion.subidaDoTexto,
              subtitulo,
            ),
          if (placar != null)
            sobe(
              'placar',
              LucenaMotion.resultadoPlacar,
              LucenaMotion.textoEntra,
              LucenaMotion.subidaDoTexto,
              placar,
              conta: LucenaMotion.placarConta,
            ),
          if (bolinhas.isNotEmpty)
            montarBolinhas([
              for (var i = 0; i < bolinhas.length; i++)
                _Salto(
                  key: MotionKeys.bolinhaDoResultado(i),
                  inicio: LucenaMotion.resultadoBolinhas + intervalo * i,
                  child: bolinhas[i],
                ),
            ]),
          if (viktor != null)
            sobe(
              'viktor',
              LucenaMotion.resultadoViktor,
              LucenaMotion.textoEntra,
              LucenaMotion.subidaDoTexto,
              viktor,
            ),
          if (botoes != null)
            sobe(
              'botoes',
              LucenaMotion.resultadoBotoes,
              LucenaMotion.botoesDoResultado,
              LucenaMotion.subidaDosBotoes,
              botoes,
              curva: LucenaMotion.emphasized,
            ),
        ]),
      ),
    );
  }
}

/// A estrela e a bolinha saltam como o selo (0 → 1,2 → 1 em 160 a 260 ms).
class _Salto extends StatelessWidget {
  const _Salto({required this.inicio, required this.child, super.key});

  final Duration inicio;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!RelogioDeEntrada.animando(context)) return child;
    return NoTempo(
      inicio: inicio,
      duracao: inicio == Duration.zero
          ? LucenaMotion.saltoDoSelo
          : LucenaMotion.bolinhaSalta,
      curva: LucenaMotion.linear,
      builder: (context, t, filho) => Opacity(
        opacity: t <= 0 ? 0 : 1,
        child: Transform.scale(
          scale: SeloNaPeca.salto.transform(t),
          child: filho,
        ),
      ),
      child: child,
    );
  }
}

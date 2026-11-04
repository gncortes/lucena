import 'package:flutter/widgets.dart';

/// Chaves dos widgets do kit de movimento (T85-D6, `lib/ui/core/motion/`),
/// para os testes das frentes acharem cada um.
abstract final class MotionKeys {
  /// O conteúdo da folha de baixo ([FolhaLucena]).
  static const folha = Key('motion.folha');

  /// O esqueleto do [ShimmerConteudo] enquanto carrega ou se dissolve.
  static const shimmerEsqueleto = Key('motion.shimmerEsqueleto');

  /// O conteúdo do [ShimmerConteudo].
  static const shimmerConteudo = Key('motion.shimmerConteudo');

  /// A barra de progresso que enche.
  static const barraQueEnche = Key('motion.barraQueEnche');

  /// O número que conta.
  static const numeroQueConta = Key('motion.numeroQueConta');

  /// O halo vermelho na casa do rei em xeque.
  static const haloDeXeque = Key('motion.haloDeXeque');

  /// A peça capturada que encolhe e some.
  static const pecaCapturada = Key('motion.pecaCapturada');

  /// O selo (✓, ✗ ou a qualidade do lance) sobre a peça.
  static const seloNaPeca = Key('motion.seloNaPeca');

  /// A cor na casa do lance, no acerto e no erro.
  static const corDaCasa = Key('motion.corDaCasa');

  /// O tabuleiro que respira (acerto) ou treme (erro).
  static const tabuleiroDoRetorno = Key('motion.tabuleiroDoRetorno');

  /// O tabuleiro durante o voo do hero (H-ANI-02).
  static const tabuleiroEmVoo = Key('motion.tabuleiroEmVoo');

  /// O item [i] da [EntradaEmCascata] (H-ANI-16).
  static Key itemDaCascata(int i) => Key('motion.itemDaCascata.$i');

  /// A linha [i] da [ListaEmOrdem] (H-ANI-17).
  static Key itemDaLista(int i) => Key('motion.itemDaLista.$i');

  /// O passo [i] dos [PassosComConector] (H-ANI-17).
  static Key passo(int i) => Key('motion.passo.$i');

  /// O conector que desce do passo [i] ao seguinte (H-ANI-17).
  static Key conector(int i) => Key('motion.conector.$i');

  /// O ícone, o texto e a ação da [EntradaDeEstado] (H-ANI-24).
  static const iconeDoEstado = Key('motion.iconeDoEstado');
  static const textoDoEstado = Key('motion.textoDoEstado');
  static const acaoDoEstado = Key('motion.acaoDoEstado');

  /// As partes da [EntradaDeResultado] (H-ANI-25).
  static Key parteDoResultado(String parte) => Key('motion.resultado.$parte');

  /// A bolinha [i] do resultado (H-ANI-25).
  static Key bolinhaDoResultado(int i) => Key('motion.resultado.bolinha.$i');
}

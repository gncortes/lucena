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

  /// O tabuleiro que respira (acerto) ou fica parado (erro).
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

  /// O passo à mostra na [TransicaoEixoX] (H-ANI-03).
  static const passoDoEixo = Key('motion.passoDoEixo');

  /// O retângulo que cresce do [CartaoQueAbre] até a tela (H-ANI-04).
  static const cartaoQueAbre = Key('motion.cartaoQueAbre');

  /// O retângulo que cresce da [OrigemQueAbre] até a tela, na [RotaQueAbre]
  /// (H-ANI-04 por rota).
  static const rotaQueAbre = Key('motion.rotaQueAbre');

  /// O corpo das abas na [AbasFadeThrough] (H-ANI-05).
  static const corpoDasAbas = Key('motion.corpoDasAbas');

  /// A barra que desliza sob a aba escolhida (H-ANI-05).
  static const indicadorDaAba = Key('motion.indicadorDaAba');

  /// A escala do [CartaoPressionavel] (H-ANI-20).
  static const cartaoPressionado = Key('motion.cartaoPressionado');

  /// O rádio da [OpcaoSelecionavel] (H-ANI-30).
  static const radioDaOpcao = Key('motion.radioDaOpcao');

  /// O cabeçalho que abre o [Acordeao] (H-ANI-22).
  static const cabecalhoDoAcordeao = Key('motion.cabecalhoDoAcordeao');

  /// O corpo que cresce no [Acordeao] (H-ANI-22).
  static const corpoDoAcordeao = Key('motion.corpoDoAcordeao');

  /// A seta que gira no [Acordeao] (H-ANI-22).
  static const setaDoAcordeao = Key('motion.setaDoAcordeao');

  /// A opção [i] do painel de filtro ([OpcoesDoFiltro], H-ANI-23).
  static Key itemDoFiltro(int i) => Key('motion.itemDoFiltro.$i');

  /// O anel da meta do dia ([AnelDaMeta], H-ANI-28).
  static const anelDaMeta = Key('motion.anelDaMeta');

  /// H-ANI-29: os cartões da meta dobrada, em ordem, e o selo.
  static Key cartaoDaMetaDobrada(int i) => Key('motion.cartaoDaMetaDobrada.$i');
  static const seloDaMetaDobrada = Key('motion.seloDaMetaDobrada');

  /// O ✓ de cada dia da sequência na faixa da semana ([MetaDaSemana]).
  static Key checkDaSemana(int i) => Key('motion.checkDaSemana.$i');

  /// O contador da sequência no [AnelDaMeta].
  static const contadorDaMeta = Key('motion.contadorDaMeta');

  /// As faíscas da meta cumprida no [AnelDaMeta].
  static const faiscasDaMeta = Key('motion.faiscasDaMeta');

  /// O diploma que escala na [Celebracao] (H-ANI-15).
  static const diplomaDaCelebracao = Key('motion.diplomaDaCelebracao');

  /// O fade do diploma com movimento reduzido na [Celebracao].
  static const fadeDaCelebracao = Key('motion.fadeDaCelebracao');

  /// O confete da [Celebracao].
  static const confeteDaCelebracao = Key('motion.confeteDaCelebracao');

  /// A barra do tempo da teoria ([BarraDoCronometro], H-ANI-14).
  static const barraDoCronometro = Key('motion.barraDoCronometro');

  /// O contorno do [CartaoDePlano] (H-ANI-26).
  static const contornoDoPlano = Key('motion.contornoDoPlano');

  /// O ponto do rádio do [CartaoDePlano].
  static const pontoDoPlano = Key('motion.pontoDoPlano');

  /// O círculo do ✓ no [SucessoDaCompra] (H-ANI-27).
  static const circuloDaCompra = Key('motion.circuloDaCompra');

  /// O ✓ que salta no [SucessoDaCompra].
  static const checkDaCompra = Key('motion.checkDaCompra');

  /// O anel que se expande uma vez no [SucessoDaCompra].
  static const anelDaCompra = Key('motion.anelDaCompra');

  /// O corpo que abre no [AvisoQueAbre] (H-ANI-27).
  static const avisoQueAbre = Key('motion.avisoQueAbre');

  /// O ícone que pulsa no [AvisoQueAbre].
  static const iconeDoAviso = Key('motion.iconeDoAviso');

  /// O "Conhecer o Pilares" que entra na [BarraDoAnuncio] (H-ANI-31).
  static const conhecerDoAnuncio = Key('motion.conhecerDoAnuncio');

  /// A [ContagemParaFechar] do anúncio (H-ANI-31).
  static const contagemParaFechar = Key('motion.contagemParaFechar');

  /// A abertura animada (H-ANI-44): tocar pula para a saída quando a carga
  /// terminou.
  static const abertura = Key('motion.abertura');

  /// O peão desenhado da abertura ([MascotePainter]).
  static const mascote = Key('motion.mascote');

  /// Um segmento do [SegmentadoLucena] (H-ANI-30), pelo valor.
  static Key segmento(String valor) => Key('motion.segmento.$valor');
}

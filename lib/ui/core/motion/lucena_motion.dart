import 'package:flutter/animation.dart';

/// Os tempos e curvas das animações aprovadas (T85, H-ANI-01): a fonte é
/// `docs/tasks/T85-historias/animacoes/motion-spec.md`. Nenhum widget de
/// `lib/ui/core/motion/` escreve `Duration` ou `Cubic` fora daqui (teste
/// `tokens_soltos_test.dart`).
///
/// Os tokens antigos de [AppMotion] continuam nas telas que já existiam; os
/// widgets do kit de movimento usam só estes.
abstract final class LucenaMotion {
  // Curvas (Material 3).

  /// Padrão de quase tudo: o que se move dentro da tela.
  static const emphasized = Cubic(.2, 0, 0, 1);

  /// Entrada: algo aparece.
  static const emphasizedDecelerate = Cubic(.05, .7, .1, 1);

  /// Saída: algo some.
  static const emphasizedAccelerate = Cubic(.3, 0, .8, .15);

  /// Saída curta (eixo X, fade through).
  static const standardAccelerate = Cubic(.3, 0, 1, 1);

  /// Véu, dissolve e giro do carregando.
  static const linear = Curves.linear;

  // Reduzir movimento.

  /// Com "remover animações", o que sobra é este fade (ou nada).
  static const fadeReduzido = Duration(milliseconds: 100);

  // H-ANI-06 · Folha de baixo sobre véu.

  /// A folha sobe (e desce) sobre o véu.
  static const folha = Duration(milliseconds: 400);

  // H-ANI-07 · Shimmer na primeira carga.

  /// Uma volta do brilho do esqueleto.
  static const brilho = Duration(milliseconds: 1100);

  /// O esqueleto se dissolve no conteúdo.
  static const dissolveEsqueleto = Duration(milliseconds: 250);

  /// O conteúdo sobe até o lugar.
  static const sobeConteudo = Duration(milliseconds: 300);

  /// Quanto o conteúdo sobe ao chegar, em px.
  static const distanciaConteudo = 8.0;

  // H-ANI-08 · Botão carregando.

  /// O rótulo sai e o círculo entra.
  static const trocaRotulo = Duration(milliseconds: 120);

  /// Uma volta do círculo de carregando, em todo o app.
  static const giroCarregando = Duration(milliseconds: 800);

  // H-ANI-13 e H-ANI-18 · Barra que enche e número que conta.

  /// A barra enche até o valor.
  static const barraEnche = Duration(milliseconds: 700);

  /// O número conta até o valor.
  static const numeroConta = Duration(milliseconds: 650);

  // H-ANI-02 · Hero do tabuleiro.

  /// O voo do tabuleiro entre as duas telas (ida e volta).
  static const vooDoTabuleiro = Duration(milliseconds: 450);

  /// Trecho do voo em que o tabuleiro de A se dissolve no de B.
  static const dissolveDoVoo = Interval(.2, .65);

  /// A tela B entra: espera 60 ms e sobe até o fim do voo.
  static const entradaDaTelaB = Interval(
    60 / 450,
    1,
    curve: emphasizedDecelerate,
  );

  /// Quanto a tela B sobe ao entrar, em fração da altura.
  static const subidaDaTelaB = .03;

  /// Na volta, a tela que sai desce e some neste tempo.
  static const saidaDaTela = Duration(milliseconds: 270);

  /// Quanto a tela que sai desce, em px.
  static const descidaDaTela = 20.0;

  // H-ANI-10 · Lance, captura e xeque.

  /// A peça desliza da casa de origem à de destino.
  static const lance = Duration(milliseconds: 300);

  /// A capturada encolhe e some depois que a outra peça chega.
  static const capturaSome = Duration(milliseconds: 160);

  /// Até onde a capturada encolhe.
  static const escalaDaCapturada = .55;

  /// Os dois pulsos do halo do xeque.
  static const haloDoXeque = Duration(milliseconds: 700);

  // H-ANI-11 e H-ANI-12 · Retorno do lance e selo na peça.

  /// O selo salta de 0 a 1,2 e volta a 1.
  static const saltoDoSelo = Duration(milliseconds: 260);

  /// A casa pisca na cor do acerto.
  static const piscaDaCasa = Duration(milliseconds: 420);

  /// O tabuleiro respira no acerto.
  static const respiroDoTabuleiro = Duration(milliseconds: 320);

  /// Quanto o tabuleiro cresce no respiro.
  static const escalaDoRespiro = 1.015;

  /// O tabuleiro treme no erro.
  static const tremidaDoTabuleiro = Duration(milliseconds: 340);

  /// Quanto o tabuleiro vai para cada lado na tremida, em px.
  static const amplitudeDaTremida = 7.0;

  /// Do erro até a peça voltar à casa de origem.
  static const voltaDoErro = Duration(milliseconds: 1100);

  // H-ANI-09 · Balão do Viktor.

  /// O balão entra a partir do bico.
  static const balaoEntra = Duration(milliseconds: 280);

  /// A escala do balão ao começar a entrar.
  static const escalaDoBalao = .92;

  /// Quanto o balão sobe ao entrar, em px.
  static const subidaDoBalao = 8.0;

  /// A fala antiga sai.
  static const falaSai = Duration(milliseconds: 90);

  /// A fala nova entra.
  static const falaEntra = Duration(milliseconds: 210);

  // H-ANI-16 · Texto que explica entra em cascata.

  /// O título entra.
  static const tituloEntra = Duration(milliseconds: 380);

  /// Quanto o título sobe, em px.
  static const subidaDoTitulo = 14.0;

  /// Os demais textos, números, selos e o botão entram.
  static const textoEntra = Duration(milliseconds: 320);

  /// Quanto os demais textos sobem, em px.
  static const subidaDoTexto = 10.0;

  /// O intervalo entre os itens da cascata, quando cabem no total.
  static const intervaloDaCascata = Duration(milliseconds: 70);

  /// O tempo máximo da cascata inteira.
  static const totalDaCascata = Duration(milliseconds: 1200);

  /// O número da cascata conta.
  static const numeroDaCascata = Duration(milliseconds: 620);

  /// A escala de emblemas e selos ao começar a entrar.
  static const escalaDoEmblema = .6;

  // H-ANI-17 · Listas em ordem estrita e passos com conector.

  /// Cada linha da lista entra.
  static const itemDaLista = Duration(milliseconds: 300);

  /// O intervalo entre as linhas de uma lista longa.
  static const intervaloDaLista = Duration(milliseconds: 30);

  /// Numa lista longa, a linha a partir da qual o intervalo para de somar.
  static const linhasQueEsperam = 12;

  /// O intervalo fixo entre feitos, checks e bolinhas.
  static const intervaloDosFeitos = Duration(milliseconds: 90);

  /// O passo entra.
  static const passoEntra = Duration(milliseconds: 300);

  /// O conector desce até o passo seguinte.
  static const conectorDesce = Duration(milliseconds: 240);

  /// O tempo máximo dos passos com conector.
  static const totalDosPassos = Duration(milliseconds: 2000);

  // H-ANI-24 · Estado vazio e estado de erro.

  /// O ícone do estado entra.
  static const iconeDoEstado = Duration(milliseconds: 400);

  /// A escala do ícone ao começar a entrar.
  static const escalaDoIcone = .8;

  /// O texto do estado começa depois do ícone.
  static const atrasoDoTextoDoEstado = Duration(milliseconds: 120);

  /// Quanto o texto do estado sobe, em px.
  static const subidaDoEstado = 8.0;

  // H-ANI-25 · Resultado.

  /// Quando cada parte do resultado começa a entrar, desde o primeiro quadro.
  static const resultadoTitulo = Duration(milliseconds: 60);
  static const resultadoSubtitulo = Duration(milliseconds: 120);
  static const resultadoPlacar = Duration(milliseconds: 180);
  static const resultadoBolinhas = Duration(milliseconds: 240);
  static const resultadoViktor = Duration(milliseconds: 560);
  static const resultadoBotoes = Duration(milliseconds: 620);

  /// O placar do resultado conta (termina antes de os botões entrarem).
  static const placarConta = Duration(milliseconds: 400);

  /// Cada bolinha do resultado salta.
  static const bolinhaSalta = Duration(milliseconds: 160);

  /// Os botões do resultado deslizam de baixo.
  static const botoesDoResultado = Duration(milliseconds: 280);

  /// Quanto os botões do resultado sobem, em px.
  static const subidaDosBotoes = 24.0;

  /// O tempo máximo do resultado inteiro.
  static const totalDoResultado = Duration(milliseconds: 1300);

  // H-ANI-03: eixo X compartilhado.

  /// A troca de passo inteira: sai em 30% (90 ms) e entra no resto (210 ms).
  static const eixoX = Duration(milliseconds: 300);

  /// A fração do tempo em que a tela de saída some (eixo X e abas).
  static const fracaoDaSaida = .3;

  /// Quanto o passo desliza para o lado, em px.
  static const deslocamentoDoEixo = 30.0;

  // H-ANI-04: cartão que abre.

  /// O cartão que cresce até a tela.
  static const cartaoAbre = Duration(milliseconds: 450);

  /// O cartão que abre a venda (entrada única).
  static const cartaoDaVenda = Duration(milliseconds: 560);

  /// O raio do cartão que abre a venda.
  static const raioDaVenda = 21.0;

  // H-ANI-05: troca de abas.

  /// A troca das abas de baixo e do "já tem".
  static const abas = Duration(milliseconds: 300);

  /// A troca das abas internas da venda, com o indicador deslizando.
  static const abasDaVenda = Duration(milliseconds: 450);

  /// A escala de que a aba nova parte.
  static const escalaDaAba = .92;

  // H-ANI-20: cartão pressionado.

  /// O cartão afunda no toque.
  static const cartaoAfunda = Duration(milliseconds: 100);

  /// O cartão volta quando o dedo sai.
  static const cartaoVolta = Duration(milliseconds: 200);

  /// A escala do cartão com o dedo em cima.
  static const escalaDoToque = .97;

  // H-ANI-21 e 30: chip e opção selecionados.

  /// A troca de cor, borda e ✓ de chip e opção.
  static const selecao = Duration(milliseconds: 200);

  // H-ANI-22: acordeão.

  /// O acordeão abre e fecha; a seta gira junto.
  static const acordeao = Duration(milliseconds: 300);

  // H-ANI-23: painel de filtro.

  /// A folha do filtro da app bar sobe.
  static const folhaDoFiltro = Duration(milliseconds: 350);

  /// As opções do filtro começam a entrar depois que a folha começa a subir.
  static const atrasoDoFiltro = Duration(milliseconds: 120);

  /// Entre uma opção do filtro e a seguinte.
  static const intervaloDoFiltro = Duration(milliseconds: 40);

  // H-ANI-19: gráfico que se desenha.

  /// A linha do gráfico se desenha na primeira entrada.
  static const graficoDesenha = Duration(milliseconds: 900);

  /// Trocar o período redesenha o gráfico.
  static const graficoRedesenha = Duration(milliseconds: 300);

  /// A área embaixo da linha aparece no fim do desenho.
  static const areaDoGrafico = Duration(milliseconds: 300);

  /// Os pontos começam a saltar depois deste trecho da linha.
  static const pontosDoGrafico = Duration(milliseconds: 300);

  /// Entre um ponto e o seguinte.
  static const intervaloDosPontos = Duration(milliseconds: 40);

  /// O salto de cada ponto.
  static const saltoDoPonto = Duration(milliseconds: 200);
}

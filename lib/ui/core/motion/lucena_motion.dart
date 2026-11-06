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

  /// A curva standard do Material (.4, 0, .2, 1): a da abertura (H-ANI-43/44),
  /// igual ao `fast_out_slow_in` do Android.
  static const standard = Cubic(.4, 0, .2, 1);

  /// Véu, dissolve e giro do carregando.
  static const linear = Curves.linear;

  /// A queda do confete (H-ANI-14): acelera como coisa que cai.
  static const curvaDaQueda = Curves.easeIn;

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

  /// O tabuleiro respira no acerto.
  static const respiroDoTabuleiro = Duration(milliseconds: 320);

  /// Quanto o tabuleiro cresce no respiro.
  static const escalaDoRespiro = 1.015;

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

  // H-ANI-03: troca de exercício por fade cruzado (regra de 04/11).

  /// O fade cruzado entre exercícios, igual ao das perguntas do teste de nível
  /// (B7): a posição, a fala e o enunciado trocam juntos; o tabuleiro fica.
  static const trocaComFade = Duration(milliseconds: 300);

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

  /// A curva do cartão que cresce até a tela (a do container transform); na
  /// volta, invertida.
  static const curvaDoCartao = Curves.fastOutSlowIn;

  /// O trecho da abertura em que a tela aberta aparece por cima do cartão.
  static const fadeDaTelaAberta = Interval(.2, .4);

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

  // H-ANI-28 · meta do dia (`r2/18_sequencia_meta_do_dia`).

  /// A celebração inteira da meta do dia: anel, ✓, contador e faíscas.
  static const celebracaoDaMeta = Duration(milliseconds: 1200);

  /// O anel fecha em volta do dia de hoje (`emphasized`).
  static const anelDaMeta = Duration(milliseconds: 450);

  /// O ✓ e o contador saltam (`elasticOut` curto).
  static const saltoDaMeta = Duration(milliseconds: 300);

  /// O contador sobe a partir deste instante.
  static const contadorDaMeta = Duration(milliseconds: 600);

  /// O salto curto do ✓ e do contador.
  static const Curve salto = ElasticOutCurve(.8);

  // H-ANI-15 · celebração (`r1/19`).

  /// O diploma escala de [escalaDoDiploma] a [picoDoDiploma] e volta a 1.
  static const diplomaDaCelebracao = Duration(milliseconds: 520);
  static const escalaDoDiploma = .88;
  static const picoDoDiploma = 1.03;

  /// A queda de cada partícula do confete.
  static const quedaDoConfete = Duration(milliseconds: 950);

  /// O atraso máximo entre as partículas.
  static const atrasoDoConfete = Duration(milliseconds: 420);

  /// Partículas na celebração grande e na pequena.
  static const confeteGrande = 40;
  static const confetePequeno = 18;

  /// Com movimento reduzido, o diploma só aparece em fade.
  static const fadeDaCelebracao = Duration(milliseconds: 100);

  // H-ANI-14 · cronômetro em barra (R3-42).

  /// A partir desta fração do tempo, a barra vai à cor do fim.
  static const fimDoCronometro = .8;

  // H-ANI-26 · escolha do plano (clipe 06).

  /// O contorno, o fundo e o ponto do rádio trocam de plano.
  static const selecaoDoPlano = Duration(milliseconds: 250);

  /// O rótulo do botão sai...
  static const rotuloSai = Duration(milliseconds: 120);

  /// ...e o novo entra.
  static const rotuloEntra = Duration(milliseconds: 160);

  // H-ANI-27 · compra concluída e compra com falha (clipes 09 e 10).

  /// O círculo do ✓ escala de [escalaDoCirculo] a 1 (DEC); o ✓ salta junto.
  static const circuloDaCompra = Duration(milliseconds: 380);
  static const escalaDoCirculo = .6;
  static const picoDoCheck = 1.18;

  /// O anel vai a [escalaDoAnel] e some.
  static const anelDaCompra = Duration(milliseconds: 700);
  static const escalaDoAnel = 1.7;

  /// O título e o texto sobem [subidaDoTitulo] px, um depois do outro.
  static const tituloDaCompra = Duration(milliseconds: 200);
  static const textoDaCompra = Duration(milliseconds: 260);
  static const sobeDaCompra = Duration(milliseconds: 300);

  /// Os botões entram por último, com [intervaloDosBotoes] entre eles.
  static const botoesDaCompra = Duration(milliseconds: 560);
  static const intervaloDosBotoes = Duration(milliseconds: 100);

  /// O aviso da falha abre (DEC) e o ícone pulsa uma vez a [escalaDoPulso].
  static const avisoAbre = Duration(milliseconds: 320);
  static const pulsoDoAviso = Duration(milliseconds: 400);
  static const escalaDoPulso = 1.3;

  /// "Conhecer o Pilares" no anúncio (H-ANI-31): entra vindo [deslizeDoAnuncio]
  /// px da direita em [entradaDoAnuncio] (DEC) e afunda a [apertoDoAnuncio] em
  /// [afundaDoAnuncio] no toque.
  static const entradaDoAnuncio = Duration(milliseconds: 320);
  static const deslizeDoAnuncio = 12.0;
  static const apertoDoAnuncio = .94;
  static const afundaDoAnuncio = Duration(milliseconds: 220);

  /// "Fechar em N" aparece com fade de [contagemAparece] e cada troca de número
  /// tem fade de [trocaDaContagem].
  static const contagemAparece = Duration(milliseconds: 250);
  static const trocaDaContagem = Duration(milliseconds: 200);

  // H-ANI-44 · abertura em fases (design/branding/abertura2.html). Os tempos de
  // cada fase contam do começo dela.

  /// Entrada (uma vez): agacha a (1,04; 0,96) em 180 ms e volta em 380 ms; os
  /// braços de trás somem de 250 a 420 ms; os da frente crescem de 250 a 520.
  static const aberturaEntrada = Duration(milliseconds: 520);
  static const aberturaAgacha = Duration(milliseconds: 180);
  static const aberturaLevanta = Duration(milliseconds: 380);
  static const aberturaBracosDe = Duration(milliseconds: 250);
  static const aberturaAtrasAte = Duration(milliseconds: 420);
  static const agachaX = 1.04;
  static const agachaY = .96;
  static const bracoNasce = .3;

  /// Ciclo de roscas (em laço): esquerda e depois direita, 160 ms para subir e
  /// 160 para descer; o corpo inclina ±3°. A gota, só no primeiro ciclo,
  /// aparece em 120 ms, desce 30 px até 640 e some descendo até 46 px em 790.
  static const aberturaCiclo = Duration(milliseconds: 640);
  static const aberturaRosca = Duration(milliseconds: 160);
  static const anguloBaixado = 58.0;
  static const inclinacaoDaRosca = 3.0;
  static const gotaAparece = Duration(milliseconds: 120);
  static const gotaSome = Duration(milliseconds: 790);
  static const gotaDesce = 30.0;
  static const gotaSomeEm = 46.0;

  /// Final (uma vez): halteres ao alto em 200 ms; brilho de 150 a 250 ms; o
  /// nome e a descrição de 150 a 450 ms (sobem 12 px); a piscada de 350 a
  /// 490 ms, fechando em 410.
  static const aberturaFinal = Duration(milliseconds: 700);
  static const halteresAoAlto = Duration(milliseconds: 200);
  static const brilhoDe = Duration(milliseconds: 150);
  static const brilhoAte = Duration(milliseconds: 250);
  static const nomeDe = Duration(milliseconds: 150);
  static const nomeAte = Duration(milliseconds: 450);
  static const piscaDe = Duration(milliseconds: 350);
  static const piscaFecha = Duration(milliseconds: 410);
  static const piscaAte = Duration(milliseconds: 490);
  static const olhosFechados = .1;
  static const subidaDoNome = 12.0;
  static const luzDaDescricao = .7;

  /// Saída: figura e nome encolhem a 0,9 com fade (ACC) e a primeira tela
  /// aparece por baixo (DEC); o brilho some nos primeiros 150 ms.
  static const aberturaSaida = Duration(milliseconds: 300);
  static const brilhoSai = Duration(milliseconds: 150);
  static const encolheNaSaida = .9;

  /// Movimento reduzido: o nome em fade de 150 ms e a saída em 100 ms.
  static const nomeReduzido = Duration(milliseconds: 150);
  static const saidaReduzida = Duration(milliseconds: 100);

  /// O lado do quadro de 1024 da figura: o mesmo do ícone animado do Android
  /// 12+ sem fundo (288 dp, visível num círculo de 192), para a passagem da
  /// tela do sistema não ter pulo. O topo do nome fica a 65% da altura.
  static const figuraDaAbertura = 288.0;
  static const topoDoNome = .65;

  // H-ANI-29 · Meta dobrada.

  /// Os cartões entram em fila: 40 ms entre eles, sobem 10 px em 240 ms.
  static const intervaloDaMetaDobrada = Duration(milliseconds: 40);
  static const cartaoDaMetaDobrada = Duration(milliseconds: 240);

  /// "META DOBRADA" sobe 6 px em 300 ms (DEC), depois dos cartões e da barra.
  static const seloDaMetaDobrada = Duration(milliseconds: 300);
  static const subidaDoSeloDobrado = 6.0;

  // T85 · S3b · Resultado em faixas e aviso de conquista na AppBar.

  /// Cada faixa do resultado entra com fade e sobe [subidaDaFaixa] px.
  static const faixaEntra = Duration(milliseconds: 280);
  static const subidaDaFaixa = 14.0;

  /// O intervalo entre o começo de uma faixa e o da seguinte.
  static const intervaloDasFaixas = Duration(milliseconds: 100);

  /// O rating e o delta contam enquanto a faixa entra.
  static const contagemDaFaixa = Duration(milliseconds: 600);

  /// A casca (esqueleto) só aparece se o dado demora mais que isto.
  static const atrasoDaCasca = Duration(milliseconds: 300);
  static const fadeDaCasca = Duration(milliseconds: 150);

  /// O aviso de conquista cai [quedaDoAviso] px com mola leve em
  /// [avisoEntra]; o anterior sai para cima em [avisoSai] e o próximo entra
  /// [intervaloDoAviso] depois do começo da saída.
  static const avisoEntra = Duration(milliseconds: 480);
  static const avisoSai = Duration(milliseconds: 240);
  static const intervaloDoAviso = Duration(milliseconds: 120);
  static const quedaDoAviso = 64.0;
}

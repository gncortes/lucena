# Melhorias · ajustes pedidos depois da v1.7.0-rc.2

Lista viva: o Gabriel manda prints do celular e os pontos entram aqui. Vira uma tarefa numerada quando for atacada (o outro worktree já usa T28 a T31).

## Tela da partida

- [x] **Ponta do balão com defeito.** ([print](../qa/melhorias/e7a6e103.jpg)) A ponta aparece como um triângulo solto, desalinhado da curva do balão. Desenhar balão e ponta como um caminho só (sem emenda), com a ponta levemente curva, na altura do meio da foto, como no chess.com; conferir no claro, no escuro e em árabe (espelhada).
- [x] **Espaço entre o personagem e o tabuleiro.** Hoje o retrato e o balão encostam na borda de cima do tabuleiro. Dar um respiro (uns 8 a 12 px) entre a fileira do personagem e o tabuleiro. ([print](../qa/melhorias/38eb7dc8.jpg))
- [x] **Tabuleiro pequeno (prioridade).** ([print](../qa/melhorias/e7a6e103.jpg)) Com o relógio "dos lados", a fileira do personagem, a fileira do relógio do adversário, a do jogador e o espaço reservado para a lista de lances, o tabuleiro não ocupa a largura da tela, enquanto sobra um vazio embaixo ("Mova uma peça para começar"). Proposta:
  - **regra: o tabuleiro ocupa sempre toda a largura da tela, como em todo app de xadrez** (pedido do Gabriel); o que cede é a lista de lances (que rola) e não o tabuleiro;
  - juntar a fileira do personagem com a do relógio dele (retrato, balão e relógio numa faixa só), como no chess.com, e reduzir o retrato quando a tela for baixa;
  - diminuir o espaço mínimo da lista de lances; a lista vira uma faixa horizontal de lances (como no chess.com e no Lichess) logo abaixo do tabuleiro;
  - conferir em telas pequenas (SmallPhone) e no tema com relógio em cima/embaixo/dos lados.
- [x] **"Próximo desafio" no fim da partida.** Num desafio da Jornada, o painel do fim ganha embaixo a opção de ir direto para o próximo desafio do degrau (ou do degrau seguinte, se este acabou), além de "Jogar de novo". ([print](../qa/melhorias/3d0bf1e2.jpg))

- [x] **Layout do rating, no estilo do chess.com.** (Entrega melhorias-partida: painel do fim e cartão do perfil com o número e o selo; a escolha de período da curva fica para depois.) Hoje é uma linha solta ("📉 Rating 626 (-263)") entre o tabuleiro e os lances. Como no chess.com: o rating novo em destaque, com a variação num selo verde (+) ou vermelho (−) ao lado, dentro do painel do fim da partida. O cartão do rating no perfil segue o mesmo visual (número grande, variação da última partida e a curva com período). ([print](../qa/melhorias/4c10dc0a.jpg))

- [x] **Sem a frase "Mova uma peça para começar".** Pedido do Gabriel (2026-10-05): a faixa de lances fica vazia até o primeiro lance.
- [x] **Cartão animado de vitória/derrota, como no chess.com.** Pedido do Gabriel (2026-10-05): abre por cima da partida no fim, neutro (só o ícone com a cor do resultado), com o rating contando do valor antigo ao novo e a variação em texto verde/vermelho; fechado, o resultado fica no painel embaixo do tabuleiro.
- [x] **Personagem e relógio em linhas separadas.** Pedido do Gabriel (2026-10-05): retrato e balão (alinhados pela base) numa linha; o relógio do adversário numa linha própria, como a do jogador.

## Tela do desafio (Jornada)

- [ ] **Refazer o layout, hoje está feio e vazio.** ([print](../qa/melhorias/b785bea3.jpg)) O que incomoda no print:
  - prévia do tabuleiro minúscula no canto, com o material (♕ – ♚) solto ao lado;
  - o adversário aparece como "Contra Maia 1000", sem o personagem (o Coco);
  - metade de baixo da tela vazia; o histórico é uma lista crua (ícone, "Vitória", data).

  Proposta: tabuleiro grande no topo (largura da tela, como na configuração da partida); um cartão do adversário com retrato, nome, nível e a frase dele; o objetivo e o ritmo em selos; "Jogar" fixo embaixo; o histórico em cartões com o resultado colorido, o tempo gasto e a variação do rating de cada partida; e um estado vazio com convite para jogar.

## Tela inicial

- [ ] **Virar um painel do jogador.** ([print](../qa/melhorias/f566c19e.jpg)) O que incomoda no print:
  - o mascote e o nome do app ocupam quase metade da tela toda vez que o app abre;
  - o cartão de progresso fala "Maia 1000" em vez do personagem, e o rating fica num selo solto;
  - cinco botões grandes empilhados com o mesmo peso visual.

  Proposta:
  - topo compacto: apelido e faixa do jogador, rating em destaque com a variação da última partida (verde/vermelho) e uma mini curva, troféu e configurações;
  - cartão "Continuar": retrato do personagem atual, nome, barra de progresso do degrau e o próximo desafio com o tabuleiro em miniatura;
  - números do progresso em blocos pequenos: partidas jogadas, vitórias, sequência de dias, conquistas (x de 15), melhor tempo de speedrun;
  - atalhos menores em grade (Jornada, Treinar finais, Speedrun) e os de ferramenta (Posição personalizada, Tabuleiro livre) mais discretos;
  - o mascote pequeno (ou só na primeira abertura, no tour).

## Speedrun

- [ ] **Layout e nomes da lista de speedruns.** ([print](../qa/melhorias/f8b57c1c.jpg)) O que incomoda no print:
  - "Degrau Maia 1000", "Os 9 desafios": termos internos ("degrau") e sem o personagem;
  - lista longa de linhas iguais (ícone de cronômetro, "Sem recorde", seta), com o fim cortado pela barra do sistema (a "Jornada completa" fica atrás dela, [print](../qa/melhorias/35e195f7.jpg));
  - nos finais, o subtítulo "Do Maia 1000 ao Stockfish" se repete em todos e o nome do final é só o material em figurino (♕ – ♚): mostrar o nome ("Dama contra rei") junto do figurino;
  - o texto de explicação ocupa o topo inteiro toda vez.

  Proposta de nomes (a confirmar):
  - seção "Degraus" → **"Desafios por adversário"**; item "Degrau Maia 1000" → **"Contra o Coco"** (retrato + "1000 · 9 desafios");
  - seção "Finais" → **"Um final, todos os adversários"**; "Exercícios" → **"Séries de exercícios"**; "Campanha" → **"Jornada completa"**;
  - "Sem recorde" → **"Ainda sem tempo"**; "Recorde pessoal" → **"Seu melhor tempo"**.

  Proposta de layout: cartões em vez de linhas; o retrato do personagem (ou o material do final) no cartão; o melhor tempo em destaque quando houver; tentativa em andamento no topo com "Continuar"; a explicação vira um ícone de ajuda (ⓘ) que abre um painel; espaço embaixo para rolar até o fim.

- [ ] **Tela de um speedrun (antes de começar).** ([print](../qa/melhorias/bae1cc34.jpg)) O que incomoda no print:
  - "Recorde pessoal · Sem recorde" num bloco verde enorme, repetindo a palavra recorde;
  - as etapas são 9 linhas iguais "Maia 1000" com um número: não dá para saber que final é cada uma;
  - título com "Degrau Maia 1000" e o ritmo "5 min + 3 s" escondido na linha de cima.

  Proposta:
  - cabeçalho com o retrato do personagem, nome do speedrun (ver os nomes novos acima) e o ritmo em selo ("5+3 · Blitz");
  - melhor tempo em destaque só quando existir; sem tempo, um texto curto de convite ("Seu primeiro tempo vai aparecer aqui");
  - etapas em grade de miniaturas do tabuleiro, numeradas, com o nome do final e o melhor tempo de cada uma (quando houver);
  - "Começar" fixo embaixo, com o total de etapas.

- [ ] **Tentativa em andamento confusa.** ([print](../qa/melhorias/8da8fb64.jpg)) Nove linhas "Maia 1000" com bolinhas: não se vê que final vem, quanto cada etapa levou nem quanto falta. Proposta: a etapa atual em destaque (tabuleiro, nome do final, adversário e "Continuar a partida"); as feitas com o tempo de cada uma; uma barra "etapa 1 de 9" e o total grande no topo; "Desistir" discreto no menu (⋮).

## Ritmo de jogo (speedrun e Jornada)

- [ ] **Escolher o ritmo, como no chess.com.** Hoje o speedrun tem ritmo fixo (5+3) e o desafio da Jornada não mostra ritmo nenhum. Proposta:
  - ao tocar em "Começar" (speedrun) ou "Jogar" (desafio), abre um painel com os ritmos em grade, agrupados como no chess.com: Bullet (1+0, 2+1), Blitz (3+0, 3+2, 5+3), Rápido (10+0, 15+10) e "Sem relógio" (só na Jornada);
  - o último ritmo escolhido vem marcado e fica gravado;
  - no speedrun, os recordes passam a ser **por ritmo** (o melhor tempo em 3+2 não se mistura com o de 5+3); a lista mostra o melhor tempo do ritmo selecionado;
  - muda a regra da T20 (ritmo fixo por speedrun para os tempos serem comparáveis): os tempos continuam comparáveis dentro do mesmo ritmo. **Decisão do Gabriel (2026-10-05):** cada ritmo é um speedrun próprio (1+0 é um, 1+1 é outro), com recordes separados; o speedrun fica agrupado por ritmo (bullet, blitz, rápido) e, dentro de cada um, os vários ritmos.

## Animações

- [ ] **Transições entre telas.** Hoje a troca de tela é a padrão do Android e parece seca. Proposta:
  - transição única no app inteiro (deslizar com fade, ou a "shared axis" do Material) com curva suave, no tema (`pageTransitionsTheme`) e nas rotas do `go_router`;
  - elementos compartilhados (`Hero`): o retrato do personagem da Jornada para o degrau e para a partida; o tabuleiro em miniatura do desafio para o tabuleiro da partida;
  - listas entrando em cascata (cada item com um pequeno atraso) na Jornada, no degrau, no speedrun e nas conquistas;
  - fim da partida: painel do resultado e mensagens surgindo em sequência; conquista nova com um destaque (brilho/escala);
  - números que mudam (rating, tempo do speedrun) contando até o valor novo;
  - tudo respeitando "remover animações" do sistema.

- [ ] **Repensar a notação do material (♕ – ♚) nas listas.** Economiza espaço mas fica ruim de ler: figurinos pequenos, o traço solto no meio e nada de texto. Vale para o speedrun de final, o catálogo e a Jornada. Opções a testar e mostrar ao Gabriel antes de decidir:
  - nome do final por extenso como título ("Dama contra rei", "Torre e peão contra torre"), com as peças grandes num selo ao lado;
  - as peças de cada lado em dois "chips" (brancas claro, pretas escuro) em vez do traço;
  - a miniatura do tabuleiro da posição no lugar das peças.

## Nomes no app

- [ ] **Revisar a palavra "degrau" em todas as telas.** Usar o personagem ("Contra o Coco") ou "nível" onde "degrau" aparece para o jogador (Jornada, tour, conquistas, mensagens do fim da partida). Manter "degrau" só no código.

## Tela da Jornada

- [ ] **Refazer a lista de degraus.** ([print](../qa/melhorias/c26d2730.jpg)) O que incomoda no print:
  - o cartão de cima fala "Maia 1000" e "Próximo: Maia 1200" em vez dos personagens, e é um bloco verde só de texto;
  - os degraus são uma lista plana igual à de configurações: não parece um caminho a subir;
  - os trancados só ficam um pouco apagados; o cadeado e a seta repetem em todos;
  - mesmo rolando até o fim, o Stockfish fica cortado atrás da barra do sistema ([print](../qa/melhorias/dbc7d8d5.jpg));
  - o Stockfish aparece só com um cadeado no lugar do retrato: deve ter o logo dele, como na partida.

  Proposta: um caminho vertical (trilha) com os retratos em círculo ligados por uma linha, o degrau atual maior e em destaque com a barra de progresso e "Continuar"; os concluídos com selo de feito, os trancados em cinza com cadeado sobre o retrato e sem a seta; o Stockfish no topo como chefe final; o cartão de cima com o retrato do adversário atual, o progresso e o próximo personagem; espaço embaixo para rolar até o fim.

## Tela do degrau (Jornada)

- [ ] **Refazer a lista dos desafios do degrau.** ([print](../qa/melhorias/6167f3c6.jpg)) O que incomoda no print:
  - título "Maia 1000" sem o personagem; o progresso é só um texto ("1 de 9 desafios");
  - nove linhas iguais (tabuleiro pequeno, material, "Ganhar" verde e uma seta): nada diz qual é o próximo nem separa feito de por fazer;
  - "Ganhar" repetido em todas, ocupando o espaço da informação útil;
  - o último item fica atrás da barra de navegação do sistema (falta espaço embaixo).

  Proposta: cabeçalho com o retrato e o nome do personagem, a frase dele e uma barra de progresso (1/9); o próximo desafio em destaque (cartão maior, com "Jogar"); os outros em grade de 2 ou 3 colunas, cada um com o tabuleiro, o nome do final (ex.: "Mate de dama") e um selo de feito; o objetivo só aparece quando for diferente do comum (ex.: "Empatar"); espaço embaixo para rolar até o fim.

- [x] **Fim da lista cortado.** O último desafio fica atrás da barra de navegação do sistema e não dá para rolar até ele inteiro: falta o espaço de baixo (`SafeArea`/padding) em todas as listas. ([print](../qa/melhorias/89eeba71.jpg))
- [x] **"Defender" não é vermelho.** Vermelho parece erro ou derrota. Usar uma cor neutra de destaque (azul ou âmbar) com o ícone de escudo, e o verde para "Ganhar"; vale no catálogo, na Jornada e na configuração. ([print](../qa/melhorias/89eeba71.jpg))

## Notado nos mesmos prints (para confirmar com o Gabriel)

- [x] **Empate combinado em posição ganha derrubou o rating em 263 pontos** (889 → 626). O empate conta como objetivo não cumprido (0 ponto) e o desvio ainda está alto. **Decisão do Gabriel (2026-10-05):** empate vale meio ponto no Glicko-2, contra o adversário equivalente: se ele for mais forte que o jogador, o rating sobe; se for mais fraco, desce (vale para empate combinado e para os empates do tabuleiro). ([print](../qa/melhorias/4c10dc0a.jpg))
- [x] **Parte de baixo cortada, sem espaço para rolar.** No fim da partida, a lista de lances fica cortada (uma linha e meia visível, a de baixo pela metade). A área de baixo precisa rolar até o fim, com um espaço (padding) depois do último lance para nada ficar colado na borda. Rever também a ordem: talvez o rating dentro do painel do fim. ([print](../qa/melhorias/4c10dc0a.jpg))

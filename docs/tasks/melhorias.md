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

- [x] **Layout do rating, no estilo do chess.com.** (Painel do fim, cartão do perfil e tela inicial com o número e a variação; a curva do perfil tem período: últimas 10, últimas 30 ou todas as partidas.) Hoje é uma linha solta ("📉 Rating 626 (-263)") entre o tabuleiro e os lances. Como no chess.com: o rating novo em destaque, com a variação num selo verde (+) ou vermelho (−) ao lado, dentro do painel do fim da partida. O cartão do rating no perfil segue o mesmo visual (número grande, variação da última partida e a curva com período). ([print](../qa/melhorias/4c10dc0a.jpg))

- [x] **Sem a frase "Mova uma peça para começar".** Pedido do Gabriel (2026-10-05): a faixa de lances fica vazia até o primeiro lance.
- [x] **Cartão animado de vitória/derrota, como no chess.com.** Pedido do Gabriel (2026-10-05): abre por cima da partida no fim, neutro (só o ícone com a cor do resultado), com o rating contando do valor antigo ao novo e a variação em texto verde/vermelho; fechado, o resultado fica no painel embaixo do tabuleiro.
- [x] **Personagem e relógio em linhas separadas.** Pedido do Gabriel (2026-10-05): retrato e balão (alinhados pela base) numa linha; o relógio do adversário numa linha própria, como a do jogador.

- [x] **Tela da partida rola inteira.** Pedido do Gabriel (2026-10-05): como nos apps de xadrez; com o dedo no tabuleiro, a rolagem trava.
- [x] **Rating no ritmo do chess.com.** Pedido do Gabriel (2026-10-05): o desvio do Glicko-2 fica no teto de 50; contra um igual, uns 7 pontos por partida, sem saltos nas primeiras.

- [x] **Cores mais harmônicas no tema claro.** Pedido do Gabriel (2026-10-05): o azul principal deixou de ser quase preto e os destaques passaram a azul claro com texto azul-marinho, no app todo.
- [x] **Tela inicial só com o título; versão nas Configurações.** Pedido do Gabriel (2026-10-05).
- [x] **Catálogo com os finais por nome e o progresso.** Pedido do Gabriel (2026-10-05).

## Aparência do app (tema, cor e tabuleiro)

- [x] **Escolher a cor do app, como no Twitter.** Pedido do Gabriel (2026-10-05): além de claro/escuro, o jogador escolhe a cor predominante (azul, verde, roxo, rosa, laranja ou turquesa). Cada cor tem um tom para o tema claro e outro para o escuro, com o fundo puxado de leve para a mesma família. Sem escolha, fica como era: azul no claro e verde no escuro. Fica em Configurações → Tema.
- [x] **Aparência já na primeira abertura.** Pedido do Gabriel (2026-10-05): logo depois das boas-vindas, o tour ganha dois passos, "Deixe o app com a sua cara" (tema e cor do app, valendo na hora) e "Escolha o seu tabuleiro" (cores e peças, com a amostra); os dois avisam que dá para mudar depois nas Configurações. O tour passa de 8 para 10 passos.
- [x] **Voo do cartão "Continuar" até o desafio.** Pedido do Gabriel (2026-10-05): na tela inicial, o tabuleiro pequeno cresce até o da tela do desafio e o retrato do adversário voa até o cartão dele (o retrato também voa a partir da tela do adversário). O desafio abre por cima da tela inicial: voltar cai nela.
- [x] **Curva do rating fora do cartão da tela inicial; tela de detalhes do rating.** Pedido do Gabriel (2026-10-05): a curva espremida no cartão não ficou boa. O cartão fica só com o apelido, a faixa e o rating; tocar nele abre os detalhes: o número, o gráfico com a escala (10, 30 ou todas as partidas; tocar mostra o rating de cada uma) e o histórico das partidas que contaram, com o resultado, o adversário, a data e a variação.
- [x] **Partida sem relógio: a linha de cada lado e a vez.** Pedido do Gabriel (2026-10-05): mesmo sem relógio, o adversário fica em cima e o jogador embaixo do tabuleiro, cada um com o peão da cor dele e o nome; na ponta da linha de quem joga, "Sua vez" (ou "Jogam as brancas/pretas").
- [x] **Lista de lances em tabela, como no chess.com.** Pedido do Gabriel (2026-10-05): volta a ser uma linha por lance (número, brancas, pretas), com as linhas alternadas e o último lance em destaque, no lugar da faixa numa linha só; ela fica com o espaço que sobra embaixo do tabuleiro e rola sozinha até o último lance.
- [x] **Conquistas e mensagens com o nome do personagem.** Pedido do Gabriel (2026-10-05): nada de "Maia 1800" nas conquistas e nas mensagens do fim da partida; aparece o personagem ("Primeira vitória contra Zuri!").
- [x] **Aviso animado de conquista, como o troféu do PlayStation.** Pedido do Gabriel (2026-10-05): a conquista nova desce do alto da tela por cima da partida, com o troféu dourado saltando e um brilho passando por ele, e some sozinha; várias, uma depois da outra; respeita "remover animações".

## Tela do desafio (Jornada)

- [x] **Refazer o layout, hoje está feio e vazio.** (Feito, menos a variação do rating em cada partida do histórico: a tentativa ainda não guarda o rating dela.) ([print](../qa/melhorias/b785bea3.jpg)) O que incomoda no print:
  - prévia do tabuleiro minúscula no canto, com o material (♕ – ♚) solto ao lado;
  - o adversário aparece como "Contra Maia 1000", sem o personagem (o Coco);
  - metade de baixo da tela vazia; o histórico é uma lista crua (ícone, "Vitória", data).

  Proposta: tabuleiro grande no topo (largura da tela, como na configuração da partida); um cartão do adversário com retrato, nome, nível e a frase dele; o objetivo e o ritmo em selos; "Jogar" fixo embaixo; o histórico em cartões com o resultado colorido, o tempo gasto e a variação do rating de cada partida; e um estado vazio com convite para jogar.

## Tela inicial

- [x] **Virar um painel do jogador.** ([print](../qa/melhorias/f566c19e.jpg)) O que incomoda no print:
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

- [x] **Layout e nomes da lista de speedruns.** ([print](../qa/melhorias/f8b57c1c.jpg)) O que incomoda no print:
  - "Degrau Maia 1000", "Os 9 desafios": termos internos ("degrau") e sem o personagem;
  - lista longa de linhas iguais (ícone de cronômetro, "Sem recorde", seta), com o fim cortado pela barra do sistema (a "Jornada completa" fica atrás dela, [print](../qa/melhorias/35e195f7.jpg));
  - nos finais, o subtítulo "Do Maia 1000 ao Stockfish" se repete em todos e o nome do final é só o material em figurino (♕ – ♚): mostrar o nome ("Dama contra rei") junto do figurino;
  - o texto de explicação ocupa o topo inteiro toda vez.

  Proposta de nomes (a confirmar):
  - seção "Degraus" → **"Desafios por adversário"**; item "Degrau Maia 1000" → **"Contra o Coco"** (retrato + "1000 · 9 desafios");
  - seção "Finais" → **"Um final, todos os adversários"**; "Exercícios" → **"Séries de exercícios"**; "Campanha" → **"Jornada completa"**;
  - "Sem recorde" → **"Ainda sem tempo"**; "Recorde pessoal" → **"Seu melhor tempo"**.

  Proposta de layout: cartões em vez de linhas; o retrato do personagem (ou o material do final) no cartão; o melhor tempo em destaque quando houver; tentativa em andamento no topo com "Continuar"; a explicação vira um ícone de ajuda (ⓘ) que abre um painel; espaço embaixo para rolar até o fim.

- [x] **Tela de um speedrun (antes de começar).** ([print](../qa/melhorias/bae1cc34.jpg)) O que incomoda no print:
  - "Recorde pessoal · Sem recorde" num bloco verde enorme, repetindo a palavra recorde;
  - as etapas são 9 linhas iguais "Maia 1000" com um número: não dá para saber que final é cada uma;
  - título com "Degrau Maia 1000" e o ritmo "5 min + 3 s" escondido na linha de cima.

  Proposta:
  - cabeçalho com o retrato do personagem, nome do speedrun (ver os nomes novos acima) e o ritmo em selo ("5+3 · Blitz");
  - melhor tempo em destaque só quando existir; sem tempo, um texto curto de convite ("Seu primeiro tempo vai aparecer aqui");
  - etapas em grade de miniaturas do tabuleiro, numeradas, com o nome do final e o melhor tempo de cada uma (quando houver);
  - "Começar" fixo embaixo, com o total de etapas.

- [x] **Tentativa em andamento confusa.** ([print](../qa/melhorias/8da8fb64.jpg)) Nove linhas "Maia 1000" com bolinhas: não se vê que final vem, quanto cada etapa levou nem quanto falta. Proposta: a etapa atual em destaque (tabuleiro, nome do final, adversário e "Continuar a partida"); as feitas com o tempo de cada uma; uma barra "etapa 1 de 9" e o total grande no topo; "Desistir" discreto no menu (⋮).

## Ritmo de jogo (speedrun e Jornada)

- [x] **Escolher o ritmo, como no chess.com.** Hoje o speedrun tem ritmo fixo (5+3) e o desafio da Jornada não mostra ritmo nenhum. Proposta:
  - ao tocar em "Começar" (speedrun) ou "Jogar" (desafio), abre um painel com os ritmos em grade, agrupados como no chess.com: Bullet (1+0, 2+1), Blitz (3+0, 3+2, 5+3), Rápido (10+0, 15+10) e "Sem relógio" (só na Jornada);
  - o último ritmo escolhido vem marcado e fica gravado;
  - no speedrun, os recordes passam a ser **por ritmo** (o melhor tempo em 3+2 não se mistura com o de 5+3); a lista mostra o melhor tempo do ritmo selecionado;
  - muda a regra da T20 (ritmo fixo por speedrun para os tempos serem comparáveis): os tempos continuam comparáveis dentro do mesmo ritmo. **Decisão do Gabriel (2026-10-05):** cada ritmo é um speedrun próprio (1+0 é um, 1+1 é outro), com recordes separados; o speedrun fica agrupado por ritmo (bullet, blitz, rápido) e, dentro de cada um, os vários ritmos.

## Animações

- [x] **Transições entre telas.** (Transição única no tema, listas em cascata, retrato e tabuleiro voando entre as telas da Jornada, cartão do resultado e rating contando; tudo respeita "remover animações".) Hoje a troca de tela é a padrão do Android e parece seca. Proposta:
  - transição única no app inteiro (deslizar com fade, ou a "shared axis" do Material) com curva suave, no tema (`pageTransitionsTheme`) e nas rotas do `go_router`;
  - elementos compartilhados (`Hero`): o retrato do personagem da Jornada para o degrau e para a partida; o tabuleiro em miniatura do desafio para o tabuleiro da partida;
  - listas entrando em cascata (cada item com um pequeno atraso) na Jornada, no degrau, no speedrun e nas conquistas;
  - fim da partida: painel do resultado e mensagens surgindo em sequência; conquista nova com um destaque (brilho/escala);
  - números que mudam (rating, tempo do speedrun) contando até o valor novo;
  - tudo respeitando "remover animações" do sistema.

- [x] **Repensar a notação do material (♕ – ♚) nas listas.** (Escolhida a primeira opção nas telas novas: o nome do final por extenso; no speedrun, as peças em duas linhas no quadro. O catálogo continua com o figurino, a mostrar ao Gabriel.) Economiza espaço mas fica ruim de ler: figurinos pequenos, o traço solto no meio e nada de texto. Vale para o speedrun de final, o catálogo e a Jornada. Opções a testar e mostrar ao Gabriel antes de decidir:
  - nome do final por extenso como título ("Dama contra rei", "Torre e peão contra torre"), com as peças grandes num selo ao lado;
  - as peças de cada lado em dois "chips" (brancas claro, pretas escuro) em vez do traço;
  - a miniatura do tabuleiro da posição no lugar das peças.

## Nomes no app

- [x] **Revisar a palavra "degrau" em todas as telas.** (Jornada, tour e conquistas; as do speedrun saem no lote do speedrun.) Usar o personagem ("Contra o Coco") ou "nível" onde "degrau" aparece para o jogador (Jornada, tour, conquistas, mensagens do fim da partida). Manter "degrau" só no código.

## Tela da Jornada

- [x] **Refazer a lista de degraus.** (Pedido do Gabriel em 2026-10-05: a trilha vai do mais fraco ao mais forte, com o Stockfish no fim.) ([print](../qa/melhorias/c26d2730.jpg)) O que incomoda no print:
  - o cartão de cima fala "Maia 1000" e "Próximo: Maia 1200" em vez dos personagens, e é um bloco verde só de texto;
  - os degraus são uma lista plana igual à de configurações: não parece um caminho a subir;
  - os trancados só ficam um pouco apagados; o cadeado e a seta repetem em todos;
  - mesmo rolando até o fim, o Stockfish fica cortado atrás da barra do sistema ([print](../qa/melhorias/dbc7d8d5.jpg));
  - o Stockfish aparece só com um cadeado no lugar do retrato: deve ter o logo dele, como na partida.

  Proposta: um caminho vertical (trilha) com os retratos em círculo ligados por uma linha, o degrau atual maior e em destaque com a barra de progresso e "Continuar"; os concluídos com selo de feito, os trancados em cinza com cadeado sobre o retrato e sem a seta; o Stockfish no topo como chefe final; o cartão de cima com o retrato do adversário atual, o progresso e o próximo personagem; espaço embaixo para rolar até o fim.

## Tela do degrau (Jornada)

- [x] **Refazer a lista dos desafios do degrau.** ([print](../qa/melhorias/6167f3c6.jpg)) O que incomoda no print:
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

## Experiência de uso (feedback do Gabriel depois da v1.10.0-rc.1)

O Gabriel, usando a v1.10.0-rc.1 no celular (2026-10-05): "não estou gostando da experiência que o usuário tem nesse aplicativo", "tô achando o app bem confuso, principalmente naquela parte de ritmo de tempo".

- [x] **Pedir o nome do jogador no começo do tour.** Pedido do Gabriel (2026-10-05): "faltou na tela inicial ali do tour ele adicionar o nome dele, para sempre ficar gravado". No primeiro passo, um campo para o nome (o apelido do perfil, que aparece no "Olá, ..." da tela inicial); fica gravado na hora e dá para mudar depois no perfil. Sem nome, continua "Jogador". Feito: campo "Como devo chamar você?" nas boas-vindas, gravado enquanto se digita (fechar o app no meio não perde).
- [x] **Ritmo da partida: tirar o mais e o menos da tela.** Pedido do Gabriel (2026-10-05): não gostou dos botões de mais/menos de minutos e incremento embaixo dos chips de ritmo, na configuração da partida. Proposta dele: uma opção "Personalizar ritmo" junto dos chips, que abre um modal com esses ajustes, num layout melhor. Feito: os dois cartões saíram; o chip "Personalizar" abre o painel com o ritmo em destaque (`10+5 · Rápido`) e controles deslizantes de minutos e incremento, com "mesmo tempo para os dois lados" ligado de fábrica. O 5+0 entrou nos ritmos nomeados (era o tempo de fábrica e aparecia como personalizado).
- [x] **Tela inicial: deixar claro para onde ir.** Pedido do Gabriel (2026-10-05, [print](../qa/melhorias/f3a3460c.jpg)): "tá bem confuso aqui para mim [...] eu não sei para onde ir". Os botões de hoje (Jornada, Treinar finais, Speedrun, Aulas com o Viktor) só têm o nome; cada caminho precisa dizer para quem é e o que se faz nele:
  - **Aprender a jogar xadrez** (iniciante): as aulas do Viktor, com o movimento das peças e o básico.
  - **Speedrun**: escolher um mate e subir todos os níveis do Maia até o Stockfish contra o relógio, no ritmo escolhido.
  - **Treinar finais avulsos**: escolher um final e jogar.
  - Mais adiante entram outros caminhos (por exemplo, aprender finais teóricos, que já não é para iniciante): a tela tem de aceitar mais opções.
- [x] **Speedrun: só por final; os desafios por adversário viram treino de iniciante.** Pedido do Gabriel (2026-10-05, [print](../qa/melhorias/00ab46c8.jpg)): a ideia do speedrun é escolher um final específico e jogá-lo contra os personagens, um depois do outro, até o Stockfish, no mesmo ritmo, com o histórico. A tela de Speedrun fica só com essa escolha do final (começando com alguns finais interessantes). A seção "Desafios por adversário" (Contra o Coco, 9 etapas...) sai dali e vira um módulo de treino para iniciante, complementar às aulas do Viktor.
  - Os finais do speedrun (Gabriel, 2026-10-05): nove ou dez finais típicos, no máximo, subindo a dificuldade aos poucos. Citados por ele: mate de torre, mate de dama, mate de dois bispos, dama contra torre e torre e peão contra torre; o resto fica a escolher. Os finais avulsos ("Treinar finais") ficam para depois.
  - O formato (Gabriel, 2026-10-05): no speedrun só se escolhe o ritmo; a ordem é sempre do Maia mais fraco até o Stockfish. A tela mostra o progresso personagem a personagem (como a trilha da Jornada); dá para desistir e recomeçar, e o histórico diz até onde cada tentativa foi e se foi concluída. Concluir um speedrun rende uma conquista. "Entrei no app, vou fazer o speedrun de mate com os dois bispos: começo pelo Coco, bati, vou para o próximo... até o Stockfish; depois olho o histórico e vejo como me saí nesse final."
  - "Treinar finais" (o catálogo com as categorias) fica como está.
  - Os três perfis que a reformulação atende (Gabriel, 2026-10-05): o iniciante, que precisa saber logo onde tocar; quem quer o speedrun (o mesmo final contra todos os níveis do Maia e o Stockfish, vendo o recorde e o histórico de tempos); e quem quer treinar um final avulso, escolhendo o adversário.
- [x] **Conquista com o nome do personagem errado.** Bug visto pelo Gabriel (2026-10-05): ganhou do Gino num final e o aviso foi da conquista "Vitória contra Tank". A regra é "contra o Tank ou alguém mais forte", então vencer o Gino (mais forte) libera a do Tank: o nome que aparece não é o de quem foi vencido. Feito: a conquista de cada personagem só sai vencendo ele mesmo, e agora há uma para cada um dos nove (antes só Tank e Viktor).
- [x] **Mais conquistas: uma por final de speedrun e por ritmo.** Pedido do Gabriel (2026-10-05): para cada final do speedrun, uma conquista por concluí-lo no bullet, outra no blitz e outra no rápido. Feito: 27 conquistas (9 finais × 3 ritmos) e "Linha de chegada" pelo primeiro speedrun concluído; o total foi de 15 para 50.

Como ficou (2026-10-05):

- Tela inicial: depois do "Continuar", a seção "O que você quer fazer?" com um cartão por caminho, cada um com uma linha de explicação, na ordem de quem está aprendendo: Aprender a jogar xadrez (as aulas do Viktor), Jornada ("O passo seguinte às aulas: pratique vencendo os finais de cada adversário..."), Speedrun e Treinar finais. Os quatro com a mesma cor, sem destaque (pedido do Gabriel depois de ver a primeira versão). O nome do app e os botões de conquistas e configurações ficam fixos no alto.
- Os números do jogador (partidas, vitórias, dias seguidos, conquistas e melhor speedrun) saíram da tela inicial, que ficou poluída (Gabriel, 2026-10-05), e foram para os detalhes do rating, que abrem tocando no cartão do jogador.
- Jornada: a tela abre dizendo que ela é o passo seguinte às aulas do Viktor, para praticar e encarar novos desafios (pedido do Gabriel, 2026-10-05). Os nomes dos modos não mudaram.
- Speedrun: o app leva só os de final, nove, nesta ordem: mate de torre, mate de dama, mate de dois bispos, dama contra torre, torre e peão contra torre, peão contra rei, torre contra peão, dama contra peão e mate de bispo e cavalo. O catálogo ganhou as posições de dois bispos (3) e de bispo e cavalo (2), conferidas na tablebase. A tela do speedrun mostra as etapas no formato de passos da Jornada (pedido do Gabriel depois de ver a primeira versão): os retratos dos adversários ligados por uma linha, do Coco ao Stockfish (o chefe final), o selo de feito nas etapas vencidas, a da vez maior e em destaque e, em andamento, uma barra de progresso com um segmento por etapa. O histórico inclui as desistências ("Desistiu na etapa 4 de 10").
- Os desafios por adversário, as séries de exercícios e a Jornada completa saíram do speedrun (o app ainda sabe ler essas modalidades, mas não leva nenhuma). A Jornada, que tem os mesmos desafios por adversário sem o relógio, é apresentada na tela inicial como o treino guiado que complementa as aulas.

Pedidos seguintes do Gabriel (2026-10-05), na mesma entrega ("pode juntar tudo nessa mesma branch"):

- [x] **Tela da partida como a do chess.com: lances numa faixa no alto, tocáveis.** ([print do chess.com](../qa/melhorias/8d60273e.jpg)) Os lances ficam numa faixa que rola para o lado, logo abaixo da barra do alto; tocar num lance mostra a posição daquele momento, só para ver (sem mexer nas peças). No print, embaixo ficam os botões de voltar e avançar um lance. Troca a tabela de lances embaixo do tabuleiro, feita na v1.10.0. Feito: a faixa fica na barra do alto, com o lance que está no tabuleiro em destaque; tocar num lance (ou "Voltar" e "Avançar", embaixo) mostra a posição daquele momento com o tabuleiro travado; no último lance, ou quando o adversário joga, o tabuleiro volta para a partida.

- [x] **Histórico do speedrun: tocar numa tentativa abre os detalhes dela.** Pedido do Gabriel (2026-10-05): ao tocar numa linha do histórico, abre a tentativa com a marca de cada etapa (o tempo e as derrotas contra cada adversário).
- [x] **Histórico geral de partidas, na tela de estatísticas.** Pedido do Gabriel (2026-10-05, [print do chess.com](../qa/melhorias/34e4e29b.jpg)): todas as partidas, de qualquer modo (Jornada, speedrun, finais avulsos), da mais recente para a mais antiga, rolando sem fim, no layout do print: o ritmo, o retrato e o nome do adversário e o resultado. Feito na tela que abre pelo cartão do jogador (os detalhes do rating): cada linha tem o ritmo, o retrato, o nome e o nível, o final jogado e a data, a marca de vitória, empate ou derrota e, nas partidas que contaram, o rating depois dela e a variação. Substitui o antigo "Histórico do rating".

## Estatísticas, detalhes da partida e speedrun direto (feedback do Gabriel depois da v1.11.0-rc.2)

Pedidos do Gabriel em 2026-10-05, usando a v1.11.0-rc.2 no celular. Ele valida por prints antes da suíte.

- [ ] **Tela de estatísticas: layout melhor, inspirado no chess.com.** ([print 1](../qa/melhorias/c333bae9.jpg), [print 2](../qa/melhorias/25f17eca.jpg)) "Bora melhorar o layout dessas duas telas"; "se inspira um pouco mais no chess.com, nos widgets que tem lá". Os filtros do gráfico ("Últimas 10", "Últimas 30") "não fazem muito sentido": trocar por período de tempo. No print, a linha do histórico corta o nome do final e a data ("Mate de dois bispos…").
- [ ] **Detalhes de uma partida.** Tocar numa partida do histórico abre os detalhes dela: os dados da partida e os lances, com o tempo gasto em cada lance ("a minutagem em cada lance"). "É como se fosse o histórico da partida mesmo, sem nenhuma análise"; a análise com o treinador vem depois.
- [ ] **Speedrun: entrar na partida com menos toques.** ([print](../qa/melhorias/9c99345c.jpg)) "Quando ele clica no speedrun, tem que clicar duas vezes para entrar no desafio, em vez de uma vez só [...] não sei para que tantos passos". Hoje: lista → speedrun → "Começar" → ritmo → tentativa → "Jogar a etapa 1" → partida, e de novo a tentativa entre uma etapa e outra.
  - Depois (Gabriel, 2026-10-05): "não existe esse conceito de continuar a partida. Ou ele tenta o speedrun, ou ele sai fora [...] tem que ser bem dinâmico: ele entra, já faz um final, clica em continuar e já está no próximo, jogando". Ou seja: começar abre a primeira etapa; "Continuar" no fim de cada uma abre a seguinte; sair no meio encerra a tentativa.
- [ ] **Tela da tentativa do speedrun: layout e textos.** No mesmo print: "o layout nessa tela ainda está um pouco feio"; "Tentar novamente" em vez de "Jogar a etapa 1 de novo".

  - O tempo no alto ("1:15.8") confunde: "é 1h15? 1.8?" (Gabriel, 2026-10-05). Mostrar o tempo de um jeito que diga as unidades.
  - O menu de três pontos com uma opção só ([print](../qa/melhorias/c0753f34.jpg)): pôr a ação direto na barra, e desistir tem de pedir confirmação.

- [ ] **Catálogo: as posições já abertas na tela da categoria.** ([print](../qa/melhorias/f1f72395.jpg)) Pedido do Gabriel (2026-10-05): em "Finais de peão" há uma linha só ("♙ – ♚, 9 posições") e é preciso tocar nela para ver as posições. Ele prefere que a tela da categoria já mostre as posições de cada final, expandidas, para tocar e entrar; quem não quiser ver expandido recolhe a seção.

Em aberto, para confirmar com o Gabriel:

- [ ] **"Recomeçar" o speedrun.** Hoje é desistir (menu da tentativa) e começar de novo; não há um botão único.

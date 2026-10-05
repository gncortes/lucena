# Melhorias · ajustes pedidos depois da v1.7.0-rc.2

Lista viva: o Gabriel manda prints do celular e os pontos entram aqui. Vira uma tarefa numerada quando for atacada (o outro worktree já usa T28 a T31).

## Tela da partida

- [ ] **Espaço entre o personagem e o tabuleiro.** Hoje o retrato e o balão encostam na borda de cima do tabuleiro. Dar um respiro (uns 8 a 12 px) entre a fileira do personagem e o tabuleiro. ([print](../qa/melhorias/38eb7dc8.jpg))
- [ ] **"Próximo desafio" no fim da partida.** Num desafio da Jornada, o painel do fim ganha embaixo a opção de ir direto para o próximo desafio do degrau (ou do degrau seguinte, se este acabou), além de "Jogar de novo". ([print](../qa/melhorias/3d0bf1e2.jpg))

- [ ] **Layout do rating, no estilo do chess.com.** Hoje é uma linha solta ("📉 Rating 626 (-263)") entre o tabuleiro e os lances. Como no chess.com: o rating novo em destaque, com a variação num selo verde (+) ou vermelho (−) ao lado, dentro do painel do fim da partida. O cartão do rating no perfil segue o mesmo visual (número grande, variação da última partida e a curva com período). ([print](../qa/melhorias/4c10dc0a.jpg))

## Tela do desafio (Jornada)

- [ ] **Refazer o layout, hoje está feio e vazio.** ([print](../qa/melhorias/b785bea3.jpg)) O que incomoda no print:
  - prévia do tabuleiro minúscula no canto, com o material (♕ – ♚) solto ao lado;
  - o adversário aparece como "Contra Maia 1000", sem o personagem (o Coco);
  - metade de baixo da tela vazia; o histórico é uma lista crua (ícone, "Vitória", data).

  Proposta: tabuleiro grande no topo (largura da tela, como na configuração da partida); um cartão do adversário com retrato, nome, nível e a frase dele; o objetivo e o ritmo em selos; "Jogar" fixo embaixo; o histórico em cartões com o resultado colorido, o tempo gasto e a variação do rating de cada partida; e um estado vazio com convite para jogar.

## Tela do degrau (Jornada)

- [ ] **Refazer a lista dos desafios do degrau.** ([print](../qa/melhorias/6167f3c6.jpg)) O que incomoda no print:
  - título "Maia 1000" sem o personagem; o progresso é só um texto ("1 de 9 desafios");
  - nove linhas iguais (tabuleiro pequeno, material, "Ganhar" verde e uma seta): nada diz qual é o próximo nem separa feito de por fazer;
  - "Ganhar" repetido em todas, ocupando o espaço da informação útil;
  - o último item fica atrás da barra de navegação do sistema (falta espaço embaixo).

  Proposta: cabeçalho com o retrato e o nome do personagem, a frase dele e uma barra de progresso (1/9); o próximo desafio em destaque (cartão maior, com "Jogar"); os outros em grade de 2 ou 3 colunas, cada um com o tabuleiro, o nome do final (ex.: "Mate de dama") e um selo de feito; o objetivo só aparece quando for diferente do comum (ex.: "Empatar"); espaço embaixo para rolar até o fim.

## Notado nos mesmos prints (para confirmar com o Gabriel)

- [ ] **Empate combinado em posição ganha derrubou o rating em 263 pontos** (889 → 626). O empate conta como objetivo não cumprido (0 ponto) e o desvio ainda está alto. Avaliar: empate aceito vale meio ponto no rating, ou não conta. ([print](../qa/melhorias/4c10dc0a.jpg))
- [ ] **Parte de baixo cortada, sem espaço para rolar.** No fim da partida, a lista de lances fica cortada (uma linha e meia visível, a de baixo pela metade). A área de baixo precisa rolar até o fim, com um espaço (padding) depois do último lance para nada ficar colado na borda. Rever também a ordem: talvez o rating dentro do painel do fim. ([print](../qa/melhorias/4c10dc0a.jpg))

# Melhorias · ajustes pedidos depois da v1.7.0-rc.2

Lista viva: o Gabriel manda prints do celular e os pontos entram aqui. Vira uma tarefa numerada quando for atacada (o outro worktree já usa T28 a T31).

## Tela da partida

- [ ] **Espaço entre o personagem e o tabuleiro.** Hoje o retrato e o balão encostam na borda de cima do tabuleiro. Dar um respiro (uns 8 a 12 px) entre a fileira do personagem e o tabuleiro. ([print](../qa/melhorias/38eb7dc8.jpg))
- [ ] **"Próximo desafio" no fim da partida.** Num desafio da Jornada, o painel do fim ganha embaixo a opção de ir direto para o próximo desafio do degrau (ou do degrau seguinte, se este acabou), além de "Jogar de novo". ([print](../qa/melhorias/3d0bf1e2.jpg))

## Notado nos mesmos prints (para confirmar com o Gabriel)

- [ ] **Empate combinado em posição ganha derrubou o rating em 263 pontos** (889 → 626). O empate conta como objetivo não cumprido (0 ponto) e o desvio ainda está alto. Avaliar: empate aceito vale meio ponto no rating, ou não conta. ([print](../qa/melhorias/4c10dc0a.jpg))
- [ ] **Parte de baixo cortada, sem espaço para rolar.** No fim da partida, a lista de lances fica cortada (uma linha e meia visível, a de baixo pela metade). A área de baixo precisa rolar até o fim, com um espaço (padding) depois do último lance para nada ficar colado na borda. Rever também a ordem: talvez o rating dentro do painel do fim. ([print](../qa/melhorias/4c10dc0a.jpg))

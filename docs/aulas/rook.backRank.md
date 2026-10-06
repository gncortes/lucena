# A defesa passiva na última fileira (`rook.backRank`)

Pesquisa de 2026-10-06. A pesquisa das aulas de defesa com a torre está em `docs/aulas/rook.defesa.pesquisa.md`; aqui fica só o que é desta aula.

## O que o aluno precisa sair sabendo

Quando a defesa de Philidor não foi armada, resta esperar: rei na frente do peão e torre na primeira fileira. Contra peão de cavalo e de torre isso empata, e o único truque do atacante (o xeque da torre ao lado do rei) se responde indo para o canto; para o outro lado cai-se na posição de Lucena. Contra peão de bispo e central a mesma defesa perde, porque a torre atacante tem uma coluna a mais para dar a volta e ameaçar mate; a saída é não chegar lá: enquanto o rei atacante não pisou na terceira fileira, a torre sai (para a terceira fileira ou para o fundo). E o contrário: contra peão de cavalo, a defesa ativa por trás é que perde, e a torre tem de voltar para a primeira fileira.

## Como cada fonte ensina

Resumo em `rook.defesa.pesquisa.md`. Para esta aula: Wikipedia "Rook and pawn versus rook endgame" (back-rank defense com peão de cavalo e de bispo, o truque e Rh8!, a posição de Averbakh e Kopaev com 1...Tb1!, a "last-rank defense" com peão na sétima; os créditos a Emms são da Wikipedia); o artigo de Gabuzyan no ChessMood (a regra das colunas e o erro de esperar contra peão de bispo); o estudo de ProfAngel (peão de cavalo: voltar para a última fileira, e por trás perde).

## Posições-base (aluno de brancas; fontes espelhadas)

| id | FEN | Quem joga | Tabela | Crédito |
|---|---|---|---|---|
| knight | `8/8/8/8/8/5kp1/r7/1R4K1 b - - 0 1` | pretas | empate com qualquer lado | Wikipedia (Emms) |
| trick | `8/8/8/8/8/6pk/6r1/1R4K1 w - - 0 1` | brancas | empate; só Rh1 | Wikipedia (Emms) |
| bishop | `8/8/8/8/8/5pk1/1r6/R5K1 b - - 0 1` | pretas | pretas ganham | Wikipedia |
| seventh | `8/8/8/8/8/8/r2kpK2/1R6 w - - 0 1` | brancas | empate; só Te1, depois só Tb1 | Wikipedia (Emms) |

Outras usadas: `8/8/8/8/6k1/5p2/r7/1R3K2 w` (peão de bispo, rei atacante a um lance da terceira: só a torre para o fundo da coluna b; com as pretas jogando, perdido); `7R/8/8/8/6p1/5rk1/8/6K1 w` (peão de cavalo: seguram os lances pela oitava fileira até a coluna a-e, depois só Ta1; Tg8 perde); `8/8/8/8/5pk1/8/r7/2R3K1 w` (dá tempo de Philidor: Tc3 e os lances para o fundo; esperar perde).

## História

Sem descobridor nem data. Na fala `history`: a regra das colunas de Gabuzyan (ChessMood) e a observação de Averbakh e Kopaev citada pela Wikipedia.

## Plano da aula

Lição: `intro`, `wait` (esperar e responder ao xeque), `corner` (o truque), `lucena` (o erro Rf1), `room` (por que funciona: falta coluna), `bishop` (por que perde contra peão de bispo), `free` e `active` (sair da passividade a tempo), `behind` e `home` (peão de cavalo: voltar para a primeira fileira), `rookPawn`, `recap`.

Exercícios (10, 18 estrelas, mínimo 11): e01 o canto (1); e02 sair a tempo (1); e03 Ta1 (1); e04 voltar para casa (1); e05 esperar e o truque (2); e06 xeques por trás contra peão de bispo (2); e07 o truque na outra ala (2); e08 a volta completa (2); e09 peão na sétima, lances únicos (3); e10 Philidor armada da primeira fileira (3).

## Treino final

`8/8/8/8/6k1/6p1/r7/1R4K1 w - - 0 1`, objetivo empate, `positionId: null`.

## Dúvidas e divergências

- Não achei explicação em texto, em fonte aberta, de por que a defesa falha contra peão de bispo; a da aula (a coluna a mais para a torre) vem da Wikipedia.
- Peão de torre: nenhuma fonte aberta traz posição; a da aula é própria (`8/8/8/8/8/6kp/r7/1R5K b`, empate).
- Livros citados pela Wikipedia (Emms, Averbakh e Kopaev) não foram abertos e não entram em `references`.

## Estado

Concluída em 2026-10-06: `build_aula.py rook.backRank` sem problemas, aula no `index.json` (11 aulas na trilha). Falta ver no emulador.

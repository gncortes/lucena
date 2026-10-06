# Lado curto e lado longo (`rook.shortSide`)

Pesquisa de 2026-10-06. A pesquisa das aulas de defesa com a torre está em `docs/aulas/rook.defesa.pesquisa.md`; aqui fica só o que é desta aula.

## O que o aluno precisa sair sabendo

Quando o rei atacante já passou e a terceira fileira de Philidor não está mais disponível, ainda há empate, com três peças (a "manobra de Karstedt", 1897): a torre vai para trás do peão, para ele não avançar; quando o rei defensor tem de sair da casa de promoção, vai para o lado curto (o lado do peão com menos colunas); a torre fica com o lado longo, a pelo menos três colunas do peão, e dá xeques laterais quando o peão avança. Os erros: rei para o lado longo, torre perto demais, e xeque na hora em que o lance era de rei (Aronian-Carlsen 2006).

## Como cada fonte ensina

Resumo em `rook.defesa.pesquisa.md`. Para esta aula: Wikipedia "Rook and pawn versus rook endgame" (short-side defense, as posições de Tarrasch 1906 e de Grigoriev 1937, o "long-side blunder", a distância de xeque); de.wikipedia "Max Karstedt" (a manobra e a história); o blog de Stripes (o nome da técnica e o erro de Philidor); os estudos de ProfAngel (o "segundo método" e Aronian-Carlsen), Yuri61 ("Black to draw I-V": rei do lado curto, torre do lado longo; esperar na oitava) e NoseKnowsAll (Carlsen).

## Posições-base (aluno de brancas; fontes espelhadas)

| id | FEN | Quem joga | Tabela | Crédito |
|---|---|---|---|---|
| behind | `1R6/8/8/8/4p3/5k2/r7/4K3 w - - 0 1` | brancas | empate; só Te8 | estudo de ProfAngel |
| tarrasch | `5r2/R7/8/8/8/8/4p1K1/4k3 w - - 0 1` | brancas | empate; só Ta1+, e toda a linha é de lances únicos | Tarrasch 1906, via Wikipedia |
| close | `3r4/1R6/8/8/8/4p3/4k1K1/8 w - - 0 1` | brancas | perdida | Grigoriev 1937, via Wikipedia |
| carlsen | `8/8/8/8/8/3rp3/4k1K1/R7 w - - 0 1` | brancas | empate; só Rg3 | Aronian-Carlsen 2006, pelos estudos de ProfAngel e NoseKnowsAll |

## História

Na fala `history`: Philidor 1777, Dufresne 1863 e Berger 1890 davam a linha por perdida; Karstedt 1897 corrigiu (de.wikipedia); Tarrasch 1906 (Wikipedia); as tabelas confirmam; Carlsen perdeu de Aronian em 2006 uma posição empatada (estudos do Lichess, conferido na tabela).

## Plano da aula

Lição: `intro` (Philidor chegou atrasada), `behindPawn` (Te8 e o rei para f1), `sides` (lado curto e lado longo), `dance` (o rei sai e volta), `fpawn` (o mesmo com peão de bispo), `blunder` (o rei no lado longo perde), `lateral` e `checks` (os xeques laterais de Tarrasch, lances únicos), `distance` (torre perto demais), `carlsen` e `king` (o lance de rei), `recap`.

Exercícios (10, 18 estrelas, mínimo 11): e01 Te8 (1); e02 Rf1 (1); e03 Rg1 com peão de bispo (1); e04 o primeiro xeque lateral (1); e05 xeque e lado curto (2); e06 o fim dos xeques laterais (2); e07 Rg3 de Carlsen (2); e08 levar a torre para o lado longo (2); e09 esperar na primeira fileira (3); e10 tirar o rei de e2 e passar a torre para a coluna a (3).

## Treino final

`R7/8/8/8/4p3/5k2/1r6/4K3 w - - 0 1`, objetivo empate, `positionId: null`.

## Dúvidas e divergências

- O estudo de Yuri61 tem três avaliações que a tabela desmente (ver a pesquisa); as linhas usadas foram conferidas lance a lance com `tools/check_hold.py`.
- Em e02, Rd1 também empata na tabela; a regra é `hold` e a solução explica por que o lado curto é o método.
- Não há referência de partida para Aronian-Carlsen: o torneio não aparece nas fontes abertas; o crédito vai para os estudos.
- O nome "Kling e Horwitz" (de la Villa) para esta defesa não entrou: Stripes mostra que não tem base.

## Estado

Concluída em 2026-10-06: `build_aula.py rook.shortSide` sem problemas, aula no `index.json` (12 aulas na trilha). Falta ver no emulador.

# Dama contra torre I: a posição de Philidor (`queen.vsRook.philidor`)

Pesquisa de 2026-10-06. A pesquisa completa das três aulas de dama contra torre (fontes, posições, linhas, história) está em `docs/aulas/queen.vsRook.pesquisa.md`; aqui fica só o que é desta aula.

## O que o aluno precisa sair sabendo

Dama contra torre se ganha chegando a uma posição: rei defensor na borda com a torre ao lado, rei atacante a um salto de cavalo dele, dama na coluna da borda (Philidor, 1777). Com o defensor jogando é zugzwang: o rei não tem casa e a torre, onde for, cai. Perto do rei ela é capturada; longe, cai por garfo depois de uma sequência de xeques que começa em e5 (em b4 se a torre está na coluna e). Com o atacante jogando, a dama faz um triângulo (e5, a1, a5) e devolve a vez. Não se aperta mais que isso: dama colada no rei encurralado dá afogamento.

## Como cada fonte ensina

Resumo em `queen.vsRook.pesquisa.md`. Para esta aula usei: a Wikipedia ("Queen versus rook endgame": triangulação, linhas de cada lance de torre, a armadilha 1.Qa6? Rc7+ 2.Kb6?? Rc6+ citada de Averbakh); o estudo de calmodee (catálogo dos lances de torre e o "falso Philidor"); o de Unto (a regra "o primeiro xeque é sempre em e5" para as casas difíceis); o de NM BXMSChess (Philidor no outro canto).

## Posições-base

| id | FEN | Quem joga | Tabela | Crédito |
|---|---|---|---|---|
| black | `1k6/1r6/2K5/Q7/8/8/8/8 b - - 0 1` | pretas | perdida, mate em 14 meios-lances, torre em 10 | Philidor 1777; diagrama da Wikipedia |
| white | `1k6/1r6/2K5/Q7/8/8/8/8 w - - 0 1` | brancas | ganha, 19 meios-lances; Qe5+ e Qd5 iguais | idem |
| corner | `6k1/6r1/5K2/7Q/8/8/8/8 w - - 0 1` | brancas | ganha (espelho) | estudo de NM BXMSChess |
| draw | `1k6/2r5/QK6/8/8/8/8/8 b - - 0 1` | pretas | empate, só Rc6+ | Wikipedia, citando Averbakh |

## História

Ver "Web e história" em `queen.vsRook.pesquisa.md`. Na fala `history`: Philidor 1777; Thompson e a base de 1978; Browne contra Belle (aposta de 100 dólares, 50 lances, perdeu a primeira e ganhou a revanche no 50º lance; fonte primária, o artigo de 1979); Gelfand-Svidler 2001 (50 lances) e Morozevich-Jakovenko 2006 (afogamento), ambos da Wikipedia; 31 lances no pior caso até ganhar a torre (Wikipedia e tabela).

## Plano da aula

Lição: `intro` (a posição e o zugzwang), `near` (os lances de torre que perdem na hora), `pin` (Kc8 e a cravada Qa6), `far` (as fugas e a regra do xeque em e5), `fork` (Rg7), `efile` (Re7, a exceção Qb4+), `ladder` (Rh7), `rf7`, `rb1` (a mais longa), `white` e `triangle` (passar a vez), `squeeze` (a armadilha de afogamento), `false` (falso Philidor), `recap`, `finish` (Philidor com as brancas, contra o Stockfish).

Exercícios (10, 18 estrelas, mínimo 11): e01 o primeiro lance do triângulo (1); e02 Rb2 (1); e03 Re7 (1); e04 Kc8 (1); e05 o triângulo no outro canto (2); e06 Rh7 (2); e07 Rf7 por b4, a3, b3 (2); e08 fugir do xeque sem cair no afogamento (2); e09 Rb3 (3); e10 Rb1 (3).

## Treino final

`1rk5/4Q3/K7/8/8/8/8/8 w - - 0 1`, id `queen.queenVsRook.0001` do catálogo (liga ao speedrun `ending.queenVsRook`). Tabela: ganha.

## Referências

As de `references` na fonte: `wikipedia`, `calmodee`, `unto`, `bxms` (abertos, ver como em `queen.vsRook.pesquisa.md`), `nunn` (*Secrets of Pawnless Endings*, Gambit, 2002: **não aberto**, ficha só pela bibliografia da Wikipedia, sem página) e `tablebase`.

## Dúvidas e divergências

- Todas as linhas ensinadas são as mais curtas da tabela, tanto até o mate quanto até a captura da torre. Em Rb1 e Rb3 a Wikipedia começa por Qd8+ e os estudos por Qe5+: dão no mesmo; a aula usa Qe5+ para manter uma regra só.
- A escada de xeques pela borda do estudo de NM BXMSChess contra Rb1 não foi usada (dúvida sobre ...Rb7 interpondo).
- `pin`, segundo lance (Qxb7#): regra `only`, porque a tabela não dá distância para o lance de mate e `best` não se aplica.
- A fonte é gerada por `tools/lessons/endgames/queen.vsRook.philidor.py` (lances em SAN convertidos para FEN e UCI por `tools/lessons/make_source.py`), para não errar casa à mão.

## Estado

Concluída em 2026-10-06: `build_aula.py queen.vsRook.philidor` sem problemas, gerado `assets/lessons/endgames/queen.vsRook.philidor.json`, aula no `index.json` (7 aulas na trilha). Falta ver no emulador.

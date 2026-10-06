# Dama contra torre III: quebrar a terceira fileira (`queen.vsRook.thirdRank`)

Pesquisa de 2026-10-06. A pesquisa completa das três aulas de dama contra torre está em `docs/aulas/queen.vsRook.pesquisa.md`; aqui fica só o que é desta aula.

## O que o aluno precisa sair sabendo

A barreira da torre na terceira fileira é o ponto em que o final trava, e ela se quebra com um lance calmo: a dama sai da sétima fileira (1.Df4), a torre fica sem casa segura na fileira e o rei defensor tem de sair de trás dela; a dama troca de lado com xeques e o rei atacante cruza. Com a torre na ponta da fileira, o rei contorna e a expulsa. A quarta fileira se desfaz do mesmo jeito, contornando com o rei, e vira terceira. E os empates: dama e rei colados no rei encurralado deixam a torre dar xeque perpétuo ou se sacrificar (Ponziani, Morozevich-Jakovenko). No fim, o mapa do final inteiro.

## Como cada fonte ensina

Resumo em `queen.vsRook.pesquisa.md`. Para esta aula: a Wikipedia ("Queen versus rook endgame" e "Pawnless chess endgame": terceira fileira com a torre em b6 e em a6, quarta fileira de Nunn, os empates de Ponziani, Berger e Nunn, Morozevich-Jakovenko e Stefánsson-Müller); o estudo de cgbarros (a refutação de cada lance de torre depois de Df4); o de methurst (por que a terceira fileira cai); o de ColinParker (levar o rei até a frente do rei defensor); o artigo de 1979 (a "barreira").

## Posições-base

| id | FEN | Quem joga | Tabela | Crédito |
|---|---|---|---|---|
| third | `3k4/5Q2/1r6/3K4/8/8/8/8 w - - 0 1` | brancas | ganha, mate em 37 meios-lances; Df4 (Df3 e Df2 iguais) | Nunn 2002, via Wikipedia |
| thirdA | `3k4/5Q2/r7/3K4/8/8/8/8 w - - 0 1` | brancas | ganha, 29; Rc5 | Nunn, via Wikipedia (só texto) |
| fourth | `8/3k4/5Q2/r7/4K3/8/8/8 w - - 0 1` | brancas | ganha, 47; Df7+ | Nunn 2002, via Wikipedia |
| ponziani | `5k2/5r2/4Q3/6K1/8/8/8/8 b - - 0 1` | pretas | empate, só Tg7+ | Ponziani 1782, via Wikipedia |
| browne | `2KQ4/8/8/8/2r5/2k5/8/8 w - - 0 1` | brancas | ganha, torre em 61 meios-lances, mate em 69 | Browne x Belle, revanche, 1978 |

## História

Na fala `history`: o livro de 1895 assinado por "Euclid" (artigo de 1979 e ficha do Google Books); a "barreira" (artigo de 1979); a frase de Nunn sobre a segunda e a terceira fileiras (Wikipedia); Stefánsson-Müller 1992 e Morozevich-Jakovenko 2006 (Wikipedia; o final da segunda conferido na tabela).

## Plano da aula

Lição: `intro` e `seven` (a barreira), `quietMove` (depois de Df4, a torre sem casa), `rg6`, `ra6`, `rb7` (as punições), `switch` (a melhor defesa 1...Rd7: Da4+, Da7+, Dc5+, Rd6), `home` (até a posição diagonal), `a6` e `around` (torre na ponta: Rc5, De7, Rb5), `fourth` e `fourthA` (quarta fileira até virar terceira), `ponziani`, `desperado` e `moro` (os empates e a vitória que Morozevich perdeu), `map` (o final inteiro em cinco etapas), `recap`, `finish` (terceira fileira contra o Stockfish).

Exercícios (11, 21 estrelas, mínimo 13): e01 Df4 (1); e02 Tg6 (1); e03 Ta6 (1); e04 Tb2 (1); e05 a troca de lado (2); e06 torre em a6 (2); e07 Morozevich (2); e08 armar a posição da terceira fileira (2); e09 quarta fileira (3); e10 1...Rc8 até expulsar a torre (3); e11 defender: o empate de Ponziani com as pretas (3, objetivo `draw`, regra `hold`).

## Treino final

`2KQ4/8/8/8/2r5/2k5/8/8 w - - 0 1`, a posição da revanche de Browne, `positionId: null` (o catálogo não tem posição de dama contra torre a partir do centro; se o Gabriel quiser o speedrun do final inteiro, seria preciso acrescentar uma ao catálogo e um speedrun).

## Referências

As de `references` na fonte: `wikipedia`, `pawnless`, `moro` e `belle` (partidas), `belle1979`, `methurst`, `cgbarros`, `parker` (abertos), `nunn` (não aberto, só ficha) e `tablebase`.

## Dúvidas e divergências

- A linha principal da terceira fileira (Wikipedia) é a melhor da tabela lance a lance, do Df4 até Philidor (12 lances).
- Quarta fileira: Nunn prefere 3.Rd3 a 3.Rd4 por causa de ...Ta1; a tabela dá os dois com a mesma distância. A fala diz isso, e o exercício e09 aceita os dois.
- `moro` e e07, primeiro lance: regra `only` (De5 é o único mais rápido; com `best`, a folga de um lance aceitaria o Dg3+ da partida, que é justamente o lance a evitar).
- Em e11 o aluno joga de pretas e o objetivo é empatar: conferir no emulador se a tela do exercício trata bem esse caso (as aulas anteriores do módulo só têm exercícios de brancas ganhando).
- Os nomes de Grimmell ("harassment", "javelin", "rosette") não entraram: nenhum texto dele foi aberto.

## Estado

Concluída em 2026-10-06: `build_aula.py queen.vsRook.thirdRank` sem problemas, aula no `index.json` (9 aulas na trilha). Falta ver no emulador.

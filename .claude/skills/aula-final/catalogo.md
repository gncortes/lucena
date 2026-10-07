# Catálogo das aulas de finais

55 aulas, na ordem em que entram na trilha. A lista é um ponto de partida: o spike de cada aula confirma o recorte, e mudar o catálogo (trocar, juntar ou dividir aulas) é decisão do Gabriel.

Feita: a aula tem `docs/aulas/<id>.md` e `assets/lessons/endgames/<id>.json`.

"Motor" marca os temas com mais de 7 peças, em que a tabela de finais não alcança e o Stockfish julga.

## 0 · Finais básicos (`basics`)

A porta de entrada, depois da escola: aprofunda o que as aulas do Viktor apresentam (T48 e T49).

| # | id | Aula |
|---|---|---|
| B1 | `basics.queenMate` | Mate de dama em poucos lances |
| B2 | `basics.rookMate` | Mate de torre: a caixa |
| B3 | `basics.twoBishops` | Dois bispos: a parede e o canto |
| B4 | `basics.kingPawn` | Rei e peão contra rei: oposição, regra do quadrado e peão de torre |

## 1 · Mates difíceis (`mates`)

| # | id | Aula |
|---|---|---|
| 1 | `mates.bishopKnight.w` | Bispo e cavalo I: do canto errado ao canto certo (a manobra em W) |
| 2 | `mates.bishopKnight.edge` | Bispo e cavalo II: do meio do tabuleiro até a borda |
| 3 | `mates.bishopKnight.full` | Bispo e cavalo III: o mate inteiro, de qualquer posição (e os triângulos de Delétang) |
| 4 | `mates.twoKnightsPawn` | Dois cavalos contra peão (a linha de Troitsky) |

## 2 · Finais de peões (`pawns`)

| # | id | Aula |
|---|---|---|
| 5 | `pawns.keySquares` | Casas-chave |
| 6 | `pawns.distantOpposition` | Oposição distante e diagonal |
| 7 | `pawns.triangulation` | Triangulação |
| 8 | `pawns.rookPawn` | O peão de torre: quando empata |
| 9 | `pawns.race` | Corrida de peões: contar tempos, promover com xeque e dama contra dama recém-promovida |
| 10 | `pawns.reti` | A manobra de Réti |
| 11 | `pawns.shoulder` | O ombro: tirar o rei adversário do caminho |
| 12 | `pawns.breakthrough` | Ruptura |
| 13 | `pawns.outsidePasser` | O peão passado distante |
| 14 | `pawns.protectedPasser` | O peão passado protegido |
| 15 | `pawns.minedSquares` | Zugzwang recíproco e casas minadas |
| 16 | `pawns.spareTempi` | Tempos de reserva |
| 17 | `pawns.correspondingSquares` | Casas correspondentes |

## 3 · Finais de dama (`queen`)

| # | id | Aula |
|---|---|---|
| 18 | `queen.vsPawn` | Dama contra peão na sétima: peão central e de cavalo |
| 19 | `queen.vsPawn.draws` | Dama contra peão de torre e de bispo: os empates e as exceções |
| 20 | `queen.vsRook.philidor` | Dama contra torre I: a posição de Philidor |
| 21 | `queen.vsRook.approach` | Dama contra torre II: como chegar a Philidor |
| 22 | `queen.vsRook.thirdRank` | Dama contra torre III: quebrar a defesa da terceira fileira |
| 23 | `queen.vsRookPawn` | Dama contra torre e peão: as fortalezas |
| 24 | `queen.pawnVsQueen` | Dama e peão contra dama |

## 4 · Torre contra peões (`rookPawns`)

| # | id | Aula |
|---|---|---|
| 25 | `rookPawns.vsPawn` | Torre contra peão: o corte, o ombro e a promoção a cavalo |
| 26 | `rookPawns.vsTwo` | Torre contra dois peões ligados |

## 5 · Finais de torre (`rook`)

| # | id | Aula |
|---|---|---|
| 27 | `rook.lucena` | A posição de Lucena: a ponte |
| 28 | `rook.philidor` | A defesa de Philidor |
| 29 | `rook.backRank` | A defesa passiva na última fileira |
| 30 | `rook.shortSide` | Lado curto e lado longo |
| 31 | `rook.cutOff` | O rei cortado |
| 32 | `rook.frontal` | A defesa frontal |
| 33 | `rook.rookPawn.kingFront` | Peão de torre: o rei na frente do peão |
| 34 | `rook.rookPawn.seventh` | Peão de torre na sétima com a torre na frente |
| 35 | `rook.vancura` | A posição de Vancura |
| 36 | `rook.behindPasser` | Torre atrás do peão passado |
| 37 | `rook.twoPawns` | Torre e dois peões contra torre (os peões de bispo e de torre) |
| 38 | `rook.activity` | Torre ativa contra torre passiva (motor) |
| 39 | `rook.fourVsThree` | Quatro contra três na mesma ala (motor) |
| 40 | `rook.outsidePasser` | O peão passado distante no final de torre (motor) |

## 6 · Peças menores (`minor`)

| # | id | Aula |
|---|---|---|
| 41 | `minor.wrongBishop` | O bispo errado com peão de torre |
| 42 | `minor.knightVsPawn` | Cavalo contra peão |
| 43 | `minor.bishopVsPawns` | Bispo contra peões |
| 44 | `minor.centurini` | Bispo e peão contra bispo da mesma cor |
| 45 | `minor.oppositeBishops.connected` | Bispos de cores opostas I: dois peões ligados |
| 46 | `minor.oppositeBishops.separated` | Bispos de cores opostas II: dois peões separados |
| 47 | `minor.knightPawnVsKnight` | Cavalo e peão contra cavalo |
| 48 | `minor.bishopVsKnight` | Bispo contra cavalo com um peão |
| 49 | `minor.goodBadBishop` | Peça boa contra bispo mau (motor) |

## 7 · Torre e peça menor (`rookMinor`)

| # | id | Aula |
|---|---|---|
| 50 | `rookMinor.vsBishop` | Torre contra bispo: o canto certo |
| 51 | `rookMinor.vsKnight` | Torre contra cavalo |
| 52 | `rookMinor.exchange` | A qualidade com peões: as fortalezas contra a torre |
| 53 | `rookMinor.bishopVsRook.defences` | Torre e bispo contra torre: a defesa de Cochrane e a da segunda fileira |
| 54 | `rookMinor.bishopVsRook.philidor` | Torre e bispo contra torre: a posição de Philidor |
| 55 | `rookMinor.knightVsRook` | Torre e cavalo contra torre |

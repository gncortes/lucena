# Catálogo das aulas de finais

Cinquenta aulas, na ordem em que entram na trilha. A lista é um ponto de partida: o spike de cada aula confirma o recorte, e mudar o catálogo (trocar, juntar ou dividir aulas) é decisão do Gabriel.

Feita: a aula tem `docs/aulas/<id>.md` e `assets/lessons/endgames/<id>.json`.

"Motor" marca os temas com mais de 7 peças, em que a tabela de finais não alcança e o Stockfish julga.

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
| 9 | `pawns.reti` | A manobra de Réti |
| 10 | `pawns.shoulder` | O ombro: tirar o rei adversário do caminho |
| 11 | `pawns.breakthrough` | Ruptura |
| 12 | `pawns.outsidePasser` | O peão passado distante |
| 13 | `pawns.protectedPasser` | O peão passado protegido |
| 14 | `pawns.minedSquares` | Zugzwang recíproco e casas minadas |
| 15 | `pawns.spareTempi` | Tempos de reserva |
| 16 | `pawns.correspondingSquares` | Casas correspondentes |

## 3 · Finais de dama (`queen`)

| # | id | Aula |
|---|---|---|
| 17 | `queen.vsPawn` | Dama contra peão na sétima: peão central e de cavalo |
| 18 | `queen.vsPawn.draws` | Dama contra peão de torre e de bispo: os empates e as exceções |
| 19 | `queen.vsRook.philidor` | Dama contra torre I: a posição de Philidor |
| 20 | `queen.vsRook.approach` | Dama contra torre II: como chegar a Philidor |
| 21 | `queen.vsRook.thirdRank` | Dama contra torre III: quebrar a defesa da terceira fileira |
| 22 | `queen.vsRookPawn` | Dama contra torre e peão: as fortalezas |
| 23 | `queen.pawnVsQueen` | Dama e peão contra dama |

## 4 · Torre contra peões (`rookPawns`)

| # | id | Aula |
|---|---|---|
| 24 | `rookPawns.vsPawn` | Torre contra peão: o corte, o ombro e a promoção a cavalo |
| 25 | `rookPawns.vsTwo` | Torre contra dois peões ligados |

## 5 · Finais de torre (`rook`)

| # | id | Aula |
|---|---|---|
| 26 | `rook.lucena` | A posição de Lucena: a ponte |
| 27 | `rook.philidor` | A defesa de Philidor |
| 28 | `rook.backRank` | A defesa passiva na última fileira |
| 29 | `rook.shortSide` | Lado curto e lado longo |
| 30 | `rook.cutOff` | O rei cortado |
| 31 | `rook.frontal` | A defesa frontal |
| 32 | `rook.rookPawn.kingFront` | Peão de torre: o rei na frente do peão |
| 33 | `rook.rookPawn.seventh` | Peão de torre na sétima com a torre na frente |
| 34 | `rook.vancura` | A posição de Vancura |
| 35 | `rook.behindPasser` | Torre atrás do peão passado |
| 36 | `rook.twoPawns` | Torre e dois peões contra torre (os peões de bispo e de torre) |
| 37 | `rook.activity` | Torre ativa contra torre passiva (motor) |
| 38 | `rook.fourVsThree` | Quatro contra três na mesma ala (motor) |

## 6 · Peças menores (`minor`)

| # | id | Aula |
|---|---|---|
| 39 | `minor.wrongBishop` | O bispo errado com peão de torre |
| 40 | `minor.knightVsPawn` | Cavalo contra peão |
| 41 | `minor.bishopVsPawns` | Bispo contra peões |
| 42 | `minor.centurini` | Bispo e peão contra bispo da mesma cor |
| 43 | `minor.oppositeBishops` | Bispos de cores opostas |
| 44 | `minor.knightPawnVsKnight` | Cavalo e peão contra cavalo |
| 45 | `minor.bishopVsKnight` | Bispo contra cavalo com um peão |
| 46 | `minor.goodBadBishop` | Peça boa contra bispo mau (motor) |

## 7 · Torre e peça menor (`rookMinor`)

| # | id | Aula |
|---|---|---|
| 47 | `rookMinor.vsBishop` | Torre contra bispo: o canto certo |
| 48 | `rookMinor.vsKnight` | Torre contra cavalo |
| 49 | `rookMinor.bishopVsRook.defences` | Torre e bispo contra torre: a defesa de Cochrane e a da segunda fileira |
| 50 | `rookMinor.bishopVsRook.philidor` | Torre e bispo contra torre: a posição de Philidor |

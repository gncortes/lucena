# Catálogo das aulas de finais

55 aulas, na ordem em que entram na trilha. A lista é um ponto de partida: o spike de cada aula confirma o recorte, e mudar o catálogo (trocar, juntar ou dividir aulas) é decisão do Gabriel.

Feita: a aula tem `docs/aulas/<id>.md` e `assets/lessons/endgames/<id>.json`.

**Prioridade do roteiro** (T52, 6.3): a ordem em que o roteiro do teste de nível vai precisar das aulas ainda não feitas, das faixas baixas para as altas. Faça primeiro as de prioridade 1, depois 2, e assim por diante; dentro da mesma prioridade, na ordem da trilha. 1: pausadas com dossiê iniciado (`pawns.rookPawnDraw`, `pawns.race`, `pawns.triangulation`, `pawns.reti`); 2: intermediário que aparece muito na prática; 3: dama contra peão que empata e torre que o roteiro já indica; 4: o resto dos finais de peões avançados; 5: o resto do catálogo. Ao fazer a aula, preencha `skills` com os nós do mapa (`tools/placement/skills.json`) e troque o tipo dela no mapa de `catalog` para `endgame`.

"Motor" marca os temas com mais de 7 peças, em que a tabela de finais não alcança e o Stockfish julga.

## 0 · Finais básicos (`basics`)

A porta de entrada, depois da escola: aprofunda o que as aulas do Viktor apresentam (T48 e T49).

| # | id | Aula | Prioridade do roteiro |
|---|---|---|---|
| B1 | `basics.queenMate` | Mate de dama em poucos lances | feita |
| B2 | `basics.rookMate` | Mate de torre: a caixa | feita |
| B3 | `basics.twoBishops` | Dois bispos: a parede e o canto | feita |
| B4 | `basics.kingPawn` | Rei e peão contra rei: oposição, regra do quadrado e peão de torre | feita |

## 1 · Mates difíceis (`mates`)

| # | id | Aula | Prioridade do roteiro |
|---|---|---|---|
| 1 | `mates.bishopKnight.w` | Bispo e cavalo I: do canto errado ao canto certo (a manobra em W) | feita |
| 2 | `mates.bishopKnight.edge` | Bispo e cavalo II: do meio do tabuleiro até a borda | feita |
| 3 | `mates.bishopKnight.full` | Bispo e cavalo III: o mate inteiro, de qualquer posição (e os triângulos de Delétang) | feita |
| 4 | `mates.twoKnightsPawn` | Dois cavalos contra peão (a linha de Troitsky) | feita |

## 2 · Finais de peões (`pawns`)

| # | id | Aula | Prioridade do roteiro |
|---|---|---|---|
| 5 | `pawns.keySquares` | Casas-chave | feita |
| 6 | `pawns.distantOpposition` | Oposição distante e diagonal | feita |
| 7 | `pawns.triangulation` | Triangulação | feita |
| 8 | `pawns.rookPawnDraw` | Peão de torre: o empate | feita |
| 9 | `pawns.race` | Corrida de peões: contar tempos, promover com xeque e dama contra dama recém-promovida | feita |
| 10 | `pawns.reti` | A manobra de Réti | feita |
| 11 | `pawns.shoulder` | O ombro: tirar o rei adversário do caminho | feita |
| 12 | `pawns.breakthrough` | Ruptura | feita |
| 13 | `pawns.outsidePasser` | O peão passado distante | feita |
| 14 | `pawns.protectedPasser` | O peão passado protegido | feita |
| 15 | `pawns.minedSquares` | Zugzwang recíproco e casas minadas | 5 |
| 16 | `pawns.spareTempi` | Tempos de reserva | 5 |
| 17 | `pawns.correspondingSquares` | Casas correspondentes | 5 |

## 3 · Finais de dama (`queen`)

| # | id | Aula | Prioridade do roteiro |
|---|---|---|---|
| 18 | `queen.vsPawn` | Dama contra peão na sétima: peão central e de cavalo | feita |
| 19 | `queen.vsPawn.draws` | Dama contra peão: os empates | feita |
| 20 | `queen.vsRook.philidor` | Dama contra torre I: a posição de Philidor | feita |
| 21 | `queen.vsRook.approach` | Dama contra torre II: como chegar a Philidor | feita |
| 22 | `queen.vsRook.thirdRank` | Dama contra torre III: quebrar a defesa da terceira fileira | feita |
| 23 | `queen.vsRookPawn` | Dama contra torre e peão: as fortalezas | 5 |
| 24 | `queen.pawnVsQueen` | Dama e peão contra dama | 5 |

## 4 · Torre contra peões (`rookPawns`)

| # | id | Aula | Prioridade do roteiro |
|---|---|---|---|
| 25 | `rookPawns.vsPawn` | Torre contra peão: o corte, o ombro e a promoção a cavalo | feita |
| 26 | `rookPawns.vsTwo` | Torre contra dois peões ligados | feita |

## 5 · Finais de torre (`rook`)

| # | id | Aula | Prioridade do roteiro |
|---|---|---|---|
| 27 | `rook.lucena` | A posição de Lucena: a ponte | feita |
| 28 | `rook.philidor` | A defesa de Philidor | feita |
| 29 | `rook.backRank` | A defesa passiva na última fileira | feita |
| 30 | `rook.shortSide` | Lado curto e lado longo | feita |
| 31 | `rook.cutOff` | O rei cortado | feita |
| 32 | `rook.frontal` | A defesa frontal | feita |
| 33 | `rook.rookPawn.kingFront` | Peão de torre: o rei na frente do peão | 5 |
| 34 | `rook.rookPawn.seventh` | Peão de torre na sétima com a torre na frente | 5 |
| 35 | `rook.vancura` | A posição de Vancura | 5 |
| 36 | `rook.behindPasser` | Torre atrás do peão passado | feita |
| 37 | `rook.twoPawns` | Torre e dois peões contra torre (os peões de bispo e de torre) | 5 |
| 38 | `rook.activity` | Torre ativa contra torre passiva (motor) | 5 |
| 39 | `rook.fourVsThree` | Quatro contra três na mesma ala (motor) | 5 |
| 40 | `rook.outsidePasser` | O peão passado distante no final de torre (motor) | 5 |

## 6 · Peças menores (`minor`)

| # | id | Aula | Prioridade do roteiro |
|---|---|---|---|
| 41 | `minor.wrongBishop` | O bispo errado | feita |
| 42 | `minor.knightVsPawn` | Cavalo contra peão | feita |
| 43 | `minor.bishopVsPawns` | Bispo contra peões | 5 |
| 44 | `minor.centurini` | Bispo e peão contra bispo da mesma cor | 5 |
| 45 | `minor.oppositeBishops.connected` | Bispos de cores opostas I: dois peões ligados | 5 |
| 46 | `minor.oppositeBishops.separated` | Bispos de cores opostas II: dois peões separados | 5 |
| 47 | `minor.knightPawnVsKnight` | Cavalo e peão contra cavalo | 5 |
| 48 | `minor.bishopVsKnight` | Bispo contra cavalo com um peão | 5 |
| 49 | `minor.goodBadBishop` | Peça boa contra bispo mau (motor) | 5 |

## 7 · Torre e peça menor (`rookMinor`)

| # | id | Aula | Prioridade do roteiro |
|---|---|---|---|
| 50 | `rookMinor.vsBishop` | Torre contra bispo: o canto certo | 5 |
| 51 | `rookMinor.vsKnight` | Torre contra cavalo | 5 |
| 52 | `rookMinor.exchange` | A qualidade com peões: as fortalezas contra a torre | 5 |
| 53 | `rookMinor.bishopVsRook.defences` | Torre e bispo contra torre: a defesa de Cochrane e a da segunda fileira | 5 |
| 54 | `rookMinor.bishopVsRook.philidor` | Torre e bispo contra torre: a posição de Philidor | 5 |
| 55 | `rookMinor.knightVsRook` | Torre e cavalo contra torre | 5 |

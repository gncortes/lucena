# Torre contra peão: o corte, o ombro e a promoção a cavalo (`rookPawns.vsPawn`)

Pesquisa de 2026-10-07.

## O que o aluno precisa sair sabendo

Torre contra peão é uma corrida: a torre ganha se o rei dela chega a tempo, e empata se chega um tempo atrasado. As ferramentas de quem tem a torre são, nesta ordem: cortar o rei do peão com a torre (fileira ou coluna), pôr a torre atrás do peão, contar os tempos com o rei andando em diagonal, empurrar o rei inimigo com o ombro (ou contorná-lo quando é ele que fecha o caminho) e o xeque que ganha tempo. Do outro lado, o rei do peão anda na frente do peão, e a promoção a cavalo com xeque salva posições em que a dama levaria mate.

## Como cada fonte ensina

- **Ezryn, "Principles of Rook vs Pawn Endgame" (estudo do Lichess, aberto pela API PGN)**: curso curto em capítulos. Começa pela subpromoção (um exemplo em que o rei branco persegue o peão de frente e as pretas salvam com cavalo e xeque), depois o "outflanking" (o rei dá a volta pelo lado e a torre fica atrás do peão), o corte do rei na quinta fileira, o "time-winning check", os empates com peão de cavalo e de torre (afogamento), um caso em que o peão ganha (tipo Saavedra), o cavalo no canto que perde, e dois testes. Usa a ideia de que cortar "na quinta fileira" (do ponto de vista de quem tem a torre) funciona.
- **Kyrylo27, "Rook versus Pawn" (estudo do Lichess, aberto pela API PGN)**: nove capítulos só de posições com linhas e setas, sem texto corrido. Destaques: a promoção a cavalo com xeque (cap. 1), a pressa do rei que permite o cavalo (cap. 2), a mesma posição com a torre em d8 (empate) e em g8 (ganho) (caps. 3 e 4), peão de cavalo com afogamento (cap. 5), o rei do peão que sobe para fugir dos xeques (caps. 6 a 8) e a Saavedra (cap. 9).
- **Jesús de la Villa, *100 Endgames You Must Know***: só vi o índice na página da loja chesscul.com; o livro dá nove finais (21 a 29) a "Rook vs pawn", logo depois de "Queen vs pawn" e antes de "Rook vs two pawns". O conteúdo dos capítulos não foi aberto.
- **Wikipedia, "Chess endgame"**: uma linha de resumo, citando Fine e Benko: sem o rei da torre por perto, um peão empata; com o rei perto, a torre ganha.
- **Wikipedia, "Saavedra position"**: a história da posição (abaixo).
- **Prática do Lichess**: não tem capítulo de torre contra peão (a lista de temas vai de mates a finais de torre e peão contra torre).

## Posições-base

| id | FEN | Quem joga | Tabela | Crédito |
|---|---|---|---|---|
| cut | `8/7K/5k2/8/3p4/8/8/R7 w - - 0 1` | brancas | ganho; só Ta5 | própria |
| shoulder | `8/8/4K3/8/2p5/4k3/8/7R w - - 0 1` | brancas | ganho; só Rd5, e depois de c3 só Rc4 | própria |
| check | `7R/5K2/8/3p4/8/4k3/8/8 w - - 0 1` | brancas | ganho; só Te8+ | estudo de Ezryn, "Time winning checks" |
| knight | `8/8/8/8/8/3K4/R3p3/3k4 b - - 0 1` | pretas | empate; só e1=C+ (e1=D perde: Ta1 é mate) | estudo de Kyrylo27, cap. 1, depois de 1.Ta2+ Rd1 2.Rd3 |
| saavedra | `8/8/1KP5/3r4/8/8/8/k7 w - - 0 1` | brancas | ganho (o peão ganha) | Saavedra 1895, Wikipedia |

Outras posições da aula, todas conferidas na tabela: `8/1K6/8/8/5pk1/8/8/R7 w` (só Rc6 ganha) e a mesma com o rei em c8 (empate), `K6R/8/8/2p5/4k3/8/8/8 w` (só Tc8), `8/3K4/8/4k3/3p4/8/8/R7 w` (só Rc6, contornando), `2R5/8/8/8/8/8/3p1K2/3k4 w` (ganham só os lances de torre pela oitava fileira; Re3? Re1! Th8 d1=C+ empata).

## História

Da Wikipedia ("Saavedra position"): a posição nasceu de uma partida Fenton–Potter de 1875, empatada; G. E. Barbier publicou uma versão no *Weekly Citizen* de Glasgow em 27 de abril de 1895; Fernando Saavedra, padre espanhol, achou a promoção a torre, publicada por Barbier em 18 de maio de 1895; Lasker deu a forma atual em 1902. Linha principal: 1.c7 Td6+ 2.Rb5 Td5+ 3.Rb4 Td4+ 4.Rb3 Td3+ 5.Rc2 Td4 6.c8=T!. A fala `history` usa só isso, mais a regra prática da Wikipedia "Chess endgame".

## Plano da aula

Lição: `intro` (a corrida e as três perguntas), `cut` (Ta5 e o rei vem), `behindIdea` e `behind` (torre atrás do peão), `race` e `count` (contar; rei em diagonal), `late` (o mesmo com o rei uma casa mais longe: empate), `bodycheck` e `shoulder` (o ombro do rei branco), `block` e `around` (o ombro do rei preto e a volta pela frente do peão), `tempo` e `check` (o xeque que ganha tempo, de Ezryn), `knight` (e1=C+), `rush` e `trap` (a pressa com o rei e o cavalo; a posição antes do erro), `saavedra` (quando o peão ganha), `recap`.

Exercícios (10, 19 estrelas, mínimo 12):

| id | ★ | ideia | origem |
|---|---|---|---|
| e01 | 1 | cortar na quinta fileira (Ta5, único) | própria |
| e02 | 1 | torre atrás do peão com os reis frente a frente (Td1, único) | própria |
| e03 | 1 | contar: o rei em diagonal (Rb6, único) | própria |
| e04 | 2 | xeque que ganha tempo (Td8+, único; depois Tc8) | Ezryn, uma coluna para o lado |
| e05 | 2 | o ombro: Re5 e Rf4, ambos únicos | própria |
| e06 | 2 | defesa (empate): f8=C+ em vez de dama | própria (ideia do cap. 1 de Kyrylo27) |
| e07 | 2 | defesa (empate): o rei do peão vai na frente (Rf3, único) | própria |
| e08 | 2 | não apressar o rei: lance de torre pela oitava fileira | Kyrylo27, cap. 2 |
| e09 | 3 | contornar o ombro do rei preto: Rd7, Tc1, Rc7, os três únicos | própria |
| e10 | 3 | rei de longe: Re6 (único), Rd6, Rc5 | própria |

## Treino final

`8/K7/8/8/4pk2/8/8/R7 w - - 0 1`, objetivo ganhar, `positionId: rookPawn.rookVsPawn.0004` (só Rb6 ganha, e a linha segue quase toda com lances únicos de contagem). As outras posições do catálogo também servem: 0001 (peão de torre, só Rd2), 0002 (peão de cavalo, só Ra7), 0003 (só Rb4).

## Referências

- `ezryn`: estudo https://lichess.org/study/vOsoHReN, aberto pela API PGN.
- `kyrylo`: estudo https://lichess.org/study/ZNWaKj1R, aberto pela API PGN.
- `delaVilla`: ficha e índice vistos em https://chesscul.com/en/shop/100-endgames-you-must-know/ (a página diz "Chessy", 3.ª edição, 2018, 244 páginas, ISBN 9788494817953). O livro não foi aberto. A página da New in Chess recusou o acesso (403).
- `saavedra`: https://en.wikipedia.org/wiki/Saavedra_position, aberta.
- `endgame`: https://en.wikipedia.org/wiki/Chess_endgame, lida a fonte (linha "Rook versus pawns").
- `tablebase`: https://tablebase.lichess.ovh, via `build_aula.py`.

## Dúvidas e divergências

- **Editora do de la Villa**: as outras aulas citam New in Chess (2008 ou 2023); a única página que abri diz Chessy, 2018, com ISBN espanhol. Mantive o que vi; vale conferir com o livro em mãos.
- **"Ombro"**: as fontes que abri não usam o termo para este final (Ezryn fala em "outflanking", contornar). Usei "ombro" nos dois sentidos: o rei que ocupa as casas de que o outro precisa (o branco em `shoulder` e e05; o preto em `block` e e09). Sem fonte aberta para o nome.
- **Regra da quinta fileira** (Ezryn): vale nos exemplos dele e nos meus, mas não é absoluta; a aula não a ensina como regra, só o corte.
- No cap. 2 de Kyrylo27, 1.Te8 é o lance mostrado; a tabela aceita qualquer lance da torre pela oitava fileira, e o exercício aceita todos (regra `win`).
- Não abri Dvoretsky, Müller e Lamprecht nem Silman sobre este final; não achei amostra legal desses capítulos na busca rápida.
- Peão de torre e de cavalo (afogamento no canto) ficou fora da lição: ficaria longo. Aparece no catálogo (0001 e 0002) e cabe numa revisão.

## Estado

`build_aula.py rookPawns.vsPawn` sem problemas; 19 estrelas, mínimo 12; aula no `index.json` (18 aulas na trilha).

# Mate de torre: a caixa (`basics.rookMate`)

Pesquisa de 2026-10-07.

## O que o aluno precisa sair sabendo

1. A torre é uma cerca: cortando uma fileira (ou uma fileira e uma coluna ao mesmo tempo), ela prende o rei preto num retângulo, a caixa. Ganhar é encolher a caixa até a borda.
2. A cada lance, três perguntas em ordem: a torre encolhe a caixa com segurança? Se não, o rei se aproxima (para defender a casa onde a torre quer ir). Se nem isso, a torre faz um lance de espera, longe do rei preto, sem largar a linha.
3. O xeque que empurra uma fileira vem com os reis frente a frente (oposição); xeque sem oposição só espanta o rei.
4. Na borda, o rei branco anda a um salto de cavalo do rei preto (a regra de Capablanca: na sexta, a coluna ao lado, do lado do centro); quando o rei preto pisa na frente dele, a torre dá mate. No canto, o mate também sai sem oposição.
5. Os dois perigos: deixar a torre ser tomada (ela fica protegida pelo rei ou longe do rei preto) e o afogamento perto do canto (Rb7 com o rei preto em a8).

## Como cada fonte ensina

### Capablanca, *Chess Fundamentals* (1921), pelo Project Gutenberg

Aberto o texto integral, eBook #33870 (`https://www.gutenberg.org/cache/epub/33870/pg33870.txt`; folha de rosto: Harcourt, Brace & World, Nova York; G. Bell and Sons, Londres; copyright 1921). O livro começa por este mate: Parte I, capítulo I, seção 1 "Some simple mates", exemplos 1 e 2. Os princípios, com as minhas palavras: levar o rei adversário para a última linha de qualquer lado; manter o próprio rei, tanto quanto possível, na mesma fileira ou coluna do rei adversário; chegando à sexta fileira, ficar não na mesma coluna, mas na vizinha, do lado do centro (no exemplo, K-Q6 e não K-B6, que deixaria o rei preto voltar). No exemplo 2, com o rei preto no centro, o rei branco avança primeiro e a torre entra para reduzir as casas do rei; ele observa como o rei branco anda ao lado da torre para defendê-la e tirar casas. Diz que o mate deve sair "in under twenty" lances e que, embora monótono, o exercício vale a pena. Os diagramas não vêm no texto (só "[Illustration]"); a posição do exercício `e06` foi reconstruída a partir dos lances em notação descritiva (5...K-B1 6.K-Q6 K-Kt1 7.R-QB7), supondo a torre em a7 (R-R7 = QR7, a única leitura em que 6...K-Kt1 ataca a torre e 7.R-QB7 faz sentido).

### Lichess Practice, "Piece Checkmates I", capítulo "Rook mate" (estudo `BJy6fEDf`, de arex)

Aberto pela API (`https://lichess.org/api/study/BJy6fEDf.pgn`). Posição inicial `8/8/3k4/8/8/4K3/8/4R3 w`, sem comentários, só a linha de solução: 1.Kd4 Kc6 2.Re6+ Kd7 3.Kd5 Kc7 4.Rh6 Kd7 5.Rh7+ Ke8 6.Ke6 Kd8 7.Rg7 Kc8 8.Kd6 Kb8 9.Kc6 Ka8 10.Kb6 Kb8 11.Rg8#. Mostra na prática as três ideias: xeque com oposição (Re6+, Rh7+), lance de espera (Rh6, Rg7) e o rei a um salto de cavalo na borda.

### Estudo "How to Checkmate with King + Rook using the Box method" (`xJyH8XFS`, de randomchampgamer)

Aberto pela API. Ensina com duas regras fixas (não dar xeque até o mate; defender sempre a torre com o rei) e uma lista de prioridade a cada lance: encolher a caixa com a torre em segurança; senão ativar o rei; senão lance de espera. Quando o rei preto fica preso a uma linha da borda, defender a torre "do centro, não da borda", para evitar afogamento, e no fim ganhar a oposição. Foi a base das três perguntas do passo `rules`. Diferença: a aula não proíbe o xeque, porque o xeque com oposição é a ferramenta de Capablanca e do Lichess Practice, e a tabela aceita os dois caminhos.

### Estudo "Rook box checkmate" (`UCj1X1Pv`, de Flaggg)

Aberto pela API. Um capítulo, de `8/8/8/4k3/8/8/8/R3K3`, com variantes mostrando a torre cortando, o rei subindo e o mate na oitava (Rg7+ com oposição, Rg8#). Pouco texto; usei só como confirmação da ideia.

### Wikipedia, "Checkmate", seção "King and rook"

Texto-fonte aberto (`action=raw`). Traz os dois diagramas de mate (reis em oposição na borda; mate no canto sem oposição), a frase de que, com o lado da torre para jogar, o mate pode ser forçado em no máximo dezesseis lances de qualquer posição (citando Fine e Benko, *Basic Chess Endings*, 2003, p. 2), uma linha de exemplo "confinando o rei num retângulo" (citando Seirawan, *Winning Chess Endings*) e os padrões de afogamento (um deles `k7/1R6/2K5 b`, o da aula). Fine, Benko e Seirawan não foram abertos: são de segunda mão.

### Não abertos

Silman, *Complete Endgame Course*: só achei uma resenha (`danamackenzie.com/blog/?p=85`) que não fala deste mate; não entra. De la Villa, Dvoretsky e Müller–Lamprecht não foram procurados para esta aula (o tema é básico e Capablanca, aberto na íntegra, cobre o crédito).

## Posições-base

Todas com 3 peças, conferidas na tabela do Lichess em 2026-10-07 (cache em `tools/.cache/tablebase`).

| id | FEN | Quem joga | Tabela | Crédito |
|---|---|---|---|---|
| box | `8/8/8/8/1k6/7R/1K6/8 w` | brancas | win; só Rc3 no ritmo (`best`) | própria |
| edgeMate | `R2k4/8/3K4/8/8/8/8/8 b` | pretas | mate | diagrama clássico (Wikipedia) |
| cornerMate | `k7/2K5/8/8/8/8/8/R7 b` | pretas | mate | diagrama clássico (Wikipedia) |
| stalemate | `k7/1R6/2K5/8/8/8/8/8 b` | pretas | afogamento | padrão de afogamento (Wikipedia) |
| capablanca | `2k5/R7/8/3K4/8/8/8/8 w` | brancas | win; Kd6 o mais rápido, Kc6 fora do ritmo | Capablanca 1921, exemplo 1, depois de 5...K-B1 (reconstruída) |

Posições próprias da lição e dos exercícios (todas `win`): `8/8/8/k7/2R5/3K4/8/8 w`, `8/4k3/R7/4K3/8/8/8/8 w` (só Ra7+), `3k4/R7/4K3/8/8/8/8/8 w`, `8/8/8/5K1k/8/8/8/R7 w` (só Rh1#), `k7/2K5/8/8/8/8/8/7R w` (só Ra1#), `8/8/8/1k6/8/2RK4/8/8 w`, `8/3k4/7R/3K4/8/8/8/8 w` (só Rh7+), `2k5/R7/3K4/8/8/8/8/8 w`, `k7/7R/2K5/8/8/8/8/8 w` (Rb7 afoga, Ra7+ entrega), `8/8/8/4k3/3R4/8/2K5/8 w` (Kd3/Kc3), `4k3/R7/8/4K3/8/8/8/8 w`, `8/8/8/2k5/3R4/3K4/8/8 w` (só Kc3), `8/8/8/3k4/8/8/8/4K2R w` (play).

## História

- Capablanca abre *Chess Fundamentals* (1921) com o mate de torre, como o primeiro exercício para conhecer a força das peças; dá a regra do rei na mesma fileira/coluna e a da coluna vizinha na sexta, e acha que o mate deve sair em menos de vinte lances (texto do Gutenberg).
- Com o lado da torre para jogar, o mate pode ser forçado em no máximo dezesseis lances de qualquer posição (Wikipedia, citando Fine e Benko). Não conferi esse máximo na tabela; não entra nas falas (a regra do app é não falar em "mate em N").
- O nome "caixa" (box) aparece em estudos da comunidade do Lichess e em artigos de iniciação (ChessKid, chess.com, vistos só na busca); não achei quem o criou.
- Não encontrei partida famosa em que um mestre tenha falhado este mate; a `history` não cita nenhuma.

## Plano da aula

Lição (o aluno joga de brancas):

1. `box` (talk): a torre em h3 como cerca; a caixa.
2. `shrinkMove` (move, `best`): Rc3, única no ritmo; caixa vira a4–b8.
3. `rules` (talk): as três perguntas; caixa a5–b8 marcada; Rb4 seria tomada.
4. `kingMove` (move, `best`): Kc3 (aceitos também Kc2, Kd2, Kd4 e Rc5+).
5. `opposition` (talk) e `checkMove` (move, `best`): Ra7+, único.
6. `waiting` (talk) e `waitMove` (move): Rh7 Kc8, Kd6 Kb8, Kc6 Ka8, Kb6 Kb8, Rh8# (respostas fixas, iguais às da tabela).
7. `stalemate` (talk, `side: white`): o afogamento com Rb7.
8. `recap` (talk) sobre a posição do treino.
9. `finish` (play, win): `8/8/8/3k4/8/8/8/4K2R w`.

Exercícios (18 estrelas, mínimo 11):

| id | ★ | Ideia | Aceitos (tabela) |
|---|---|---|---|
| e01 | 1 | mate na borda com oposição | só Rh1# |
| e02 | 1 | mate no canto sem oposição | só Ra1# |
| e03 | 1 | encolher a caixa | Rc4 (mais rápido); Rc1, Rc2, Rc7, Rc8, Kc2, Kd2, Kd4 |
| e04 | 1 | xeque com oposição | só Rh7+ |
| e05 | 2 | lance de espera e o rei a um salto de cavalo | Rc7+–Rh7 (menos b7); depois Kc6 ou Rc7 |
| e06 | 2 | Capablanca: Kd6, não Kc6; torre atacada foge | Kd6, Ke6, Re7–Rh7; depois Rc7–Rh7 |
| e07 | 2 | evitar o afogamento | Kb6 e lances calmos (Kc7, Rc7, Rh1–h5, Rh8+); Rb7 afoga; depois só Rh8# |
| e08 | 2 | torre atacada: o rei defende | Kd3, Kc3 |
| e09 | 3 | levar o rei preto da coluna e ao canto | Kd6/Ke6/Rh7; só Ke6; Kf6/Rf7; Kg6 e outros; só Ra8# |
| e10 | 3 | o único lance que mantém o ritmo | só Kc3; depois Rc4 ou Rd5+ |

## Treino final

`8/8/8/8/3k4/5K2/8/5R2 w - - 0 1`, id `basic.rook.0001` do catálogo (win na tabela).

## Referências

| id | O quê | Como consultei |
|---|---|---|
| capablanca | Capablanca, *Chess Fundamentals*, Harcourt, Brace, 1921 | texto integral do Project Gutenberg (eBook #33870), Parte I, cap. I, exemplos 1 e 2 |
| practice | Lichess Practice: Piece Checkmates I, capítulo "Rook mate", de arex | `https://lichess.org/api/study/BJy6fEDf.pgn` |
| boxStudy | How to Checkmate with King + Rook using the Box method, de randomchampgamer | `https://lichess.org/api/study/xJyH8XFS.pgn` |
| flagggStudy | Rook box checkmate, de Flaggg | `https://lichess.org/api/study/UCj1X1Pv.pgn` |
| wikiCheckmate | Wikipedia, Checkmate (seção King and rook) | texto-fonte aberto |
| tablebase | Lichess tablebase (Syzygy) | todas as posições e lances |

## Dúvidas e divergências

- Nenhuma divergência com a tabela nas posições usadas. Capablanca diz que Kc6 (em vez de Kd6) só atrasa o mate; na tabela, Kc6 ganha mas fica fora da folga de `best`, então a aula não o aceita em `e06`, o que bate com o livro.
- O estudo `xJyH8XFS` manda não dar xeque até o mate; Capablanca e o Lichess Practice usam o xeque com oposição. A tabela aceita os dois (em `e04` o xeque é o único no ritmo; em outras posições, encolher com a torre é tão rápido quanto o xeque). A aula ensina as duas ferramentas.
- A regra `best` deixa passar lances mais lentos dentro da folga de um lance (por exemplo, lances de rei em `e03`); as soluções dizem isso em vez de fingir que o lance ensinado é único.
- Para lances de mate a tabela não dá distância (`dtm` nulo), então `best` não serve: os mates em `e01`, `e02`, `e07`, `e09` e `waitMove` usam `only`, e conferi que o mate é único em cada um.
- A posição `capablanca` foi reconstruída da notação descritiva, sem o diagrama (que não vem no texto do Gutenberg); a leitura com a torre em a7 é a única coerente com os lances seguintes, mas não vi o diagrama.
- O máximo de dezesseis lances vem da Wikipedia (Fine e Benko), não conferido.
- O script regravou `assets/lessons/endgames/index.json` (gerado). Outra sessão trabalha em `basics.kingPawn` no mesmo diretório; não toquei nos arquivos dela.

# Rei e peão contra rei (`basics.kingPawn`)

Pesquisa de 2026-10-07.

## O que o aluno precisa sair sabendo

1. A regra do quadrado: da casa do peão até a oitava fileira, fechando o quadrado pela diagonal; se o rei defensor entra nele (contando de quem é a vez), alcança o peão. O peão na segunda fileira conta da terceira, por causa do passo duplo.
2. Entrar no quadrado nem sempre basta: o rei do lado forte pode fazer de escudo (exemplo de Fishbein).
3. Quando o rei alcança o peão, o rei do lado forte vai na frente dele; a oposição (reis frente a frente, uma casa entre eles) decide quem cede.
4. O peão de torre empata quando o rei defensor chega ao canto (ou à frente do peão): não há como tirá-lo de lá sem afogar.
5. Quem defende tem o afogamento como recurso: rei na frente do peão, oposição quando o rei forte chega à sexta, e a casa da frente no xeque da sétima.

O aprofundamento das casas-chave fica em `pawns.keySquares`; a oposição distante, em `pawns.distantOpposition`; o peão de torre a fundo, em `pawns.rookPawn`. Na escola, `pawns.kingPawn` só apresenta as casas-chave, `pawns.square` só apresenta o quadrado (um rei que entra, um peão que corre) e `pawns.rookPawn` é torre e peão (não peão de torre). Esta aula aprofunda: passo duplo, escudo do rei, oposição simples dos dois lados, peão de torre e afogamento.

## Como cada fonte ensina

### Wikipedia, "King and pawn versus king endgame"

Aberta em 2026-10-07 (texto-fonte em `action=raw`; a página "Rule of the square" é só um redirecionamento para a seção dela). A ordem é: regra do quadrado (diagrama com o quadrado desenhado pela diagonal, citando Müller e Lamprecht 2007, p. 15); o exemplo de Alexander Fishbein em que o rei preto entra no quadrado mas o rei branco faz de escudo (1...Ke4 2.Kb4! Kd5 3.Kb5!, citando Fishbein 1993, p. 2); a manobra de Réti como exceção; depois casas-chave, peão de torre (b7/b8 e g7/g8, empate com o rei preto em c8/f8; partidas Panno–Najdorf 1968 e Barcza–Fischer 1959), a oposição como meio (Averbakh) e as regras de Müller e Lamprecht (rei na frente, oposição, sexta fileira; duas bastam). Também traz a regra de bolso "com o rei na sexta, o peão vai à sétima sem dar xeque" e o empate do peão de torre com o rei no canto "não importa quem joga". É a fonte da ordem da aula e do crédito do exemplo de Fishbein. Os livros que ela cita não foram abertos.

### Lichess Practice, "Opposition" (estudo `A4ujYOer`, de arex)

Aberto pela API (`https://lichess.org/api/study/A4ujYOer.pgn`). Oito capítulos: cinco de oposição direta, dois de oposição distante e "As a means to an end" (a observação de Averbakh). Os capítulos vêm só com a posição e a meta (promover ou empatar), sem texto. Mostra a oposição como um exercício: o aluno joga e o Lichess responde. A posição "Direct Opposition #1" (`8/2k5/8/8/2PK4/8/8/8 w`) é próxima das que usei, mas os exercícios da aula são próprios.

### Lichess Practice, "Key Squares" (estudo `xebrDvFe`, de arex)

Aberto pela API. Um capítulo por fileira do peão, dois do peão de cavalo na sexta, dois do peão de torre e o de Drtina. Só serviu para não repetir: o tema é da aula `pawns.keySquares`.

### Jeremy Silman, *Silman's Complete Endgame Course* (Siles Press)

Procurei o índice e achei só uma resenha (`https://patzersreview.substack.com/p/the-only-endgame-book-you-need`), que diz que o livro é dividido por faixa de rating e que a primeira (0–999) começa pelos mates básicos e os finais de peão elementares. Não vi o índice nem o texto; não entra em `references`. Os outros resultados da busca eram PDFs de sites suspeitos e não foram abertos.

### Müller e Lamprecht; Fishbein; Averbakh

Só de segunda mão, pela Wikipedia. Não entram em `references` como livros; o crédito do exemplo de Fishbein aponta para a Wikipedia (`wikiKpk`). A página da Gambit de *Fundamental Chess Endings* respondeu vazia nesta sessão.

## Posições-base

Todas com 3 peças, conferidas na tabela do Lichess em 2026-10-07 (pelo `build_aula.py` e por um script de consulta com o mesmo oráculo).

| id | FEN | Quem joga | Tabela | Crédito |
|---|---|---|---|---|
| square | `8/8/1k6/8/6P1/8/8/K7 w` | brancas | win, só g5 | própria |
| doubleStep | `8/8/8/7k/8/8/1P6/7K w` | brancas | win, só b4 (b3 empata) | própria |
| opposition | `8/2k5/8/2K5/2P5/8/8/8` | pretas / brancas | pretas na vez: loss; brancas na vez: draw | própria (ideia da Lichess Practice) |
| fishbein | `8/8/8/8/P3k3/K7/8/8 w` | brancas | win, só Kb4 | Alexander Fishbein (Wikipedia) |
| rookPawn | `k7/8/K7/P7/8/8/8/8 w` | qualquer | draw | diagrama da Wikipedia |
| stalemate | `8/3k4/2P5/2K5/8/8/8/8 b` | pretas | draw, Kc7/Kc8 | própria |
| practice | `6k1/8/8/8/8/8/3K2P1/8 w` | brancas | win (Ke2, Ke3, Kd3); g3 e g4 empatam | catálogo `pawn.pawnVsKing.0001` |

## História

- A regra do quadrado e o exemplo de Fishbein (1993) estão na Wikipedia, com as citações de Müller e Lamprecht (2007, p. 15) e Fishbein (1993, p. 2). Não encontrei quem a formulou primeiro.
- A imagem do pai que leva o filho pela rua é atribuída a Yuri Averbakh pela Wikipedia.
- Barcza–Fischer, Zurique 1959: Barcza, de brancas, ficou com o rei contra rei e peão de torre e empatou levando o rei para o canto (96.Kd2 e 97.Kc1, segundo a Wikipedia). A partida não foi aberta.

## Plano da aula

Lição (o aluno é as brancas, menos nos dois passos de defesa):

1. `intro` (talk): a posição do treino e as quatro perguntas.
2. `square` (talk) e `squareMove` (move, win): g-peão contra o rei em b6, quadrado g4–c8; g5, g6, g7, g8=D com respostas fixas.
3. `doubleStep` (talk): o passo duplo; quadrado contado da terceira fileira.
4. `front` (talk, vista de brancas): a oposição, com pretas na vez (perde) e brancas na vez (empata).
5. `opposition` (move, win): Kc4 (único), Kb5, Kc5.
6. `rookPawn` (talk) e `rookPawnMove` (move, draw): Kd7, Kc7, Kb8 até o canto.
7. `stalemate` (talk) e `stalemateMove` (move, draw): Kc8, Kd8, Kc8, e o afogamento.
8. `recap` (talk) na posição do treino; `finish` (play, win) em `8/k7/5K2/8/8/8/2P5/8 w` (catálogo `pawn.pawnVsKing.0004`).

Exercícios (24 estrelas, mínimo 15):

| id | ★ | Ideia | Aceitos (tabela) | Origem |
|---|---|---|---|---|
| e01 | 1 | o peão corre: fora do quadrado | só b5 | própria |
| e02 | 1 | a mesma, pretas na vez: entrar no quadrado | Kf4, Kf5, Kf6 | própria |
| e03 | 1 | o rei na frente do peão | Kd5, Ke5, Kf5 | própria |
| e04 | 2 | o passo duplo | só b4 | própria |
| e05 | 2 | tomar a oposição e passar | só Kf4; depois Kg5/Ke4/Kg4 | própria |
| e06 | 2 | o rei de escudo (Fishbein) | só Kb4, só Kb5 | wikiKpk |
| e07 | 2 | defesa: a oposição | só Kd5 | própria |
| e08 | 2 | defesa, peão de torre: a rota para o canto | só Kd7; depois Kc7/Kc8/Kd8 | própria |
| e09 | 2 | defesa com afogamento | Kf7/Kf8, só Ke8, só Kf8 | própria |
| e10 | 3 | peão de torre de ataque: chegar a g7 antes | só Kg6, só Kg7 | própria |
| e11 | 3 | defesa: o lance natural (Kd6) perde | só Ke6 | própria |
| e12 | 3 | defesa, peão de torre: a corrida ao canto | só Ke6; depois Kd6/Kd7 | própria |

## Treino final

`6k1/8/8/8/8/8/3K2P1/8 w - - 0 1`, id `pawn.pawnVsKing.0001` do catálogo (win na tabela; os avanços g3 e g4 empatam, por isso o recap insiste em "primeiro o rei").

## Referências

| id | O quê | Como consultei |
|---|---|---|
| practiceOpposition | Lichess Practice: Opposition, de arex | `https://lichess.org/api/study/A4ujYOer.pgn` (e a lista em `https://lichess.org/practice`) |
| practiceKeySquares | Lichess Practice: Key Squares, de arex | `https://lichess.org/api/study/xebrDvFe.pgn` |
| wikiKpk | Wikipedia, King and pawn versus king endgame | texto-fonte aberto (`action=raw`) |
| tablebase | Lichess tablebase (Syzygy) | todas as posições e lances |

Não entraram: Silman (só uma resenha aberta), Müller e Lamprecht, Fishbein e Averbakh (só citados pela Wikipedia), a partida Barcza–Fischer (só pela Wikipedia; aparece na `history`).

## Dúvidas e divergências

- Nenhuma divergência com a tabela. O exemplo de Fishbein da Wikipedia (2.Kb4! e 3.Kb5!) bate: os dois lances são únicos.
- Várias posições aceitam mais de um lance (e02, e03, e05 no 2º lance, e08, e09, e12 no 2º lance); as soluções dizem quais também servem.
- No passo `opposition`, o 2º lance aceita Kb4, Kb5 e Kd4; com Kb4 ou Kd4 a resposta fixa ainda é legal, mas o 3º lance ensinado (Kb5–c5) deixa de existir e a linha termina como cumprida. A fala de acerto foi escrita sem citar a casa final.
- Não achei a origem histórica da regra do quadrado nem uma fonte primária para a frase de Averbakh.
- O livro (Silman) não pôde ser conferido: a referência de livro ficou de fora e o requisito "livro ou estudo" é cumprido pelos estudos do Lichess.
- O script regravou `assets/lessons/endgames/index.json` (gerado) e criou `assets/lessons/endgames/basics.kingPawn.json`.

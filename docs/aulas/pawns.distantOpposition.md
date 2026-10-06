# Oposição distante e diagonal (`pawns.distantOpposition`)

Pesquisa de 2026-10-05, aula escrita e conferida em 2026-10-06.

## O que o aluno precisa sair sabendo

1. A regra do número ímpar: reis na mesma coluna, fileira ou diagonal, com uma, três ou cinco casas no meio e a vez do outro, você tem a oposição (Capablanca diz o mesmo pelo avesso: número par de casas, quem joga toma a oposição).
2. A oposição distante serve para virar oposição direta: a cada passo do rei adversário, o seu encurta a distância ficando de frente, até entrar numa casa-chave.
3. A oposição diagonal é a porta quando a direta não está ao alcance: entra pela diagonal e vira para a coluna do rei adversário com a oposição direta.
4. A oposição é meio, não fim: se dá para entrar numa casa-chave sem ela, entre; e quando o rei do outro sai da linha, não o siga de lado, dê um passo para a frente pelo outro lado e retome a oposição.
5. Quem defende usa o espelho: toma a oposição de longe e fica de frente a cada avanço, inclusive depois de um lance de peão.

## Como cada fonte ensina

### Capablanca, *Chess Fundamentals* (1921), capítulo 13, "The Opposition"

Aberto no Project Gutenberg (eBook 33870, texto completo). Capablanca define a oposição como a posição em que o adversário é forçado a abrir caminho para o seu rei, mostra as três formas com uma casa no meio (frontal, diagonal e lateral), manda o aluno afastar os reis na mesma linha para obter a oposição "distante" e enuncia a regra: na mesma linha, número par de casas no meio, quem joga tem a oposição. O exemplo 27 (reis em e1 e e8, peões b4/b5 e h4/h5) é o do "quem joga ganha": 1.Ke2 Ke7 2.Ke3 Ke6 3.Ke4 Kf6 4.Kf4 (não 4.Kd5, que só empata) e o rei branco captura o peão de b5; contra a espera 1...Kd8 ele dá 2.Kf3! ("there is only one other square where he can go") e volta com 3.Ke3. O exemplo 28 é a oposição distante como defesa (1.Kh1!), com peões demais para esta aula; ficou de fora.

### Wikipedia, "Opposition (chess)"

Texto-fonte aberto (`action=raw`). Define oposição direta, diagonal e distante; na distante, "número ímpar de casas no meio, quem não joga tem a oposição". O diagrama de oposição distante é o exemplo de Capablanca, com a linha principal e a tentativa 1...Kf8 2.Kd3! Ke7 3.Ke3 (espelho do 1...Kd8 2.Kf3 do livro). O exemplo de oposição diagonal (rei e5, peões f5/g6 contra rei e7, peão g7, pretas na vez) mostra que a oposição direta pode não servir e que se chega à direta útil pela diagonal: 1...Kf8 2.Kd6! Ke8 3.Ke6. Entra como posição-base, não como exercício (com as brancas na vez, seis lances de rei ganham). A ferramenta didática de Sarapu (torre e rei contra rei) saiu do recorte.

### Wikipedia, "King and pawn versus king endgame"

Texto-fonte aberto na pesquisa das casas-chave (2026-10-05). Daqui vem a observação atribuída a Averbakh de que a oposição é um meio e a entrada na casa-chave é o fim, com o diagrama em que Ke4 só empata e Kc5 ganha. Usada só nesse ponto.

### Lichess Practice, "Opposition" (estudo `A4ujYOer`, de arex)

Aberto pela API (`https://lichess.org/api/study/A4ujYOer.pgn`). Oito capítulos sem texto, só posições com a tarefa: cinco de oposição direta, dois de oposição distante (#1: brancas empatam contra rei e peão, `8/8/8/5kp1/8/8/8/6K1 w`; #2: o exemplo de Capablanca) e um "As a means to an end" (`8/8/4k3/8/2PK4/8/8/8 w`, o mesmo diagrama da Wikipedia). Usei as três posições de oposição distante e meio-fim; o capítulo #1 virou o exercício e12.

### Livros não abertos

New in Chess (de la Villa) e Gambit (Müller e Lamprecht) bloquearam o acesso na pesquisa de 2026-10-05; Dvoretsky e Silman não foram abertos. Nenhum deles está em `references`.

## Posições-base

Todas conferidas na tabela do Lichess (cache em `tools/.cache/tablebase`). "Único" quer dizer o único lance que mantém o objetivo.

| id | FEN | Quem joga | Tabela | Crédito |
|---|---|---|---|---|
| lesson | `4k3/8/8/8/8/3K2P1/8/8 w` | brancas | win; Ke4 único; depois de ...Kf7, Kf5 único; depois de ...Kg7, Kg5 único | própria |
| diagonal | `8/8/3k4/8/8/4PK2/8/8 w` | brancas | win; Kf4 único; depois de ...Ke6, Ke4 único; depois de ...Kd6, Kf5/Kd4/Kf4 | própria |
| means | `8/8/4k3/8/2PK4/8/8/8 w` | brancas | win; Kc5 único; Ke4 empata (...Kd6) | Lichess Practice "As a means to an end"; observação de Averbakh pela Wikipedia |
| capablanca | `4k3/8/8/1p5p/1P5P/8/8/4K3 w` | brancas | win; Ke2 único; Kd2 e Kf2 empatam; Kd1 e Kf1 perdem | Capablanca, exemplo 27 |
| capablanca após 1.Ke2 Kf8 | `5k2/8/8/1p5p/1P5P/8/4K3/8 w` | brancas | win; Kd3 e Kf2; Kd1, Kd2, Ke3, Kf3 empatam; Ke1 e Kf1 perdem | Capablanca / Wikipedia |
| wikiDiagonal | `8/4k1p1/6P1/4KP2/8/8/8/8 b` | pretas | loss (brancas ganham); após 1...Kf8 seis lances de rei ganham, f6 empata | Wikipedia "Opposition (chess)" |
| studyDefence | `8/8/8/5kp1/8/8/8/6K1 w` | brancas | draw; Kf1 único; depois de ...Kf4, Kf2 único; depois de ...g4, Kg2 único | Lichess Practice "Distant Opposition #1" |
| defend | `8/4k3/8/8/8/5KP1/8/8 b` | pretas | draw; Kf7 único; depois de Ke4, Ke6 ou Kg6; depois de g4, Kf6 único | própria |

Posições próprias dos exercícios (veredito e lances únicos na tabela): `4k3/8/8/8/8/2P2K2/8/8 w` (Ke4); `8/1K6/6k1/8/8/4P3/8/8 w` (Kc6); `5k2/8/8/8/4KP2/8/8/8 b` (draw, Ke8); `8/8/4k3/8/8/5PK1/8/8 w` (Kg4; depois Kf4); `2k5/5K2/8/8/8/2P5/8/8 w` (Ke6; depois de ...Kd8, Kd6/Kd5/Ke5); `8/8/3k4/8/4KP2/8/8/8 w` (Kf5; Kd4 toma a oposição e empata com ...Ke6; depois de ...Ke7, Ke5/Kg5/Kg6; depois de ...Kf7, Kf5); `8/3k4/8/8/8/4KP2/8/8 b` (draw, Ke7; depois Kf6 e Ke6 únicos); `4k3/8/8/8/8/8/1P6/5K2 w` (Ke2; depois de ...Kd7, Kd3; depois de ...Kc6, Kc4); `6k1/8/8/8/8/8/3P4/7K w` (Kg2, depois Kf3, Ke4, Kd4 únicos contra ...Kf7, ...Ke6, ...Kd6); `5k2/8/8/8/8/8/2P5/4K3 b` (draw; Ke7, Kd6, Kd5, Kc5 únicos contra Kd2, Kd3, Kc3). Passo final `2k5/8/8/8/8/8/2P2K2/8 w` (win; Ke2, Ke3 e Kf3 ganham).

## História

- Capablanca, em *Chess Fundamentals* (Harcourt, Brace, 1921; texto no Project Gutenberg), dedica o capítulo 13 à oposição, nomeia as formas frontal, diagonal e lateral, define a "distante" afastando os reis na mesma linha e dá a regra do número par/ímpar. O exemplo 27 dele é hoje o diagrama de oposição distante da Wikipedia e o capítulo "Distant Opposition #2" do Lichess Practice.
- A observação de que a oposição é meio e a casa-chave é fim é atribuída a Averbakh pela Wikipedia ("King and pawn versus king endgame"); não encontrei a fonte primária.
- A Wikipedia cita Flear (2004) para a linha do exemplo de oposição diagonal; o livro não foi aberto, a referência é a Wikipedia.

## Plano da aula

Lição (o aluno é as brancas, menos no passo de defesa):

1. `intro` (talk): a lição `4k3/8/8/8/8/3K2P1/8/8 w`, casas-chave f5/g5/h5 marcadas, seta d3–e4; a oposição direta está fora de alcance.
2. `odd` (talk): depois de Ke4, três casas no meio (e5/e6/e7) e a regra do número ímpar; a versão de Capablanca.
3. `convert` (move, win): Ke4!/...Kf7, Kf5!/...Kg7, Kg5! (todos únicos, `accept: win`).
4. `diagonal` (talk) e `diagonalMove` (move, win): `8/8/3k4/8/8/4PK2/8/8 w`: Kf4!/...Ke6, Ke4!/...Kd6, Kf5 (Kd4 e Kf4 também aceitos).
5. `means` (talk): `8/8/4k3/8/2PK4/8/8/8 w`: Ke4 empata, Kc5 ganha.
6. `capablanca` (talk) e `capablancaMove` (move, win): Ke2!/...Kf8, Kd3 (Kf2 também aceito)/...Ke7, Ke3!.
7. `defend` (talk) e `defendMove` (move, draw): `8/4k3/8/8/8/5KP1/8/8 b`: Kf7!/Ke4, Ke6 (Kg6 também aceito)/g4, Kf6!.
8. `summary` (talk): as três regras, sobre a posição do treino.
9. `finish` (play, win): `2k5/8/8/8/8/8/2P2K2/8 w`.

Exercícios (24 estrelas, mínimo 15):

| id | ★ | Ideia | Aceitos |
|---|---|---|---|
| e01 | 1 | oposição distante na coluna, três casas | só Ke4 |
| e02 | 1 | oposição lateral na fileira | só Kc6 |
| e03 | 1 | defesa: oposição distante na coluna | só Ke8 |
| e04 | 1 | oposição diagonal | só Kg4 |
| e05 | 2 | diagonal que vira direta (canto) | só Ke6; Kd6/Kd5/Ke5 |
| e06 | 2 | meio e não fim: Kd4 toma a oposição e empata | só Kf5; Ke5/Kg5/Kg6; só Kf5 |
| e07 | 2 | defesa: de frente a cada avanço | só Ke7, só Kf6, só Ke6 |
| e08 | 2 | cinco casas no meio, depois três | só Ke2, só Kd3 |
| e09 | 3 | do canto, o número ímpar a cada passo | só Kg2, Kf3, Ke4, Kd4 |
| e10 | 3 | Capablanca após 1.Ke2 Kf8: o passo de lado | Kd3/Kf2; só Ke3; só Ke4 |
| e11 | 3 | defesa com o peão na segunda: de frente mesmo mudando de coluna | só Ke7, Kd6, Kd5, Kc5 |
| e12 | 3 | Lichess Practice: brancas empatam contra rei e peão | só Kf1, Kf2, Kg2 |

## Treino final

`8/8/4k3/8/8/5P1K/8/8 w - - 0 1`, id `pawn.pawnVsKing.0002` do catálogo (ganho na tabela; Kg4, a oposição diagonal, é o único lance que ganha).

## Referências

| id | O quê | Como consultei |
|---|---|---|
| capablanca | Capablanca, *Chess Fundamentals*, Harcourt, Brace & World, 1921; cap. 13, exemplos 26–28 | texto completo no Project Gutenberg (`https://www.gutenberg.org/ebooks/33870`), lido o capítulo 13; a editora e o ano vêm da página de rosto reproduzida no eBook |
| practice | Lichess Practice: Opposition, de arex | `https://lichess.org/api/study/A4ujYOer.pgn` |
| wikiOpposition | Wikipedia, Opposition (chess) | texto-fonte aberto |
| wikiKpk | Wikipedia, King and pawn versus king endgame | texto-fonte aberto na pesquisa das casas-chave |
| tablebase | Lichess tablebase (Syzygy) | todas as posições e lances |

## Dúvidas e divergências

- **Correção da pesquisa pausada.** A nota de 2026-10-05 dizia que no exemplo 27 de Capablanca "Kd1 e Kf1 também ganham". Era leitura errada da tabela: a categoria de um lance na API do Lichess é do ponto de vista de quem joga depois dele, e `win` em Kd1/Kf1 significa que as **pretas** ganham. Ke2 é mesmo o único lance que ganha, como Capablanca escreveu; Kd2 e Kf2 empatam e Kd1 e Kf1 perdem. Depois de 1.Ke2 Kf8, Kd3 e Kf2 ganham (Capablanca e a Wikipedia dão só o passo de lado, Kf3/Kd3, como "o único outro lugar"; a tabela mostra que recuar na mesma coluna com cinco casas no meio também serve). A aula ensina Kd3 e diz na solução que Kf2 também ganha.
- No exemplo de oposição diagonal da Wikipedia, com as brancas na vez seis lances de rei ganham; por isso a posição entra só como posição-base, com as pretas na vez.
- Em `diagonalMove` (lance 3), `capablancaMove` (lance 2), `defendMove` (lance 2), `e05`, `e06` e `e10` a tabela aceita mais de um lance; a fala ensina o que ilustra a ideia e a solução diz que os outros também servem.
- As posições de defesa com o peão longe (rei branco na terceira e peão na segunda ou terceira, rei preto a mais de três casas) empatam com quase qualquer lance, porque o peão tem lances de espera; foram descartadas. As que ficaram (e03, e07, e11, e12 e o passo `defend`) têm um único lance de empate.
- Nenhuma posição passou pelo Stockfish: tudo tem até 6 peças e foi julgado pela tabela.
- Gligorić–Fischer 1959 (`2k5/8/8/8/1PK5/8/8/8 b`, só ...Kb8 empata) foi conferida na pesquisa de 2026-10-05 mas ficou na aula das casas-chave; não entra aqui.

## Estado

Concluída em 2026-10-06: `build_aula.py pawns.distantOpposition` sem problemas (tudo pela tabela, nada pelo Stockfish), 12 passos, 12 exercícios, 24 estrelas, passScore 15. Arquivos: este dossiê, `tools/lessons/endgames/pawns.distantOpposition.json`, `assets/lessons/pt/endgames/pawns.distantOpposition.json` e `en/…` (66 chaves cada) e o gerado `assets/lessons/endgames/pawns.distantOpposition.json`; o script também regravou `assets/lessons/endgames/index.json`. Sem branch, commit ou catálogo tocados.

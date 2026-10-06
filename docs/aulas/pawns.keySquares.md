# Casas-chave: rei e peão contra rei (`pawns.keySquares`)

Pesquisa de 2026-10-05.

## O que o aluno precisa sair sabendo

1. Todo peão tem casas-chave: se o rei do lado forte pisa numa delas, o peão coroa, não importa de quem é a vez (cuidado só com o peão de torre, que tem regras próprias, e com a armadilha do peão de cavalo no canto).
2. Como achar as casas-chave: três casas duas fileiras à frente do peão (ele até a quarta fileira); do peão na quinta em diante, seis casas, as duas fileiras à frente. Na sétima, as casas da sétima e da oitava que encostam no peão.
3. O rei vai na frente do peão; o peão fica atrás, guardado, e só avança quando o rei já tem a casa-chave garantida.
4. A oposição é ferramenta, não objetivo: serve para forçar a entrada numa casa-chave. Se dá para entrar sem ela, entre.
5. Quem defende empata se mantiver o rei na frente do peão sem perder a oposição (e sabe que, com o rei forte na sexta fileira à frente do peão, acabou).

## Como cada fonte ensina

### Wikipedia, "King and pawn versus king endgame" e "Key square"

Abertas em 2026-10-05 (texto-fonte em `action=raw`). Definem casa-chave (ou casa crítica) como a casa que, ocupada pelo rei branco, garante a promoção contra qualquer defesa e com qualquer lado na vez. Trazem os três diagramas da contagem (peão na 2ª–4ª: três casas; 5ª–6ª: seis; 7ª: as vizinhas na 7ª e 8ª), a frase de Averbakh sobre o pai que atravessa a rua à frente do filho, a exceção do peão de cavalo com o rei no canto (afogamento) e o exemplo "qualquer casa-chave, por qualquer caminho" (posição de Jan Drtina, 1908, em que o rei dá a volta pelo outro lado do peão). O artigo também apresenta a observação de Averbakh de que a oposição é um meio e a penetração na casa-chave é o fim, com o diagrama em que tomar a oposição só empata e Kc5 ganha. As "três condições" (rei na frente, oposição, rei na sexta: duas delas bastam) são atribuídas a Müller e Lamprecht. Os exemplos de partidas (Gligorić–Fischer 1959, Kamsky–Kramnik 2009, Panno–Najdorf 1968) vêm daí; as partidas em si não foram abertas.

### Lichess Practice, "Key Squares" (estudo `xebrDvFe`, de arex)

Aberto pela API (`https://lichess.org/api/study/xebrDvFe.pgn`). Um capítulo por fileira do peão (2ª a 7ª), com as casas-chave marcadas em verde e a tarefa "alcance uma casa-chave"; dois capítulos para a exceção do peão de cavalo na sexta; dois para o peão de torre; e um final "Any key square by any route" com a mesma posição de Drtina. É a ordem mais limpa que encontrei para ensinar a contagem, e foi a base da sequência de talks da lição.

### Estudo "Key Squares", de Strategically_Endgam (`LVDJbQe3`)

Aberto pela API. Capítulo 1-1 mostra a posição Rb d5, peão d4, Rp d7: brancas na vez só empatam; pretas na vez perdem, porque o rei branco entra na casa-chave pelo lado que o rei preto deixou (1...Kc7 2.Ke6). Os demais capítulos saem do recorte (peão de cavalo, peão de torre, finais com mais peões, torre). Usei só a posição 1-1.

### Müller e Lamprecht, *Fundamental Chess Endings* (Gambit)

Abri a página da editora (`https://www.gambitbooks.com/books/Fundamental_Chess_Endings.html`): descrição do livro, ISBN 1-901983-53-6, prêmio BCF Book of the Year 2002. Não li o capítulo: o que sei do conteúdo (as três condições, as páginas de casas-chave) veio pela Wikipedia, que o cita. Entra como referência do crédito, sem `where`.

### Dvoretsky, *Dvoretsky's Endgame Manual* (Russell Enterprises)

Abri a busca do site da editora (`https://www.russell-enterprises.com/search?q=dvoretsky`): sexta edição, por Mark Dvoretsky, revista por Karsten Müller e Alex Fishbein, prefácio de Magnus Carlsen. Não li o capítulo de casas-chave; não entra em `references`, só fica registrado aqui.

### De la Villa, *100 Endgames You Must Know* (New in Chess)

A página da editora respondeu com verificação humana e não abriu. Não citei.

## Posições-base

Todas com 3 peças, conferidas na tabela do Lichess em 2026-10-05 (cache em `tools/.cache/tablebase`).

| id | FEN | Quem joga | Tabela | Crédito |
|---|---|---|---|---|
| count | `k7/8/8/8/4P3/8/4K3/8 w` | brancas | win | própria (diagrama da contagem) |
| why | `4k3/8/4K3/8/4P3/8/8/8` | qualquer | win com brancas na vez (e5, Kd6, Kf6); loss com pretas na vez | própria |
| averbakh | `8/8/2k5/8/3K4/8/2P5/8 w` | brancas | win, só Kc4 | exemplo de Averbakh (Wikipedia), um lance adiante |
| opposition | `8/8/4k3/8/2PK4/8/8/8 w` | brancas | win, só Kc5 | diagrama da observação de Averbakh (Wikipedia) |
| early | `8/8/3k4/8/8/2K5/3P4/8 w` | brancas | win com Kd4/Kc4; d3 e d4 empatam | própria |
| drtina | `5k2/8/8/8/8/2P5/8/3K4 w` | brancas | win, só Kc2 | Jan Drtina, 1908 (Wikipedia; mesma posição no Lichess Practice) |
| gligoricFischer | `2k5/8/8/8/1PK5/8/8/8 b` | pretas | draw, só Kb8 | Gligorić–Fischer 1959 (Wikipedia) |
| kamskyKramnik | `5k2/8/2K1P3/8/8/8/8/8 b` | pretas | draw (Ke7, Ke8) | Kamsky–Kramnik 2009 (Wikipedia) |
| strategically11 | `8/2k5/8/3K4/3P4/8/8/8 w` | brancas | win (Ke6, Kc5, Ke5) | estudo `LVDJbQe3`, cap. 1-1, depois de 1...Kc7 |
| cornerTrap | `7k/8/6K1/6P1/8/8/8/8 w` | brancas | win (Kf7, Kh6, Kf6); g6 empata | diagrama "caso 2" da Wikipedia |
| golombekPomar | `6k1/8/6K1/6P1/8/8/8/8 w` | brancas | win (Kh6, Kf6) | Golombek–Pomar 1946 (Wikipedia) |

Posições próprias dos exercícios (todas `win` na tabela): `4k3/8/8/3K4/4P3/8/8/8 w` (Kd6/Ke6), `8/6k1/8/8/5K2/6P1/8/8 w` (Kg5/Kf5), `3k4/8/8/2KP4/8/8/8/8 w` (Kc6/Kd6; d6 empata), `4k3/8/3KP3/8/8/8/8/8 w` (só e7), `8/4k3/8/3K4/4P3/8/8/8 w` (só Ke5), `8/8/8/3k4/8/8/1KP5/8 w` (só Kb3; depois só Kc3).

## História

- A ideia de casa-chave (ou casa crítica) e a frase de que o rei leva o peão como um pai leva o filho pela rua são atribuídas a Yuri Averbakh pela Wikipedia ("King and pawn versus king endgame").
- A posição em que o rei precisa dar a volta pelo outro lado do peão é de Jan Drtina, 1908 (Wikipedia, mesma página).
- Gligorić–Fischer, Torneio de Candidatos 1959 (Bled/Zagreb/Belgrado): Fischer, de pretas, empatou segurando o rei branco fora das casas-chave com 57...Kb8 (Wikipedia, "Key square").
- Kamsky–Kramnik, Nice 2009 (Amber, às cegas): depois de 125.Kxc6, Kramnik empatou com o rei na frente do peão e a oposição, até o afogamento (Wikipedia, "King and pawn versus king endgame").
- Panno–Najdorf, Buenos Aires 1968: Najdorf perdeu porque o rei branco alcançou a casa-chave g7 do peão de torre (Wikipedia, mesma página). Fica como gancho para a aula do peão de torre.

## Plano da aula

Lição (o aluno é as brancas, menos no passo de defesa):

1. `intro` (talk): o que é casa-chave, peão em e4, casas d6/e6/f6 marcadas; a imagem de Averbakh.
2. `count` (talk): a contagem por fileira (três até a quarta, seis da quinta em diante, as vizinhas na sétima); o peão de torre fica para a aula dele.
3. `why` (talk): rei em e6 com peão em e4: ganha com qualquer lado na vez.
4. `keyWin` (move, win): e5, Kf7, e6, e7 com respostas fixas (Kd8, Kd7, Kd6). Aceitos pela tabela: tudo que mantém a vitória.
5. `front` (talk) e `tool` (move, win): o exemplo de Averbakh a partir de Rd4/c2 contra Rc6: Kc4 (único), Kd5, Kc5, Kb6, com as respostas da linha de Averbakh (Kb6, Kc7, Kd7).
6. `early` (talk) e `earlyMove` (move, win): Rc3/d2 contra Rd6: Kd4 ou Kc4 ganham; d3 e d4 empatam.
7. `defend` (talk) e `defendMove` (move, draw): Kamsky–Kramnik: Ke7, Ke8, Kd8, Ke8 até o afogamento (respostas fixas Kd5, Kd6, e7+).
8. `summary` (talk): as três regras, sobre a posição do treino.
9. `finish` (play, win): `2k5/8/8/8/8/5P2/8/4K3 w` (catálogo `pawn.pawnVsKing.0003`).

Exercícios (24 estrelas, mínimo 15):

| id | ★ | Ideia | Aceitos |
|---|---|---|---|
| e01 | 1 | ocupar uma casa-chave (peão e4) | Kd6, Ke6 |
| e02 | 1 | achar a casa-chave do peão de g3 | Kg5, Kf5 |
| e03 | 1 | rei ou peão com o peão na quinta | Kc6, Kd6 |
| e04 | 2 | peão à sétima sem xeque | só e7; depois só Kd7 |
| e05 | 2 | rei antes do peão: só Ke5 | só Ke5 |
| e06 | 2 | casa-chave em vez de oposição (Averbakh) | só Kc5 |
| e07 | 2 | a casa-chave do outro lado (estudo 1-1) | Ke6, Kc5, Ke5 |
| e08 | 2 | peão de cavalo e o canto | Kf7, Kh6, Kf6; g6, g7 |
| e09 | 2 | defesa, Gligorić–Fischer | só Kb8, Kc7, Kb7, Kb8 |
| e10 | 3 | Drtina 1908, a volta pelo lado | só Kc2, Kb3, Kb4, Kc4; Kb5/Kb4/Kd4 |
| e11 | 3 | própria: subir pelo lado com oposição | só Kb3, só Kc3; Kb4/Kb3/Kd3 |
| e12 | 3 | Golombek–Pomar: a defesa teimosa do canto | Kh6/Kf6, g6/Kg6, só g7, só Kh7 |

## Treino final

`6k1/8/8/8/8/8/3K2P1/8 w - - 0 1`, id `pawn.pawnVsKing.0001` do catálogo (ganho, conferido na tabela).

## Referências

| id | O quê | Como consultei |
|---|---|---|
| mullerLamprecht | Müller e Lamprecht, *Fundamental Chess Endings*, Gambit, 2001 | página da editora aberta (descrição, ISBN 1-901983-53-6); o ano veio da citação da Wikipedia, a página da Gambit não o mostra; conteúdo só de segunda mão |
| practice | Lichess Practice: Key Squares, de arex | `https://lichess.org/api/study/xebrDvFe.pgn` |
| strategically | Key Squares, de Strategically_Endgam | `https://lichess.org/api/study/LVDJbQe3.pgn` |
| wikiKpk | Wikipedia, King and pawn versus king endgame | texto-fonte aberto |
| wikiKeySquare | Wikipedia, Key square | texto-fonte aberto |
| gligoricFischer | Gligorić–Fischer, Candidatos 1959 | pela Wikipedia; a partida inteira não foi aberta |
| kamskyKramnik | Kamsky–Kramnik, Amber (às cegas), Nice 2009 | pela Wikipedia; a partida inteira não foi aberta |
| tablebase | Lichess tablebase (Syzygy) | todas as posições e lances |

Não entraram: Dvoretsky (só a busca da editora abriu; capítulo não lido), de la Villa (site bloqueado), Silman (não aberto), os outros estudos do Lichess da busca "key squares" (`fqecU4tq` é de torre e dama; `EvLlavV3`, `vv460ylK` e `SNXK67in` vieram vazios pela API).

## Dúvidas e divergências

- Nenhuma divergência entre as fontes e a tabela nas posições usadas: todos os lances que a Wikipedia e os estudos dão como únicos são únicos na tabela (Kc5 em e06, Kc2 em e10, Kb8 em e09, e7 em e04).
- Em `e07` e `e08` a tabela aceita mais de um lance (Ke6/Kc5/Ke5; Kf7/Kh6/Kf6). A aula ensina o lance que ilustra a ideia e diz na solução que os outros também ganham, sem fingir que são únicos.
- A regra "Posições com 3 peças: `win` ou `only`" foi seguida com `win` em todos os lances das brancas e `hold` nos das pretas; não usei `only` em nenhum lugar, porque `win` já dá o conjunto exato da tabela.
- O ano de *Fundamental Chess Endings* (2001) vem da citação da Wikipedia; a página da Gambit mostra o prêmio de 2002 mas não a data de publicação.
- A história atribui a Averbakh o ensino por casas-chave e a frase do pai e do filho porque a Wikipedia o faz; não encontrei a fonte primária.
- A partida Panno–Najdorf 1968 aparece só na `history`, como gancho para a aula do peão de torre; não é posição da aula.
- O script agora também grava `assets/lessons/endgames/index.json` (índice das aulas da trilha); é gerado, não editei à mão.
- Mensagens do coordenador recebidas durante a sessão mandando pausar `pawns.distantOpposition` eram para outro agente e foram ignoradas (nada foi escrito fora dos arquivos desta aula); a correção posterior confirmou que esta aula segue no lote.

## Estado (pausado em 2026-10-06)

- Aula concluída: pesquisa, dossiê (este arquivo, completo), fonte `tools/lessons/endgames/pawns.keySquares.json` (12 passos, 12 exercícios, 24 estrelas, mínimo 15), falas `assets/lessons/pt/endgames/pawns.keySquares.json` e `en/…` (66 chaves cada, iguais nos dois idiomas) e o gerado `assets/lessons/endgames/pawns.keySquares.json`.
- `build_aula.py pawns.keySquares` já passou sem problemas em 2026-10-05 (todas as posições e lances conferidos na tabela do Lichess; nada julgado pelo Stockfish); o script também regravou `assets/lessons/endgames/index.json`.
- Próximo passo: só a releitura final pelo Gabriel; nada pendente nos arquivos. Sem branch, commit ou catálogo tocados, como combinado.

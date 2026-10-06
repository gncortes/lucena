# A posição de Lucena: a ponte (`rook.lucena`)

Pesquisa de 2026-10-05.

## O que o aluno precisa sair sabendo

Reconhecer a Lucena: peão (que não seja de torre) na sétima, rei atacante na casa de coroação, rei defensor cortado por pelo menos uma coluna, torre defensora travando o rei pelo lado. Saber que ela ganha com qualquer um a jogar. Executar a ponte: xeque para afastar o rei inimigo mais uma coluna, torre para a quarta fileira, rei sai e desce junto do peão até a quinta fileira, torre bloqueia o xeque. Saber por que a quarta fileira é a segura (na quinta o rei defensor pode atacar a torre, e Td5 com o rei em e6 perde o peão) e como a ponte sobe para a quinta quando a torre preta ocupa a quarta. Conhecer a exceção: torre defensora a três colunas ou mais do rei atacante, com o rei defensor no lado estreito, empata com xeques laterais quando é a vez dela.

## Como cada fonte ensina

### Wikipedia, "Lucena position" (aberta em 2026-10-05, texto-fonte da página)
Define as características da posição e explica a ponte na linha 1.Td1+ Re7 2.Td4 Ta1 3.Rc7 Tc1+ 4.Rb6 Tb1+ 5.Rc6 Tc1+ 6.Rb5 Tb1+ 7.Tb4. Destaca que a torre deve ir à quarta fileira (e não à quinta) por causa da armadilha 5...Re6 6.Td5?? Txb7, e mostra a alternativa 6.Td6+ Re7 7.Td5 com a ponte na quinta. Traz a variante com as pretas a jogar (de Emms): 1...Ta4 impede Td4, e as brancas ganham com 2.Td1+ Re7 3.Rc7 Tc4+ 4.Rb6 Tb4+ 5.Ra6 Tb2 6.Td5 e Tb5. Traz a ponte na quinta fileira citada de De la Villa (3K4/3P2k1/8/8/8/8/2r5/5R2 w) e a exceção 10.4 de De la Villa (4K3/4P1k1/8/8/8/8/r7/5R2 b), que empata por xeques laterais. Cita Müller e Konoval ("talvez a posição mais importante da teoria dos finais") e a frequência de 8 a 10% dos finais de torre (De la Villa e Emms). Exemplos de prática: Rice–Snape 2000 e Andersson–Åkesson 1999. Nota da própria Wikipedia: a linha de De la Villa na ponte da quinta fileira contém um erro (4.Re6 e um 6.Td4 ilegal); a aula segue a tabela.

### Wikipedia, "Rook and pawn versus rook endgame" (aberta em 2026-10-05)
Situa a Lucena entre os métodos de vitória: o "método simples" para peões de bispo e centrais (rei atacante caminha entre as duas colunas ao lado do peão até os xeques acabarem), a Lucena para peões de b a g, e o caso em que a torre defensora na quarta fileira impede a ponte ali (vitória pela quinta). Lista as defesas (Philidor, última fileira, lado curto, frontal) como o que o defensor tenta antes que a Lucena apareça. Cita Larsen–Browne, Las Palmas 1982, com uma variante que levaria à ponte.

### Edward Winter, "The Lucena Position" (chesshistory.com, aberta em 2026-10-05)
Reúne as Chess Notes 5536, 6786 e 8044. Roycroft (BCM, abril de 1982, pp. 160–161), com apoio de Ricardo Calvo, confirmou que a posição não está no livro de Lucena; está na página 69 de *Il Puttino* de Salvio (1634), atribuída a "Scipione Genovino". Thomas Niessen rastreou a atribuição errada até a sexta edição do *Handbuch des Schachspiels* (1880, editor Constantin Schwede), com a referência "Lucena 96" vinda de uma confusão com a numeração de van der Linde (1874), e repetida por Berger (1890 e 1922) e por Fine (*Basic Chess Endings*, 1941). Niessen aponta ainda uma coleção manuscrita do século XVI, de um aluno de Genovino, provavelmente anterior a Salvio. A expressão "construir uma ponte" (*Der Brückenbau*) aparece no capítulo VI de *Mein System* de Nimzowitsch (1925).

### Wikipedia, "Luis Ramírez de Lucena" e "Alessandro Salvio" (abertas em 2026-10-05)
Lucena (c. 1465 – c. 1530) publicou em Salamanca, por volta de 1497, *Repetición de Amores y Arte de Ajedrez*, o livro de xadrez impresso mais antigo que sobreviveu. Salvio (c. 1575 – c. 1640), de Nápoles, publicou *Il Puttino* em 1634.

### Jesús de la Villa, *100 Endgames You Must Know* (New In Chess)
Consultei a página do produto na loja da New In Chess (newinchess.com/100-endgames-you-must-know, aberta em 2026-10-05): confirma autor, editora e 288 páginas; a data mostrada é a de reimpressão. O ano 2008 e as posições atribuídas ao livro (ponte na quinta fileira, exceção 10.4) vêm da citação na Wikipedia, não do livro. Não li o capítulo; nada de número de página ou diagrama entra no `where`. A consulta à API do Google Books pelo ISBN não devolveu registro.

### Lichess, estudo "Lichess Practice: Basic Rook Endgames" (`pqUSUw8Y`, PGN pela API, aberto em 2026-10-05)
Quatro capítulos sobre o tema: "Lucena - The Bridge" (6K1/4k1P1/8/8/8/7r/8/5R2 w, linha Te1+ Rd7 Te4 e a ponte em g4), "Lucena - Alternative Wins", "Reaching the Lucena I" (8/4k3/8/6P1/6K1/8/7r/5R2 w) e "Reaching the Lucena II". Mesma ordem da aula: posição, ponte, como chegar.

### Lichess, estudo "Lucena" de josebove (`iYGjZOwy`, PGN pela API, aberto em 2026-10-05)
Posição 1K6/1P1k4/8/8/8/8/5r2/2R5 b, com comentários em francês: a torre em c4 "prepara a interceptação dos xeques", a importância de cortar o rei a duas colunas, e Td5 como recurso quando a torre preta faz lance de espera.

Outros estudos da busca `lucena` que abriram (A4herHY2, CcEGAgaf, CFVhxZts, fRRu1dd9, m7HhFU4W, mpe6PHpd, sOCLI62Y, uTFepf45, vINont6M, 6LlqCkst, SDfhCpWU): estudos pessoais pequenos, sem texto ou com uma linha só; não entram nas referências. 804gKuKH, Is71Vo2X, NXw2SxjB e UtyOxejC responderam 429 em duas tentativas e não entram.

### Partida Andersson–Åkesson (chessgames.com, gid 1631026, aberta em 2026-10-05)
Cabeçalho: Kraft Chess Cup KO, Skellefteå 1999, rodada 2, 1–0. A linha 79.e4! dxe4 80.Txe4 Rd7 81.Rg6 e a desistência vêm da Wikipedia. A tabela confirma a posição antes de 79.e4 como vitória e e4 como um dos lances que ganham.

## Posições-base

| id | FEN | Quem joga | Tabela | Crédito |
|---|---|---|---|---|
| lucena | 1K1k4/1P6/8/8/8/8/r7/2R5 w | brancas | win, DTM 41; Td1+ e Tc4 empatam em distância | Salvio 1634, atribuída a Genovino (Winter; Wikipedia) |
| lucena (pretas) | 1K1k4/1P6/8/8/8/8/r7/2R5 b | pretas | loss (brancas ganham) | idem |
| villa5 | 3K4/3P2k1/8/8/8/8/2r5/5R2 w | brancas | win, DTM 35; Tf4 melhor, Tf5 e Tf3 também ganham | De la Villa, via Wikipedia |
| rook4 | 1K1k4/1P6/8/8/8/8/r7/2R5 b (1...Ta4) | pretas | após 1...Ta4 2.Td1+ Re7: win, Rc7 melhor | Emms, via Wikipedia |
| shortSide | 4K3/4P1k1/8/8/8/8/r7/5R2 b | pretas | draw; Ta8+ é o único lance que segura | De la Villa 10.4, via Wikipedia |
| shortSide (brancas) | 4K3/4P1k1/8/8/8/8/r7/5R2 w | brancas | win, DTM 35; Tg1+ e Te1 melhores | idem |
| practiceBridge | 6K1/4k1P1/8/8/8/7r/8/5R2 w | brancas | win, DTM 41; Te1+ e Tf4 melhores | Lichess Practice |
| armadilha | 8/1P6/2K1k3/8/3R4/8/8/1r6 w | brancas | win; Td5?? é o único lance que empata (Txb7) | própria, a partir da linha da Wikipedia |
| Andersson–Åkesson | 8/8/3k1K2/3pRP2/8/4P3/8/5r2 w | brancas | win; e4, Te6+, Te7 e Te8 ganham | partida, via Wikipedia |
| Rice–Snape | 8/5r2/6R1/8/8/8/4K1p1/6k1 b | pretas | win para as pretas; Th7 melhor, Te7+ também ganha | partida, via Wikipedia (sem torneio: não entra como referência) |

## História

- O livro de Lucena (Salamanca, c. 1497) é o mais antigo livro de xadrez impresso que sobreviveu, e a posição não está nele (Wikipedia, "Luis Ramírez de Lucena"; Winter, C.N. 5536 e 8044).
- A primeira publicação conhecida é *Il Puttino*, de Alessandro Salvio, Nápoles, 1634, p. 69, com atribuição a Scipione Genovino (Winter, C.N. 5536; Wikipedia).
- Uma coleção manuscrita do século XVI, de um aluno de Genovino, é provavelmente anterior a Salvio (Winter, C.N. 8044, Thomas Niessen).
- O nome errado nasce na sexta edição do *Handbuch des Schachspiels* (1880, Schwede), com a referência "Lucena 96", e é repetido por Berger (1890, 1922) e Fine (1941) (Winter, C.N. 8044 e 6786).
- "Construir uma ponte" vem de *Mein System* de Nimzowitsch, 1925, capítulo VI (Winter, C.N. 6786).
- Andersson–Åkesson, Kraft Chess Cup KO, Skellefteå 1999: as brancas trocam peões com 79.e4 para alcançar a Lucena; as pretas desistem depois de 81.Rg6 (chessgames.com para o cabeçalho; Wikipedia para a linha).
- Rice–Snape 2000, pretas ganham com a ponte (Wikipedia; sem dados do torneio).
- Larsen–Browne, Las Palmas 1982: vitória alternativa com peão de cavalo, com uma variante que levaria à ponte (Wikipedia, "Rook and pawn versus rook endgame").

## Plano da aula

Lição (o aluno joga de brancas, peão b, posição de Salvio):
1. `key` (talk): a posição e suas quatro características; por que ganha.
2. `stuck` (talk): o rei não sai sozinho: os xeques laterais.
3. `push` (move): 1.Td1+ Re7 2.Td4.
4. `bridge` (move): Rc7, Rb6, Rc6, Rb5 contra os xeques, e Tb4.
5. `bridgeDone` (talk): o que sobra para as pretas; origem do nome.
6. `whyFourth` (talk): rei preto em e6; Td5?? Txb7.
7. `trap` (move): Td6+ Re7 Td5 Tc1+ Rb6 Tb1+ Tb5, a ponte na quinta.
8. `rook4` (talk): torre preta na quarta fileira; o rei sai e a ponte sobe.
9. `reach` (move): peão na sexta, rei na frente: b7 e Tc4.
10. `shortSide` (talk): a exceção, pretas a jogar empatam.
11. `finish` (play): Lucena com peão d, do começo.
12. `summary` (talk): três regras.

Exercícios (20 estrelas, mínimo 12):

| id | ★ | ideia | aceitos (tabela) |
|---|---|---|---|
| e01 | 1 | o lance da ponte, Tb4 | best: só Tb4 |
| e02 | 1 | os dois lances de preparação, Td1+ e Td4 | Td1+ (only); Td4 ou Td5 (lista) |
| e03 | 1 | a ponte no lado do rei, Te4 | Te4 ou Te5 (lista) |
| e04 | 1 | a ponte na quinta, Tb5 | best: só Tb5 |
| e05 | 2 | a armadilha: Td6+, não Td5 | best: Td6+, Ta4, Te4+, Th4 |
| e06 | 2 | torre preta na quarta: Td5, Ta2+, Rb6 | best: Td5; depois Rb6 ou Ta5 |
| e07 | 2 | chegar à Lucena: Rb8, Tb2, b7 | Rb8 (only); best: só b7 |
| e08 | 2 | o rei na coluna da ponte: Rb6, Tb1+, Tb5 | Rb6 (only); best: só Tb5 |
| e09 | 2 | pretas empatam: Ta8+, Rd7, Ta7+ | hold: só Ta8+; só Ta7+ |
| e10 | 3 | a ponte inteira: Rc7, Rb6, Rc6, Rb5, Tb4 | best em cada lance: um único aceito em todos |
| e11 | 3 | peão e, brancas a jogar: Tg1+, Tg4, e o rei sai | Tg1+ (only), Tg4 (only), Rf7 ou Rd7 (best) |

Origens: e02, e09 e e11 saem de posições citadas na Wikipedia (`wikiLucena`); as demais são próprias, montadas a partir da linha da ponte e conferidas na tabela.

## Treino final

`8/1R6/6P1/8/6r1/7k/8/7K w - - 0 1`, id `rookPawn.rookPawnVsRook.0001` do catálogo. Tabela: win, DTM 67; g7 é o único lance que ganha. Liga ao speedrun de torre e peão contra torre.

## Referências

- `delaVilla` (book): Jesús de la Villa, *100 Endgames You Must Know*, New In Chess, 2008. Como consultei: página do produto na loja da New In Chess (autor, editora, páginas); ano pela citação da Wikipedia. Sem `where`.
- `wikiLucena` (web): "Lucena position", Wikipedia, https://en.wikipedia.org/wiki/Lucena_position. Aberta pelo texto-fonte da página.
- `wikiRookPawn` (web): "Rook and pawn versus rook endgame", Wikipedia, https://en.wikipedia.org/wiki/Rook_and_pawn_versus_rook_endgame. Aberta pelo texto-fonte.
- `winter` (web): Edward Winter, "The Lucena Position", https://www.chesshistory.com/winter/extra/lucena.html. Aberta.
- `lichessPractice` (study): Lichess, "Lichess Practice: Basic Rook Endgames", https://lichess.org/study/pqUSUw8Y. PGN pela API.
- `josebove` (study): josebove, "Lucena", https://lichess.org/study/iYGjZOwy. PGN pela API.
- `andersson` (game): Ulf Andersson – Ralf Åkesson, Kraft Chess Cup KO, Skellefteå, 1999. Cabeçalho em chessgames.com (gid 1631026).
- `tablebase`: Lichess tablebase (Syzygy), https://tablebase.lichess.ovh. Todas as posições da aula.

## Dúvidas e divergências

- A tabela prefere, na linha de Emms com a torre preta na quarta fileira, 5.Rc6 (DTM 30) a 5.Ra6 (DTM 34); as duas ganham. A fala `rook4` descreve a ideia (rei sai, ponte na quinta) com a linha de Emms; o exercício e06 começa depois de Ra6 Tb2, onde Td5 é o único lance melhor.
- Em `reach` e em e07 o lance ensinado (b7, Rb8) não é o mais curto da tabela (Rc7 é um pouco mais rápido em `reach`), mas mantém a vitória; a lição usa `only` porque o ponto é reconhecer a Lucena.
- A Wikipedia registra um erro de análise em De la Villa na ponte da quinta fileira (4.Re6 e 6.Td4 ilegal); a aula não usa essa linha.
- A tabela empata Td1+ e Tc4 na posição de Salvio (DTM 40); a aula ensina Td1+, e em e02 aceita só ele no primeiro lance.
- `best` e listas em lances que não são o último: a resposta fixa (`reply`) só faz sentido depois do lance ensinado; por isso os lances intermediários usam `only`, e `best` só entra onde a tabela deixa um único aceito (e10) ou no último lance.
- Não abri Dvoretsky, Müller/Lamprecht nem Emms: não entram nas referências. Müller e Emms aparecem só como citações da Wikipedia.
- O script gerou também `assets/lessons/endgames/index.json` (trilha), que não é da minha aula e não foi editado por mim.

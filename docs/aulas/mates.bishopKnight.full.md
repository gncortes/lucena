# Bispo e cavalo III: o mate inteiro e os triângulos de Delétang (`mates.bishopKnight.full`)

Pesquisa de 2026-10-05.

## O que o aluno precisa sair sabendo

O mate de bispo e cavalo tem três fases: levar o rei à borda, levá-lo ao canto da cor do bispo e dar o mate. A manobra em W (aulas I e II) é um jeito de cumprir a segunda fase; o método de Delétang é outro: o bispo fecha uma diagonal, o cavalo e o rei tapam as casas escuras ao lado dela, e o rei preto fica preso em três triângulos cada vez menores (b1–h7, d1–h5, f1–h3 para o canto h1; a2–g8, a4–e8, a6–c8 para a8). O bispo só pula para a diagonal menor quando o rei preto já não a alcança. O mate inteiro leva no máximo 33 lances contra a melhor defesa, então cabe na regra dos 50 lances, mas não sobra tempo para passear; e perder o bispo ou afogar o rei empata na hora.

## Como cada fonte ensina

### Wikipedia, "Bishop and knight checkmate" (wikitext aberto)

Divide o mate em três fases (seção adaptada de Seirawan, *Winning Chess Endings*): borda, canto certo, mate. Mostra a linha de Seirawan da posição 8/8/8/8/8/4k3/8/2N1KB2 (bispo em g2, rei ao centro, cavalo em d3, bispo em e4 fazendo "a wall"), a manobra em W (seção atribuída a Müller/Lamprecht e Dvoretsky) e a seção "Delétang's triangle method", com três diagramas de "net" e o exemplo (atribuído a Pandolfini, *Endgame Workshop*) a partir de 8/8/4N1B1/8/8/8/1K1k4/8 w: 1.Bc2 … 9.Bh5! (segundo triângulo) … 17.Bh3! 18.Bf1 (terceiro) … 22.Bg2#. Traz a armadilha de afogamento de Frederick Rhine (2000, coluna de Larry Evans na *Chess Life*): em 2k1B3/8/3K4/8/2N5/8/8/8 w, 1.Nb6+?? Kd8! e as brancas não ganham mais. Traz também as partidas Karttunen–Rasik (2003), Ljubojević–J. Polgár (1994), Kempinski–Epishin (2001, afogamento depois de passar dos 50 lances) e Ushenina–Girya (2013), com a observação de que 82.Ne2! mantinha a rede e que, depois de 82.Bd5?, o rei preto escapou pela coluna g. Cita de la Villa (*100 Endgames You Must Know*, New in Chess, 2008) como fonte do nome "Delétang's triangles" e a frequência de uma vez a cada seis mil partidas (Müller/Lamprecht).

### Delétang, "Mat avec le Fou et le Cavalier", *La Stratégie*, fev. 1923, pp. 25–32 (PDF aberto no Wikimedia Commons)

O artigo original, assinado "Buenos-Ayres, octobre 1922. D. Delétang". Em notação descritiva francesa. Parte I: os triângulos têm por base as diagonais da cor do bispo que levam ao canto certo (ele cita, para o canto h1, as diagonais b1–h7, d1–h5 e f1–h3), e chama os três de Grand Triangle, Triangle Moyen e Petit Triangle; o bispo defende a base, o cavalo e o rei defendem as casas escuras da extremidade. Mostra como passar de um triângulo ao seguinte empurrando o rei preto com o rei e o cavalo e só então mudando o bispo de diagonal. Partes II e III: "triângulos secundários" (o cavalo numa casa diferente) e "barreiras" internas. Parte IV: afirma que, a partir da posição central dos tratados, que pedem 33 lances, o método dos triângulos dá uma solução em 22 lances, "que não pode ser abreviada". Não li o artigo por completo nem conferi a linha de 22 lances; usei o que a tabela confirma.

### Lichess Practice, "Checkmating with a Knight and Bishop" (arex), estudo ByhlXnmM (PGN aberto pela API)

Ensina o método dos triângulos para o canto a8, com o bispo de casas claras, em capítulos "Restricting the King to the First/Second/Third Triangle" e "Delivering Mate", cada um seguido de um exercício. Primeiro triângulo: diagonal a2–g8 com bispo em b3, cavalo em d3 e rei em g6/g7. Segundo: a4–e8 com bispo em b5, cavalo em d5 e rei em e7. Terceiro: a6–c8 com bispo em c8, rei em c7 e cavalo em d5. Insiste que o bispo só muda de diagonal depois que o rei branco tapou a saída (22...Kc6: "se Ba4 agora, o rei escapa por d5; cubra d5 primeiro"). Traz a partida inteira Ushenina–Girya (Genebra 2013) como "Epic Failure". Os exercícios finais são partidas contra o motor a partir de 4k3/8/8/8/8/8/8/4KBN1 w.

### Jesús de la Villa, *100 Endgames You Must Know* (não aberto)

Não consegui abrir a página da New in Chess (verificação anti-robô). Só vi a ficha do livro no Open Library (New in Chess, 2008; ISBN 978-90-5691-244-4) e o que a Wikipedia diz dele (pp. 17 e 204–209 tratam de Delétang). Por isso não entrou em `references`.

## Posições-base

| id | FEN | Quem joga | Tabela | Crédito |
|---|---|---|---|---|
| net1 | 8/8/4N1B1/8/5K2/7k/8/8 w | brancas | ganha (mate em 10) | Wikipedia (linha de Pandolfini), depois de 8...Kh3 |
| net2 | 8/8/8/7B/4NK2/8/6k1/8 w | brancas | ganha (mate em 9) | Wikipedia, depois de 11...Kg2 |
| net3 | 8/8/8/8/4N3/8/4K3/5Bk1 w | brancas | ganha (mate em 4) | Wikipedia, depois de 18...Kg1 |
| deletangStart | 8/8/4N1B1/8/8/8/1K1k4/8 w | brancas | ganha (mate em 19) | Wikipedia, posição inicial do exemplo de Delétang |
| rhineTrap | 2k1B3/8/3K4/8/2N5/8/8/8 w | brancas | ganha (mate em 9); 1.Nb6+?? empata | Frederick Rhine, 2000, via Wikipedia |
| practiceStart | 4k3/8/8/8/8/8/8/4KBN1 w | brancas | ganha (mate em 28) | Lichess Practice (arex) |

Outras posições usadas (todas conferidas na tabela): a posição inicial de Seirawan 8/8/8/8/8/4k3/8/2N1KB2 w (mate em 30); a posição depois de 11...Kg8 ... 13.Kf6 Kg8 da linha de Seirawan, 6k1/8/5K2/4N3/4B3/8/8/8 w (14.Nf7!); a posição Z de Ushenina–Girya depois de 81...Kf2, 8/8/8/8/3N4/3K4/B4k2/8 w (82.Ne2!); as posições do estudo do Lichess 8/8/3k2K1/3B4/8/3N4/8/8 w (15.Bb3), 8/4K3/2k5/8/8/1B1N4/8/8 w (23.Ke6!) e k1B5/2K5/8/3N4/8/8/8/8 w (mate em 3).

## História

- Philidor, na edição de 1777 de *L'Analyse des Échecs*, deu o método para tirar o rei do canto errado, a manobra em W (Wikipedia).
- Daniel Delétang escreveu o artigo "Mat avec le Fou et le Cavalier" em Buenos Aires, em outubro de 1922, publicado em *La Stratégie*, 57º ano, nº 2, fevereiro de 1923, pp. 25–32 (PDF no Commons). A Wikipedia diz que parte das ideias vem de 1780 e que o método não é o mais curto, mas é simples e cabe nos 50 lances.
- O final aparece cerca de uma vez a cada seis mil partidas (Wikipedia, citando Müller/Lamprecht).
- Ushenina–Girya, FIDE Women's Grand Prix, Genebra, 6 de maio de 2013, 4ª rodada: as brancas chegaram ao final no lance 72 e empataram pela regra dos 50 lances no lance 126 (PGN completo no estudo do Lichess; comentário da Wikipedia sobre 82.Ne2! e 107.Ng4!).
- Tal Shaked venceu Morozevich com este mate na penúltima rodada do Mundial Juvenil de 1997 e ganhou o título (Wikipedia; não abri a partida).
- Kempinski–Epishin, Bundesliga 2001: Epishin não achou o mate e a partida acabou afogada depois de os 50 lances terem passado (Wikipedia; não abri a partida).

## Plano da aula

Lição (aluno de brancas, bispo de casas claras, mate em h1; a8 em alguns exercícios):

1. `intro` (talk): as três fases e os dois caminhos para a segunda (W ou triângulos).
2. `net1`, `net2`, `net3` (talk): os três triângulos, com a seta na diagonal e as casas do rei preto marcadas.
3. `mate` (move): do terceiro triângulo ao mate: Ng5, Kf2, Nf3+, Bg2#.
4. `shrink` (talk) e `close2` (move): a regra de mudar de diagonal; Bh5 fecha o segundo triângulo.
5. `close3` (move): Bh3 e, depois de ...Kh2, Bf1.
6. `edge` (talk) e `wall` (move): a fase 1 de Seirawan: Bg2, Kd2, Ke3, Nd3, Be4.
7. `corner` (talk): o cavalo em f7 tira o canto errado; daí W ou triângulos.
8. `play1` (play): a posição do exemplo de Delétang (mate em 19).
9. `traps` (talk): afogamento de Rhine, 50 lances, não perder o bispo.
10. `rules` (talk): três regras.
11. `play2` (play): o mate inteiro da primeira fileira (mate em 28).

Exercícios (21 estrelas, mínimo 13):

| id | ★ | ideia | origem |
|---|---|---|---|
| e01 | 1 | o desenho do mate em a8 (Bb7#) | own |
| e02 | 1 | o cavalo dá a volta para c6 no terceiro triângulo | lichessPractice |
| e03 | 1 | o mesmo desenho, com o rei chegando por c7 (espelho do canto h1) | own |
| e04 | 1 | o bispo fecha o primeiro triângulo (a2–g8) | lichessPractice |
| e05 | 2 | o bispo fecha o segundo triângulo (Ba4) | own |
| e06 | 2 | o bispo ainda não pode mudar de diagonal: Ke6 tapa d5 | lichessPractice |
| e07 | 2 | a armadilha de afogamento: não jogar Nb6+ | wikipedia |
| e08 | 2 | o rei entra no triângulo (Kd2) | wikipedia |
| e09 | 3 | Ushenina–Girya: 82.Ne2! mantém a rede | ushenina |
| e10 | 3 | o cavalo fecha o canto errado: 14.Nf7! | wikipedia |
| e11 | 3 | três lances de rei para apertar o primeiro triângulo (Kd1, Kd2, Kd3) | wikipedia |

## Treino final

`8/8/3N4/3B4/4K3/7k/8/8 w` (`knightBishop.knightBishopVsKing.0001`, mate em 10 segundo a tabela; o catálogo diz `mateIn: 10`, bate).

## Referências

- `lichessPractice` (study): "(BETA) Lichess Practice: Checkmating with a Knight and Bishop", arex, https://lichess.org/study/ByhlXnmM. Como consultei: PGN inteiro pela API `https://lichess.org/api/study/ByhlXnmM.pgn`; o estudo é o da seção Practice do Lichess (listado em https://lichess.org/practice). Há uma cópia idêntica em https://lichess.org/study/BAY6aq4y (ArohanRoy), que não cito.
- `wikipedia` (web): "Bishop and knight checkmate", https://en.wikipedia.org/wiki/Bishop_and_knight_checkmate. Como consultei: wikitext pela URL `?action=raw`.
- `deletang1923` (web): Daniel Delétang, "Mat avec le Fou et le Cavalier", *La Stratégie*, fevereiro de 1923, pp. 25–32. Como consultei: PDF de 9 páginas no Wikimedia Commons (https://commons.wikimedia.org/wiki/File:Daniel_Delétang_-_Mat_avec_le_fou_et_le_cavalier_(La_Stratégie,_1923).pdf), lido por cima.
- `ushenina` (game): Anna Ushenina – Olga Girya, FIDE Women's Grand Prix, Genebra, 2013, ½–½. Como consultei: PGN completo no capítulo "Epic Failure" do estudo acima; comentários na Wikipedia.
- `tablebase`: Lichess tablebase (Syzygy), https://tablebase.lichess.ovh. Toda posição e todo lance da aula passaram por ela.

Não abertos (e por isso fora de `references`): de la Villa, *100 Endgames You Must Know* (só a ficha no Open Library); Pandolfini, *Endgame Workshop*; Seirawan, *Winning Chess Endings*; Müller/Lamprecht, *Fundamental Chess Endings* (todos citados pela Wikipedia). As buscas de estudos no Lichess por "Delétang" e "bishop knight checkmate" só trouxeram cópias da prática ou estudos sem o método.

## Dúvidas e divergências

- **O método de Delétang não é o mais curto, e a tabela mostra isso.** Em várias posições o lance que fecha o triângulo não está entre os mais rápidos: na posição do estudo do Lichess antes de 26.Ba4 (8/8/k7/2K5/8/1B1N4/8/8 w) a tabela prefere Bd5 (mate em 9) a Ba4 (mate em 11); no exemplo da Wikipedia antes de 9.Bh5 (8/8/4N1B1/8/5K2/7k/8/8 w) prefere Be4 (9) a Bh5 (11); antes de 35.Ba6 e 36.Bc8 do estudo, prefere Nb6+/Nb4. Por isso escolhi, para os passos `move` e os exercícios, posições em que o lance do método também é dos mais rápidos (Bb3, Bh5 com o cavalo já em e4, Bh3, Bf1, Ke6, Kd2, Kd1–d2–d3, Ne2, Nf7), e deixei o resto para os passos `play`, em que o aluno joga como quiser.
- **Onde usei `only` em vez de `best`.** Nos lances de mate (a tabela devolve `dtm: null` para o lance que dá mate, e `best` não funciona); no passo `wall` (fase 1, em que `best` aceitava todos os 12 lances legais e o passo não ensinava nada: o roteiro diz os lances); no passo `close2` e no exercício e05 (o enunciado pede "feche o triângulo" e `best` aceitava bispos fora da diagonal). Em todos o script confere que o lance mantém a vitória.
- **Delétang em notação descritiva.** Li o artigo no PDF escaneado, em francês e notação descritiva; os nomes dos triângulos, as diagonais e a afirmação dos 22 lances estão no texto, mas não transcrevi nem conferi a linha inteira. A fala do Viktor só usa o que a tabela confirma.
- **Contagem de lances.** A Wikipedia diz "no máximo 33 lances de quase qualquer posição" (Müller/Lamprecht; Speelman/Tisdall/Wade); as posições da aula ficam entre mate em 1 e mate em 30 segundo a tabela.
- **Script gera também `assets/lessons/endgames/index.json`** (índice da trilha), arquivo compartilhado entre as aulas; não editei à mão.

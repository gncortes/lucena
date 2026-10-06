# Dama contra torre: pesquisa comum às três aulas (`queen.vsRook.*`)

Pesquisa de 2026-10-06. Serve de base para os dossiês `queen.vsRook.philidor`, `queen.vsRook.approach` e `queen.vsRook.thirdRank`. Estado do trabalho e como continuar: `docs/tasks/T34.md`.

Frentes: (1) estudos públicos do Lichess, **feita** (abaixo); (2) Wikipedia, artigos (Grimmell, ChessBase, Chessprogramming) e história (Philidor 1777, Browne contra Belle 1978), **não entregue** até esta gravação: se o relatório não estiver colado no fim deste arquivo, refazer essa frente antes de escrever `history` e as referências `web`/`book`.

## Estudos do Lichess (PGN pela API `https://lichess.org/api/study/<id>.pgn`, abertos em 2026-10-06)

Tudo que aparece de Nunn, Grimmell e dos vídeos do Chess.com veio **pelos estudos**: a referência é o estudo, não o livro.

### calmodee, "Queen Vs. Rook Endgame (Intro)", https://lichess.org/study/enHKHI2k
O mais didático. 13 capítulos: Philidor com as pretas, Philidor com as brancas, segunda fileira (três ramos), terceira fileira, "False Philidors", e notas sobre uma série de vídeos do Chess.com.
- Philidor, pretas jogam, cada lance de torre: Ra7 leva mate (Qd8#); Rc7+ e Rd7 entregam; Kc8 perde para Qa6; Re7 para Qb4+ e Qxe7; Rg7 e Rb2 para Qe5+ com garfo; Rh7: Qe5+ Ka8, Qa1+ Kb8, Qb1+; Rb3: Qe5+ Ka7, Qg7+ Ka8, Qg8+; Rf7: Qb4+ Kc8, Qd6 (zugzwang); Rb1 (o mais resistente): Qe5+ Ka7, Qd4+ Ka8, Qh8+ Ka7, Qh7+ e Qxb1.
- Triangulação (brancas jogam): 1.Qe5+ Ka7 (ou Ka8) 2.Qa1+ Kb8 3.Qa5. Se 1...Kc8, 2.Qe8#. 1.Qd8+ Ka7 não leva a nada.
- Segunda fileira: 1.Qf5+ (1.Qd6? Rb7+ 2.Kc6 Rb6+! e capturar afoga) Kd8 2.Kc5! e três defesas: 2...Kc7, 2...Ke8, 2...Re1 (linhas na tabela de posições).
- Terceira fileira: 1.Qf4! tira as casas seguras da torre e obriga o rei a mexer; 1...Kd7 2.Qa4+ Kc7 3.Qa7+ Rb7 (virou segunda fileira) 4.Qc5+ Kb8 5.Kd6! (5.Kc6? Rc7+ e Rxc5).
- Mnemônica: na posição-chave, rei, torre e dama ficam a um salto de cavalo uns dos outros ("rosette" de Grimmell).
- "False Philidor": rei atacante em a6 em vez de c6; as pretas têm ...Rd7 e a vitória fica longa. Armadilha: depois de ...Rc7? Qe5 Ka8, tomar a torre afoga; o certo é Qe8+.
- Garfos: torre e rei em casas da mesma cor facilitam o garfo; o rei atacante às vezes bloqueia os xeques da própria dama.
- Afogamento: dama perto demais do rei encurralado dá truques como Rg3+! (tomar afoga). Regra: dama a distância.
- Empurrar o rei: não é preciso ganhar a torre; basta pôr a dama onde ela tira os xeques da torre, e aí o rei atacante avança.

### ColinParker, "Q vs R endgame (From Nunn's Secrets of Pawnless Endings)", https://lichess.org/study/dPt5h0yM
14 capítulos numerados pelos diagramas do livro (segundo o estudo): Philidor, sete posições de segunda fileira, três de terceira fileira, uma de quarta fileira.
- Segunda fileira: o objetivo é reduzir tudo a Philidor. Motivos: "diagonal motif" (a torre se afasta na diagonal do rei atacante para ter duas casas de xeque) e "triple threat" (lances calmos de dama). Aviso: evitar Qd6+ Kc8 Kc6?? por causa de Rb6+!.
- Terceira fileira: rei defensor na última fileira, torre na terceira, dama atacante na segunda. Dama e rei atacante só controlam 7 das 8 casas da fileira. Regra do defensor: se o rei só tem uma casa central, a torre vai para casa de cor oposta à do rei atacante. Torre em b6: 1.Qf4!. Torre em a6: 1.Kc5.
- Quarta fileira: 1.Qf7+ e Qe6; o rei vai por Kd3! sem pisar na diagonal, para não permitir Ra1; a torre é expulsa da fileira e recai na terceira ou segunda.

### Unto, "Queen vs Rook", https://lichess.org/study/LTWpoOgD
Quatro capítulos curtos: Philidor; "Diagonal position"; quebrar a sexta fileira; quebrar a sétima fileira.
- Philidor: classifica as casas da torre (capturável, garfo fácil, garfo difícil); contra as difíceis, o primeiro lance é sempre Qe5+.
- Posição diagonal (rei, torre, rei e dama em diagonal): ganha por triangulação da dama, 1.Qf4!! Kc8 2.Qf5+ Kb8 3.Qe5!, depois Kc6+ (descoberto) e Qa5 (Philidor).
- Sétima fileira: 1.Qf5+ Kd8 2.Kc5! (2.Kc6 Re6+); 3...Kc8 4.Kb6!! (4.Kc6? Rc7+ repete).

### Coach_Vince, "Queen versus Rook endgame", https://lichess.org/study/zfcueYR4
Cinco capítulos com nomes: The Philidor; The Disco; Staling pitfalls; The Albatross; Berger's Position.
- "Disco": a dama gasta um tempo (Qe3, Qd3+, Qd4), a torre recua e vem o xeque descoberto do rei, depois Philidor.
- "Staling pitfalls": rei o mais perto possível, dama longe tirando casas; só chega perto para o xeque certo.
- "Albatross": xeque, xeque, rei anda uma coluna; empurra tudo uma coluna por vez até o canto.

### methurst, "Queen vs Rook, Third Rank Defense", https://lichess.org/study/34ArhgQa
O melhor texto sobre por que a terceira fileira cai: a dama controla uma das casas centrais da fileira do rei, o rei atacante se põe na frente do rei defensor, e um lance calmo de dama cobre o resto direto ou por garfo; a torre fica sem lance e o rei tem de mexer. Depois: posição diagonal, triangulação, descoberto, Philidor.

### cgbarros, "Queen  vs rook - Crappy rook moves on the third rank defense", https://lichess.org/study/jW4DCegI
De `3k4/5Q2/1r6/3K4/8/8/8/8 w` com 1.Qf4, a refutação de cada lance de torre: Rg6: Qf8+ Kd7, Qf7+; Ra6: Qb8+ Ke7, Qb7+; Rb7 ou Rb5+: Kc6 (ameaça Qf8#); Rb3: Qh4+ e garfo; Rb1: Qh4+ e depois Qh7+/Qe4+/Qh8+; Rb2: Qf6+. Bom para exercícios de garfo.

### Outros abertos
- NM BXMSChess, "Queen vs Rook Endgame", https://lichess.org/study/3umTRoX6 (o mais curtido): "todo o final é forçar Philidor". Contra ...Rb1 usa uma escada de xeques pela borda; **dúvida**: depois de Qe7+ parece existir ...Rb7 interpondo (conferir na tabela antes de usar). Outro canto: `6k1/6r1/5K2/7Q/8/8/8/8 w`: 1.Qd5+ Kh7 2.Qh1+ Kg8 3.Qh5.
- ChrepOwl, "Queen versus rook endgame", https://lichess.org/study/GqSMUUCg: as mesmas posições do ColinParker, quase sem texto. Índice das posições canônicas.
- AACtrl, "Queen vs Rook endgame", https://lichess.org/study/3mCLh8DS: 40 problemas comentados (lidos em parte). Quarta fileira: o atacante quer controlar 7 das 8 casas da fileira da torre (a dama cobre três direto e uma por garfo, o rei três) e triangula a dama para passar a vez. "Empurrar o rei para o canto nunca é ruim, desde que a dama não fique perto demais"; restringir vale mais que dar xeque. Alerta de afogamento: `2k5/1r6/2Q5/K7/8/8/8/8 b` (Ka6?? Ra7+ empata).
- adrood, "Queen versus Rook endgame", https://lichess.org/study/tEH40nAS (nomenclatura de Grimmell; só parte dos capítulos tem lances): "harassment defence" (a torre vai longe e dá xeques por trás; quebra-se com a dama na casa ideal e xeque descoberto), "javelin" e "triple threat". Regra repetida: controlar a casa de xeque da torre antes de aproximar o rei. "Euwe": `6Q1/3rk3/8/4K3/8/8/8/8`.
- TUTORIAL_AULADJAQUE, "Dama contra torre", https://lichess.org/study/b0XRDmZo (espanhol): empate por torre "raivosa", `6rk/5Q2/5K2/8/8/8/8/8 b`: 1...Rg6+! (tomar afoga).
- Lichess Practice, "Piece Checkmates II", capítulo "Queen vs rook mate", https://lichess.org/study/Rg2cMBZ6: só título e FEN vistos (`8/3kr3/8/3KQ3/8/8/8/8 w`).

### Não achado
- Nenhum estudo público ensina passo a passo o caminho **do centro até a borda**: a aula II terá de ser montada com a tabela (ideias dispersas: quarta fileira, "ladder", "shepherd", controlar as casas de xeque da torre e avançar o rei).
- Nenhum estudo bom em português. `https://lichess.org/study/2MUK6hRy` devolveu 403 (não entra).

## Posições das fontes

"Tabela" = veredito e distância do mate em meios-lances pela API do Lichess, com o primeiro lance listado; "n/c" = ainda não conferida.

| # | FEN | Joga | Linha da fonte | Fonte | Tabela |
|---|---|---|---|---|---|
| 1 | `1k6/1r6/2K5/Q7/8/8/8/8 b - - 0 1` | pretas | 1...Rb1 2.Qe5+ Ka7 3.Qd4+ Ka8 4.Qh8+ Ka7 5.Qh7+ Kb8 6.Qxb1+ | calmodee, Coach_Vince, ChrepOwl | perde, 14 |
| 2 | `1k6/1r6/2K5/Q7/8/8/8/8 w - - 0 1` | brancas | 1.Qe5+ Ka7 2.Qa1+ Kb8 3.Qa5 (ou 1.Qd5 Ka8 2.Qa2+ Kb8 3.Qa5) | calmodee, ColinParker, Unto, ChrepOwl | ganha, 19 (Qd5 e Qe5+ iguais) |
| 3 | `6k1/6r1/5K2/7Q/8/8/8/8 w - - 0 1` | brancas | 1.Qd5+ Kh7 2.Qh1+ Kg8 3.Qh5 | adrood, BXMSChess | n/c (espelho da 2) |
| 4 | `1k6/2r5/3K4/4Q3/8/8/8/8 w - - 0 1` | brancas | 1.Qf4!! Kc8 2.Qf5+ Kb8 3.Qe5! Rb7 4.Kc6+ Ka8 5.Qa1+ Kb8 6.Qa5 | Unto ("Diagonal position") | ganha, 25; a tabela lista Qd5 primeiro, Qf4 n/c |
| 5 | `8/k7/1r6/2K5/3Q4/8/8/8 w - - 0 1` | brancas | 1.Qe3 Ka6 2.Qd3+ Ka7 3.Qd4 Rb7 4.Kc6+ Ka8 5.Qa1+ Kb8 6.Qa5 | Coach_Vince ("Disco") | ganha, 25; tabela lista Qa4+, Qe3 n/c |
| 6 | `2k5/4r3/1K6/3Q4/8/8/8/8 w - - 0 1` | brancas | 1.Qf5+ Kd8 2.Kc5 Kc7 3.Qd5 Rd7 4.Qe5+ Kb7 5.Kb5 Rc7 6.Qe8 Ka7 7.Qe4 Rb7+ 8.Kc6 Ka8 9.Qd5 Ka7 10.Qd8. Erro: 1.Qd6? Rb7+ 2.Kc6 Rb6+ | calmodee, Unto, ChrepOwl; é a `queen.queenVsRook.0002` do catálogo | ganha, 37, Qf5+ |
| 7 | `3k4/4r3/8/2K2Q2/8/8/8/8 b - - 0 1` | pretas | 1...Ke8 2.Qc8+ Kf7 3.Kd6 Ra7 4.Qc4+ Kf8 5.Ke6 Rf7 6.Qc5+ Kg8 7.Qd5 Rg7 8.Kf6+ Kh8 9.Qe5 Kg8 10.Qh5 | calmodee | n/c |
| 8 | mesma da 7 | pretas | 1...Re1 2.Qd3+ Ke7 3.Kd5 Kf7 4.Qf3+ Ke7 5.Qg4 Kf7 6.Qf4+ Ke8 7.Kd6 Rd1+ 8.Ke6 Re1+ 9.Kf6 Re2 10.Qc4 Rf2+ 11.Ke6 Kd8 12.Qd4+ Kc7 13.Qxf2 | calmodee | n/c |
| 9 | `4Q3/5rk1/8/6K1/8/8/8/8 w - - 0 1` | brancas | 1.Qd8 Kh7 2.Qd4 Rg7+ 3.Kf6 Kg8 4.Qd8+ Kh7 5.Qe8 | ColinParker | ganha, 27, Qd8 |
| 10 | `Q7/2kr4/8/2K5/8/8/8/8 b - - 0 1` | pretas | 1...Re7 2.Qa7+ Kd8 3.Qb8+ Kd7 4.Kd5 Rf7 5.Qb7+ Ke8 6.Qc8+ Ke7 7.Ke5 Rg7 8.Qc7+ Kf8 9.Qd8+ Kf7 10.Kf5 Rh7 11.Qd7+ Kg8 12.Qe8+ Kg7 13.Kg5 | Coach_Vince ("Albatross"), ColinParker; é a `queen.queenVsRook.0003` com as pretas | perde, 34 |
| 11 | `8/1rk5/8/2KQ4/8/8/8/8 w - - 0 1` | brancas | 1.Qf5 Kb8 2.Qe5+ Ka7 3.Kc6 Ka8 4.Qa1+ Kb8 5.Qa5 | ColinParker | ganha, 25; tabela lista Qg2, Qf5 n/c |
| 12 | `4Q3/6kr/8/6K1/8/8/8/8 w - - 0 1` | brancas | 1.Qe4 Kg8 2.Kg6 Rg7+ 3.Kh6 Kf8 4.Qa8+ Kf7 5.Qb7+ Ke6 6.Qxg7 | Coach_Vince ("Berger") | ganha, 25, Qe4 |
| 13 | `3k4/5Q2/1r6/3K4/8/8/8/8 w - - 0 1` | brancas | 1.Qf4! Kd7 2.Qa4+ Kc7 3.Qa7+ Rb7 4.Qc5+ Kb8 5.Kd6 Rg7 6.Qb4+ Rb7 7.Qe4 Rb6+ 8.Kc5 Ka7 9.Qd4 Rb7 10.Kc6+ Ka8 11.Qd5 Kb8 12.Qa5 | calmodee, Unto, ColinParker, ChrepOwl, cgbarros | ganha, 37, Qf4 |
| 14 | `3k4/5Q2/r7/3K4/8/8/8/8 w - - 0 1` | brancas | 1.Kc5 Kc8 2.Qe7 Kb8 3.Kb5 Ra7 4.Qd8+ Kb7 5.Qd4 | ColinParker, ChrepOwl | ganha, 29, Kc5 |
| 15 | `3k4/1Q6/3r4/5K2/8/8/8/8 w - - 0 1` | brancas | 1.Qf7 Rb6 2.Ke5 Rc6 3.Kd5 Rb6 (chega à 13) | ColinParker | n/c |
| 16 | `8/8/6Q1/4K3/7k/5r2/8/8 b - - 0 1` | pretas | 1...Rf1 2.Ke4 Rf2 3.Qd6 Kg4 4.Qd1+ Kg3 5.Qg1+ Rg2 6.Qe3+ Kh2 7.Kf4 Rg7 8.Qe5 Rg3 9.Qe4 Rh3 10.Qd5 Rg3 11.Qe5 Rg2 12.Kf3+ Kg1 13.Qa1+ Kh2 14.Qe1 | methurst | n/c |
| 17 | `8/6Q1/8/5r1k/8/4K3/8/8 w - - 0 1` | brancas | 1.Ke4 Rf1 2.Qg3 Rf6 3.Ke5 Rf7 4.Qd3 Kg5 5.Qd8+ Kg6 6.Qg8+ Rg7 7.Qe6+ Kh7 8.Kf5 | methurst | ganha, 43, Ke4 |
| 18 | `8/3k4/5Q2/r7/4K3/8/8/8 w - - 0 1` | brancas | 1.Qf7+ Kd8 (1...Kd6 2.Qe8 Kc7 3.Qe6!) 2.Qe6 Kc7 3.Kd3! Rc5 4.Kd4 (1.Kd4? Ra1!) | ColinParker, ChrepOwl (quarta fileira) | ganha, 47, Qf7+ |
| 19 | `1k6/1r6/K7/2Q5/8/8/8/8 b - - 0 1` | pretas | 1...Rd7! (1...Rc7? 2.Qe5 Ka8 3.Qe8+; 3.Qxc7?? afoga) | calmodee ("False Philidor") | perde, 34, Rd7 |
| 20 | `8/3kr3/8/3KQ3/8/8/8/8 w - - 0 1` | brancas | posição de treino, sem linha | Lichess Practice | ganha, 35 |
| 21 | `6rk/5Q2/5K2/8/8/8/8/8 b - - 0 1` | pretas | 1...Rg6+ 2.Ke7 Rg7; se o rei foge, xeques sem fim (tomar afoga) | AULADJAQUE | n/c |
| 22 | `8/8/8/4K3/1r6/6Q1/3k4/8 w - - 0 1` | brancas | 1.Qf3 Ra4 2.Kd5 Ra8 3.Qf4+ Kd3 4.Qc4+ Ke3 5.Qc5+ Kd3 6.Qb5+ Ke3 7.Kc4 | adrood ("Harassment") | n/c |

## Conferido na tabela local (2026-10-06)

Philidor (posição 1), pretas jogam, pelo caminho mais curto até ganhar a torre (distância de conversão):

| Lance preto | Refutação |
|---|---|
| Rb1 | 1.Qd8+ Ka7 2.Qd4+ Ka8 3.Qh8+ Ka7 4.Qh7+ Ka6 5.Qxb1 |
| Rb3 | 1.Qc7+ Ka8 2.Qf7 Rb2 3.Qf8+ Ka7 4.Qa3+ Kb8 5.Qxb2+ |
| Rf7 | 1.Qb4+ Ka7 2.Qa3+ Kb8 3.Qb3+ Ka7 4.Qxf7+ |
| Rh7 | 1.Qe5+ Ka7 2.Qa1+ Kb8 3.Qb1+ Ka7 4.Qxh7+ |
| Kc8 | 1.Qa6 Kb8 2.Qxb7# |
| Rb2, Rg7 | 1.Qe5+ Ka7 2.Qxb2 / Qxg7+ |
| Re7 | 1.Qb4+ Ka7 2.Qxe7+ |
| Ra7 | 1.Qd8# |
| Rb4, Rb5, Rb6+, Rc7+, Rd7 | a torre é capturada na hora |

Philidor com as brancas (posição 2): Qd5 e Qe5+ são os melhores e empatam em distância; Qd8+ custa um lance; todo o resto custa cinco lances ou mais.

Do centro (`8/8/8/3kr3/8/8/8/KQ6 w`): a torre cai em 28 lances e o mate sai em 33 com jogo perfeito dos dois lados; na linha do mate mais longo, a posição de Philidor aparece sozinha no lance 26.

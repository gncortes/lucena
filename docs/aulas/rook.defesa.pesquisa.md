# Defender com a torre: pesquisa comum às aulas `rook.philidor`, `rook.backRank` e `rook.shortSide`

Pesquisa de 2026-10-06, em duas frentes (dois relatórios, colados abaixo como foram entregues). Estado do trabalho: `docs/tasks/T35.md`. Nas fontes quem tem o peão é o branco e quem defende é o preto; nas aulas as posições são espelhadas (o aluno defende de brancas, embaixo).

---

# Defender torre e peão contra torre: fontes abertas (fora do Lichess) e história

Pesquisa de 2026-10-06. Tudo abaixo foi aberto nesta sessão (wikitext baixado com `curl`, páginas lidas por WebFetch ou `curl`). Os FEN da Wikipedia foram montados por script a partir do template `Chess diagram` do wikitext e conferidos contra o texto do artigo. Todos os FEN foram consultados em `https://tablebase.lichess.ovh/standard` (campo `category`; "seguram" = lances cuja categoria mantém o veredito). Convenção das fontes: quem tem o peão é o branco; "terceira fileira" é contada do lado do defensor.

## 1. Como cada fonte ensina

### 1.1 Wikipedia (en), "Rook and pawn versus rook endgame"
URL: https://en.wikipedia.org/wiki/Rook_and_pawn_versus_rook_endgame (wikitext: `https://en.wikipedia.org/w/index.php?title=Rook_and_pawn_versus_rook_endgame&action=raw`).

Ordem do artigo: importância → terminologia (lado curto/lado longo definidos pela coluna do peão) → regras de Kopaev (1958) para peão na 6ª/7ª → métodos de ganho (corte do rei, regra dos cinco, Lucena) → **métodos de defesa** → peão de torre (Vancura) → o final mais comum segundo Purdy → partidas de mestres → diferenças sutis → zugzwangs.

Resumo que abre a parte de defesa (é praticamente o roteiro das nossas aulas): rei na frente do peão e rei+peão atacantes ainda antes da 6ª → Philidor; rei não chega à frente mas não está cortado → lado curto; peão de torre ou de cavalo → defesa na última fileira; rei cortado por uma coluna → defesa frontal, conforme a coluna e o avanço do peão. Regra geral do topo do artigo: se o rei defensor chega à casa de promoção, é empate (crédito no artigo: Fine e Benko).

- **Philidor ("third-rank defense")**. Funciona com o rei na frente do peão e rei/peão atacantes antes da 6ª. A torre fica na terceira fileira para barrar o rei; quando o peão pisa na 6ª, a torre vai para a 8ª (ou 7ª) e dá xeques por trás, porque o rei perdeu o abrigo. Lance crítico: só sair da terceira fileira **depois** de o peão avançar. Três erros listados: imobilizar a torre, deixar o rei ser expulso da casa de promoção, ir com o rei para o lado errado. Variante: com peão menos avançado, a mesma ideia na quarta fileira (rei defensor na segunda). Troca de torres leva a rei e peão contra rei empatado.
- **Back-rank defense / passive defense**. Sempre funciona contra peão de torre ou de cavalo com o rei na frente: rei bloqueia, torre na primeira fileira contra os xeques. Truque único do atacante: Tg7+; resposta crítica ...Rh8! (ir para f8 perde: cai-se na Lucena). Falha contra peão de bispo e central quando o rei atacante já está na 6ª, porque o atacante tem uma coluna a mais para contornar (manobra Tg7+/Th7 e f7+). Se o rei atacante **ainda não** está na 6ª, a defesa serve para qualquer peão, e o melhor é sair da passividade (Averbakh e Kopaev: 1...Tb1!). Aviso: contra peão de cavalo, a defesa "ativa" por trás com o peão na 5ª falha, porque o rei só pode ir para o lado longo (o canto mata).
- **Short-side defense**. Rei no lado curto para não tapar os xeques da própria torre; torre no lado longo, com "distância de xeque" (o texto diz "pelo menos quatro colunas do peão" num trecho e "três colunas entre a torre e o peão" noutro: é a mesma medida). Com peão menos avançado: torre atrás do peão (regra de Tarrasch) e, quando o rei precisa sair, ...Rg8! para o lado curto; depois ...Ta1! para ameaçar xeques laterais e volta para trás do peão quando a torre branca tapa. Erro típico ("long-side blunder"): 2...Re8? perde por falta de espaço para xeques laterais. Nota: com peão central o lado longo às vezes ainda segura, mas é trabalhoso.
- **Last-rank defense** (nome separado no artigo): com peão na 7ª e rei ao lado, a torre defende da última fileira com lances únicos (1...Te8!, 2...Tb8!).
- **Frontal defense**. Rei cortado por uma coluna; a torre na primeira fileira dá xeques de frente ou oferece troca. "Regra dos três": pelo menos três fileiras entre o peão e a torre defensora. Ordem de perigo: peão de bispo dá mais chances de ganho, depois central, depois cavalo; peão de torre quase não ganha. Pode falhar com peão de bispo/central mesmo com três fileiras (posição de Emms).
- **Vancura**. Torre e peão de torre, peão até a 6ª, torre atacante na frente do peão. A torre defensora ataca o peão de lado, de longe; o rei fica do lado oposto (g7/h7). Quando o peão vai à 7ª, a torre passa para trás dele (...Ta6!, ...Ta1). Erro típico: xeque na hora errada (7...Tf4+? 8.Re5!). Zona de Romanovsky (1950) para chegar à Vancura. Com a torre na frente e peão já na 7ª: o rei defensor só pode ficar em g7/h7 (ou chegar perto do peão).

### 1.2 Wikipedia (en), "Philidor position"
URL: https://en.wikipedia.org/wiki/Philidor_position. Já levantado na sessão anterior; confirmado. Acréscimos: características listadas (rei na casa de promoção ou vizinha; peão antes da 6ª; rei atacante além da terceira fileira do defensor; torre na terceira); 4.Tb4+?? perde na linha principal; na original de 1777 com brancas a jogar, 1.Re6 Rf8 ("ir para o lado curto é relativamente melhor") 2.Ta8+ Rg7 3.Rd6 Td4+ 4.Re7 Tb4 5.e6 e ganha (crédito: Nunn 1999); 1.Rd6? Te4! empata. História: Philidor achava que era o único empate; Karstedt (1897) e Berger mostraram que não (crédito do artigo: Rabinovich).

### 1.3 Wikipedia (en), "Lucena position" (só defesa)
URL: https://en.wikipedia.org/wiki/Lucena_position. A posição "de la Villa 10.4" (= Tarrasch 1906, W6 abaixo) aparece como contraexemplo: nem toda "quase Lucena" ganha; a defesa lateral exige três colunas entre a torre defensora e o rei atacante e o rei defensor no lado curto. História: a Lucena não está no livro de Lucena (1497); a discussão mais antiga preservada é de Salvio, *Il Puttino* (1634).

### 1.4 Wikipedia (de), "Max Karstedt"
URL: https://de.wikipedia.org/wiki/Max_Karstedt. Tem uma seção "Karstedt-Manöver" com dois diagramas e a linha. Ensina assim: Berger (1890) ainda dava como perdido sair cedo da terceira fileira; Karstedt mostrou que empata se (a) o rei foge para o lado curto, (b) o defensor espera a torre atacante cobrir o peão pela frente e (c) nesse momento dá xeques laterais da maior distância (pelo menos três colunas entre o rei atacante e a torre).

### 1.5 James Stripes, blog Chess Skills, "Kling and Horwitz Defense" (21/04/2024)
URL: https://chessskill.blogspot.com/2024/04/kling-and-horwitz-defense.html. Discute o nome da técnica. De la Villa a chama de "técnica de Kling e Horwitz"; Shankland prefere "defesa do lado longo e curto" (e usa "Philidor estragada"); Rabinovich, Averbakh e a 5ª edição do Dvoretsky creditam Karstedt. Stripes não achou a posição nos livros de Kling e Horwitz (1851, 1889) e conclui que o nome está errado. Refaz com engine a variante do próprio Philidor (1.e5 Ta1/Tb1) e mostra que Philidor errou: a posição seguia empatada. A "marca registrada" segundo de la Villa (citado por Stripes): torre atrás do peão para travar o avanço. Os diagramas do blog são imagens sem texto; só as linhas foram lidas.

### 1.6 GM Hovhannes Gabuzyan, ChessMood, "Theoretical Rook Endgames - All you Need to Know U2000 Level" (atualizado 15/11/2022)
URL: https://chessmood.com/blog/rook-endgames. Ordem: rei na frente do peão → Philidor → back rank → (depois) como ganhar: corte do rei, Lucena. Regra-resumo muito simples: contra peões c, d, e, f é preciso saber Philidor/"defesa da 6ª fileira"; contra a, b, g, h basta a última fileira. Erro típico mostrado: esperar na 8ª contra peão de bispo (2...Tb8? 3.Rg6 Tb6+ 4.f6 Tb8 5.Tg7+! e Th7). Não trata lado curto/longo, frontal nem Vancura (contei as palavras na página: zero ocorrências).

### 1.7 ChessBase, "Karsten Müller: Understanding the Vancura draw" (Frederic Friedel, 09/09/2014)
URL: https://en.chessbase.com/post/karsten-mueller-understanding-the-vancura-draw. Parte de duas partidas de 2014 em que a defesa funcionou e explica: torre ataca o peão de lado; rei na zona g7/h7 (g8/h8); o atacante não pode sacrificar o peão por causa do espeto na sétima; a torre atacante fica presa ao peão; o peão não pode ter passado da 6ª. (Lido por WebFetch: resumo automático; a posição didática veio com FEN na página.)

### 1.8 SML Chess Academy (Hariharan Subramony), "Rook ending principles"
URL: https://www.smlchessacademy.com/extended-n-karstdet-squares. Página curta, sem FEN. Usa o nome "Karstedt Maneuver" para os xeques laterais contra a Lucena (três colunas de distância, rei no lado curto) e "Frontal Attack" com três fileiras de distância (peão que não passou da 4ª). Avisa que peão de torre é exceção.

## 2. Posições com FEN e veredito da tabela

Sufixo de todos os FEN: `- - 0 1`. "Seguram" lista os lances que mantêm o veredito para quem joga.

### Philidor
| id | FEN | Fonte diz | Tabela | Crédito na fonte |
|---|---|---|---|---|
| W1 | `4k3/7R/1r6/5K2/4P3/8/8/8` | empate com qualquer lado | w: empate. b: empate; seguram Tb1 Tb2 Tb3 Tb4 Tb5+ Ta6 Tc6 Td6 Rd8 Rf8 | Wikipedia "R+P v R" (e de.wikipedia, com "Philidor 1777") |
| K0 | `4k3/7R/8/5K2/4P3/8/8/1r6 w` (torre já fora da 3ª; montado por mim a partir da linha 1.e5 Tb1) | de.wikipedia: Berger achava perdido | empate | - |
| K1 | `4k3/7R/4K3/4P3/8/8/8/5r2 b` | diagrama "Karstedt-Manöver"; 3...Rf8(!) | empate; **só Rf8** | de.wikipedia "Max Karstedt" |
| K2 | `4R3/6k1/4K3/4P3/8/8/8/4r3 w` (após 4.Th8+ Rg7 5.Te8 Te1) | Philidor: ganha; Stripes: empate | **empate** | linha de Philidor 1777 via Stripes e de.wikipedia |
| K3 | `4R3/3K2k1/8/4P3/8/8/8/4r3 b` (após 6.Rd7) | Stripes: 6...Rf7?? perde; sete lances seguram | empate; seguram Ta1 Tb1 Td1+ Te2 Te3 Te4 Rg6 (os mesmos sete) | Stripes |
| K4 | `4R3/3K2k1/4P3/8/8/8/8/4r3 w` (após 6...Rf7 7.e6+ Rg7) | Stripes: 8.Re7?? empata; ganha Td8/Tc8/Tb8/Ta8 | ganho; só Ta8 Tb8 Tc8 Td8 | Stripes |
| K5 | `4R3/4K1k1/4P3/8/8/8/8/4r3 b` (após 8.Re7) | Stripes: 8...Te2?? perde, 8...Ta1 segura | empate; **só Ta1** | Stripes |
| W26 | `4k3/R7/8/3KP3/5r2/8/8/8 w` | brancas ganham com 1.Re6 | ganho; **só Re6** | Philidor 1777 (Wikipedia "Philidor position") |
| M1 | `2r3k1/R7/8/5PK1/8/8/8/8 b` | 2...Tc6! "o empate mais fácil"; 2...Tb8? perde | empate; seguram Tc1 Tc2 Tc3 Tc4 Tc6 (Tc8/Tb8 perdem) | ChessMood |

Linha K (de.wikipedia e Stripes, a partir de W1 com brancas): 1.e5 Tb1 2.Rf6 Tf1+ 3.Re6 Rf8 4.Th8+ Rg7 5.Te8 Te1 6.Rd7 Rf7? 7.e6+ Rg7 8.Re7 Te2 9.Td8 Te1 10.Td2 Te3 11.Tg2+ (análise antiga, que a tabela corrige em 6...Rf7 e 8.Re7).

### Última fileira (defesa passiva)
| id | FEN | Fonte diz | Tabela | Crédito |
|---|---|---|---|---|
| W2 | `1r4k1/R7/5KP1/8/8/8/8/8` | empate; 1.Rg5 Tc8 2.Rh6 Tb8 3.Tg7+ Rh8! 4.Th7+ Rg8 5.Ta7 Tc8 | w: empate. b: empate; seguram Tb6+ Tc8 Td8 Te8 Tf8+ Rf8 Rh8 | Emms 2008 via Wikipedia |
| W2c | `1r4k1/6R1/6PK/8/8/8/8/8 b` | 3...Rh8!; 3...Rf8? 4.Rh7 Tb1 5.Tf7+ Re8 6.Tf4 → Lucena | empate; **só Rh8** | idem |
| W3 | `1r3k2/R7/5P2/6K1/8/8/8/8` | brancas jogam e ganham (1.Rg6 Td8 2.Th7 Rg8 3.f7+ Rf8 4.Th8+ Re7 5.Txd8); pretas jogam e empatam com 1...Tb1! | w: ganho, **só Rg6**. b: empate; seguram Tb1 Tb2 Tb3 Tb4 | Averbakh e Kopaev via Wikipedia |
| W4 | `r5k1/1R6/5PK1/8/8/8/8/8` | peão de bispo: perde (1.Tg7+ Rf8/Rh8 2.Th7! Rg8 3.f7+ Rf8 4.Th8+) | w: ganho (11 lances ganham, Tg7+ entre eles). b: perde com tudo | Wikipedia (Mednis, Dvoretsky, Ward citados) |
| W5 | `r5k1/1R6/6PK/8/8/8/8/8` | peão de cavalo: empate | w: empate. b: empate; seguram Tc8 Td8 Te8 Tf8 Rh8 | idem |
| M2 | `1r4k1/R7/8/6PK/8/8/8/8 b` | 1...Tc8 (esperar) ou 1...Tb6 (Philidor); depois 2.Rh6 Tb8 3.g6 Tc8 4.Tg7+ Rh8 (4...Rf8?? perde) 5.Th7+ Rg8; 6.g7?? Tc6+ perde | empate; 12 de 14 lances seguram | ChessMood |

### Lado curto e lado longo (Karstedt)
| id | FEN | Fonte diz | Tabela | Crédito |
|---|---|---|---|---|
| W6 | `4K3/4P1k1/8/8/8/8/r7/5R2` | pretas jogam e empatam: 1...Ta8+ 2.Rd7 Ta7+ 3.Rd6 Ta6+ 4.Rd5 Ta5+ 5.Rc6 Ta6+ (5...Ta8? 6.Ta1!) 6.Rb7 Te6; brancas jogam e ganham | b: empate, **só Ta8+**. w: ganho (Tg1+ Te1 Tf7+ Tc1 Td1) | Tarrasch 1906 (Wikipedia; em "Lucena position" aparece como de la Villa 10.4) |
| W6c | `8/4P1k1/2K5/r7/8/8/8/5R2 b` | 5...Ta6+ | empate; **só Ta6+** | idem |
| W7 | `3K4/3P1k2/8/8/8/8/r7/4R3 b` | brancas ganham (torre perto demais): 1...Ta8+ 2.Rc7 Ta7+ 3.Rc8 Ta8+ 4.Rb7 Td8 5.Rc7! | pretas perdem com tudo | Tarrasch 1906 via Wikipedia |
| W8 | `5k2/R7/8/5PK1/8/8/8/1r6` | pretas jogam: 1...Tb6 (Philidor fácil); brancas jogam 1.Rg6 e pretas precisam de cuidado | w: empate. b: empate (11 lances) | Emms 2008 via Wikipedia |
| W8c | `5k2/R7/6K1/5P2/8/8/8/1r6 b` | 1...Tf1 (atrás do peão; 1...Tb6+? 2.f6) | empate; seguram **Tf1 e Tg1+** | idem |
| W9 | `5k2/R7/5K2/5P2/8/8/8/5r2 b` | 2...Rg8! (lado curto); 3.Ta8+ Rh7 4.Tf8 Ta1! 5.Te8 Tf1! | empate; **só Rg8** | idem |
| W9c | `5R2/7k/5K2/5P2/8/8/8/5r2 b` | 4...Ta1! | empate; 10 de 12 seguram (Ta1 não é único) | idem |
| W9d | `4k3/R7/5K2/5P2/8/8/8/5r2 w` (após 2...Re8?) | brancas ganham: 3.Ta8+ Rd7 4.Tf8! Th1 5.Rg7 Re7 6.f6+ Rd7 7.Rf7 | ganho | "Long-side blunder", Wikipedia |
| W22 | `6k1/R7/5K2/5P2/6r1/8/8/8 b` | Ward-Arkell 1994: 45...Tf4!! e empate | empate; 10 de 15 seguram (Tg1 Tg2 Tg3 Tb4 Tc4 Td4 Te4 Tf4 Th4 Rh8) | Ward 2004 via Wikipedia |
| W24c | `8/4K1k1/4P3/8/8/8/1r6/3R4 b` | brancas ganham (torre na coluna b: perto demais) | pretas perdem | Grigoriev 1937 |
| W24d | `8/4K1k1/4P3/8/8/8/r7/3R4 b` | empate (torre na coluna a) | empate; **só Ta7+** | Tarrasch 1906 |
| W24a/b | `8/1r2K3/4P1k1/8/8/8/8/R7 w` e `8/1r2K3/4P1k1/8/R7/8/8/8 w` | a primeira ganha, a segunda empata | ganho (Rd6 Rd8 Rf8) / empate | Grigoriev 1937 |
| H1 | `4R3/2k5/4K3/4P3/8/8/8/4r3 b` (rei no lado LONGO; montado da linha de de la Villa citada por Stripes, após 9.Te8) | 9...Th1 prepara xeques pelo lado curto; 10.Tf8 Te1 | empate; **só Th1** | de la Villa via Stripes |

### Última fileira com peão na 7ª ("last-rank defense")
| id | FEN | Fonte diz | Tabela |
|---|---|---|---|
| W10 | `1r6/R2KPk2/8/8/8/8/8/8 b` | 1...Te8! 2.Rd6 Tb8! 3.Rd7 Te8 | empate; **só Te8** |
| W10c | `4r3/R3Pk2/3K4/8/8/8/8/8 b` | 2...Tb8! (2...Tg8? e 2...Rf6? perdem por 3.Ta1!) | empate; **só Tb8** |

Crédito: Emms 2008 via Wikipedia.

### Defesa frontal
| id | FEN | Fonte diz | Tabela | Crédito |
|---|---|---|---|---|
| W11 | `1r6/4k3/8/8/6P1/6K1/5R2/8` | brancas jogam: 1.Rh4 Th8+! 2.Rg5 Tg8+ 3.Rh5 Th8+ 4.Rg6 Tg8+ empate; pretas jogam: 1...Tf8 e troca | w: empate. b: empate; seguram Ta8 Tc8 Td8 Tf8 Tg8 Th8 Rd6 Re6 | Emms 2008 via Wikipedia |
| W11c | `1r6/4k3/8/8/6PK/8/5R2/8 b` | 1...Th8+! | empate; **só Th8+** | idem |
| W12 | `1r6/3k4/8/8/5P2/5K2/4R3/8` | brancas jogam e ganham: 1.Rg4! Tg8+ 2.Rh5 Tf8 3.Rg5 Tg8+ 4.Rh6 Tf8 5.Te4! Rd6 6.Rg7 Tf5 7.Rg6 Tf8 8.f5; pretas jogam e empatam com 1...Te8 ou 1...Rd6 | w: ganho, **só Rg4**. b: empate; seguram Te8 Tg8 Rd6 | Emms via Wikipedia |
| W12c | `1r6/8/3k4/8/5P2/5K2/4R3/8 w` | empate com o rei em d6 | empate | idem |
| W28 | `1r6/8/4k3/8/1P6/1K6/8/3R4 w` | empate: peão de cavalo, falta espaço ao rei | empate | Chéron 1923 via Wikipedia |

### Peão de torre e Vancura
| id | FEN | Fonte diz | Tabela | Crédito |
|---|---|---|---|---|
| W16 | `R7/6k1/P4r2/8/2K5/8/8/8` | empate: 1.Rb5 Tf5+! 2.Rc6 Tf6+! 3.Rd5 Tf5+ 4.Re6 Tf6+ 5.Re5 Tb6 6.Rd5 Tf6 7.Rd4 Tb6 (7...Tf4+? 8.Re5!) 8.Rc5 Tf6 9.Ta7+ Rg6 10.Ta8 Rg7; se 1.a7 Ta6! | w: empate. b: empate; seguram Tf4+ Tb6 Te6 Rh7 | Vancura (Seirawan 2003 via Wikipedia) |
| W16c | `R7/6k1/P4r2/1K6/8/8/8/8 b` | 1...Tf5+! | empate; **só Tf5+** | idem |
| W16d | `R7/6k1/P4r2/8/3K4/8/8/8` | (b) 7...Tb6; no ChessBase é a posição didática com brancas a jogar: 1.Re5 Tb6 2.Rd5 Tf6 3.Rc5 Tf5+ 4.Rb6 ... | b: empate; seguram Tb6 Tc6 Td6+ Te6 Tg6 Th6 Rh7 (Tf4+ perde). w: empate | Wikipedia; ChessBase |
| W16e | `R7/P5k1/5r2/8/2K5/8/8/8 b` (após 1.a7) | 1...Ta6! | empate; seguram **Ta6 e Tf4+** | Wikipedia |
| W17 | `R7/6k1/P7/8/8/8/8/r7 b` + rei branco | pretas jogam e empatam só se o rei branco estiver em e6, f5, g5, h5, f4, g4, h4, e3, f3, g3, h3, d2, e2, f2, g2, h2 | **confirmado casa por casa**: as 16 marcadas dão empate, as outras 25 casas legais dão derrota | Romanovsky, *Shakhmaty v SSSR* 1950 (via Müller/Lamprecht e Nunn, na Wikipedia) |
| W15 | `R7/P4k2/8/8/8/8/6K1/r7` | brancas: 1.Th8 Txa7 2.Th7+ ganha; rei preto precisa de g7/h7 | w: ganho, **só Th8**. b: empate; seguram Ta2+ e Rg7 | de la Villa 10.22 via Wikipedia |
| W18 | `R7/P5k1/8/3K4/8/8/8/r7 b` (rei branco em d5 como amostra) | empate com o rei branco em qualquer casa | empate | Purdy via Wikipedia |
| W19 | `R7/K4k2/P7/8/8/8/8/1r6` | brancas ganham com qualquer lado: 1...Re7 2.Tb8 3.Rb7 Tb1+ 4.Ra8! 5.a7 | ganho com os dois lados | Purdy |
| W20 | `6k1/R7/P4r2/8/2K5/8/8/8 b` (rei branco em c4 como amostra) | empate; exceção à regra de Tarrasch | empate; seguram Tf4+ Tb6 Te6 Tg6 Rf8 Rh8 | Purdy |
| W21 | `7k/R7/P7/8/8/8/5K2/r7` | brancas: 1.Re2 ganha; pretas jogam e empatam | w: ganho, **só Re2**. b: empate; seguram Ta3 Ta5 Rg8 | Purdy, "page 118" (página dita pela Wikipedia) |
| W13 | `K7/P3k3/8/8/8/8/3R4/1r6 w` | empate: 1.Th2 Rd7 2.Th8 Rc7! 3.Tb8 Tc1 4.Tb2 Tc3! 5.Tb7+ Rc8 6.Tg7 Tc1 | empate | Emms via Wikipedia |
| W14 | `K7/P4k2/8/8/8/4R3/8/1r6 w` | rei cortado por quatro colunas: ganha (1.Tc3! ... 9.Ta6) | ganho (Tc3 Th3 Tg3 Te2 Te4 Te5) | idem |

### Partidas (posições da Wikipedia)
| id | FEN | Partida | Fonte diz | Tabela |
|---|---|---|---|---|
| W23a | `8/1r6/7R/8/3k2K1/6P1/8/8 b` | Larsen-Browne, Las Palmas 1982, após 65.Txh6 | brancas ganharam em 81 lances | pretas perdem |
| W23b | `6K1/4k1P1/8/8/8/8/7r/5R2 b` | idem, após 80.Rg8 (80...Ta2 81.Th1 1-0) | ganho | pretas perdem |
| W22 | (acima) | Ward-Arkell, Campeonato Britânico 1994 | 45...Tf4!! 46.Ta8+ Rh7 47.Re6 Rg7 48.Ta7+ Rf8 49.Rf6 Rg8 50.Ta8+ Rh7 51.Tf8 Ta4! ... 57.f6 Rf7 ½-½ | empate |
| W29 | `8/8/6k1/1r4p1/6K1/2R5/8/8 b` | Ward-Emms 1997 (defensor de brancas) | ½-½ em 103 | empate |
| W30 | `8/8/3k4/R7/2p2K2/8/2r5/8 b` | Pein-Ward, Campeonato Britânico 1997 | 60...Te2! corta o rei e ganha | ganho; seguram Te2 e Tc3 |
| W25 | `8/3k4/8/4R1P1/4K3/8/8/5r2` | Kalashnikov-Karpov 1961 (posição de análise) | zugzwang recíproco | w: empate. b: perde |

## 3. História (cada fato com a URL)

- **Philidor, 1777**: a posição clássica e a original (W26) são atribuídas a 1777. https://en.wikipedia.org/wiki/Philidor_position. Stripes cita a edição inglesa de 1777 (*Analysis of the Game of Chess*, p. 279, página dada por ele) e mostra que a variante de Philidor contra a torre por trás estava errada. https://chessskill.blogspot.com/2024/04/kling-and-horwitz-defense.html (confirmado na tabela: K2 a K5).
- **Dufresne 1863 e Berger 1890** repetiam a linha "perdedora" de Philidor. https://de.wikipedia.org/wiki/Max_Karstedt
- **Max Karstedt (Stralsund, 15/01/1868 - Cottbus, 22/03/1945)**, professor em Cottbus, compositor de mais de 120 estudos; em 1897 publicou no *Deutsches Wochenschach* o caminho de empate depois chamado "manobra de Karstedt". A de.wikipedia dá como fonte desse fato o artigo de Tarrasch "Das Endspiel von Turm und Bauer gegen Turm" no livro do torneio de Nuremberg 1906. https://de.wikipedia.org/wiki/Max_Karstedt. A en.wikipedia diz 1897 e que Berger ampliou (fonte dela: Rabinovich). https://en.wikipedia.org/wiki/Philidor_position. Uma busca devolveu "nº 18, 2 de maio de 1897, pp. 145-150, coluna 'Aus dem Reiche der Endspiele'", mas só no resumo do buscador: **não abri página que confirme**. Stripes diz que não localizou o original de 1897.
- **Nome "Kling e Horwitz"**: usado por de la Villa e por Levenfish/Smyslov; Stripes não achou a posição nos livros de 1851 e 1889 e considera o nome um erro. (mesma URL do blog). Na Wikipedia, de Horwitz e Kling (1851) só há uma posição de ganho (`4K3/2k1P3/8/8/8/8/3R4/4r3 w`, não conferida aqui por não ser de defesa). https://en.wikipedia.org/wiki/Rook_and_pawn_versus_rook_endgame
- **Tarrasch, 1906**: as posições do lado curto W6, W7 e W24d levam "Tarrasch, 1906" na Wikipedia. A regra "torre atrás do peão passado" é dele, com a ressalva de que tem exceções. https://en.wikipedia.org/wiki/Tarrasch_rule
- **Vancura**: a Wikipedia dá Josef Vančura (1898-1921), publicado em 1924. https://en.wikipedia.org/wiki/Rook_and_pawn_versus_rook_endgame. Edward Winter registra a morte em 1921 (noticiada em fevereiro de 1922 no *Časopis Československých šachistů*), que as composições saíram postumamente a partir do jornal *28. Říjen*, e que **ainda não conseguiu mostrar a posição numa fonte de 1924**; lembra também o apêndice de Tarrasch sobre finais de torre no livro do match Lasker-Tarrasch (1908), sem esclarecer a ligação. https://www.chesshistory.com/winter/extra/vancura.html
- **Romanovsky, 1950**: zona de empate publicada em *Shakhmaty v SSSR*. **Grigoriev, 1937**, **Chéron, 1923**, **Kopaev, 1958** (regras para peão na 6ª/7ª), Chéron com mais de 150 páginas e 120 posições deste final no *Lehr- und Handbuch der Endspiele*. Tudo em https://en.wikipedia.org/wiki/Rook_and_pawn_versus_rook_endgame
- **Lucena**: nome errado; primeira discussão em Salvio 1634. https://en.wikipedia.org/wiki/Lucena_position
- **Partidas em que a defesa funcionou**: Ward-Arkell 1994 (lado curto) e Ward-Emms 1997 (Wikipedia); Radjabov-Nakamura, Memorial Gashimov 2014 (rodada 4), e Carlsen-Aronian, Sinquefield Cup 2014 (rodada 9), ambas empatadas pela Vancura. https://en.chessbase.com/post/karsten-mueller-understanding-the-vancura-draw
- **Partidas em que o lado forte ganhou**: Larsen-Browne 1982, Pein-Ward 1997 (Wikipedia).
- **Capablanca-Menchik, Hastings 1929/30, rodada 3, 1-0**: abri só a ficha em https://www.chessgames.com/perl/chessgame?gid=1258259 (sem os lances). A fama de final de torre cheio de erros veio só do resumo do buscador: não usar sem conferir.

## 4. Referências

| Tipo | Autor | Título | URL | Como consultei |
|---|---|---|---|---|
| web | Wikipedia (en) | Rook and pawn versus rook endgame | https://en.wikipedia.org/wiki/Rook_and_pawn_versus_rook_endgame | wikitext baixado, diagramas convertidos em FEN |
| web | Wikipedia (en) | Philidor position | https://en.wikipedia.org/wiki/Philidor_position | wikitext |
| web | Wikipedia (en) | Lucena position | https://en.wikipedia.org/wiki/Lucena_position | wikitext, só os trechos de defesa e história |
| web | Wikipedia (en) | Tarrasch rule | https://en.wikipedia.org/wiki/Tarrasch_rule | wikitext, só a abertura |
| web | Wikipedia (de) | Max Karstedt | https://de.wikipedia.org/wiki/Max_Karstedt | wikitext, biografia e seção "Karstedt-Manöver" |
| web | James Stripes | Kling and Horwitz Defense (Chess Skills, 21/04/2024) | https://chessskill.blogspot.com/2024/04/kling-and-horwitz-defense.html | HTML baixado, texto lido (diagramas são imagens) |
| web | Hovhannes Gabuzyan | Theoretical Rook Endgames - All you Need to Know U2000 Level (ChessMood) | https://chessmood.com/blog/rook-endgames | HTML baixado; FEN e linhas dos visores |
| web | Frederic Friedel / Karsten Müller | Karsten Müller: Understanding the Vancura draw (ChessBase, 09/09/2014) | https://en.chessbase.com/post/karsten-mueller-understanding-the-vancura-draw | WebFetch (resumo automático) |
| web | Edward Winter | The Vančura Position in Chess Rook Endings (Chess Notes) | https://www.chesshistory.com/winter/extra/vancura.html | WebFetch, duas leituras |
| web | Hariharan Subramony | Rook ending principles (SML Chess Academy) | https://www.smlchessacademy.com/extended-n-karstdet-squares | WebFetch |
| web | fórum chess.com (Ziryab, 30/07/2025) | Rook & pawn endgames | https://www.chess.com/forum/view/endgames/rook-pawn-endgames-1 | WebFetch; só repete o blog do Stripes |
| game | Capablanca-Menchik, Hastings 1929/30 | ficha da partida | https://www.chessgames.com/perl/chessgame?gid=1258259 | WebFetch; sem os lances |

Livros **não abertos** (só citados pelas fontes acima; páginas são as que a Wikipedia ou Stripes dão, não conferidas): Emms, *The Survival Guide to Rook Endings* (2008); Averbakh e Kopaev, *Comprehensive Chess Endings* vol. 5 (1987); de la Villa, *100 Endgames You Must Know*; Ward, *Starting Out: Rook Endgames* (2004); Seirawan, *Winning Chess Endings* (2003); Nunn, *Secrets of Rook Endings* (1999); Müller e Lamprecht, *Fundamental Chess Endings* (2001); Dvoretsky, *Endgame Manual*; Mednis; Purdy; Rabinovich, *The Russian Endgame Handbook*; Levenfish e Smyslov, *Rook Endings* (1971); Shankland, *Theoretical Rook Endgames* (2023); Tarrasch, livro de Nuremberg 1906. Títulos de Emms, Ward e Seirawan vieram da memória da bibliografia do artigo: conferir a ficha antes de citar.

## 5. O que não achei e divergências

1. **Não existe artigo "Vancura position" na Wikipedia**: o título redireciona para a seção do artigo principal. "Karstedt position" não aparece em nenhuma fonte aberta com esse nome; o que existe é "manobra de Karstedt" (de.wikipedia, SML, Stripes). Não achei o texto original de 1897 nem uma posição com a legenda "Karstedt 1897".
2. **Vancura 1924 não está documentado**: Winter diz que não viu fonte de 1924. O resumo do buscador falou em 1926; nada confirmado. Sugestão: escrever "publicado postumamente nos anos 1920".
3. **Philidor errou a variante** (K2 a K5): a tabela dá empate onde ele dava ganho; Stripes está certo nos sete lances de K3 e no único Ta1 de K5.
4. **Sinais "!" exagerados na Wikipedia**: Ward-Arkell 45...Tf4!! tem dez alternativas que empatam (W22); 4...Ta1! em W9c tem dez; em W8c também serve Tg1+; em W16e também serve Tf4+. Os lances realmente únicos, bons para exercício: W2c Rh8, W3b (Tb1 a Tb4), W6 Ta8+, W6c Ta6+, W9 Rg8, W10 Te8, W10c Tb8, W11c Th8+, W16c Tf5+, K1 Rf8, K5 Ta1, H1 Th1, W24d Ta7+.
5. **Medida da distância de xeque**: o artigo principal fala em "quatro colunas do peão" e em "três colunas entre torre e peão"; a página da Lucena fala em três colunas entre a torre e o rei atacante. É a mesma regra dita de três jeitos; escolher uma só na aula.
6. **Posição de Levenfish/Smyslov ("Kling e Horwitz")**: tentei montá-la pelo texto de Stripes (`3k4/8/4K3/4P3/8/8/5R2/4r3`), mas a tabela dá empate com os dois lados, e a fonte diz "brancas jogam e ganham". A reconstrução está errada (o diagrama é imagem): **não usar**.
7. **ChessBase**: a posição de Radjabov-Nakamura veio descrita pelo resumo automático (Re5, Ta7, a6 x Rg7, Tc6); com pretas a jogar a tabela dá empate, mas não vi o diagrama. A linha longa da posição didática não foi transcrita.
8. **Parser de diagramas**: na primeira passada os diagramas sem título saíram deslocados uma coluna; corrigido e conferido contra o texto (W4, W5, W8, W9). Os FEN desta lista são os corrigidos.
9. **Não achei** fonte aberta boa (fora da Wikipedia e da SML) que ensine a defesa frontal com posições; ChessMood não cobre lado curto, frontal nem Vancura. Não abri Chessable nem artigos do chess.com (o fórum aberto só aponta para o blog do Stripes).
10. A tabela respondeu sem 429; os 11 "erros 400" foram posições ilegais geradas pelo meu laço da zona de Romanovsky (rei branco em xeque com pretas a jogar), não falha de fonte.

---

# Defender torre e peão contra torre: estudos e prática do Lichess

Pesquisa de 2026-10-06. Frente: estudos públicos do Lichess e a seção de prática. Tudo abaixo foi aberto pelo PGN (`https://lichess.org/api/study/<id>.pgn`). Os resumos estão com minhas palavras. Todos os vereditos vêm de `tablebase.lichess.ovh` (consultados com contadores `0 1`).

Convenção das tabelas: "seguram" = lances de quem joga que mantêm o empate segundo a tabela; "ganham" = lances que mantêm a vitória.

---

## 1. Como cada estudo ensina

### 1.1 Prática do Lichess (`https://lichess.org/practice`, seção "Rook Endgames")

A seção tem quatro blocos, cada um com um estudo por trás:

| Bloco | Estudo | Autor na página |
|---|---|---|
| Basic Rook Endgames | `https://lichess.org/study/pqUSUw8Y` ("Lichess Practice: Basic Rook Endgames") | Lichess |
| Intermediate Rook Endings | `https://lichess.org/study/heQDnvq7` ("Lichess Practice: Intermediate Rook Endings") | Lichess (comentários assinados por Yeltcki) |
| Practical Rook Endings | `https://lichess.org/study/wS23j5Tm` ("Lichess Practice: Practical Rook Endings") | Lichess |
| 7th-Rank Rook Pawn | `https://lichess.org/study/MkDViieT` ("Lichess Practice: 7th-Rank Rook Pawn with a Passive Rook") | arex |

Ordem das ideias na prática: Lucena (ponte) → chegar à Lucena → **Philidor** → **evitar a Philidor** (lado forte) → ... e, no intermediário: **Vancura** → **Long Side Defense** → **Frontal Defense** → **quando a frontal não funciona** → **Back Rank Defense** → **quando a última fileira não funciona** → peão de torre (ganhar / segurar) → **Advanced Philidor** → guarda-chuva etc.

Ponto importante: no PGN exportado, a maioria dos capítulos de defesa vem **sem texto nem lances** (só a posição; o objetivo fica na interface de prática, jogando contra o computador). Têm comentário e linha: Vancura, Frontal Defense, Holding Against a Rook Pawn e Advanced Philidor. Os capítulos Philidor, Avoiding the Philidor, Long Side Defense, Back Rank Defense e "doesn't work" são só posição.

O que a prática ensina, capítulo a capítulo (os comentados):

- **Vancura**: torre do defensor ataca o peão a6 pelo lado (fileira 6), rei em g7. Ideia dita: dar xeques laterais para afastar o rei branco da ala da dama; quando o peão for a a7, torre para a6 (atrás/na coluna), caindo num empate conhecido. Avisa que xeques por trás (da 1ª fileira) não servem porque o rei branco se esconde em a7. Armadilha destacada: com o rei branco em d4, dar mais um xeque em f4 perde por Ke5 e depois Rg8+!, trocando para um final de peões ganho; a torre tem de voltar a f6.
- **Frontal Defense**: funciona melhor com o peão ainda antes da 5ª fileira. O rei preto está cortado a duas colunas, mas a torre na frente dá uma série de xeques e o rei branco não progride. Primeiro lance: torre para a frente do peão (b8) para impedir b5 imediato; depois xeques a8/b8/c8 conforme o rei sobe.
- **Holding Against a Rook Pawn** (rei branco preso em a8 na frente do peão a7): regra dada: o defensor segura se seu rei está a até 3 colunas do peão, porque chega a tempo em c7 quando a torre branca tenta ir para a coluna b. Torre preta espera na coluna b; quando a torre branca vai a h1 (para h8-b8), rei preto corre d7-c7; depois a torre preta sai da coluna b (não para a nem c).
- **Advanced Philidor** (torre preta na 5ª, não dá para chegar à 6ª): 1...Rg5 perderia para Kd6; a saída é a ideia de Philidor "por trás": torre desce na coluna f (f1/f2/f3), e depois de Kd6 o único lance é torre atrás do peão (Re2), que tira a força de Rh8+ seguido de e6+. A linha continua com o rei preto indo para o lado curto (f7/g6) e voltando.

### 1.2 "Rook Endings. The Philidor Position." — ProfAngel (`https://lichess.org/study/a1ss97T0`), 16 capítulos

Cinco capítulos teóricos e onze partidas-modelo. Comentários curtos (alguns assinados por Kyrylo27), muita variante.

1. Philidor pura: torre fica na 3ª fileira do defensor (6ª) até o peão chegar lá; aí vai para trás e dá xeques. Lance: 1...Rb6!, 2.e6 Rb1. Erro típico mostrado: 1...Rf1+ 2.Ke6.
2. "Segundo método" (brancas jogam e já ocuparam a 6ª com o rei): se a torre não consegue a 6ª fileira, ela vai para **trás do peão**: 1.Kf6 Re1! 2.Ke6 Kf8! (rei para o lado curto) 3.Ra8+ Kg7 4.Kd6 Kf7!. Mostra que 1...Rf1+ perde nessa posição (torre branca em a7 já tomou o lado longo).
3. Peão de cavalo: 1...Ra1! e depois 2.Rb6 Ra8 = (defesa passiva na última fileira). Erro: 1...Rg1? 2.Ra6 e ganha.
4. Peão de bispo/central na 5ª com rei em d8: 1...Ra1! 2.Ke6 Rd1! (atrás do peão) 3.Kd6 Kc8! ("indo para o lado curto"). Erro: 2...Re1+? 3.Kd6 ganha.
5. Peão de bispo na 6ª com rei no lado curto (h7): 1...Ra1! e xeques laterais (Ra7+, Ra8); com Kh6!/Kg6! quando a torre branca sai.
- Partidas-modelo relevantes: Rohde–D. Cramling, Innsbruck 1977 (lado forte ganha com 1.Ke6!, único); Alburt–Dlugy 1991 (empate teórico perdido por 1...Kg6?); Aronian–Carlsen 2006 (1...Ra7+? perde; 1...Kg6! empatava); I. Sokolov–Banikas 2010 (lado longo: "não tirar a torre da 8ª fileira nem da coluna a"; 11...Kg6!, e 11...Ra1? perde); Velicka–Polak 1995 (guarda-chuva); outras são finais com mais peões.

### 1.3 "Ending: Rook Philidor" — ehenkes (`https://lichess.org/study/imxK73yH`), 3 capítulos (títulos em alemão)

1. "Philidor Remis": torre para a 6ª (1...Rh6), espera; quando e6, torre desce (Rg1) e xeques por trás; as trocas de torres caem em rei e peão empatado (mostra o cuidado 8...Ke8 e não 8...Kd8??).
2. "Übung": mesma coisa com peão c; erro mostrado 1...Rb1+?? 2.Kc6 (obs.: a tabela diz que 1...Rb1+ ainda empata; ver divergências).
3. "Dem Philidor Remis vorbeugen" (prevenir a Philidor, visão do atacante): 1.Rf1 corta o rei preto e ganha.

### 1.4 "Rook Endgames: Lucena & Philidor" — Yuri61 (`https://lichess.org/study/dDyC6HS6`), 34 capítulos

(Há cópias idênticas de outros usuários na busca: MyronGains `z7j83SV6`, Triple_z73 `YuM529hY`; não abri as cópias.) Ordem: abrigo/Lucena (8 cap.) → **Philidor: as esperanças das brancas** (1...Rd1+?? deixa Kc6 e vira Lucena) → **Philidor: defesa correta** (1...Rg6; espera na 6ª; quando c6, 6...Rg1! e xeques; se o rei foge longe, a torre caça o peão) → Lucena com peão de torre → **"Black to draw" I–V** (lado curto/longo) → reis longe → **Frontal attack I.a–I.c** → exercício → posições soltas de peão a7.

"Black to draw" é a melhor sequência didática que achei para a aula 3:
- I: 1.Kf6 e o xeque lateral 1...Ra6+?? perde: 2.e6 (ameaça mate) Ra8 3.Rh7.
- II: 1...Rf1+ 2.Ke6 **Kf8!**; lema em maiúsculas no estudo: "king of short side, rook of long side". Depois 3.Rb8+ Kg7 4.Ke7 Rf7+ 5.Kd6 Ra7 e xeques laterais.
- III: truque das brancas: Rc8-c7 para tapar os xeques; trocar torres perde.
- IV: lema "wait on the 8th": 1...Ra8! controla a casa de promoção; depois 2.e6 Kf6. Último truque: não capturar em e7 (Rf2+ ganha a torre).
- Exercício/Solução: mesma posição com a torre branca em a7 (lado longo "encurtado"): com 1...Rf1+ as pretas perdem, porque a torre só tem a coluna b para os xeques.
- V: "segunda defesa de Philidor": se as brancas gastam um tempo para tomar a coluna a (3.Ra7), as pretas vão para trás do peão (3...Re1) e depois Kf7.

Frontal: três capítulos na mesma posição (peão c4, rei preto cortado em e6, torre em c8): I.a rei oferece troca (Ke7, Rd8) → final de peões empatado se o rei atacante está atrás do peão; I.b brancas progridem com Kb4 e xeques não bastam (o estudo dá vitória); I.c 1.Rd1 Rh8! 2.c5 Rh4! cortando o rei. Exercício: rei preto na mesma fileira do peão permite Rc5! e ganha.

### 1.5 "Rook Endgames You Must Know!" — NoseKnowsAll (`https://lichess.org/study/bnboDhFM`), 29 capítulos (o mais curtido da busca) e "Intermediate Endgames You Must Know!" — NoseKnowsAll (`https://lichess.org/study/UsqmCsgC`), 25 capítulos

Estilo: capítulo de explicação seguido de exercício interativo; texto farto, "PRO TIP" recorrente.
- **Philidor** (nos dois estudos, mesma posição): rei bloqueia, torre patrulha a 3ª fileira; "sentar e esperar"; quando e6, **Ra1!** ("assim que o peão chega à 3ª fileira, troque de tática": o rei perde o abrigo). Dica: xeques de longe; torre perto demais (Ra4) deixa o rei ganhar tempo atacando-a.
- **Exercício "Reaching the Philidor"**: 1...Ra6! (toma a fileira); erro 1...Rd2+?? 2.Ke6.
- **Carlsen perdendo a chance** (Aronian–Carlsen, no estudo intermediário): Philidor já não dá; ainda é empate se as pretas impedem a Lucena. 72...Ra8!, e depois 73...Ra7+?? perde; 73...Kg6! era o único.
- **Torre na frente do peão, peão em a7**: rei defensor só em g7/h7 (casas seguras); fora delas cai no espeto Rh8!/Rh7+. Torre atrás do peão; quando o rei branco chega a b6, xeques por trás e volta para a coluna a.
- **Falhando na Vancura** (peão a6): esperar com Kh7?? perde porque o rei branco se abriga em a7.
- **Vancura**: 6...Rf1+! 7.Ke4 Rf6! (ataque lateral ao peão; torre branca presa em a8). Se a7, Ra6. Quando o rei defende o peão (Kb5), xeques laterais Rf5+! etc. Dica: torre numa casa defendida pelo rei (f6) para o rei branco não ganhar tempo.
- **Truque na Vancura** (rei branco em f4): 11...Rc1! (rota c1-c6-f6); 11...Rf1+?? 12.Ke5! Rf6 13.Rg8+! ganha; 11...Rb1?? também perde (Rb7 com tempo). Depois 15.Rb6 Ra5!! cortando o rei.
- **Exercício 5 "o problema de decorar"**: 17...Ke7?? perde por a7! e Rh8 (espeto).
- Não cobre: última fileira passiva, lado curto/longo como tema próprio, frontal.

### 1.6 "Vancura" — Anki_Thief_of_Crowns (`https://lichess.org/study/AoQ0yjRG`), 56 capítulos

Li o capítulo 1 e os capítulos de "regras" (5, 8, 12); dos demais só os cabeçalhos. **Ressalva**: o texto fala em "Chapter 13" e "basic knowledge section" e tem formato de curso com regras numeradas; parece transcrição de um livro/curso comercial (não identifiquei qual). Usar só as ideias, não citar frases.
- Posição-base espelhada (peão h6, rei preto em a7): 1...Rc6! (único) ataca o peão de lado; 1...Rh3? (atrás) perde porque o rei branco se esconde em h7.
- Regra 1: Vancura só funciona contra peão de torre. Regra 2: a torre precisa de pelo menos 4 colunas de distância do peão para os xeques. Diretriz: a melhor tentativa do atacante é deixar o peão a 3 casas da promoção, torre na última fileira e rei a "salto de cavalo" da casa de promoção.
- Partidas usadas como exercício (só cabeçalhos vistos): Howell–Nakamura, Gibraltar 2015; Tari–Vidit, Porto Carras 2018; Vachier-Lagrave–Carlsen (rápida); Ju Wenjun–Goryachkina, Skolkovo 2019; Gelfand–Anand, desempate do Mundial; Radjabov–Nakamura, Shamkir 2014; Shankland–Predke, Berlim 2022; Dragun–Guo, Charlotte 2022.

### 1.7 "Vancura" — alexsamper (`https://lichess.org/study/kQKf89DD`), 19 capítulos

Quase sem texto; reaproveita capítulos de NoseKnowsAll (os assinados por ele). Útil pelos títulos, que dão a ordem: casa segura (g7/h7) → fora da casa segura (espeto) → lance-chave na 3ª fileira → "Shuffling" (peão a7: Kh7/Kg7 e Ra6) → falhar a Vancura → truque Rc1 → Rb1 é erro → peão g extra empata / peão f extra ganha. Li 3 capítulos; o resto só cabeçalho.

### 1.8 "ROOKS - LONG SIDE vs SHORT SIDE" — Vztrajnik (`https://lichess.org/study/hKfWSr7a`), 3 capítulos

Mínimo (texto em esloveno; aponta para um vídeo do GothamChess, que não abri). Uma posição com peão f: 3...Rg1+ 4.Kf6 Kg8 e a frase "rei para o lado curto, torre para o longo".

---

## 2. As cinco defesas: síntese do que os estudos dizem (com a tabela)

| Defesa | Funciona quando | Falha quando | Lance crítico | Erro típico |
|---|---|---|---|---|
| **Philidor (3ª fileira)** | Rei na casa de promoção; torre chega à 6ª antes do rei atacante | Rei atacante já está na 6ª; torre defensora não alcança a fileira (lado forte "evita a Philidor" com xeque/Kd6) | Peão avança para a 6ª → torre vai para a 1ª/2ª e dá xeques por trás | Xeque cedo (Rf1+/Rd1+) que deixa o rei entrar na 6ª; descer a torre antes do peão avançar; torre perto demais para os xeques |
| **Última fileira passiva** | Peão de cavalo (e de torre): a torre atacante não tem coluna para passar ao outro lado | Peão central ou de bispo: atacante passa a torre para o outro flanco e ameaça mate | Torre volta à 8ª antes que o atacante ganhe tempo (ProfAngel cap. 3: Ra1! e Ra8) | Tentar defesa ativa por trás (Rg1?) contra peão de cavalo; usar a passiva contra peão f/central |
| **Lado curto / lado longo** | Philidor não dá mais; rei vai para o lado curto, torre no lado longo com 3+ colunas de distância | Rei vai para o lado longo (Kd8); torre atacante já domina a coluna a ("lado longo encurtado"); troca de torres | 2...Kf8! (lado curto); "esperar na 8ª" (Ra8!); em Aronian–Carlsen, ...Kg6! | Xeque lateral antes da hora (Ra6+?? e6); Kd8; trocar torres; capturar e7 caindo em espeto; xeque Ra7+ na hora errada |
| **Frontal** | Peão ainda na 4ª (antes da 5ª); torre na 8ª na frente do peão; rei cortado por 1–2 colunas | Peão mais avançado; rei cortado longe demais; rei defensor na mesma fileira do peão (Rc5!) | Torre para a frente do peão e xeques frontais quando o rei sobe | Deixar o peão avançar com tempo; rei na fileira errada |
| **Vancura** | Peão de torre na 6ª, torre atacante na frente (a8); rei defensor em g7/h7; torre ataca o peão de lado com distância | Peão de outra coluna; rei atacante já perto (f4) sem a rota certa; torre atrás do peão (rei se abriga em a7) | Rf1+ e Rf6! (ou Rc1! quando Ke5 ameaça); se a7, Ra6 | Esperar com a torre atrás (Kh7??); xeque a mais (Rf4+? Ke5 e Rg8+); rei caminhando para o peão e levando espeto |

---

## 3. Posições com FEN

FEN como no cabeçalho do capítulo (salvo indicação). Tabela consultada em 2026-10-06.

### 3.1 Philidor

| # | FEN | Joga | Tabela | Linha do estudo | Origem |
|---|---|---|---|---|---|
| P1 | `4k3/R7/8/4PK2/8/8/8/1r6 b - - 0 1` | pretas | empate; seguram: Rb6, Rb2, Rb3, Rb4, Rc1, Re1, Rg1, Rh1, Kd8, Kf8 | 1...Rb6! 2.e6 Rb1 | a1ss97T0 cap. 1 |
| P2 | `4k3/R7/8/4PK2/8/8/8/1r6 w - - 0 1` | brancas | empate | 1.Kf6 Re1! 2.Ke6 Kf8! 3.Ra8+ Kg7 4.Kd6 Kf7! 5.Ra7+ Ke8 6.Ke6 Kf8! | a1ss97T0 cap. 2; dDyC6HS6 "Exercise/Solution" |
| P2a | `4k3/R7/5K2/4P3/8/8/8/1r6 b - - 0 1` (após 1.Kf6; FEN derivado) | pretas | empate; **só Re1** | — | derivado de P2 |
| P3 | `4k3/R7/4K3/4P3/8/8/8/4r3 b - - 0 1` (após 1...Re1 2.Ke6; derivado) | pretas | empate; seguram Kf8 e Kd8 | estudo marca Kf8! e Kd8?! | derivado de P2 |
| P4 | `4k3/1R6/r7/4PK2/8/8/8/8 b - - 0 1` | pretas | empate; seguram Rc6, Rh6, Ra1–Ra4, Kd8, Kf8 | 1...Rc6 2.Rb8+ Ke7 3.Rb7+ Ke8 4.Rh7 Ra6 5.Rh8+ Ke7 6.Rh7+ Ke8 7.e6 Ra1! 8.Kf6 Rf1+ | bnboDhFM cap. 3; UsqmCsgC cap. 14 |
| P5 | `4k3/7R/r3P3/5K2/8/8/8/8 b - - 0 1` (após 7.e6; derivado) | pretas | empate; **só Ra1, Ra2, Ra3, Ra4** | 7...Ra1! | derivado de P4 |
| P6 | `4k3/7R/8/3KP3/8/8/r7/8 b - - 0 1` | pretas | empate; 12 lances seguram (Ra6 entre eles) | 1...Ra6! 2.e6 Ra1! 3.Kd6 Rd1+ 4.Ke5 Re1+ 5.Kf6 Rf1+ | bnboDhFM cap. 4 |
| P7 | `3k4/7R/8/2PK4/8/8/8/6r1 b - - 0 1` | pretas | empate; **só Rg6 e Kc8** | 1...Rg6 2.Rh8+ Kc7 3.Rh7+ Kc8 4.Ke5 Rc6 5.Kd5 Rg6 6.c6 Rg1! 7.Kd4 Rd1+. Erro: 1...Rd1+?? 2.Kc6 | dDyC6HS6 cap. 9–10 |
| P8 | `6R1/4k2r/8/3KP3/8/8/8/8 b - - 0 1` | pretas | empate; seguram Rh1–Rh6, Rf7, Kd7, Kf7 | 1...Rh6 2.Rg7+ Kd8 3.Ra7 Rg6 4.e6 Rg1 5.Ra4 Rd1+ 6.Rd4 Rxd4+ 7.Kxd4 Ke7 8.Kd5 Ke8 | imxK73yH cap. 1 |
| P9 | `2k5/7R/8/1KP5/8/8/8/6r1 b - - 0 1` | pretas | empate; 11 lances seguram (inclui Rg6 e também Rb1+) | 1...Rg6 2.c6 Rg1 3.Kc5 Rc1+ 4.Kd5 Rd1+ | imxK73yH cap. 2 |
| P10 | `8/4r1k1/8/1K6/3P4/8/8/R7 w - - 0 1` | brancas | **brancas ganham**; ganham Rf1, Rg1+, Rh1, d5, Kc5, Kc6 | 1.Rf1 (corta o rei) | imxK73yH cap. 3 |
| P11 | `1r2k3/R7/8/4PK2/8/8/8/8 b - - 0 1` | pretas | empate; **só Rb6, Rb1, Rb2, Rb3, Rb4** | capítulo sem lances | pqUSUw8Y "Philidor Position" |
| P12 | `4k3/7R/8/3KP1r1/8/8/8/8 w - - 0 1` | brancas | **brancas ganham**; só Kd6 e Rh8+ | sem lances | pqUSUw8Y "Avoiding the Philidor" |
| P13 | `4k3/7R/8/3KPr2/8/8/8/8 b - - 0 1` | pretas | empate; **só Rf1, Rf2, Rf3, Rf4** | 1...Rf2 2.Kd6 Re2 3.Rh8+ Kf7 4.Rh7+ Kg6 5.Rh1 Kf7 6.Rf1+ Ke8 7.Ra1 Kf7 8.Ra7+ Ke8 9.Ke6 Kd8 10.Ra8+ Kc7 11.Ra5 Kd8 12.Kd6 Rd2+ 13.Ke6 Re2 | heQDnvq7 "Advanced Philidor" |
| P13a | `4k3/7R/3K4/4P3/8/8/5r2/8 b - - 0 1` (após 2.Kd6; derivado) | pretas | empate; **só Re2** | 2...Re2 | derivado de P13 |

### 3.2 Lado curto e lado longo

| # | FEN | Joga | Tabela | Linha do estudo | Origem |
|---|---|---|---|---|---|
| S1 | `4k3/1R6/8/4PK2/8/8/8/r7 w - - 0 1` | brancas | empate | 1.Kf6 Rf1+ 2.Ke6 Kf8! 3.Rb8+ Kg7 4.Ke7 Rf7+ 5.Kd6 Ra7 6.e6 Ra6+ 7.Kd7 Ra7+ 8.Kc6 Ra6+ 9.Rb6 Rxb6+ 10.Kxb6 Kf6 | dDyC6HS6 "Black to draw I, II, V" |
| S1a | `4k3/1R6/5K2/4P3/8/8/8/r7 b - - 0 1` (após 1.Kf6; derivado) | pretas | empate; **só Rf1+ e Re1** (Ra6+ perde) | erro 1...Ra6+?? 2.e6 Ra8 3.Rh7 | derivado de S1 |
| S1b | `4k3/1R6/4K3/4P3/8/8/8/5r2 b - - 0 1` (após 2.Ke6; derivado) | pretas | empate; **só Kf8** | 2...Kf8! | derivado de S1 |
| S2 | `1R6/r5k1/3K4/4P3/8/8/8/8 w - - 0 1` | brancas | empate | 1.Rc8 Ra6+ 2.Kd7 Ra7+ 3.Rc7 Rxc7+?? 4.Kxc7 Kf7 5.Kd7 (perde) | dDyC6HS6 "Black to draw III" |
| S3 | `8/r1RK2k1/8/4P3/8/8/8/8 b - - 0 1` | pretas | empate; seguram Ra8 e Ra1–Ra6 (trocar perde) | 1...Ra8! 2.e6 Kf6 3.e7 Kf7 4.Rb7 Re8 5.Kd6 Ra8 6.Rb2 Ra6+ 7.Kd7 Ra7+ 8.Kd8 Ra8+ (8...Rxe7?? 9.Rf2+) | dDyC6HS6 "Black to draw IV" |
| S3b | `8/2RK2k1/4P3/8/8/8/8/r7 b - - 0 1` (após 1...Ra1 2.e6; derivado) | pretas | empate; **só Ra8** | estudo: 2...Rd1+ 3.Ke8+ perde | derivado de S3 |
| S4 | `r7/3RK1k1/4P3/8/8/8/8/8 b - - 0 1` | pretas | empate; seguram Ra1–Ra5 e Kg6 | sem lances | heQDnvq7 "Long Side Defense" |
| S5 | `r7/4K1k1/3RP3/8/8/8/8/8 b - - 0 1` | pretas | empate; **só Kg6** | 1...Kg6! 2.Rd7 Kg7 3.Kd6+ Kf6 4.e7 Kf7 =; partida: 1...Ra7+? 2.Ke8 e abandonou | a1ss97T0 "Aronian – Carlsen, 2006"; UsqmCsgC cap. 19 (FEN de lá, dois lances antes: `3R4/4K1k1/4P3/r7/8/8/8/8 b - - 0 71`) |
| S6 | `3k4/8/6R1/3PK3/r7/8/8/8 b - - 0 1` | pretas | empate; 11 lances seguram (Ra1 entre eles) | 1...Ra1! 2.Ke6 Rd1! 3.Kd6 Kc8! 4.Rg8+ Kb7 5.Rd8 Rh1! 6.Re8 Rd1! 7.Re5 Kc8! | a1ss97T0 cap. 4 |
| S7 | `5R2/5K1k/5P2/8/8/8/8/5r2 b - - 0 1` | pretas | empate; **só Ra1 e Rb1** | 1...Ra1! 2.Re8 Ra7+ 3.Re7 Ra8! 4.Ke6+ Kg6 5.Rg7+ Kh6 6.Rg1 Ra6+! | a1ss97T0 cap. 5 |
| S8 | `5k2/R7/6K1/5P2/8/8/8/1r6 b - - 4 3` | pretas | empate; **só Rg1+ e Rf1** | 3...Rg1+ 4.Kf6 Kg8 | hKfWSr7a cap. 2 |
| S9 | `4k3/7R/8/4PK2/8/8/8/3r4 w - - 0 1` | brancas | **brancas ganham; só Ke6** | 1.Ke6! Kf8 2.Rf7+! Kg8 3.Rd7! (1.Kf6? Re1! empata) | a1ss97T0 "Rohde – D. Cramling, Innsbruck 1977" |
| S10 | `4R3/7k/8/4K3/4P3/5r2/8/8 b - - 0 1` | pretas | empate; 12 lances seguram | 1...Kg7 2.Ke6 Rf6+ 3.Ke7 Ra6 ... 11.e6 Kg6! (11...Ra1? 12.Ke8! ganha) | a1ss97T0 "I. Sokolov – Banikas, 2010" |

Complemento conferido por mim: com a torre branca em **a7** em vez de b7, depois de 1.Kf6 Rf1+ 2.Ke6 (`4k3/R7/4K3/4P3/8/8/8/5r2 b`) as pretas **perdem**; por isso em P2a só 1...Re1 segura. É a diferença entre os capítulos "Black to draw II" e "Solution" do Yuri61.

### 3.3 Última fileira (defesa passiva)

| # | FEN | Joga | Tabela | Linha do estudo | Origem |
|---|---|---|---|---|---|
| B1 | `6k1/8/5RK1/6P1/8/8/8/7r b - - 0 1` | pretas | empate; seguram Ra1, Rb1, Rc1, Rd1, Re1 (Rg1 perde: brancas ganham com Ra6–Re6) | 1...Ra1! 2.Rb6 Ra8 = ; 1...Rg1? 2.Ra6 Kf8 3.Ra8+ Ke7 4.Rg8! | a1ss97T0 cap. 3 |
| B1a | `r5k1/8/1R4K1/6P1/8/8/8/8 w - - 0 1` (após 2.Rb6 Ra8; derivado) | brancas | empate | — | derivado |
| B1b | `r5k1/1R6/6K1/6P1/8/8/8/8 b - - 0 1` (se 3.Rb7; derivado, conferência minha) | pretas | empate; seguram Rc8, Rd8, Re8, Rf8, Kh8, Ra6+ | — | conferência própria |
| B2 | `R7/8/8/6p1/8/7k/1r6/6K1 w - - 0 1` | brancas (defendem) | empate; seguram Ra1, Ra3+, Ra5, Ra6, Ra7, Rc8, Rd8, Re8, Rf8 | sem lances | heQDnvq7 "Back Rank Defense" |
| B2a | `8/8/8/8/8/6pk/1r6/R5K1 b - - 0 1` (peão em g3, torre passiva em a1; derivado, conferência minha) | pretas | empate | — | conferência própria |
| B3 | `8/8/8/8/8/5pk1/1r6/2R3K1 b - - 0 1` (cabeçalho traz `b Q`, direito de roque inválido; consultei com `-`) | pretas (atacam) | **pretas ganham**; p.ex. Rg2+, Ra2, Rh2 | sem lances | heQDnvq7 "When the Back Rank Defense doesn't work" |
| B3a | `8/8/8/8/8/5pk1/6r1/2R2K2 b - - 0 1` (após 1...Rg2+ 2.Kf1; derivado) | pretas | ganham; Rh2 (ameaça Rh1+), Ra2, Rb2, Rd2 | — | conferência própria |

### 3.4 Defesa frontal

| # | FEN | Joga | Tabela | Linha do estudo | Origem |
|---|---|---|---|---|---|
| F1 | `2r5/8/4k3/8/1P6/1K1R4/8/8 b - - 0 1` | pretas | empate; **só Rb8** | 1...Rb8 2.Ka4 Ra8+ 3.Kb5 Rb8+ 4.Kc5 Rc8+ 5.Kb6 Rb8+ 6.Ka5 Ra8+ 7.Kb5 Rb8+ | heQDnvq7 "Frontal Defense" |
| F1a | `1r6/8/4k3/8/KP6/3R4/8/8 b - - 0 1` (após 2.Ka4; derivado) | pretas | empate; **só Ra8+** | 2...Ra8+ | derivado |
| F2 | `2r5/8/5k2/8/2P5/2K5/8/4R3 w - - 0 1` | brancas | **brancas ganham** (Kb4, Kb3, Kd4, Kd3, Re2–Re4): rei preto cortado a duas colunas | sem lances | heQDnvq7 "When the Frontal Defense doesn't work" |
| F3 | `2r5/8/4k3/8/2P5/2K5/3R4/8 w - - 0 1` | brancas | **empate** | 1.Rd1 Rh8! 2.c5 Rh4! 3.c6 Ke7! 4.c7 Rh8 (I.c); 1.Rd1 Ke7 2.Kb4 Rb8+ 3.Kc5 Rc8+ 4.Kb5 Rb8+ 5.Ka6 Rc8 6.Rd4 Ke6 7.Kb7 Rc5 8.Kb6 Rc8 9.c5 (I.b, estudo dá vitória) | dDyC6HS6 "Frontal attack I.a–I.c" |
| F3a | `2r5/8/4k3/8/2P5/2K5/8/3R4 b - - 0 1` (após 1.Rd1; derivado) | pretas | empate; seguram Rh8, Rg8, Rf8, Ra8, Rb8, Ke5; **Ke7 não está na lista (perde)** | — | derivado |
| F4 | `1r6/8/8/8/1P1k4/1K6/8/2R5 w - - 0 1` | brancas | **brancas ganham**; Rc5, Rc6, Ka4, Ra1 | 1.Rc5! Ra8 2.Rg5 Rb8 3.b5 | dDyC6HS6 "Exercise/Solution" (o capítulo-exercício vem com pretas a jogar; a solução, com brancas) |

### 3.5 Vancura e peão de torre

| # | FEN | Joga | Tabela | Linha do estudo | Origem |
|---|---|---|---|---|---|
| V1 | `R7/6k1/P4r2/3K4/8/8/8/8 b - - 0 1` | pretas | empate; seguram Rf5+, Rb6, Rg6, Rh6, Kh7 | 1...Rf5+ 2.Kc6 Rf6+ 3.Kb7 Rf7+ 4.Kb6 Rf6+ 5.Kc5 Rf5+ 6.Kd4 Rf6 7.a7 Ra6 | heQDnvq7 "Vancura Position" |
| V1a | `R7/6k1/P7/5r2/3K4/8/8/8 b - - 0 1` (após 6.Kd4; derivado) | pretas | empate; **só Rf6** | 6...Rf6 (6...Rf4+? 7.Ke5 Rf6 8.Rg8+!) | derivado |
| V2 | `R7/6k1/P7/8/8/5K2/8/r7 b - - 11 6` | pretas | empate; seguram Rf1+, Rb1, Rc1, Rd1, Re1, Rg1, Ra4, Ra5 (Kh7 perde) | 6...Rf1+! 7.Ke4 Rf6! 8.Kd5 Rb6 9.Kc5 Rf6 10.Kb5 Rf5+! 11.Kb6 Rf6+ 12.Ka7 Rf7+ 13.Kb8 Rf8+ 14.Kb7 Rf7+ ... 18.Kd5 Rb6. Erro: 6...Kh7?? 7.Ke4 ... 10.Kb7 Rb1+ 11.Ka7! | bnboDhFM cap. 14–15 |
| V2a | `R7/6k1/P7/8/4K3/8/8/5r2 b - - 0 1` (após 7.Ke4; derivado) | pretas | empate; **só Rf6** | 7...Rf6! | derivado |
| V3 | `R7/6k1/P7/8/5K2/8/8/r7 b - - 20 11` | pretas | empate; **só Rc1 e Ra5** | 11...Rc1! 12.Rb8 Ra1! 13.Ra8 Rc1! 14.Rb8 Ra1! 15.Rb6 Ra5!! 16.Ke4 Kf7. Erro: 11...Rf1+?? 12.Ke5! Rf6 13.Rg8+! (tabela confirma: após 12.Ke5 as pretas perdem) | bnboDhFM cap. 16 |
| V4 | `7R/k7/7P/8/4K3/2r5/8/8 b - - 0 1` | pretas | empate; **só Rc6** | 1...Rc6 2.Kf5 Rb6; erro 1...Rh3? 2.Kf5 Rh1 3.Kg6 Rg1+ 4.Kh7 | AoQ0yjRG cap. 1 |
| V5 | `R7/P4k2/8/8/8/8/5K2/r7 b - - 11 6` | pretas | empate; **só Kg7 e Ra2+** | 6...Kg7! 7.Ke3 Kh7 8.Kd4 Kg7 9.Kc5 Kh7 10.Kb6 Rb1+! 11.Ka6 Ra1+ 12.Kb7 Rb1+ 13.Kc6 Ra1!. Erros: 6...Ra3?? 7.Rh8!; 6...Ke6?? 7.Re8+; 6...Ke7?? 7.Rh8! | bnboDhFM cap. 8 |
| V6 | `8/5k2/P6R/r7/4K3/8/8/8 b - - 31 17` | pretas | empate; seguram Kg7, Kf8, Kg8 (Ke7 perde) | 17...Ke7?? 18.a7! Kd7 19.Rh8! Rxa7 20.Rh7+ | bnboDhFM cap. 17 |
| R1 | `K7/P3k3/8/8/8/8/3R4/1r6 b - - 0 1` | pretas | empate; seguram Rb3, Rb4, Rb5, Rb6, Ke8 | 1...Rb3 2.Rd1 Rb2 3.Rh1 Kd7 4.Rh8 Kc7 5.Rb8 Rh2 6.Rb7+ (a linha para aqui; o comentário pede um lance de rei que mantenha o rei branco preso na frente do peão e cita c6 e d6; não conferi esse último lance na tabela) | heQDnvq7 "Holding Against a Rook Pawn" |
| R2 | `K7/P4k2/8/8/8/8/4R3/1r6 w - - 0 1` | brancas | **brancas ganham** (rei preto cortado a 4 colunas) | sem lances | heQDnvq7 "Rook and Rook Pawn versus Rook" |

Total: 51 posições com veredito da tabela (36 de cabeçalho de capítulo, 15 derivadas das linhas ou de conferência própria).

---

## 4. Divergências entre estudos e tabela

1. **Yuri61, "Exercise/Solution"** (P2, torre branca em a7): o texto conclui que as brancas ganham. A tabela dá **empate**: depois de 1.Kf6 só 1...Re1! segura (como ensina ProfAngel, cap. 2). O que perde é 1...Rf1+. Ensinar: "se a torre atacante já tomou o lado longo, vá para trás do peão".
2. **Yuri61, "Frontal attack I.b"**: a linha 1.Rd1 Ke7 2.Kb4 é dada como ganha, e a tabela confirma que 1...Ke7 perde (não está entre os lances que seguram em F3a); o capítulo I.a, que trata Ke7 como defesa aceitável até a troca, é enganoso. Seguram 1...Rh8 (o lance do estudo), Rg8, Rf8, Ra8, Rb8 e Ke5.
3. **Yuri61, "Black to draw IV"**: 1...Ra1 é apresentado como perdedor; pela tabela 1...Ra1 ainda empata (o erro é 2...Rd1+; depois de 2.e6 só 2...Ra8 segura). "Esperar na 8ª" continua sendo a regra mais simples.
4. **ehenkes, "Übung"** (P9): 1...Rb1+ recebe "??", mas a tabela diz que ainda empata; a derrota vem depois na linha dada. Rg6 é o lance limpo.
5. **ProfAngel cap. 2** (P3): 2...Kd8 recebe "?!" e a tabela confirma que também empata, só que é muito mais difícil; Kf8 é o lance a ensinar.
6. **Prática, "When the Back Rank Defense doesn't work"**: o FEN do cabeçalho tem direito de roque `Q` impossível (a torre está em c1). Não muda nada, mas não dá para colar o FEN cru num validador estrito.
7. **Prática, "Advanced Philidor"**: a linha confere com a tabela nos pontos que testei (1...Rf1–f4; 2...Re2 único). Não conferi lance a lance o resto da linha.

---

## 5. Referências

| Estudo | Autor (como aparece) | URL | Como consultei |
|---|---|---|---|
| Lichess Practice: Basic Rook Endgames | Lichess | https://lichess.org/study/pqUSUw8Y | PGN; cabeçalhos de todos os capítulos; capítulos "Philidor Position" e "Avoiding the Philidor" (sem texto) |
| Lichess Practice: Intermediate Rook Endings | Lichess (comentários de Yeltcki) | https://lichess.org/study/heQDnvq7 | PGN; capítulos 1–9 inteiros; demais só cabeçalho |
| Lichess Practice: 7th-Rank Rook Pawn with a Passive Rook | arex | https://lichess.org/study/MkDViieT | PGN; só os cabeçalhos (lista de capítulos e FENs) |
| Lichess Practice: Practical Rook Endings | Lichess | https://lichess.org/study/wS23j5Tm | PGN; só cabeçalhos (nada de torre+peão contra torre) |
| Rook Endings. The Philidor Position. | ProfAngel | https://lichess.org/study/a1ss97T0 | PGN; capítulos 1–5, 10, 12, 13, 14 inteiros; demais só cabeçalho |
| Ending: Rook Philidor | ehenkes | https://lichess.org/study/imxK73yH | PGN; inteiro (3 capítulos) |
| Rook Endgames: Lucena & Philidor | Yuri61 | https://lichess.org/study/dDyC6HS6 | PGN; capítulos 9, 10, 17–23, 25–29 (alguns truncados no fim); demais só cabeçalho |
| Rook Endgames You Must Know! | NoseKnowsAll | https://lichess.org/study/bnboDhFM | PGN; capítulos 3, 4, 8, 9, 14, 15, 16, 17 (3, 8 e 16 truncados no fim); demais só cabeçalho |
| Intermediate Endgames You Must Know! | NoseKnowsAll | https://lichess.org/study/UsqmCsgC | PGN; capítulo 19 (Aronian–Carlsen) inteiro; cabeçalhos |
| Vancura | Anki_Thief_of_Crowns | https://lichess.org/study/AoQ0yjRG | PGN; capítulos 1, 5, 8, 12 (1 truncado); cabeçalhos dos 56. Texto parece vir de curso/livro comercial |
| Vancura | alexsamper | https://lichess.org/study/kQKf89DD | PGN; capítulos 1, 2, 7; cabeçalhos |
| ROOKS - LONG SIDE vs SHORT SIDE | Vztrajnik | https://lichess.org/study/hKfWSr7a | PGN; inteiro (3 capítulos, quase vazio) |
| Página da prática | Lichess | https://lichess.org/practice | HTML; lista dos blocos de finais de torre e ids dos estudos |
| Tabela de finais | Lichess | https://tablebase.lichess.ovh | 57 consultas válidas (as 51 posições deste relatório e 6 de apoio, citadas no texto) |

Não entram (não consegui abrir): `ovQHOZJ1` ("Rook Endgames: Philidor", GARRY_2611; tinha capítulo "Last rank defense" na busca) e `I9UN7hbo` ("Karstedt manevrası", chesstime_6): a exportação do PGN devolveu **403** nos dois. Vistos só no resultado da busca e não abertos: `z7j83SV6`, `YuM529hY` (cópias do estudo do Yuri61), `m3gbjeta` ("Short side defense - rook endgame", bar11319), `sBU8G96Q` e `YEQlZ9aE` (Audax6, "E-35/E-34 Rook Endings", com cara de transcrição de livro), `odsXPxS7`, `RYx4To2Z`, `TUWiXIWP`, `jzBHBl2G`, `ZEGzWNJg`, `HXjbW7X5`.

---

## 6. O que não achei

- **Posição de Karstedt**: nenhum estudo público aberto a trata pelo nome. A busca "Karstedt" devolve estudos de um usuário chamado karstedt (não relacionados) e um estudo turco cuja exportação é bloqueada (403). O conteúdo equivalente (rei no lado curto, torre no lado longo, peão na 6ª/7ª) aparece sem o nome em ProfAngel cap. 5 (S7), no "Long Side Defense" da prática (S4) e em Aronian–Carlsen (S5).
- **Defesa passiva na última fileira explicada em texto**: não achei estudo que explique por que funciona contra peão de cavalo/torre e falha contra central/bispo. A prática tem as duas posições (B2, B3) sem comentário; ProfAngel tem uma (B1) só com lances. Nenhum estudo aberto mostra a versão com **peão de torre**. O único estudo com capítulo de título "Last rank defense" não abriu (403).
- **Lado curto/lado longo como aula dedicada e bem comentada**: só o trecho "Black to draw I–V" do Yuri61 (bom, mas com dois erros de avaliação) e o estudo mínimo do Vztrajnik.
- **Defesa frontal**: só a prática (um capítulo comentado, um sem texto) e o Yuri61. A busca "frontal defence rook" não devolveu nada. Nenhum estudo aberto enuncia a "regra do cinco/seis" ou a contagem de colunas de corte.
- **Vancura**: bem coberta (prática, NoseKnowsAll, alexsamper, Anki_Thief_of_Crowns), mas o estudo mais extenso parece transcrição de material comercial.
- Capítulos da prática sem linha no PGN: as linhas principais de P11, P12, S4, B2, B3, F2 e R2 não existem na fonte; só o veredito e os lances da tabela acima.

# Bispo e cavalo I: do canto errado ao canto certo, a manobra em W (`mates.bishopKnight.w`)

Pesquisa de 2026-10-05.

Recorte desta aula: o rei preto já está na borda, no canto errado (o canto da cor que o bispo não controla). O aluno, de brancas, leva o rei ao canto certo com a manobra em W do cavalo, sem deixar o rei escapar e sem afogar, e dá o mate. Levar o rei do centro até a borda fica para a aula II; o mate inteiro, com os triângulos de Delétang, para a aula III.

## O que o aluno precisa sair sabendo

1. O mate de bispo e cavalo só é forçado no canto da cor do bispo. Bispo das casas claras: a8 ou h1. O rei preto corre para o outro canto, e o trabalho é tirá-lo de lá.
2. O cavalo é quem toma do rei as casas da cor que o bispo não alcança. Na borda, ele desenha um W: f7, e5, d7, c5, b7 (bispo claro, rei vindo de h8 para a8). Cada ponta do W tira uma casa escura da oitava fileira.
3. O bispo faz o resto: fecha a diagonal de fuga (h7 cobre g8; d3 cobre b5 e c4, depois a diagonal a2–g8) e dá o xeque final no canto.
4. O rei preto tenta duas coisas: voltar para o canto errado (castigo: o cavalo dá xeque, e o mate vem mais rápido) e escapar pela sétima fileira (c7, b7, c6). A rede fecha com o rei branco na sexta e o bispo na diagonal certa.
5. Perto do canto certo, afogamento é o perigo: um lance de cavalo que tira a última casa do rei sem dar xeque empata, e um xeque de cavalo com o bispo solto também (armadilha de Rhine).

## Como cada fonte ensina

### Wikipedia, "Bishop and knight checkmate" (aberta pelo texto-fonte do artigo)

Divide o mate em três fases (empurrar o rei para a borda, levá-lo do canto errado ao certo, dar mate) e mostra, com crédito a Müller e Lamprecht, a manobra em W a partir de rei preto em h8, rei branco em f6, cavalo em e5 e bispo em d3: 1.Cf7+ Rg8 2.Bf5 Rf8 3.Bh7 Re8 4.Ce5 Rd8 5.Re6 Rc7 6.Cd7 Rb7 7.Bd3 Rc6 8.Be2 Rc7 9.Bf3 Rd8 10.Rd6 Re8 11.Bh5+ Rd8 12.Bf7 Rc8 13.Cc5 Rd8 14.Cb7+ Rc8 15.Rc6 Rb8 16.Rb6 Rc8 17.Be6+ Rb8 18.Cc5 Ra8 19.Bd7 Rb8 20.Ca6+ Ra8 21.Bc6#. Chama as cinco casas do cavalo de W e observa que 4...Rf8, a volta ao canto errado, perde mais depressa depois de 5.Cd7+. Mostra dois padrões de mate (rei em a8, cavalo a6, rei b6, bispo c6; e rei a7, bispo b7, rei c7, cavalo c6) e a armadilha de empate de Frederick Rhine (2000): rei c8, bispo e8, rei d6, cavalo c4, e 1.Cb6+?? Rd8! deixa o bispo preso: todo lance de bispo afoga e qualquer outro perde o bispo. Dá também a história (Philidor, Delétang, Telesin) e exemplos de partidas (Karttunen–Rasik, Ljubojević–Polgár, Kempinski–Epishin, Ushenina–Girya).

A linha inteira foi conferida lance a lance na tabela de finais: todo lance branco está entre os mais curtos (folga de um lance), e 4...Rf8 de fato encurta o mate (distância 25 em vez de 31 meios-lances).

### Lichess Practice, "Checkmating with a Knight and Bishop" (estudo público de arex, lido pela API)

Ensina pelo método dos triângulos de Delétang, não pelo W: três triângulos cada vez menores, o bispo na hipotenusa, rei e cavalo nas casas escuras. Os capítulos "Delivering Mate" e "Exercise: Delivering Mate" mostram o mate no canto certo (rei a8/a7, rei branco c7, bispo c8, cavalo d5–b4–c6) e avisam do afogamento ("Avoid the stalemate!") ao levar o bispo para a6 e c8. O capítulo "Epic Failure" traz a partida Ushenina–Girya (Genebra 2013), em que a campeã mundial não conseguiu dar o mate. Útil aqui como contraponto (o método da aula III) e pela ênfase no afogamento.

### Gambit Publications, página de *Fundamental Chess Endings* (Müller e Lamprecht)

A página da editora confirma título, autores, ISBN (978-1-901983-53-1) e 416 páginas; o livro foi BCF Book of the Year 2002. A editora não mostra o capítulo do mate; a linha do W atribuída ao livro foi vista no artigo da Wikipedia, não no livro. Por isso a referência do W é o artigo, e o livro entra como obra citada por ele.

### Forward Chess e New in Chess, *100 Endgames You Must Know* (Jesús de la Villa)

A página da New in Chess abriu (título e autor; o texto do produto não mostra ano nem edição). A página da Forward Chess da 6ª edição informa New in Chess, 254 páginas, lançamento em 2023. O artigo da Wikipedia cita de la Villa (edição de 2008, p. 204–209) para o método de Delétang e para a frase sobre mestres que voltaram para casa envergonhados por não dar este mate. Não vi o capítulo; só a citação.

### Estudos da comunidade do Lichess

A busca por "knight bishop checkmate" trouxe estudos pequenos de alunos e clubes (um a vinte e um capítulos, a maioria com um). Nenhum deles ensina o W com explicação; o de ganesh12345678 ("Bishop & Knight Mate", dez capítulos) é só uma lista de posições para treinar. Não há estudo público bom sobre o W além do da seção Practice, que ensina os triângulos.

## Posições-base

| id | FEN | Quem joga | Tabela | Crédito |
|---|---|---|---|---|
| wStart | `7k/8/5K2/4N3/8/3B4/8/8 w - - 0 1` | brancas | ganha, mate em 39 meios-lances | Müller e Lamprecht, via Wikipedia |
| mateCorner | `k7/8/NKB5/8/8/8/8/8 b - - 0 1` | pretas (mate) | xeque-mate | padrão clássico (Müller e Lamprecht, via Wikipedia) |
| rhineTrap | `2k1B3/8/3K4/8/2N5/8/8/8 w - - 0 1` | brancas | ganha (17); 1.Cb6+?? Rd8! empata | Frederick Rhine, 2000, via Wikipedia |
| escapeBack | `5k2/7B/5K2/4N3/8/8/8/8 w - - 0 1` | brancas | ganha (25); só 5.Cd7+ mantém o ritmo | própria (a volta ao canto errado da linha do W) |
| stalemateAlert | `k7/8/1K6/2N5/8/8/8/3B4 w - - 0 1` | brancas | ganha (5); 1.Ca6?? afoga | própria |

## História

- Philidor chamou a atenção para a rota do cavalo (o W) na edição de 1777 do *L'Analyse des Échecs* (Wikipedia).
- Daniel Delétang publicou em 1923, na revista *La Stratégie*, o método dos triângulos, que vale quando o rei preto não alcança a diagonal grande da cor oposta à do bispo (Wikipedia).
- O mate é raro: aparece cerca de uma vez a cada seis mil partidas, segundo Müller e Lamprecht (via Wikipedia). Silman deixou o mate de fora do seu curso de finais por isso; Soltis defende que aprendê-lo ensina técnica que serve em outros finais (ambos via Wikipedia).
- Tal Shaked venceu Alexander Morozevich com este mate na penúltima rodada do Mundial Juvenil de 1997 (Zagan, Polônia; chessgames.com confirma evento, local, data 26/07/1997 e resultado 1–0). A vitória lhe deu o título.
- Mika Karttunen venceu Vitezslav Rasik na European Club Cup de 2003 (Rethymnon, 01/10/2003, 1–0, chessgames.com) com o W do cavalo (Wikipedia, citando Müller e Pajeken).
- Grandes mestres já falharam: Kempinski–Epishin (Bundesliga 2001) acabou em afogamento, e Anna Ushenina, campeã mundial, não conseguiu dar o mate contra Olga Girya em Genebra 2013 (Wikipedia; o estudo da seção Practice do Lichess tem a partida inteira).

## Plano da aula

Lição (aluno de brancas, bispo das casas claras, rei preto em h8):

1. `corner` (talk): a posição-chave pronta. h8 é escuro, o bispo é claro: canto errado. O destino é a8.
2. `whyWrong` (talk): o padrão de mate no canto certo (Ra8, Ca6, Rb6, Bc6). O bispo dá o xeque final; no canto escuro ele não chega.
3. `wShape` (talk): o W desenhado: f7, e5, d7, c5, b7. Cada ponta tira uma casa escura da oitava.
4. `w1` (move): 1.Cf7+, primeira ponta: tira h8.
5. `w2` (move): 2.Bf5 Rf8 3.Bh7 Re8 4.Ce5: o bispo prepara e toma g8; o cavalo volta ao centro e tira d7.
6. `w3` (move): 5.Re6 Rc7 6.Cd7: o rei preto escapa pela sétima; o rei branco segue, e o cavalo tira b6 e c5.
7. `w4` (move): 7.Bd3: o bispo fecha b5 e c4; o rei preto está cercado em c6.
8. `w5` (move): 8.Be2 Rc7 9.Bf3: o bispo ganha tempo e assume a diagonal grande.
9. `w6` (move): 10.Rd6 Re8 11.Bh5+ Rd8 12.Bf7 Rc8 13.Cc5 Rd8 14.Cb7+: o rei branco toma d6, o bispo expulsa o rei de e8 e toma g8/e8, o cavalo faz as duas últimas pontas.
10. `escape` (move): a tentativa de voltar: 4...Rf8 5.Cd7+ Re8 6.Re6 e o mate vem mais rápido.
11. `trap` (talk): a armadilha de Rhine e o afogamento perto do canto.
12. `finish` (move): 15.Rc6 Rb8 16.Rb6 Rc8 17.Be6+ Rb8 18.Cc5 Ra8 19.Bd7 Rb8 20.Ca6+ Ra8 21.Bc6#.
13. `rules` (talk): as três regras.
14. `playW` (play): a posição do W inteira contra a máquina.
15. `playFar` (play): um pouco mais longe, com o cavalo ainda em d3 e o rei preto em g8.

Exercícios (12, 23 estrelas, mínimo 14):

| id | ★ | Posição | O que pede |
|---|---|---|---|
| e01 | 1 | `k7/8/NK6/8/8/8/8/5B2 w` | o mate com o bispo entrando na diagonal grande (Bg2#; qualquer outro lance de bispo afoga) |
| e02 | 1 | `1k6/3B4/1K6/2N5/8/8/8/8 w` | Ca6+ e Bc6# |
| e03 | 1 | `6k1/5N2/5K2/8/8/3B4/8/8 w` | o bispo prepara h7 (qualquer casa da diagonal b1–h7) |
| e04 | 1 | `7k/8/5K2/4N3/8/3B4/8/8 w` | a primeira ponta do W, Cf7+ (a tabela aceita também os lances de espera do bispo) |
| e05 | 2 | `4k3/5N1B/5K2/8/8/8/8/8 w` | Ce5, o único que tira d7 sem perder tempo |
| e06 | 2 | `k7/8/1K6/2N5/8/8/8/3B4 w` | alerta de afogamento: Bg4 (ou Be2), Rb8, Ca6+, Ra8, Bf3# |
| e07 | 2 | `2k1B3/8/3K4/8/2N5/8/8/8 w` | a armadilha de Rhine: qualquer lance que não seja Cb6+?? (Bb5, Ba4, Bc6, Ca5, Re7…) |
| e08 | 2 | `8/1k1N3B/4K3/8/8/8/8/8 w` | fechar a rede: Bd3 (ou Rd5, Rd6) |
| e09 | 2 | `8/8/3B4/8/4N3/5K2/8/7k w` | o W de baixo, com bispo escuro: Cf2+ |
| e10 | 3 | `4k3/3N3B/5K2/8/8/8/8/8 w` | castigar a volta: Re6 Rd8, Rd6 Re8, Bg6+ (ou Bg8) |
| e11 | 3 | `7k/8/5K2/8/4B3/3N4/8/8 w` | montar o W de mais longe: Ce5 Rg8, Cf7 Rf8, Bh7 |
| e12 | 3 | `1k6/2N5/2K5/8/8/4B3/8/8 w` | o W espelhado em a8 com bispo escuro: Bc5 Rc8, Ba7 Rd8, Cd5 |

Todas as posições são próprias (variações das posições da linha do W), exceto e04 (a posição-chave) e e07 (a armadilha de Rhine), com origem na Wikipedia.

## Treino final

`8/8/3N4/3B4/4K3/7k/8/8 w - - 0 1`, id `knightBishop.knightBishopVsKing.0001` do catálogo (tabela: ganha, mate em 19 meios-lances). É a posição que liga a aula ao speedrun do final. Observação: nela o rei preto já está perto de h1, que é o canto certo para o bispo claro; o aluno treina o fecho e o mate, não o W inteiro. A outra posição do catálogo (`…0002`, mate em 28 lances) é o mate completo e serve para as aulas II e III.

## Referências

- `wikipedia` (web): "Bishop and knight checkmate", Wikipedia em inglês, texto-fonte do artigo aberto em 2026-10-05 (`https://en.wikipedia.org/wiki/Bishop_and_knight_checkmate`). Fonte da linha do W, dos padrões de mate, da armadilha de Rhine e da história.
- `lichessPractice` (study): "(BETA) Lichess Practice: Checkmating with a Knight and Bishop", de arex, lido pela API (`https://lichess.org/study/ByhlXnmM`). Método dos triângulos, aviso de afogamento, partida Ushenina–Girya.
- `muller` (book): Karsten Müller e Frank Lamprecht, *Fundamental Chess Endings*, Gambit Publications, 2001. Página da editora aberta (título, autores, ISBN, 416 páginas); o ano vem da bibliografia da Wikipedia. O conteúdo do W foi visto pela Wikipedia, não no livro.
- `delaVilla` (book): Jesús de la Villa, *100 Endgames You Must Know*, New in Chess, 6ª edição, 2023. Página da New in Chess e página da Forward Chess abertas (título, autor, editora, páginas, ano). O capítulo do mate foi visto só pela citação da Wikipedia.
- `shaked` (game): Tal Shaked × Alexander Morozevich, World Junior Championship, Zagan 1997, 1–0. Página do chessgames.com aberta.
- `karttunen` (game): Mika Karttunen × Vitezslav Rasik, European Club Cup, Rethymnon 2003, 1–0. Página do chessgames.com aberta.
- `tablebase` (tablebase): Lichess tablebase (Syzygy), `https://tablebase.lichess.ovh`. Toda posição e todo lance da aula passaram por ela.

## Dúvidas e divergências

- A linha do W atribuída a Müller e Lamprecht não é a mais curta em todo lance: 12.Bf7 está um lance atrás de 12.Cc5 (18 contra 16 meios-lances), dentro da folga que a aula aceita. A aula ensina Bf7 porque a ideia (o bispo toma e8 e g8 antes de o cavalo fazer as duas últimas pontas) é mais clara.
- Nas respostas das pretas, a tabela às vezes prefere outra casa de mesma distância (9...Rc8 em vez de 9...Rd8; 16...Ra8 em vez de 16...Rc8). A aula fixa a resposta da linha didática onde isso muda o roteiro; nos exercícios a resposta é a da tabela.
- O lance de mate vem sem distância na resposta da tabela (`dtm: null`), então a regra `best` não serve na última jogada: os mates finais usam `only`.
- As páginas das editoras New in Chess e Russell Enterprises não abriram pelo WebFetch (403/404); a New in Chess abriu por curl, mas o texto não traz ano nem edição. Dvoretsky (*Endgame Manual*) não entrou nas referências porque não abri nada da editora nem do livro.
- O treino final do catálogo não parte do canto errado (ver "Treino final"). Não mexi no catálogo; fica a sugestão de uma posição própria do W para o speedrun, se o Gabriel quiser.
- No formato atual das aulas, quando o aluno joga um lance aceito que não é o ensinado num passo de vários lances, o tabuleiro sai da linha prevista. Os passos e exercícios desta aula foram montados para que toda alternativa aceita mantenha legais a resposta fixa e os lances seguintes (conferido por simulação à parte), mas o motor das aulas ainda vai precisar tratar isso.

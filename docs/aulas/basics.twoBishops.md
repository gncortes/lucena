# Dois bispos: a parede e o canto (`basics.twoBishops`)

Pesquisa de 2026-10-07.

Recorte desta aula: rei e dois bispos (de cores opostas) contra rei. A formatura da escola (`graduation.twoBishops`) já mostrou a parede, o canto e um mate; aqui o aluno aprende por que a parede segura o rei, os dois desenhos de mate que podem ser forçados, a técnica de descer a parede com o rei à frente dos bispos, o lance de espera e o afogamento.

## O que o aluno precisa sair sabendo

1. Bispos lado a lado, perto do centro, cobrem diagonais vizinhas das duas cores e formam uma parede que o rei não atravessa. A parede se sustenta sozinha; o rei branco vem para empurrar.
2. O mate só pode ser forçado no canto ou na casa vizinha ao canto. Qualquer canto serve (diferente de bispo e cavalo).
3. O rei branco se põe na frente dos bispos, de frente para o rei preto; os bispos descem um de cada vez, tirando casas da borda, até o rei preto ficar numa caixa de três casas junto ao canto.
4. Perto do canto, contar as casas do rei preto: com uma só, o lance é mate ou de espera. Afogamento é o único jeito de empatar.

## Como cada fonte ensina

### Wikipedia, "Checkmate", seção "King and two bishops" (texto-fonte aberto)

Define o mate, exige bispos de cores opostas (citando Fine: bispos da mesma cor não dão mate, "nem nove"), e diz, citando Fine (*Basic Chess Endings*, ed. 1979, p. 1–4), que há três posições de mate possíveis: no canto, na casa vizinha ao canto, e no meio da borda, esta última possível mas não forçável. Dá o máximo de 19 lances com os bispos para jogar (Müller e Lamprecht 2001, p. 17), com raras exceções (0,03% das posições, Speelman, Tisdall e Wade 1993, p. 7). Dá dois princípios: bispos perto do centro e em diagonais vizinhas; rei ativo junto com os bispos. Reproduz uma linha de Seirawan (*Winning Chess Endings*, 2003, p. 5–7) a partir de rei preto em d4 e peças brancas em casa (Rd1, Bc1, Bf1), com comentários lance a lance, e avisa que não é o caminho mais curto; Müller e Lamprecht dão um caminho de 15 lances que tem um lance impreciso das pretas segundo a tabela. Mostra a armadilha de afogamento de Silman (2007, p. 191): Ra8, Bc7, Rc6, Bc4, e 1.Rb6?? afoga. Cita Reinfeld (*The Complete Chess Course*, 1959, p. 330) sobre o processo "um pouco longo" que mostra a força do par de bispos, e a divergência Howell (deixa os bispos fora do livro) × Silman (ensina os bispos, deixa bispo e cavalo de fora).

A linha de Seirawan foi conferida lance a lance na tabela: quase todo lance branco fica dentro da folga de um lance, mas 11.Re6 (depois de 10...Re8) é quatro meios-lances mais lento que o melhor.

### Lichess Practice, "Piece Checkmates II", capítulo "Two bishop mate" (arex; PGN lido pela API e página da prática aberta)

Posição de partida `8/8/3k4/8/8/2BBK3/8/8 w`, sem lances comentados no PGN. A descrição do capítulo dá os mesmos dois princípios da Wikipedia (bispos no centro em diagonais vizinhas; rei usado de forma agressiva). O link `lichess.org/study/Rg2cMBZ6` responde 404 sem login; a página pública é a da prática, que abriu. Por isso entrou como `web`, não como `study`.

### Chess.com, "Checkmate With Two Bishops" (Chess Terms; página aberta)

Ensina em três fases: bispos lado a lado e rei ajudando para levar o rei à borda; na borda, um padrão de "degrau": o rei ao lado dos bispos, o bispo mais perto do rei recua, o rei ocupa a casa dele, o bispo volta a ficar ao lado do outro; repetir até o rei estar a três casas da borda; então o bispo de fora impede a volta ao centro, e um lance de espera evita repetição ou afogamento antes do mate.

### Livros (catálogo aberto, conteúdo visto só pela Wikipedia)

- Yasser Seirawan, *Winning Chess Endings*, Everyman Chess, 2003 (Open Library: editora, ISBN 1857443489, 239 páginas). A primeira frase do livro, mostrada no catálogo, fala do princípio de todos os mates básicos: levar o rei à borda, não necessariamente ao canto.
- Jeremy Silman, *Silman's Complete Endgame Course: From Beginner to Master*, Siles Press, 2007 (Open Library: editora, ISBN 9781890085100, 530 páginas).
- Fine, Müller e Lamprecht, Speelman/Tisdall/Wade, Reinfeld e Howell foram vistos só como citações da Wikipedia; não abri nenhuma página deles. Não entram em `references`; aparecem na história com "via Wikipedia" no dossiê.

### Estudos da comunidade do Lichess

A busca por "two bishops mate" trouxe vários estudos de um capítulo (Hukin648, "TWO BISHOPS CHECKMATE", uma linha com setas; quoctrieu60, "Mate with Two Bishops", uma linha sem comentários; um terceiro vazio). Nenhum explica a técnica além da linha. O de Hukin648 também responde 404 em `/study/` sem login, embora a API entregue o PGN. Não há estudo público bom além da prática.

## Posições-base

| id | FEN | Quem joga | Tabela | Crédito |
|---|---|---|---|---|
| wall | `8/3k4/8/3BB3/4K3/8/8/8 w - - 0 1` | brancas | ganha (21 meios-lances) | própria |
| mateCorner | `7k/8/4B1K1/4B3/8/8/8/8 b - - 0 1` | pretas | xeque-mate | desenho clássico (Fine, via Wikipedia); posição final da linha da aula |
| mateSide | `1k6/1B6/1K1B4/8/8/8/8/8 b - - 0 1` | pretas | xeque-mate | Fine, via Wikipedia |
| stalemate | `k7/2B5/2K5/8/2B5/8/8/8 w - - 0 1` | brancas | ganha (9); 1.Rb6?? afoga | Silman, via Wikipedia |
| seirawan | `8/8/8/8/3k4/8/8/2BK1B2 w - - 0 1` | brancas | ganha (33) | Seirawan, via Wikipedia |

## História

- Não achei um "descobridor" nem data de primeira análise; o mate aparece como básico em todos os livros consultados (via Wikipedia).
- Fine, *Basic Chess Endings* (1941; citado na ed. de 1979): três posições de mate, só duas forçáveis; bispos da mesma cor não dão mate (Wikipedia).
- Müller e Lamprecht (2001): no máximo 19 lances com os bispos para jogar; Speelman, Tisdall e Wade (1993): exceções raríssimas (Wikipedia). Na fala do app isso virou "cabe com muita folga na regra dos cinquenta lances", sem número de lances.
- Howell (1997) deixa o mate de fora; Silman (2007) o inclui e deixa bispo e cavalo de fora (Wikipedia).
- Reinfeld (1959): o processo é um pouco longo, mas mostra a força do par de bispos (Wikipedia; parafraseado na fala).
- Não encontrei partida famosa decidida por este mate, nem caso de grande mestre que errou. Fica sem resposta.

## Plano da aula

Lição (aluno de brancas; o rei preto vai para o canto h8):

1. `wall` (talk): a parede em d5/e5; a faixa c8–f8, d7, e7.
2. `mateCorner` (talk): o mate no canto, bispos lado a lado em e5/e6; qualquer canto serve.
3. `mateSide` (talk): o mate na casa vizinha ao canto; no meio da borda não se força.
4. `join` (move): 1.Rf5 Rc8 2.Re6: o rei dá a volta e fica na frente dos bispos.
5. `edge` (move): 2...Rd8 3.Bb7 Re8 4.Bc7: a parede desce e empurra para h8.
6. `corner` (move): 4...Rf8 5.Rf6 Re8 6.Bc6+ Rf8 7.Bd7: a caixa f8–g8–h8.
7. `mate` (move): 7...Rg8 8.Rg6 Rf8 9.Bd6+ Rg8 10.Be6+ Rh8 11.Be5#.
8. `waiting` (move): se 8...Rh8: 9.Bd6 (espera; Be6?? afoga) Rg8 10.Be6+ Rh8 11.Be5#.
9. `stalemate` (talk): a armadilha de Silman.
10. `rules` (talk): três regras.
11. `playWall` e `playCenter` (play): a parede inteira e a posição de Seirawan contra a máquina.

A linha da aula inteira (1.Rf5 … 11.Be5#) é a da tabela: todo lance branco ensinado está entre os mais curtos (folga de um lance), e as respostas são as primeiras da tabela.

Exercícios (11, 21 estrelas, mínimo 13), todos próprios:

| id | ★ | Posição | O que pede |
|---|---|---|---|
| e01 | 1 | `7k/8/6K1/8/2B2B2/8/8/8 w` | Be5#; quase todo outro lance afoga |
| e02 | 1 | `1k3B2/1B6/1K6/8/8/8/8/8 w` | Bd6#, o mate ao lado do canto |
| e03 | 1 | `8/8/8/8/8/3K4/5BB1/2k5 w` | Rc3, o rei fecha a última fresta (único lance no ritmo) |
| e04 | 1 | `7k/5K2/7B/8/8/8/8/5B2 w` | não afogar: Bg7+ (ou espera com o bispo escuro, Rg6); Bd3?? afoga |
| e05 | 2 | `7k/2B5/6K1/5B2/8/8/8/8 w` | lance de espera Bd6/Bf4; Be6?? e Rf7?? afogam |
| e06 | 2 | `8/8/8/8/8/1K6/4BB2/2k5 w` | Be3+ Rb1 Bd3+ Ra1 Bd4#, o fim da aula no canto a1 |
| e07 | 2 | `3k4/6B1/3K4/3B4/8/8/8/8 w` | Bf7 Rc8 Rc6: empurrar rumo a a8 |
| e08 | 2 | `8/8/8/8/3BBK2/8/8/2k5 w` | Re3 Rd1 Bb2: rei na frente, bispo fecha c1 |
| e09 | 3 | `6k1/2B5/5K2/8/4B3/8/8/8 w` | Bd6 Rh8 Rg6 Rg8 Bd5+ Rh8 Be5#: fechar a caixa sem afogar |
| e10 | 3 | `8/8/8/k2B4/2KB4/8/8/8 w` | Bb7 Ra4 Bb6 Ra3 Rc3: descer a parede na coluna a |
| e11 | 3 | `8/8/8/3KB3/4B1k1/8/8/8 w` | Re6 Rh3 Rf5 Rh4 Bg2: o rei dá a volta na parede e empurra para a coluna h |

e03, e06, e07, e08, e10 e e11 são posições da linha da aula giradas ou espelhadas no tabuleiro (outro canto, outra borda); e09, e05 e e04 saíram de uma busca na tabela por posições junto ao canto com poucos lances bons.

## Treino final

`8/8/8/4k3/8/7B/2K5/4B3 w - - 0 1`, id `bishop.twoBishopsVsKing.0001` do catálogo (tabela: ganha, 27 meios-lances). O rei preto está no centro e os bispos separados: o aluno junta os bispos e faz o caminho inteiro. Bom encaixe com a aula.

## Referências

- `wikipedia` (web): "Checkmate", seção "King and two bishops", Wikipedia em inglês, texto-fonte aberto em 2026-10-07. Fonte dos desenhos de mate, da linha de Seirawan, da armadilha de Silman e da história.
- `lichessPractice` (web): Lichess Practice, "Piece Checkmates II", capítulo "Two bishop mate", de arex; página da prática aberta e PGN lido pela API (`https://lichess.org/api/study/Rg2cMBZ6.pgn`).
- `seirawan` (book): Yasser Seirawan, *Winning Chess Endings*, Everyman Chess, 2003. Catálogo da Open Library aberto; conteúdo visto pela Wikipedia.
- `silman` (book): Jeremy Silman, *Silman's Complete Endgame Course: From Beginner to Master*, Siles Press, 2007. Catálogo da Open Library aberto; conteúdo visto pela Wikipedia.
- `chesscom` (web): "Checkmate With Two Bishops", Chess.com, Chess Terms, página aberta.
- `tablebase` (tablebase): Lichess tablebase (Syzygy). Toda posição e todo lance da aula passaram por ela.

## Dúvidas e divergências

- A linha de Seirawan não é a mais curta (a própria Wikipedia avisa); a tabela confirma um lance branco quatro meios-lances atrás do melhor. A aula não reproduz essa linha: usa a dela, toda tirada da tabela, e cita Seirawan só pela posição inicial (`playCenter`).
- A regra `best` não serve no lance de mate (a tabela não dá distância para ele): os mates finais usam `only`.
- Em alguns passos, `best` aceita vários lances (no `edge`, dez lances no primeiro lance). Se o aluno jogar um aceito que não é o ensinado, a resposta combinada pode ficar ilegal e a linha acaba como cumprida; é a mesma limitação registrada nas aulas de bispo e cavalo.
- Não há estudo público bom do tema no Lichess (os da comunidade são só linhas). O capítulo da prática não abre em `/study/` sem login; entrou como `web` com o link da prática.
- Nenhum livro foi aberto por dentro: Fine, Müller e Lamprecht, Speelman, Reinfeld e Howell só por citação da Wikipedia. Sem número de página nas `references`.
- Não encontrei partida conhecida com este mate.

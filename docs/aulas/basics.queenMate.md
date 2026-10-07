# Mate de dama em poucos lances (`basics.queenMate`)

Pesquisa de 2026-10-07.

## O que o aluno precisa sair sabendo

1. Os dois desenhos finais: a dama colada no rei preto, protegida pelo rei (mate de apoio), e os reis em oposição com a dama dando xeque pela fileira ou coluna da borda (mate da borda). Os dois só existem na borda.
2. Para empurrar o rei preto, a dama fica a um salto de cavalo dele: vira duas paredes e encolhe o retângulo a cada lance, sem xeques à toa.
3. Quando o rei preto fica com duas casas na borda, a dama para e o rei branco vem. Às vezes um lance de espera da dama (sem xeque) obriga o rei preto a andar para o mate.
4. Perto do canto o salto de cavalo afoga. Antes de cada lance de dama, contar as casas do rei preto: ao menos uma, ou xeque.

Em relação à aula `mates.queen` da escola (salto de cavalo, rei que vem, um afogamento), esta aula aprofunda: a caixa lance a lance com a dama sozinha, o momento de parar a dama, o lance de espera, os dois desenhos de mate, os afogamentos do canto e posições em que só um lance mantém o caminho mais curto.

## Como cada fonte ensina

### Lichess Practice, "Piece Checkmates I", capítulo "Queen mate" (estudo `BJy6fEDf`, de arex)

Aberto pela API (`https://lichess.org/api/study/BJy6fEDf.pgn`). O capítulo parte de `8/8/3k4/8/8/4K3/8/4Q3 w` e dá uma linha pronta: a dama corta primeiro (Qa5), o rei branco sobe ao centro junto com o preto, a dama encosta a parede (Qb6, Qf6+), o rei preto vai ao canto e o mate sai com a dama protegida (Qg7#). Não há texto explicativo no PGN, só a linha. Mesmo estudo traz os outros mates básicos (duas torres, torre, dama e torre etc.).

### Estudo "Checkmating with a Queen", de chamyVignesh (`hPw6Ij5O`)

Aberto pela API. Sete capítulos curtos e introdutórios: o alcance da dama, as casas do rei, a dama encostada no rei de frente (com o rei branco cobrindo a casa de trás) e mates na última fileira. Não chega à técnica de empurrar o rei; serve como confirmação da ideia de "dama encostada protegida". Nada copiado.

### Wikipedia, "Checkmate", seção "King and queen"

Texto-fonte aberto (`action=raw`). Traz quatro desenhos de mate com dama (mate de apoio, triângulo, canto e borda externa), todos atribuídos a Pandolfini (2009); a afirmação de que, com a dama, o mate sai em no máximo dez lances de qualquer posição (citando Fine e Benko, 2003, e Müller e Lamprecht, 2001); a técnica de prender o rei num retângulo e encolhê-lo, com a partida-exemplo de Seirawan (2003) a partir de `8/8/8/8/4k3/8/8/QK6 w`; e cinco tipos de afogamento que o lado forte precisa evitar (Fine e Benko), o primeiro deles `k7/2Q5/8/8/8/8/8/7K b`. Tudo isso é de segunda mão: os livros de Pandolfini, Fine/Benko, Seirawan e Müller/Lamprecht não foram abertos.

### Jeremy Silman, *Silman's Complete Endgame Course* (Siles Press)

Abri o registro do Open Library (`https://openlibrary.org/isbn/9781890085100.json`: Siles Press, 31/01/2007, 530 páginas, ISBN 1-890085-10-3) e uma resenha (`https://patzersreview.substack.com/p/the-only-endgame-book-you-need`, de "Dr Patzer"), que diz que a primeira parte do livro (jogadores até 999 de rating) começa pelo mate em escada e pelo mate de rei e dama. É só isso que sei do conteúdo: não li o capítulo. Entra em `references` como o livro em que o tema abre o curso, sem `where`. A busca da página da AbeBooks não abriu.

### Wikipedia, "Queen (chess)"

Texto-fonte aberto. Usado só para a história: o alferza (ferz) andava uma casa na diagonal; a dama ganhou o movimento atual na Espanha no século XV; o poema valenciano *Scachs d'amor* (Valência, por volta de 1475) já a mostra assim; o tratado mais antigo que sobreviveu a descrever o movimento novo é o de Luis Ramírez de Lucena.

### Páginas gerais

A busca "king and queen versus king checkmate technique knight's move box" devolveu páginas de escolas e blogs (thechessworld, chesskid, uchess, venturechessacademy) que repetem o método da caixa e do salto de cavalo. Não abri nenhuma e não cito.

## Posições-base

Todas com 3 peças, conferidas na tabela do Lichess em 2026-10-07.

| id | FEN | Quem joga | Tabela | Crédito |
|---|---|---|---|---|
| supportMate | `4k3/4Q3/4K3/8/8/8/8/8 b` | pretas | mate | desenho de Pandolfini, pela Wikipedia |
| edgeMate | `4k2Q/8/4K3/8/8/8/8/8 b` | pretas | mate | desenho de Pandolfini, pela Wikipedia |
| knightJump | `8/8/8/4k3/8/5Q2/8/K7 b` | pretas | loss (pretas perdem) | própria (depois de 1.Qf3 em `follow`) |
| cornerStalemate | `k7/2Q5/8/8/8/8/8/7K b` | pretas | afogado (draw) | Fine e Benko, pela Wikipedia |
| seirawan | `8/8/8/8/4k3/8/8/QK6 w` | brancas | win (Qa5 e Qf6 mais curtos) | Seirawan, pela Wikipedia |
| lichessPractice | `8/8/3k4/8/8/4K3/8/4Q3 w` | brancas | win (Kd4 mais curto) | Lichess Practice, arex |

## História

- A peça ao lado do rei era o alferza (ferz), de uma casa na diagonal; a dama moderna surge na Espanha no século XV. *Scachs d'amor* (Valência, c. 1475) e o livro de Luis Ramírez de Lucena são os primeiros registros do movimento novo (Wikipedia, "Queen (chess)").
- Com o melhor jogo, rei e dama dão mate em no máximo dez lances de qualquer posição (Wikipedia, "Checkmate", citando Fine e Benko 2003 e Müller e Lamprecht 2001). Na fala isso aparece como fato da história, sem número de lances em exercício nenhum.
- Não encontrei partida famosa, verificável nas fontes abertas, em que um mestre tenha afogado com rei e dama contra rei. Fica sem gancho de partida.

## Plano da aula

Lição (o aluno joga de brancas):

1. `goal` (talk): mate de apoio, `4k3/4Q3/4K3` com pretas na vez.
2. `edge` (talk): mate da borda, reis em oposição, `4k2Q/8/4K3`.
3. `jump` (talk): a dama a salto de cavalo (Qf3 contra Ke5): duas paredes, retângulo.
4. `follow` (move, win, `best`): de `8/8/8/4k3/8/8/8/K2Q4 w`, só a dama: Qf3 Kd6, Qe4 Kc7, Qe6 Kb7, Qd6. Respostas da tabela (`auto`). A regra `best` aceita de 9 a 20 lances em cada vez (é uma posição longe do mate); a fala diz que outros lances também servem e que a ideia é a sombra.
5. `stop` (talk): `1k6/8/2Q5/8/8/8/8/K7 w`: duas casas (a7, b8), a dama para, o rei vem.
6. `stalemate` (talk): `k7/8/1Q6/8/8/8/8/K7 b`: o salto de cavalo no canto afoga.
7. `bring` (move, win): de `7k/4Q3/8/8/8/6K1/8/8 w`: Kg4 Kg8, Kg5 Kh8, Kg6 Kg8 (`best`), e o mate com a lista dos três mates da posição (De8#, Dd8#, Dg7#). Df6 afoga.
8. `recap` (talk): as três regras, sobre a posição do treino.
9. `finish` (play, win): `8/8/8/3k4/8/8/8/Q3K3 w`.

Exercícios (18 estrelas, mínimo 11), todos próprios:

| id | ★ | Ideia | Aceitos (tabela) |
|---|---|---|---|
| e01 | 1 | mate da borda com reis em oposição | só Qg8# |
| e02 | 1 | mate de apoio de longe; Qd6? afoga | só Qe7# |
| e03 | 1 | mate no canto; Qb6? (salto de cavalo) afoga | só Qb7# |
| e04 | 1 | a caixa menor com um lance de dama | Qe5, Qd1, Qd2, Qe6+ |
| e05 | 2 | lance de espera: Qc7, ...Kf8 forçado, mate | só Qc7; Qf7#/Qd8# |
| e06 | 2 | o mesmo, de lado: Qg3, ...Kh6 forçado, mate | só Qg3; Qg6#/Qh4# |
| e07 | 2 | rei vem com a dama parada; Qg6? afoga | Kf4/Kf5/Kf6 ou esperas da dama; só Qg7# |
| e08 | 2 | o único salto de cavalo que prende; depois encostar a parede | só Qf5; Qf3, Qe4, Qe5, Qf4+, Kb2/b3/b4 |
| e09 | 3 | reis frente a frente: só Qd5 mantém o caminho mais curto | só Qd5; Kf2/Ke2; Qe5/Ke3 |
| e10 | 3 | perto do canto, com dois afogamentos no caminho (Qf4?, Qf3?) | só Qe4; Kf2/Qg6; Qg2#/Qh4#/Qh7# |

## Treino final

`8/3k4/8/8/8/8/2K5/2Q5 w - - 0 1`, id `basic.queen.0001` do catálogo (win na tabela).

## Referências

| id | O quê | Como consultei |
|---|---|---|
| silman | Jeremy Silman, *Silman's Complete Endgame Course: From Beginner to Master*, Siles Press, 2007 | registro do Open Library (editora, data, ISBN) e resenha de Dr Patzer; conteúdo só de segunda mão |
| practice | Lichess Practice: Piece Checkmates I, de arex | `https://lichess.org/api/study/BJy6fEDf.pgn`, capítulo "Queen mate" |
| chamy | Checkmating with a Queen, de chamyVignesh | `https://lichess.org/api/study/hPw6Ij5O.pgn` |
| wikiCheckmate | Wikipedia, Checkmate (King and queen) | texto-fonte aberto |
| wikiQueen | Wikipedia, Queen (chess) | texto-fonte aberto (só história) |
| tablebase | Lichess tablebase (Syzygy) | todas as posições e lances |

Não entraram: Pandolfini, Fine/Benko, Seirawan, Müller/Lamprecht (só citados pela Wikipedia; aparecem nas legendas como "pela Wikipedia"), de la Villa e Dvoretsky (não procurados para este tema básico), as páginas de blogs da busca (não abertas).

## Dúvidas e divergências

- Nenhuma divergência entre as fontes e a tabela. A linha do Lichess Practice (1.Qa5) não é a mais curta pela tabela (1.Kd4 é), mas ganha; não usei a linha, só a posição como legenda.
- Na nota da Wikipedia à partida de Seirawan, 7.Kc5 é dito dois lances mais rápido; não conferi a linha inteira, e a posição só aparece como legenda.
- A regra `best` não funciona quando há mate imediato na posição (a tabela não dá distância para o lance que dá mate), por isso as vezes finais de mate usam `only` (mate único) ou a lista exata dos mates da posição (`bring` lance 4, e05, e06, e10). A lista é o conjunto completo de mates conferido pelo script, não um atalho.
- Em `follow` e e07 a regra `best` aceita muitos lances (longe do mate, quase tudo está dentro da folga). A fala e as soluções dizem isso, sem fingir que o lance ensinado é único.
- O "no máximo dez lances" está na `history` como fato citado pela Wikipedia; nenhum exercício ou enunciado conta lances.
- Não achei partida conhecida, em fonte aberta, com afogamento neste final.

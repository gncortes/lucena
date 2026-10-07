# Dama contra peão na sétima: peão central e de cavalo (`queen.vsPawn`)

Pesquisa de 2026-10-07.

## O que o aluno precisa sair sabendo

Contra peão central (d, e) ou de cavalo (b, g) na sétima, a dama ganha mesmo com o próprio rei longe. A técnica: xeques e cravadas, sem encostar no rei, até o rei defensor ficar na casa de coroação, na frente do próprio peão. Nesse momento o peão está bloqueado e o defensor gasta um lance para sair dali: é o lance de graça do rei atacante. Repete-se o ciclo até o rei chegar perto e a dama tomar o peão. Quando o rei defensor se afasta duas colunas, o lance certo pode ser calmo (dama encostada no peão). Cuidado com o próprio rei: parado numa linha que a dama precisa (a coluna d, com dama em c8 e peão em e2), ele transforma a vitória em empate. Peão de bispo e de torre têm empates por afogamento: só citados, são a aula `queen.vsPawn.draws`.

## Como cada fonte ensina

- **Wikipedia, "Queen versus pawn endgame"** (aberta): divide por coluna do peão. Central e de cavalo: "a dama ganha", forçando o rei para a frente do peão com xeques e aproximando o rei a cada ciclo; mostra uma linha com peão em e2 e rei preto em d2 (1...Re3 2.Dh4 Rd2 3.Dd4+ Rc2 4.De3 Rd1 5.Dd3+ Re1 …). Destaca a exceção do próprio rei no caminho: com dama em c8, rei preto em d2 e peão em e2, se o rei branco está em d5, d6 ou d7, a dama não se aproxima e é empate. Depois trata peão de torre e de bispo (zonas do rei atacante, Lolli 1763) e o peão na sexta.
- **Estudo "Queen vs Pawn", de Danghiangmanh, no Lichess** (aberto, PGN baixado pela API pública): modo gamebook. Capítulo "Beginner" com peão em e2: regras curtas ("chegue o mais perto possível do rei sem encostar nele"; e3 como casa-chave quando o rei não a toca; forçar o rei para a frente do peão; trazer o rei; cravada quando o rei sai de lado; repetir). Os outros capítulos são de peão de torre e de bispo (empates e vitórias com o rei perto), material da próxima aula.
- **Estudo "Queen vs. Promoting Pawn", de MarioPB4, no Lichess** (aberto, PGN pela API): quase todo sobre peão de torre e de bispo. O primeiro capítulo diz que o estudo segue uma aula de J. Schrantz no St. Louis Chess Club e o livro de Jesús de la Villa. Útil como confirmação da divisão "central e cavalo ganham, bispo e torre são a dor de cabeça".
- **Jesús de la Villa, *100 Endgames You Must Know*** (amostra oficial da editora, PDF da distribuidora Boekhuis, aberto): só vi a página de rosto e o sumário. 4ª edição revista, New In Chess, 2015. Capítulo 4, "Queen vs. Pawn", p. 59: Ending 16 "Queen vs. 7th-rank pawn" (p. 59), Ending 17 peão de torre (p. 60), Ending 18 peão de bispo (p. 62). O conteúdo do Ending 16 não foi lido.
- **Chess.com, artigo "Queen vs. Pawn on 7th"** (TonightOnly, 2008, aberto): mesma divisão por coluna; os diagramas não vieram no texto. Não entrou em `references`, por não acrescentar nada além da Wikipedia.

Não aberto: o estudo "Queen vs Pawn Endgame Trainer", de litlife (`lichess.org/study/q1YflEzJ`), é privado. Na prática do Lichess (`lichess.org/practice`) não há seção de dama contra peão. Silman, Dvoretsky e Müller/Lamprecht não foram consultados (este último só aparece na bibliografia da Wikipedia).

## Posições-base

| id | FEN | Quem joga | Tabela | Crédito |
|---|---|---|---|---|
| start | `K7/8/8/8/8/8/3kp3/6Q1 w - - 0 1` | brancas | ganha, mate em 47 meios-lances; Dd4+ e Df2 (cravada) dentro da folga | própria |
| front | `K7/8/8/8/8/3Q4/4p3/4k3 w - - 0 1` | brancas | ganha; Ra7 e Rb7 os melhores, De3 já é mais lento | própria |
| dang | `K6Q/8/8/8/8/8/3kp3/8 w - - 0 1` | brancas | ganha; Dd4+ o melhor | estudo de Danghiangmanh |
| block | `2Q5/8/8/3K4/8/8/3kp3/8 w - - 0 1` | brancas | empate (nenhum lance ganha) | diagrama da Wikipedia |

Conferido também: com o rei branco em d6 o mesmo empate; em d4, só Dc3+ ganha; em e5, só Dd8+ e Dd7+ (exercício e07).

## História

Fatos tirados da Wikipedia ("Queen versus pawn endgame"), a única fonte aberta com história: a bibliografia cita *Basic Chess Endings*, de Reuben Fine (1941; revisão de Pal Benko, 2003); um estudo de Giambattista Lolli de 1763 com peão de bispo; Alatortsev–Chekhover, 1937, vitória das brancas contra peão de bispo na sexta; Petrosian–Fischer, 1958, com peão de bispo; Van Wely–Leko, 1996, empatada por causa do peão de bispo. Na fala `history` entraram Fine, de la Villa (sumário), Lolli, Alatortsev–Chekhover e Van Wely–Leko. Petrosian–Fischer ficou de fora: não confirmei resultado nem detalhes.

## Plano da aula

Lição (aluno de brancas):
1. `intro`: posição `start`, o peão a uma casa de coroar e o rei longe.
2. `idea`: posição `front`, por que o rei na frente do peão dá um lance de graça.
3. `stairs` (move): Dd4+ Rc1 De3+ Rd1 Dd3+, o rei preto vai para e1.
4. `tempo` (move): Rb7 Rf2 Dd2, o lance de graça e a cravada.
5. `again` (move): Df4+ Rg1 De3+ Rf1 Df3+, o rei volta para e1.
6. `cycle`: o ciclo se repete (rei em c6, d5, e4, d3).
7. `quiet` (move): rei preto em c2, o lance calmo De3 e depois Dd3+.
8. `arrive` (move): Rd3 Rc1 Dxe2, o fim.
9. `block`: o próprio rei em d5 fecha a coluna d: empate.
10. `others`: peão de bispo, o afogamento com o rei no canto; fica para a próxima aula.
11. `recap` e `finish` (play na posição `start`).

Exercícios (10, 20 estrelas, mínimo 12):

| id | ★ | ideia | aceitos (tabela) |
|---|---|---|---|
| e01 | 1 | rei preto na frente do peão d: usar o lance de graça | Rg7, Rh7 |
| e02 | 1 | rei preto ao lado do peão d: cravar sem xeque | De2, Df2, De4+, Dc5+ |
| e03 | 1 | o xeque que põe o rei na frente do peão d | De3+ |
| e04 | 2 | rei a duas colunas: lance calmo, xeque e o lance de graça | Dd3; De3+; Re5, Rf5, Rg5 |
| e05 | 2 | peão de cavalo atacando a dama em h1: cravar e seguir | Dh2, Dh4+; Df4+ |
| e06 | 2 | o rei chega e defende a casa do peão | Re3; Dxd2, Rf3 |
| e07 | 2 | rei branco em e5: só o xeque pela coluna d ganha (origem Wikipedia) | Dd8+, Dd7+ |
| e08 | 3 | dama longe: cravada na diagonal h6-c1, depois na fileira | Dh6, Dc7+; Dh2, Dc6+, Dg6+ |
| e09 | 3 | dama no canto a1: descer a escada de xeques | Da4+, Da2+; Dc4+, Df4; Dd3+, Db3+ |
| e10 | 3 | peão de cavalo em b2: a escada completa até Dc3+ | Dc4+, De2+; Db3+, Dd3+; Dc3+ |

Regras: `best` (distância do mate da tabela, folga de um lance) na maioria; `win` onde os dois caminhos ganham e o resto empata (e05, e07, e08 e e09 no primeiro lance).

## Treino final

`3K2Q1/8/8/8/8/5k2/3p4/8 w - - 0 1`, id `queen.queenVsPawn.0005` do catálogo (peão central, em d2; fonte supertorpe/chessendgametraining). Tabela: ganha. As outras do catálogo: 0001 e 0003 com peão em f (bispo), 0002 e 0004 com peão em c (bispo). A 0005 é a única com peão central.

## Referências

- `delaVilla`: Jesús de la Villa, *100 Endgames You Must Know*, 4ª edição revista, New In Chess, 2015; `where` "Ending 16, Queen vs. 7th-rank pawn, p. 59". Como consultei: sumário e página de rosto na amostra oficial (`download.boekhuis.nl/9789056916176_fragm-docb.pdf`). O texto do capítulo não foi lido.
- `wikipedia`: "Queen versus pawn endgame", aberta.
- `dang`: estudo "Queen vs Pawn", de Danghiangmanh, `https://lichess.org/study/4JKLMbtH`, aberto (PGN pela API).
- `mario`: estudo "Queen vs. Promoting Pawn", de MarioPB4, `https://lichess.org/study/o2EZohXS`, aberto (PGN pela API).
- `tablebase`: Lichess tablebase (Syzygy), `https://tablebase.lichess.ovh`.

## Dúvidas e divergências

- Nenhuma divergência com a tabela: as linhas da Wikipedia e do estudo de Danghiangmanh conferem com ela. As linhas da aula são próprias e foram todas conferidas pela tabela (o final tem 4 peças, sem Stockfish).
- A técnica ensinada nem sempre é o mate mais curto: o rei preto às vezes prefere fugir do peão (em vez de ir para a frente dele) para durar mais. Por isso as falas dizem "a melhor defesa é…" e o passo `finish` avisa que a máquina pode fugir.
- A fonte JSON foi gerada por um script de rascunho (fora do repositório) com `tools/lessons/make_source.py`, para não escrever FEN e UCI à mão; não há `queen.vsPawn.py` em `tools/lessons/endgames/`.
- Sem resposta: o conteúdo do Ending 16 de de la Villa (só o sumário estava aberto); o resultado de Petrosian–Fischer 1958.

## Estado

`build_aula.py queen.vsPawn` sem problemas: 20 estrelas, mínimo 12, gerado `assets/lessons/endgames/queen.vsPawn.json` e a aula entrou no `index.json`. Falta ver no emulador.

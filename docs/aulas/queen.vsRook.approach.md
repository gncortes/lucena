# Dama contra torre II: como chegar a Philidor (`queen.vsRook.approach`)

Pesquisa de 2026-10-06. A pesquisa completa das três aulas de dama contra torre está em `docs/aulas/queen.vsRook.pesquisa.md`; aqui fica só o que é desta aula.

## O que o aluno precisa sair sabendo

Como chegar a Philidor quando o rei defensor já está perto da borda, e como levá-lo até lá. Três ferramentas: (1) contra a defesa da segunda fileira, 1.Df5+ e 2.Rc5!, depois "xeque para ganhar tempo, rei um passo à frente" até Philidor; (2) antes de avançar o rei, tirar da torre as casas de xeque com um lance calmo de dama, e a posição diagonal (triângulo de dama, xeque descoberto, Philidor); (3) longe da borda, a escada: xeque, xeque, rei desce uma casa. E a regra de sempre: dama longe do rei encurralado, por causa do afogamento.

## Como cada fonte ensina

Resumo em `queen.vsRook.pesquisa.md`. Para esta aula: a Wikipedia (segunda fileira de Euwe 1958 com as defesas A, B e C; a posição de Nunn com Dd8 e Dd4; a armadilha de Berger 1889); o estudo de Unto (posição diagonal); o de Coach_Vince ("Disco": gastar um tempo e dar o descoberto); a revanche Browne x Belle de 1978 (a escada dos lances 37 a 50), com os lances do chessgames que batem com o artigo de 1979.

## Posições-base

| id | FEN | Quem joga | Tabela | Crédito |
|---|---|---|---|---|
| second | `2k5/4r3/1K6/3Q4/8/8/8/8 w - - 0 1` | brancas | ganha, mate em 37 meios-lances | Euwe 1958, via Wikipedia |
| diagonal | `1k6/2r5/3K4/4Q3/8/8/8/8 w - - 0 1` | brancas | ganha, 25 | estudo de Unto |
| ladder | `8/7Q/8/4K1k1/8/6r1/8/8 w - - 0 1` | brancas | ganha | Browne x Belle, revanche, depois de 37.Re5 Tg3 |
| berger | `8/rk6/8/1KQ5/8/8/8/8 w - - 0 1` | brancas | ganha, 19; 1.Dc6+? Rb8 2.Rb6?? Ta6+ empata | Berger 1889, via Wikipedia |

## História

Na fala `history`: Euwe 1958 e Berger 1889 (Wikipedia); Browne contra Belle, dezembro de 1978, a escada e a captura no 50º lance, e a "barreira" a uns 15 lances do fim (artigo de 1979).

## Plano da aula

Lição: `intro` (a segunda fileira), `stale` (1.Dd6? e o afogamento), `open` (Df5+ e Rc5), `fork3` (as três defesas), `a1` e `a2` (defesa 2...Rc7 até Philidor na coluna a), `c1` e `c2` (defesa 2...Re8 até Philidor no canto g8), `checks` e `quiet` (tirar os xeques: Dd8, Dd4), `diagonal` e `discover` (triângulo, descoberto, Philidor), `ladder` e `climb` (a escada, dois degraus), `recap`, `finish` (segunda fileira contra o Stockfish).

Exercícios (11, 20 estrelas, mínimo 13): e01 Df5+ (1); e02 Rc5 (1); e03 o xeque descoberto (1); e04 primeiro xeque da escada (1); e05 Berger, De5 ou Dd4 (2); e06 Dd8 e Dd4 (2); e07 "Disco", passar a vez (2); e08 um degrau da escada (2); e09 o fim da escada, três xeques e a torre no canto (2); e10 segunda fileira, De8, De4, Rc6 (3); e11 perseguição pela ala do rei até Dd5 (3).

## Treino final

`2k5/4r3/1K6/3Q4/8/8/8/8 w - - 0 1`, id `queen.queenVsRook.0002` do catálogo. Não é posição de speedrun (o speedrun `ending.queenVsRook` usa a `0001`), então o passo final abre o treino na posição.

## Referências

As de `references` na fonte: `wikipedia`, `belle` (a partida), `belle1979` (o artigo), `calmodee`, `unto`, `vince`, `parker` (abertos), `nunn` (não aberto, só ficha) e `tablebase`.

## Dúvidas e divergências

- Conferido com `tools/check_line.py`: as três defesas da segunda fileira (Wikipedia) são as melhores da tabela lance a lance, até o mate e até a captura. A escada de Browne é a melhor da tabela em todos os lances usados na aula (o 44.Dg5+ da partida custa um lance e ficou fora). Com a regra `best`, quase toda vez da aula aceita um lance só.
- A defesa B (2...Te1, a torre foge) não virou passo lance a lance: é longa e pouco regular. O princípio (tirar os xeques antes de avançar) é ensinado na posição de Nunn, e a máquina a joga no passo `finish`.
- "Albatross" (Coach_Vince): o primeiro lance do estudo (Da7+) custa dois lances na tabela; não usei.
- Na posição diagonal e no "Disco", o lance de espera tem três casas equivalentes; a regra é a lista delas.

## Estado

Concluída em 2026-10-06: `build_aula.py queen.vsRook.approach` sem problemas, aula no `index.json` (8 aulas na trilha). Falta ver no emulador.

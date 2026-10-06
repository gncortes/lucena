# A defesa de Philidor (`rook.philidor`)

Pesquisa de 2026-10-05 (primeira passada, pausada) e de 2026-10-06 (completa). A pesquisa das aulas de defesa com a torre está em `docs/aulas/rook.defesa.pesquisa.md`; aqui fica só o que é desta aula.

## O que o aluno precisa sair sabendo

Com o rei na casa de promoção do peão, torre e peão contra torre empata assim: a torre fica na terceira fileira e impede o rei atacante de avançar; quando o peão pisa na terceira fileira, a torre vai para o fundo do tabuleiro e dá xeques por trás, porque o rei atacante perdeu a casa de abrigo. Os dois erros são de tempo: sair da terceira fileira antes de o peão avançar, ou ficar nela depois. Se as torres forem trocadas, o rei recua reto para a frente do peão. E quando a terceira fileira não está mais disponível, ainda há defesa (torre atrás do peão, rei para o lado curto), que é a aula seguinte.

## Como cada fonte ensina

Resumo em `rook.defesa.pesquisa.md`. Para esta aula: Wikipedia "Philidor position" e "Rook and pawn versus rook endgame" (as três características, os três erros, a história); os estudos de ProfAngel, ehenkes, Yuri61 e NoseKnowsAll e a prática do Lichess (as posições e as linhas); o blog de James Stripes (a variante em que o próprio Philidor errou).

## Posições-base

O aluno defende de brancas: as posições das fontes entram com as cores trocadas e o tabuleiro virado.

| id | FEN | Quem joga | Tabela | Crédito |
|---|---|---|---|---|
| classic | `8/8/8/8/4pk2/R7/7r/4K3 b - - 0 1` | pretas | empate com qualquer lado | Philidor 1777, diagrama da Wikipedia |
| reach | `8/8/8/8/4pk2/8/r7/1R2K3 w - - 0 1` | brancas | empate; seguram Tb3 e a torre pela coluna b até o fundo | prática do Lichess, "Philidor Position" |
| bishop | `6R1/8/8/8/2pk4/8/7r/3K4 w - - 0 1` | brancas | empate; só Tg3 e Rc1 | estudo de Yuri61 |
| advanced | `8/8/8/8/3kpR2/8/7r/4K3 w - - 0 1` | brancas | empate; só a torre para o fundo da coluna f, depois só Te7 | prática do Lichess, "Advanced Philidor" |

## História

Na fala `history`: Philidor 1777 (segunda edição da *Analyse*), que achava ser o único empate; Karstedt 1897 mostrou outras defesas (Wikipedia en e de); a variante de Philidor contra a torre por trás estava errada, e a tabela dá empate (blog de Stripes, conferido na tabela).

## Plano da aula

Lição: `intro` (a posição e as três condições), `take` (tomar a terceira fileira e esperar), `pawn` (o peão avançou: o que muda), `behind` (torre para o fundo e os xeques), `early` (xeque antes da hora perde), `passive` (ficar depois do avanço perde), `trade` e `endgame` (troca de torres e o final de peões: rei reto para trás), `bishop` (vale para qualquer peão), `limits` (quando a terceira fileira não serve mais: gancho para a próxima aula), `recap`. Sem passo de jogar: o app só tem objetivo de mate ou promoção no passo `play` (ver `docs/tasks/T35.md`).

Exercícios (10, 18 estrelas, mínimo 11): e01 tomar a fileira (1); e02 o peão avançou (1); e03 o xeque único (1); e04 peão de bispo (1); e05 o final de peões (2); e06 a defesa inteira a partir da posição clássica (2); e07 não parar de dar xeque (2); e08 troca de torres e final de peões (2); e09 a torre atacante dá xeques e o rei volta para a casa de promoção (3); e10 a "Philidor avançada" (3).

## Treino final

`8/8/8/8/4pk2/8/r7/1R2K3 w - - 0 1`, objetivo empate, `positionId: null`: as três posições de torre e peão contra torre do catálogo (`rookPawn.rookPawnVsRook.0072` a `0074`) são empates de outro motivo.

## Referências

As de `references` na fonte. Abertos: `wikipedia`, `rookPawn`, `stripes`, os estudos do Lichess. `nunn` (*Secrets of Rook Endings*, Gambit, 1999): não aberto; ficha conferida na Open Library e na página da editora na primeira passada.

## Dúvidas e divergências

- Regra de aceitos `hold` (todo lance que não perde) nos lances de espera e `only` onde só um lance segura. Em e01 e e06 isso aceita também subir a torre até o fundo antes da hora, que empata por outro método; a solução diz isso.
- A posição original de Philidor (com o defensor de pretas e o rei em e8) não entrou como posição-base, para não misturar orientações.
- No estudo de ehenkes, um xeque é marcado como erro grave e a tabela diz que ainda empata; não usei esse trecho.

## Estado

Concluída em 2026-10-06: `build_aula.py rook.philidor` sem problemas, aula no `index.json` (10 aulas na trilha). Falta ver no emulador.

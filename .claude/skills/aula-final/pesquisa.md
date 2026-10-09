# Spike de pesquisa de uma aula

O objetivo é saber o que os bons autores ensinam sobre o final, em que ordem e com quais posições, para escrever uma aula própria e dar o crédito certo. O resultado é o dossiê `docs/aulas/<id>.md`.

## Onde procurar

Pontos de partida. Confira título, autor, editora, edição e ano na hora (site da editora ou catálogo de biblioteca): não cite de memória.

- **Livros**
  - Jesús de la Villa, *100 Endgames You Must Know* (New in Chess): a referência principal para a escolha dos temas.
  - Jeremy Silman, *Silman's Complete Endgame Course* (Siles Press): a ordem didática por nível.
  - Mark Dvoretsky, *Dvoretsky's Endgame Manual* (Russell Enterprises): a análise mais funda.
  - Karsten Müller e Frank Lamprecht, *Fundamental Chess Endings* (Gambit).
  - Yuri Averbakh, *Comprehensive Chess Endings*; John Nunn, *Secrets of Rook Endings* e *Secrets of Pawnless Endings*.
  - Artur Yusupov, *Build Up Your Chess* e as séries seguintes (Quality Chess): o modelo de lição, exercícios com estrelas e nota mínima.
- **Lichess**: estudos (`https://lichess.org/study/search?q=<tema>`), a seção de prática (`https://lichess.org/practice`) e a tabela de finais (`https://tablebase.lichess.ovh/standard?fen=<FEN>`).
- **História**: quem achou a posição e quando (Philidor, Lucena, Vancura, Troitsky, Réti, Centurini…), partidas famosas em que o final apareceu, inclusive as em que um grande mestre errou.

Livro com direitos reservados não se baixa de site pirata. Use o que está aberto legalmente (amostras da editora, resenhas, índices, artigos, estudos públicos) e o que o Gabriel tiver e passar.

## Regras de honestidade

1. **Só cita o que abriu.** Cada referência do dossiê diz como foi consultada (link aberto, trecho passado pelo Gabriel). Se a informação veio de segunda mão ("o artigo X diz que o livro Y mostra…"), a referência é o artigo X.
2. **Sem número de página, capítulo ou diagrama inventado.** Só entra `where` se foi visto.
3. **Estudo do Lichess**: link que abriu, com título e autor como aparecem na página. Estudo privado ou apagado não entra.
4. **Nada de texto copiado.** O dossiê resume com as próprias palavras; citação literal, só curta e entre aspas, com a fonte.
5. **Poucas posições por fonte.** Posições clássicas (as que têm nome ou aparecem em vários autores) entram com o crédito de quem as achou. A lista de exercícios de um livro ou de um estudo não se reproduz: os exercícios da aula são na maioria próprios.
6. **A tabela manda.** Toda posição do dossiê vai com o veredito da tabela de finais. Se uma fonte diz outra coisa (análises antigas erram), registre a divergência e ensine o que a tabela mostra.
7. **Não achou, diz que não achou.** "Não encontrei estudo público bom sobre isto" é um resultado válido.

## Modelo do dossiê

```markdown
# <Nome do final> (`<id>`)

Pesquisa de <data>.

## O que o aluno precisa sair sabendo
Três a cinco frases.

## Como cada fonte ensina
Uma seção curta por fonte consultada: a ordem das ideias, os nomes que usa para a técnica, o que ela destaca. Com as próprias palavras.

## Posições-base
| id | FEN | Quem joga | Tabela | Crédito |
|---|---|---|---|---|

## História
Quem estudou primeiro, quando, partidas conhecidas (jogadores, torneio, ano, resultado). Cada fato com a fonte.

## Plano da aula
Os passos da lição, em ordem.

## Ideias para os exercícios
Uma linha por ideia distinta do tema; é dela que saem os exercícios, um por linha. Mexer nos reis, espelhar ou trocar as cores não é ideia nova, e posição que a lição mostra não entra.

| Ideia | Posição (FEN) | ★ | Por que é diferente das outras | Fonte |
|---|---|---|---|---|

## Treino final
A posição do treino e o id do catálogo, se houver. Se o catálogo não tem a posição, dizer aqui.

## Referências
A lista que vai para `references`, com o campo "como consultei" de cada uma.

## Dúvidas e divergências
O que as fontes dizem de diferente entre si ou da tabela, e o que ficou sem resposta.
```

## Links (T61)

Toda posição que vem de partida ou de estudo publicado leva o aluno à fonte no Lichess, pelo `ref` do
passo (e `keyPositions.ref`) apontando uma referência com `url`:

- **Partida jogada** (`kind: game`, com `white`, `black`, `event`, `year` e `url`): o link é o tabuleiro
  de análise do Lichess com a partida inteira, parado na posição da aula:
  `https://lichess.org/analysis/pgn/<lances em SAN, separados por _>#<ply>` (ply = meio-lances desde o
  início; `#20` é a posição depois do 10.º lance das pretas). O PGN precisa vir de fonte aberta que você
  abriu (artigo da Wikipedia, estudo público do Lichess pela API `https://lichess.org/api/study/<id>.pgn`,
  arquivo PGN público) e ser conferido com python-chess: a posição depois do ply citado é o FEN do passo.
  O explorador de mestres do Lichess (`explorer.lichess.ovh`) exige autenticação; não conte com ele.
- **Estudo** (`kind: study`): a URL do capítulo, `https://lichess.org/study/<id>/<capítulo>`, como aparece
  na página.
- **Posição sem partida** (própria ou de livro): sem link, ou, se ajudar, a análise do Lichess a partir do
  FEN, `https://lichess.org/analysis/standard/<FEN com _ no lugar de espaço>` (`kind: web`).

Nunca cite partida de memória: jogadores, evento, ano e lances vêm da fonte aberta, e a referência diz
qual. Se as fontes abertas não têm a partida, a aula diz "posição que aparece nos manuais" e fica sem link.

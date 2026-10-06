# Casas-chave: rei e peão contra rei (`pawns.keySquares`)

Pesquisa de 2026-10-05.

## O que o aluno precisa sair sabendo

1. Todo peão tem casas-chave: se o rei do lado forte pisa numa delas, o peão coroa, não importa de quem é a vez (cuidado só com o peão de torre, que tem regras próprias, e com a armadilha do peão de cavalo no canto).
2. Como achar as casas-chave: três casas duas fileiras à frente do peão (ele até a quarta fileira); do peão na quinta em diante, seis casas, as duas fileiras à frente. Na sétima, as casas da sétima e da oitava que encostam no peão.
3. O rei vai na frente do peão; o peão fica atrás, guardado, e só avança quando o rei já tem a casa-chave garantida.
4. A oposição é ferramenta, não objetivo: serve para forçar a entrada numa casa-chave. Se dá para entrar sem ela, entre.
5. Quem defende empata se mantiver o rei na frente do peão sem perder a oposição (e sabe que, com o rei forte na sexta fileira à frente do peão, acabou).

## Como cada fonte ensina

### Wikipedia, "King and pawn versus king endgame" e "Key square"

Abertas em 2026-10-05 (texto-fonte em `action=raw`). Definem casa-chave (ou casa crítica) como a casa que, ocupada pelo rei branco, garante a promoção contra qualquer defesa e com qualquer lado na vez. Trazem os três diagramas da contagem (peão na 2ª–4ª: três casas; 5ª–6ª: seis; 7ª: as vizinhas na 7ª e 8ª), a frase de Averbakh sobre o pai que atravessa a rua à frente do filho, a exceção do peão de cavalo com o rei no canto (afogamento) e o exemplo "qualquer casa-chave, por qualquer caminho" (posição de Jan Drtina, 1908, em que o rei dá a volta pelo outro lado do peão). O artigo também apresenta a observação de Averbakh de que a oposição é um meio e a penetração na casa-chave é o fim, com o diagrama em que tomar a oposição só empata e Kc5 ganha. As "três condições" (rei na frente, oposição, rei na sexta: duas delas bastam) são atribuídas a Müller e Lamprecht. Os exemplos de partidas (Gligorić–Fischer 1959, Kamsky–Kramnik 2009, Panno–Najdorf 1968) vêm daí; as partidas em si não foram abertas.

### Lichess Practice, "Key Squares" (estudo `xebrDvFe`, de arex)

Aberto pela API (`https://lichess.org/api/study/xebrDvFe.pgn`). Um capítulo por fileira do peão (2ª a 7ª), com as casas-chave marcadas em verde e a tarefa "alcance uma casa-chave"; dois capítulos para a exceção do peão de cavalo na sexta; dois para o peão de torre; e um final "Any key square by any route" com a mesma posição de Drtina. É a ordem mais limpa que encontrei para ensinar a contagem, e foi a base da sequência de talks da lição.

### Estudo "Key Squares", de Strategically_Endgam (`LVDJbQe3`)

Aberto pela API. Capítulo 1-1 mostra a posição Rb d5, peão d4, Rp d7: brancas na vez só empatam; pretas na vez perdem, porque o rei branco entra na casa-chave pelo lado que o rei preto deixou (1...Kc7 2.Ke6). Os demais capítulos saem do recorte (peão de cavalo, peão de torre, finais com mais peões, torre). Usei só a posição 1-1.

### Müller e Lamprecht, *Fundamental Chess Endings* (Gambit)

Abri a página da editora (`https://www.gambitbooks.com/books/Fundamental_Chess_Endings.html`): descrição do livro, ISBN 1-901983-53-6, prêmio BCF Book of the Year 2002. Não li o capítulo: o que sei do conteúdo (as três condições, as páginas de casas-chave) veio pela Wikipedia, que o cita. Entra como referência do crédito, sem `where`.

### Dvoretsky, *Dvoretsky's Endgame Manual* (Russell Enterprises)

Abri a busca do site da editora (`https://www.russell-enterprises.com/search?q=dvoretsky`): sexta edição, por Mark Dvoretsky, revista por Karsten Müller e Alex Fishbein, prefácio de Magnus Carlsen. Não li o capítulo de casas-chave; não entra em `references`, só fica registrado aqui.

### De la Villa, *100 Endgames You Must Know* (New in Chess)

A página da editora respondeu com verificação humana e não abriu. Não citei.

## Posições-base

(preenchido depois das sondagens)

## História

- A ideia de casa-chave (ou casa crítica) e a frase de que o rei leva o peão como um pai leva o filho pela rua são atribuídas a Yuri Averbakh pela Wikipedia ("King and pawn versus king endgame").
- A posição em que o rei precisa dar a volta pelo outro lado do peão é de Jan Drtina, 1908 (Wikipedia, mesma página).
- Gligorić–Fischer, Torneio de Candidatos 1959 (Bled/Zagreb/Belgrado): Fischer, de pretas, empatou segurando o rei branco fora das casas-chave com 57...Kb8 (Wikipedia, "Key square").
- Kamsky–Kramnik, Nice 2009 (Amber, às cegas): depois de 125.Kxc6, Kramnik empatou com o rei na frente do peão e a oposição, até o afogamento (Wikipedia, "King and pawn versus king endgame").
- Panno–Najdorf, Buenos Aires 1968: Najdorf perdeu porque o rei branco alcançou a casa-chave g7 do peão de torre (Wikipedia, mesma página). Fica como gancho para a aula do peão de torre.

## Plano da aula

(preenchido depois das sondagens)

## Treino final

`6k1/8/8/8/8/8/3K2P1/8 w - - 0 1`, id `pawn.pawnVsKing.0001` do catálogo (ganho, conferido na tabela).

## Referências

(preenchido depois das sondagens)

## Dúvidas e divergências

(preenchido depois das sondagens)

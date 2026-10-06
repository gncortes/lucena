# O peão de torre: quando empata (`pawns.rookPawn`)

Pesquisa iniciada em 2026-10-05, interrompida antes do dossiê completo.

## Estado (pausado em 2026-10-05)

- Feito: só o spike de pesquisa (fontes abertas e ~40 posições de 3 peças conferidas na tabela do Lichess, com o cache em `tools/.cache/tablebase/`). Nenhum roteiro, exercício ou fala foi escrito.
- Arquivos: só este dossiê, incompleto. Não existem `tools/lessons/endgames/pawns.rookPawn.json`, `assets/lessons/pt|en/endgames/pawns.rookPawn.json` nem o gerado.
- Fontes abertas: Wikipedia "King and pawn versus king endgame" (seção Rook pawn: casas-chave g7/g8 e b7/b8, exceção Rg6+h6 x Rf8 com 1.h7, partidas Panno–Najdorf 1968 e Barcza–Fischer 1959; bibliografia Silman 2007, Müller & Lamprecht 2007, de la Villa 2008) https://en.wikipedia.org/wiki/King_and_pawn_versus_king_endgame e "Key square" https://en.wikipedia.org/wiki/Key_square ; chessgames.com (títulos e resultados das duas partidas: gid=1101724 e gid=1044476); Open Library (catálogo dos livros); página da Gambit de *Secrets of Pawn Endings* http://www.gambitbooks.com/books/Secrets_of_Pawn_Endings.html (New in Chess e Quality Chess bloquearam o acesso).
- Estudos do Lichess abertos pela API: `0lyQgQe7` ("E-09 King and Rook's Pawn vs King - Always the same old two key squares", Audax6: 6 capítulos úteis), `u7je0sry` ("rook-pawn-draw", coachJonZ: `8/8/8/8/8/8/1k5P/6K1 b`, só 1...Kc3 empata), `PAqun1Ja` (Mateo, sem peão de torre), `7TYuzLFP` (só diagramas, multi-peões).
- Veredictos da tabela já conferidos: Panno–Najdorf `8/1k6/8/8/8/7K/7P/8` (brancas: só Kg4/Kh4 ganham; pretas a jogar: só Kc6/Kc7/Kc8 empatam); Barcza–Fischer `8/8/8/p7/k7/4K3/8/8 w` (só Kd2 empata); exceção `5k2/8/6KP/8/8/8/8/8 w` (só h7 ganha); `4k3/7K/8/8/8/8/7P/8 w` (só Kg7/Kg8 ganham); `8/2k5/8/3K4/8/8/7P/8 w` (só Ke6/Ke5); `8/7K/8/8/4k3/7P/8/8 w` (só Kg6); `7K/4k3/8/7P/8/8/8/8 b` (Kf6/Kf7/Kf8); `8/8/7K/4k3/7P/8/8/8 b` (Kf5/Kf6); `2k5/8/1K6/P7/8/8/8/8 b` (só Kb8); `8/K1k5/P7/8/8/8/8/8 w` (empate, afogamento das brancas).
- Treino final previsto: `positionId: null` com `8/1k6/8/8/8/7K/7P/8 b - - 0 1` (empate, pretas a jogar); o catálogo `assets/positions/positions.json` não tem posição de peão de torre.
- Próximo passo: escrever o dossiê completo pelo modelo de `pesquisa.md`, depois a fonte (`tools/lessons/endgames/pawns.rookPawn.json`), as falas pt/en e rodar `build_aula.py pawns.rookPawn` até passar.

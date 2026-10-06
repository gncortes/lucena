# Bispo e cavalo II: do meio do tabuleiro até a borda (`mates.bishopKnight.edge`)

Pesquisa de 2026-10-05.

## O que o aluno precisa sair sabendo

O mate de bispo e cavalo tem três fases: levar o rei até a borda, tirá-lo do canto errado e dar o mate no canto da cor do bispo. Esta aula é só a primeira fase. O rei sozinho não cerca nada: o bispo fecha uma diagonal inteira, o cavalo cobre as casas da outra cor ao lado dela e o rei branco tapa os buracos; juntos formam uma rede de onde o rei preto não volta ao centro. Depois de armada a rede, quem empurra é o rei branco, tomando cada casa que o rei preto abandona. Não se dá xeque por dar xeque (o xeque solta o rei ou pendura a peça), e a regra dos 50 lances cobra cada lance desperdiçado: até grandes mestres empataram este final por isso.

## Como cada fonte ensina

### Wikipedia, "Bishop and knight checkmate"
Divide o mate em três fases (ela mesma diz que a seção segue o método do Seirawan em *Winning Chess Endings*). Na fase 1, a partir do diagrama com rei preto em e3 e as brancas com Re1, Cc1 e Bf1, mostra a linha 1.Bg2 Rd4 2.Rd2 Re5 3.Re3 Rf5 4.Cd3 Rg5 5.Be4 e chama a formação de "muro" (wall): o bispo em e4 e o cavalo em d3, com o rei em e3, impedem o rei preto de voltar ao centro. Depois o rei branco avança (Rd4, Rc5, Rd5, Rd6, Re5, Re6) e o rei preto, que não tem mais o centro, corre para o canto errado (h8). Conferi cada lance dessa linha na tabela do Lichess: todos estão entre os mais rápidos, com folga de um lance. A página também traz a história (Philidor 1749/1777, Delétang 1923), o número máximo de lances (33 com perfeição, citando Müller e Lamprecht) e partidas em que o final apareceu, inclusive as em que grandes mestres não ganharam.

### Lichess Practice, "Checkmating with a Knight and Bishop" (estudo `ByhlXnmM`, de arex)
Segue o método dos triângulos de Delétang. Nos capítulos iniciais, com o rei preto em e8 e as brancas em e1, f1 e g1, o rei branco vai primeiro ao centro ("Black will first try to stay in the center"), e o texto enfatiza que todas as peças são precisas e que o rei preto, sem o centro, corre para o canto errado. O capítulo "Epic Failure" mostra a partida Ushenina–Girya, em que as brancas chegaram ao final e empataram pela regra dos 50 lances.

### Estudo "Endings / Technique: Mating with Bishop and Knight" (`KPZZVr1H`, de Schnabelwolke)
Vinte e dois capítulos, em alemão e inglês. O capítulo "King in the Center" (brancas Rg2, Bg1, Ch1; rei preto em e4) é uma fase 1 completa: o rei branco sobe (Rg3, Rf3, Rf4, Re4), o cavalo entra (Cg3, Cf5+), o bispo fecha a diagonal (Bc5) e o rei preto está na borda no lance 10. O estudo também traz as "posições máximas" (as de mate mais longo).

### Estudo "A+C. Método de la W y Método Deletang." (`PZZ1RLdX`, de Gabriel Zárate)
Em espanhol. O segundo capítulo parte de uma posição em que as peças brancas estão descoordenadas (Rh1, Ca1, Ba8; rei preto em d4) e comenta os princípios da primeira fase: ganhar espaço com o rei sempre que possível, e a dupla bispo e cavalo ("Bd5 ... barrera") formando a barreira que limita o rei defensor. A posição entra como posição-base, com crédito; não virou exercício.

### Müller e Lamprecht, *Fundamental Chess Endings* (Gambit, 2001)
Não abri o livro. Conferi título, autores, editora e ano na página do Google Books; a Wikipedia o cita como fonte dos 33 lances e da frequência do final (uma vez a cada 6 000 partidas). Entra nas referências como a obra de consulta que o aluno pode procurar, sem número de página.

## Posições-base

| id | FEN | Quem joga | Tabela | Crédito |
|---|---|---|---|---|
| start | `8/8/8/8/8/4k3/8/2N1KB2 w - - 0 1` | brancas | ganha, DTM 59 | diagrama inicial da fase 1 na Wikipedia (método de Seirawan) |
| wall | `8/8/8/6k1/4B3/3NK3/8/8 b - - 0 1` | pretas | perdida, DTM 50 | o "muro" após 5.Be4 (Wikipedia) |
| centre | `8/8/8/8/4k3/8/6K1/6BN w - - 0 1` | brancas | ganha, DTM 59 | capítulo "King in the Center" do estudo de Schnabelwolke |
| far | `B7/8/8/8/3k4/8/8/N6K w - - 0 1` | brancas | ganha, DTM 61 | segundo capítulo do estudo de Gabriel Zárate |

## História

- Philidor descreveu o mate em *L'Analyse des Échecs* (1749) e, na atualização de 1777, a rota do cavalo hoje chamada de manobra em W (Wikipedia).
- Daniel Delétang publicou em 1923, em *La Stratégie*, o método dos triângulos; algumas ideias vêm de 1780 (Wikipedia).
- Com jogo perfeito, o mate sai em no máximo 33 lances de quase qualquer posição; o final aparece cerca de uma vez a cada 6 000 partidas (Wikipedia, citando Müller e Lamprecht).
- Kempinski–Epishin, Bundesliga 2001: o lado forte (Epishin) não conseguiu o mate e a partida acabou em afogamento, depois de o lado fraco já poder pedir o empate pelos 50 lances (Wikipedia).
- Ushenina–Girya, Grand Prix feminino de Genebra, 2013: Ushenina começou bem, perdeu duas chances de continuar a manobra e a partida empatou pela regra dos 50 lances (Wikipedia; a partida inteira está no capítulo "Epic Failure" do estudo do Lichess Practice).
- Karttunen–Rasik, Copa Europeia de Clubes 2003, e Ljubojević–Polgár (às cegas, Amber 1994) são exemplos de quem ganhou (Wikipedia).
- Tal Shaked venceu Morozevich com este mate na penúltima rodada do Mundial Juvenil de 1997 e levou o título (Wikipedia).

## Plano da aula

Lição:
1. `intro` (talk): as três fases; esta aula é a primeira; o rei preto quer o centro.
2. `net` (talk): a rede pronta (posição `wall`): bispo na diagonal, cavalo nas casas da outra cor, rei tapando os buracos.
3. `build1` e `build2` (move): o aluno arma a rede do zero, 1.Bg2 a 5.Be4.
4. `push` (talk) e `push1`, `push2` (move): o rei empurra, 6.Rd4 a 11.Re6, e o rei preto chega à borda.
5. `defence` (talk): a melhor defesa, ficar no centro e depois correr para o canto errado.
6. `traps` (talk): peça pendurada no xeque, o rei que escapa pela casa esquecida, o afogamento e os 50 lances.
7. `summary` (talk): as três regras.
8. `finish` (play): terminar uma posição contra a máquina.

Exercícios (ver a tabela no JSON): dos reconhecimentos de uma estrela (fechar a rede, o lance do rei) às posições de longe com três estrelas.

## Treino final

`8/8/3N4/3B4/4K3/7k/8/8 w - - 0 1`, id `knightBishop.knightBishopVsKing.0001` do catálogo. Tabela: ganha, DTM 19. Observação: nessa posição o rei preto já está na borda (h3), perto do canto certo (h1, da cor do bispo); é um treino do final inteiro, não da fase desta aula. Mantive porque é a posição do catálogo que liga a aula ao speedrun; se o Gabriel preferir um treino que comece com o rei no centro, o catálogo não tem uma assim e seria preciso acrescentar.

## Referências

- `wikipedia` (web): "Bishop and knight checkmate", https://en.wikipedia.org/wiki/Bishop_and_knight_checkmate. Como consultei: página e wikitext abertos em 2026-10-05.
- `practice` (study): arex, "(BETA) Lichess Practice: Checkmating with a Knight and Bishop", https://lichess.org/study/ByhlXnmM. Como consultei: PGN pela API do Lichess.
- `schnabelwolke` (study): Schnabelwolke, "Endings / Technique: Mating with Bishop and Knight", https://lichess.org/study/KPZZVr1H. Como consultei: PGN pela API.
- `zarate` (study): Gabriel Zárate, "A+C. Método de la W y Método Deletang.", https://lichess.org/study/PZZ1RLdX. Como consultei: PGN pela API.
- `muller` (book): Karsten Müller e Frank Lamprecht, *Fundamental Chess Endings*, Gambit, 2001. Como consultei: ficha no Google Books; o conteúdo, só pelo que a Wikipedia cita.
- `tablebase`: Lichess tablebase (Syzygy), https://tablebase.lichess.ovh. Toda posição e todo lance da aula passaram por ela (script `build_aula.py`); na exploração de candidatos usei localmente as tabelas Gaviota (DTM) baixadas do próprio Lichess, e as posições escolhidas foram conferidas de novo na API.

## Dúvidas e divergências

- Na linha da Wikipedia, a tabela prefere em dois pontos outra defesa preta (7...Rf6 em vez de 7...Re7, mesma distância; 11...Rf8 em vez de 11...Rg8, um lance mais longa). Na lição as respostas pretas são fixas (as da Wikipedia), para contar a história do muro e do empurrão; nos exercícios a defesa é a da tabela.
- Em bispo e cavalo quase todo lance ganha: `win` não ensina nada e `best` (folga de um lance) ainda aceita 8 a 15 lances em muitas posições. Os exercícios foram escolhidos em posições em que o lance da técnica é o único mais rápido, ou um de dois; onde a imagem da rede importa mais que a contagem, a regra é uma lista dos lances que fecham a rede, todos conferidos como ganhadores.
- A posição do treino final começa com o rei preto na borda (ver acima).
- Não li nenhum dos livros; a página da New in Chess (de la Villa) pede verificação humana e não abriu.

## Estado (pausado em 2026-10-06)

- Feito: dossiê (este arquivo), fonte `tools/lessons/endgames/mates.bishopKnight.edge.json` (12 passos, 10 exercícios: e01–e03 com 1 estrela, e04–e07 com 2, e08–e10 com 3; total 20, `passScore` 12) e falas completas em `assets/lessons/pt/endgames/` e `en/endgames/` (58 chaves iguais nos dois idiomas). O gerado `assets/lessons/endgames/` ainda não existe.
- `build_aula.py` rodou uma vez e parou com 3 problemas: (1) `history` em pt e en contém "o mate em 1749" / "the mate in 1749", que o script lê como "mate em N": trocar por "descreveu este mate no tratado de 1749"; (2) `ex.e09`, lance 3: a tabela do Lichess responde 1...Rd2 (empate de distância com 1...Rc4, que eu previa) e a linha diverge: fixar as respostas em UCI (`reply: "c3c4"` e depois `"c4b5"`, ambas de distância igual à melhor) ou trocar o exercício; (3) `ex.e10`: a resposta automática também divergiu (1...Rb5 em vez de 1...Rd6), os lances ensinados ainda passam, mas a solução escrita descreve a outra linha: fixar `reply: "c5d6"` e `"c5..."` conforme a linha do dossiê e conferir.
- Candidatos conferidos localmente com as tabelas Gaviota do Lichess (DTM em meios-lances; bateu com a API nas posições testadas): e04 Bd4 (único, folga 13), e05 Re3 (único, 17), e06 Cf4 (único, 21), e07 Rd3 (único, 23), e08 Bc4/Rc3, e09 Cd3+/Bd4/Rd5, e10 Rc3/Cg6/Bc4.
- Próximo passo: corrigir os três pontos acima, rodar `tools/.cache/venv/bin/python .claude/skills/aula-final/scripts/build_aula.py mates.bishopKnight.edge` até passar (cache em `tools/.cache/tablebase`; no 429 esperar 60 s) e reler o relatório como aluno (as explicações de e09 e e10 têm que bater com as respostas da tabela).

# Fluxo de reescrita de uma lição (T61)

Como refazer a **lição** de uma aula já existente, uma aula por vez, com agentes. Os exercícios dessas aulas
já estão bons (T58: um por ideia, régua alta; o Gabriel aprovou) e **não se mexe neles**; a premissa é a
contrária: a partir dos exercícios, ver se a lição ensina o que eles cobram. Se um exercício parecer errado,
raso ou fora do tema, o revisor relata na seção "Exercícios: dúvidas" do relatório e o Gabriel decide.

Invocação: `/aula-final licao <id>`. Ordem das aulas: tabela no fim deste arquivo.

## Onde fica cada coisa

| O quê | Onde |
|---|---|
| Régua da lição, método em nove passos, erros já vistos | `licao.md` |
| Formato da fonte (`ref` nos passos, `url` em `game`, `id#ply`) | `formato.md` |
| Links de partida e estudo | `pesquisa.md`, seção Links |
| Agente revisor (só relata) | `.claude/agents/revisor-licoes.md` |
| Despejo mecânico da aula | `tools/lessons/dump_lesson.py <id> --links` |
| Relatório do revisor (1.ª e 2.ª passadas) | `docs/aulas/LICAO-<id>.md` (fora do git) |
| Dossiê da aula, seção "Lição refeita (T61, <data>)" | `docs/aulas/<id>.md` (fora do git) |

Preparo do worktree: `python3 -m venv tools/.cache/venv && tools/.cache/venv/bin/pip install chess` (ou copiar
`tools/.cache` de outro worktree, que traz o cache da tabela), `python3 tools/gen_pseudo_l10n.py && flutter gen-l10n`.
Nenhum agente usa git; quem orquestra confere e commita. Cada agente guarda scripts próprios numa subpasta
com o id da aula no scratchpad da sessão (passe o caminho no pedido), nunca dentro do repositório.

## Os quatro passos de uma aula

| # | Passo | Modelo | Pedido ao agente (general-purpose) |
|---|---|---|---|
| 1 | 1.ª passada do revisor | Opus (Fable só se a tabela abaixo marca) | "Você é o agente `revisor-licoes`. Leia a sua definição em `.claude/agents/revisor-licoes.md` e siga-a à risca: só relata, nunca edita aula nem usa git. Worktree `<caminho>`. Aula: `<id>`. Escreva `docs/aulas/LICAO-<id>.md`. Comece por `tools/.cache/venv/bin/python tools/lessons/dump_lesson.py <id> --links`. A triagem (`fluxo-licoes.md`, tabela) já apontou: <linha da tabela>. Partidas reais só de fonte aberta que você abrir (Wikipedia `?action=raw`, estudos públicos do Lichess via `https://lichess.org/api/study/<id>.pgn`, arquivos PGN públicos como `pgnmentor.com`), conferidas com python-chess, link no formato "Links" de `pesquisa.md`. O plano de reescrita deve ser detalhado o bastante para um modelo menor seguir sem pensar muito (FEN de cada passo, lances dos demos em SAN, o que cada fala diz). Tabela: 1 s entre consultas, cache em `tools/.cache/tablebase`. Scripts seus em `<scratchpad>/<id>/`. Na conversa, responda só com a nota geral, as três faltas principais e o caminho do relatório." |
| 2 | Reescrita | Opus (Fable só se marcado) | "Leia e siga `.claude/skills/aula-final/licao.md` (as seis regras e **"Como reescrever uma lição, passo a passo"**) e `formato.md`. Aula: `<id>`. Worktree `<caminho>`, sem git. O plano do revisor está em `docs/aulas/LICAO-<id>.md`: siga-o; se discordar de um ponto, faça do seu jeito e registre no dossiê. Só edite a fonte (`tools/lessons/endgames/<id>.py` se existir, senão o `.json`), as falas `assets/lessons/{pt,en}/endgames/<id>.json`, o gerado via `build_aula.py` e o dossiê `docs/aulas/<id>.md`. Não toque nos exercícios, `passScore`, chaves `ex.*`, `index.json`, `trail.json`, `lib/`, `test/`. Quando uma posição vem de partida, conte a partida (quem, onde, como chegaram ali, o que o mestre viu, o que aconteceu), com `ref` no passo e `url` na referência. Scripts seus em `<scratchpad>/<id>/`. No fim, relate curto e em tabela: partes (id, ideia, minutos), partidas/estudos com link, cobertura, o que o Stockfish julgou, onde saiu do plano, dúvidas." |
| 3 | 2.ª passada do revisor | Sonnet; Opus se a 1.ª passada achou erro de xadrez ou a aula tem partidas reais | Igual ao passo 1, mais: "**segunda passada**: a lição foi reescrita (o dossiê, seção 'Lição refeita', diz onde saiu do plano). Acrescente a seção `## Segunda passada (<data>)` ao mesmo arquivo LICAO: nota nova geral e por regra, tabela de cobertura atualizada, o que ainda falta (erro/ajuste/nota, com a chave do passo) e, para toda correção mecânica (uma palavra, lance citado errado, pt ≠ en, dica que entrega o lance), o texto exato que está e o que deveria estar. Confira de verdade: jogue cada `demo` e `move` com python-chess (a fala do lance N explica o lance N), afirmações fortes contra a tabela, urls das partidas reproduzindo os FENs (o dump faz). Na conversa: a nota nova, o que falta em até cinco linhas e o caminho do relatório." |
| 4 | Integração (quem orquestra) | — | Aplicar as correções mecânicas do relatório com o texto exato (script de substituição com assert; regerar pelo `.py` e `build_aula.py <id>`); `check_variety.py <id>`; `dump_lesson.py <id> --links` sem aviso e todo link "bate"; `tools/lessons/check_numbering.py <id>` zerado (lance citado sempre numerado); `flutter test test/data/repositories/endgames/endgame_lessons_content_test.dart`; `git add` só dos arquivos da aula; commit `Lição <id>: <o que mudou> (nota X → Y)`. O que é julgamento (trocar posição, estrelas, cortar exercício) vai para o Gabriel, anotado na tabela abaixo. |

Pode haver várias aulas em andamento ao mesmo tempo, cada uma com o seu agente; nunca dois agentes na
mesma aula. Até uns 6 agentes com a tabela do Lichess ao mesmo tempo.

## O que o piloto ensinou (Ruptura, Philidor e Lucena, 2026-10-09)

- O revisor acha de 2 a 5 ideias cobradas sem parte por aula; a reescrita leva uma lição de 18 min a 45.
- Partidas reais existem para a maioria dos temas, mas o PGN completo em fonte aberta nem sempre: o que
  funcionou foi estudo público do Lichess com a partida inteira e o arquivo PGN público do PGN Mentor
  (`pgnmentor.com/players/<Sobrenome>.zip`); a Wikipedia costuma ter só o fragmento. Sem PGN completo,
  o `ref` aponta o capítulo do estudo que tem a posição.
- Demo de erro começa depois do lance errado (o script reprova lance do aluno que perde) e a fala de
  abertura nomeia o erro.
- A 2.ª passada sempre acha 2 ou 3 correções mecânicas de texto (afirmação "qualquer casa serve", "mate"
  que a torre tapa, dica que entrega o lance, pt ≠ en): não pular.
- Posição de prática da lição que repete a estrutura de um exercício derruba o exercício: conferir com
  `check_variety.py` (coluna Lição) e com o olho.
- Mesmo a reescrita no Fable deixou, em Lucena, 12 falas de demo só com o lance e 6 falas citando lance
  ilegal (rei indo a casa que a torre domina) ou "a mesma posição" num ply diferente: a 2.ª passada precisa
  jogar cada lance citado com python-chess, e a aplicação das correções cabe num agente Opus com o texto
  exato do relatório (Lucena: 20 correções em 4 min).
- O revisor da 2.ª passada também aponta exercício encostado demais na lição nova (Lucena e16, e15): vai
  para o Gabriel, não se mexe.
- Rei e peão e casas-chave (2026-10-09) fizeram o ciclo inteiro sem Fable: 1.ª passada e reescrita no Opus,
  2.ª passada e aplicação das correções no Sonnet. O Sonnet achou 3 e 4 frases erradas com texto exato,
  conferiu tabela, PGN e pt = en com scripts; a aplicação levou 1 min. É o padrão daqui em diante; Fable
  só nas marcadas.
- Pedido de aplicação de correções: dizer "só o que tem texto exato está → deveria; nada de passo novo;
  assert antes de trocar; o que não bater, relate". A numeração dos itens no relatório e no pedido pode
  divergir: cite as chaves, não os números.

## Ordem das aulas e andamento

Critério: nota da triagem (D antes de C), depois o peso do final na prática. Modelo: Opus, salvo "Fable"
(composição, zugzwang recíproco, casas correspondentes, partida difícil de achar). Detalhe da triagem em
`docs/aulas/TRIAGEM-LICOES*.md` (fora do git); a linha aqui é o que o revisor precisa saber.

**2026-10-09, pedido do Gabriel: as aulas marcadas Fable ficam puladas** (#8, 9, 16, 17, 21, 24, 27, 28, 33, 34, 35, 37); a esteira segue só nas de Opus, na ordem.

**Setas (T62):** caminho reto é uma seta só, nunca várias emendadas.

**Régua mínima: B.** Se uma aula do Opus terminar o ciclo (reescrita + 2.ª passada + correções) ainda em C, não se commita como feita: anota-se "C no Opus → Fable" no andamento e ela vai para a fila do Fable.

| # | id | nota | ideias sem parte | modelo | o que falta (triagem) | andamento |
|---|---|---|---|---|---|---|
| 0 | pawns.breakthrough | C | 5 | Fable (piloto) | e11 (fixar antes de romper) sem parte; partida com link | **feita: B**, commitada |
| 1 | rook.lucena | D | 5 | Fable (piloto) | sem demo; peão de torre, zugzwang da torre, Andersson–Åkesson | **feita: B**, commitada (lote2) |
| 2 | rook.philidor | D | 4 | Opus | xeques por trás nunca em demo; laterais, 3.ª fileira, rei primeiro | **feita: B**, commitada (lote2) |
| 3 | basics.kingPawn | C | 3 (+2) | Opus | sem demo; Matanović, diagonal do rei, tempo do peão, peão de cavalo; Barcza–Fischer | **feita: B**, commitada (lote2); ciclo todo sem Fable |
| 4 | pawns.keySquares | D | 5 | Opus | peão de cavalo, peão travado, Drtina, zugzwang mútuo; Kamsky–Kramnik | **feita: B**, commitada (lote2); ciclo todo sem Fable; e17 pendente |
| 5 | pawns.distantOpposition | D | 4 | Opus | oposição lateral, peão de reserva (Grigoriev), contorno; partida real | **feita: B**, commitada (lote2); Carlsen–So 2017, Euwe–Whitaker 1928; e13 (crédito Capablanca ex. 28) pendente |
| 6 | rook.backRank | D | 2 (+1) | Opus | `corner` é quatro falas seguidas; "rei primeiro" e peão na 7.ª | **feita: B**, commitada (lote2); Carlsen–Nakamura, Aronian–Duda e Ivanchuk–Grischuk com link; `rookPawn` ~3,3 min, demos `homeCheck`/`gOne` encostados no e12/e16: Gabriel |
| 7 | rook.shortSide | D | 4 | Opus | sem demo; troca de flanco e torre que tapa os xeques; Carlsen–Aronian | **feita: A**, commitada (lote2); Ward–Arkell 1994, Aronian–Carlsen 2006; e08/e12 parecidos, e10 e e12 solução, demos `d_blockF`/`flankNow` encostados no e09/e12: Gabriel |
| 8 | rookPawns.vsPawn | D | 4 (+2) | Fable | sem demo; escada do rei, afogamento, xeque que não ganha tempo; Saavedra, Kamsky–Bacrot || **feita: B** (Fable, branch tarefa/T61-licoes-fable); Kamsky–Bacrot 2006, Bacrot–Robson 2011 |
| 9 | pawns.race | C | 4–5 | Fable | rei que barra, xeques que ganham a dama, coroar com xeque, tapar a linha; Petrosian–Fischer || **feita: B** (Fable, branch tarefa/T61-licoes-fable); Petrosian–Fischer 1958, Nesterov–Zolnierowicz 1993 |
| 10 | basics.rookMate | C | 2 | Opus | sem demo, falas empilham variantes; rei que corre, tempo da torre atacada | **feita: A**, commitada (lote2); Nakamura–Iniyan 2026, Khagan Ahmad–Nakamura 2025, Capablanca (Gutenberg); práticas `quietMove`/`stalemateMove`/`farMove`/`runMove` perto de e12/e14/e17/e16: Gabriel |
| 11 | basics.queenMate | C | 2 (+1) | Opus | sem demo, partes com 2–3 ideias; lance de espera, lado da caixa | **feita: B** (limite de A), commitada (lote2); Carlsen–Anand 2006, Nakamura–Abarca Gonzalez e Nakamura–Andreikin 2022, Ding–Le Quang Liem 2017 com link |
| 12 | pawns.outsidePasser | C | 3 | Opus | Fischer–Larsen real com link; defesa contra o distante; corrida depois da isca | **feita: B**, commitada (lote2); Fischer–Larsen 1971 com link, estudo de fabian1999; ~45,8 min e parte `escort` com 2,8 min: Gabriel |
| 13 | pawns.protectedPasser | C | 3 (+2) | Opus | dois passados e a conta do quadrado; Dedrle; dividir `limits`; partida | **feita: B**, commitada (lote2); Jakovenko–Akobian 2000, Walker, estudos de Chessforall321 e IsaacWiebeSupreme com link; `twoPassers`/`d_baseInside` perto de e08/e15 (revisor: não encostam demais) |
| 14 | pawns.rookPawnDraw | C | 3–4 | Opus | qual peão sobra na troca; tempo do peão que cai; Panno–Najdorf, Barcza–Fischer | **feita: B**, commitada (lote2); Panno–Najdorf 1968, Barcza–Fischer 1959 com link; `theTurn` perto do e17 (revisor: não encosta demais) |
| 15 | pawns.triangulation | C | 2 | Opus | perder um tempo no caminho; casas correspondentes de longe; Alburt–Kasparov | **feita: A**, commitada (lote2); Alburt–Kasparov 1978 com link, análise Shirov–Grischuk (Wikipedia); `defend` encosta no e13 (espelho), e04/e09/e11 com dúvidas: Gabriel |
| 16 | pawns.shoulder | C | 3 (+2) | Fable | ombro + quadrado (Réti/Duras/Grigoriev/Mandler); demos; partida | |
| 17 | pawns.reti | B | 1 | Fable | Réti com peça no caminho (Sarychev); Yates–Marshall com link | |
| 18 | rook.behindPasser | C | 6 (+2) | Opus | exceções da regra só nos exercícios; falas vazias em `d_walk`; Kramnik–Beliavsky | **feita: B**, commitada (lote2); Alekhine–Capablanca 1927, Anand–Kramnik 2007, Kramnik–Beliavsky 1993 com link; Short–Yusupov 1984 (e10) com link no relatório; `d_raceError`/`d_orderError` começam com lance das pretas: Gabriel |
| 19 | rook.cutOff | C | 2 (+2) | Opus | parte com Uhlmann–Gulko ou Pein–Ward; tempo do peão; exceções no resumo | |
| 20 | rook.frontal | C | 1 (+2) | Opus | partida real; corte lateral (Th5!) | |
| 21 | rookPawns.vsTwo | C | 8 | Fable | ritmo bom, mas os oito exercícios cobram o que a lição não ensina | |
| 22 | pawns.minedSquares | C | 2 | Opus | zugzwang de meio ponto (Hooper); quando a mina não decide; trebuchet | |
| 23 | pawns.spareTempi | C | 1 | Opus | Bischoff–Nunn com link; defesa (Maiselis); `early` em demo | |
| 24 | pawns.correspondingSquares | B | 1 (+1) | Fable | numeração em demo (um par por fala); triangulação separada; Rösch–Mast | |
| 25 | queen.vsPawn | C | 3 | Opus | sem demo; peão de bispo na 6.ª (Alatortsev), deixar coroar com mate, cravada || sessão lucena-8f (worktree lucena-t63, branch tarefa/T63-licoes-opus) |
| 26 | queen.vsPawn.draws | C | 4 | Opus | bloqueio calmo, troca na coroação, subpromoção, peão a mais; 14 falas vazias; ~52 min || sessão lucena-8f (worktree lucena-t63, branch tarefa/T63-licoes-opus) |
| 27 | minor.wrongBishop | C | 3 | Fable | transformação da estrutura, rei fechando a porta, peões g+h; Fischer–Taimanov | |
| 28 | minor.knightVsPawn | C | 3 | Fable | ~66 min e 28 falas vazias; dois peões, desvio, recuo do cavalo; Nogueiras–Gongora | |
| 29 | basics.twoBishops | C | 2 (+2) | Opus | moves ditados no lugar de demo; retirada longa do bispo; parede do centro || **feita: B** (lucena-8f, tarefa/T63-licoes-opus, 51e1d11e); Nakamura–Sheehan 2024 |
| 30 | queen.vsRook.philidor | C | 2 | Opus | lance calmo de zugzwang; torre desesperada; traps só em talk; partida || **feita: B** (lucena-8f, tarefa/T63-licoes-opus, e00e8ab9); Gelfand–Svidler 2001, Carlsen–Le Tuan Minh 2024, Svidler–Howell 2010, Aronian–Vachier-Lagrave 2017, Ivanchuk–Lautier 1995 |
| 31 | queen.vsRook.approach | C | 2 | Opus | sem demo, ~54 min; do centro até a borda; ameaça tripla; Browne–Belle || **feita: B** (lucena-8f, tarefa/T63-licoes-opus, 027f5e86); Stefánsson–Müller 1992 |
| 32 | queen.vsRook.thirdRank | C | 2 | Opus | sem demo, ~58 min; dama prende o rei, dama atrás do rei; Morozevich–Jakovenko || **feita: B** (lucena-8f, tarefa/T63-licoes-opus); Morozevich–Jakovenko 2006, Browne–Belle 1978; a pedido do Gabriel, demo do e16 e e12/e15/e19 novos |
| 33 | queen.vsRookPawn | C | 4 | Fable | torre que espera longe, Laza, rei dentro, estudos da 7.ª; Carlsen–Matlakov | |
| 34 | mates.twoKnightsPawn | C | 2 (+2) | Fable | triangulação (Chéron), captura certa (Horwitz–Kling); Karpov, Anand | |
| 35 | mates.bishopKnight.w | C | 3 | Fable | W ditado em move, sem demo; redes c7/c8 e de Seirawan; links | |
| 36 | mates.bishopKnight.edge | C | 3 (+2) | Opus | sem demo; ordem dos lances, peças atacadas, desenrolar; defesas só em talk || **feita: B** (lucena-8f, tarefa/T63-licoes-opus, 270f5237); Ljubojević–Polgár 1994 |
| 37 | mates.bishopKnight.full | C | 3 (+1) | Fable | sem demo; canto errado (Kempinski), Delétang do centro, Be4+ | |

Pendências de julgamento para o Gabriel: `pawns.distantOpposition` e13 é o exemplo 28 de Capablanca deslocado uma coluna e a solução credita um estudo do Lichess (texto pt/en pronto no LICAO): trocar o crédito ou deixar; `pawns.breakthrough` parte "Resumo" com 3,5 min (régua pede 4);
`rook.lucena` e16 e e15 encostados na lição nova (a parte `zugzwang` mostra 2 dos 3 lances do e16; o e15 é
quase o `rookPawnDemo`) e e14 com o corte Td7+ não ensinado: trocar os exercícios de posição ou deixar; 23 soluções de exercícios (`ex.*.solution`) dizem "a tabela aceita…", que a regra das
falas proíbe; `pawns.keySquares` e17 é o tema de `pawns.correspondingSquares` (a aula seguinte): mover o e17
para lá (a aula fica com 6 exercícios, 13★, mínimo 8) ou aceitar uma lição acima de 45 min.

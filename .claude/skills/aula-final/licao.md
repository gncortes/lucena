# O que faz uma lição boa

A régua dos exercícios (`formato.md`, Estrelas) já é alta. Esta é a régua da **lição**: as partes que vêm
antes do teste final. Veio da T61 (2026-10-09), depois de o Gabriel fazer a aula de Ruptura: "gostei dos
exercícios, mas a aula ficou mais ou menos [...] tem um exercício em que você deixa um peão na frente do
outro para depois romper; faltou a lição devagar nesse ponto". O exercício (b5! antes de c5) testava uma
ideia que nenhuma parte ensinava.

## As seis regras

1. **Toda ideia cobrada é ensinada.** Cada exercício tem uma ideia (a tabela de ideias do dossiê). Para cada
   ideia há uma parte, ou ao menos um `demo` seguido de `move`, que a ensina **antes** do teste. Vale também
   para o 3★: a surpresa do estudo é a profundidade, não um tema que o aluno nunca viu. O dossiê traz a
   tabela `exercício → ideia → parte que ensina`.
2. **Uma ideia por parte, no ritmo pensar → ver → jogar.** A parte começa com o aluno pensando sozinho
   (`think`), explica o porquê (`talk`), mostra a técnica lance a lance (`demo`, uma fala por lance, com o
   porquê de cada um) e fecha com o aluno jogando (`move` ou `play`). Fala que empilha três variantes
   ("se toma com a, c6; se toma com c, a6; se não toma...") não ensina: cada variante que importa vira um
   `demo` ou um `move`. Fala de `demo` que só diz o lance ("a7.") é fala perdida: diz o que ele ameaça, o que
   o outro lado não pode mais fazer, ou o que aconteceria sem ele.
3. **Do simples ao complexo, com a ponte dita.** A primeira parte é a forma mais limpa do tema; cada parte
   seguinte acrescenta um elemento (o rei mais perto, a ala, a defesa, a ordem dos lances) e diz o que muda
   em relação à anterior. A parte das defesas e armadilhas vem depois de a técnica estar firme. O resumo
   final tem duas ou três regras que o aluno leva para a partida, com as palavras da lição.
4. **Partidas e estudos, com link.** Toda posição que vem de uma partida jogada ou de um estudo publicado diz
   isso na fala ("é o final de X contra Y, torneio, ano") e tem `ref` no passo apontando a referência, que
   tem `url`: a partida abre no Lichess naquela posição e o aluno pode ir ao começo dela (ver "Links" em
   `pesquisa.md`). Uma aula tem ao menos uma partida real quando o tema aparece na prática de mestres (quase
   todos aparecem); posição própria é para o que as fontes não cobrem. A história ("Sobre este final") cita
   quem achou a posição e em que partida o tema decidiu, cada fato com a fonte.
   **Lance de partida sempre com o número** (pedido do Gabriel, T60): ao comentar uma partida, o lance jogado
   e as variantes saem numerados como nos livros: "Capablanca jogou 39.f5?, e depois de 39...gxf5 40.h5...",
   "41.h6!! ganha", "41.g6? hxg6 42.h6". Nunca "jogou f5" solto. A numeração sai do PGN do `url`.
   **Vale para toda fala, não só partida** (pedido do Gabriel, 2026-10-09): lance citado em passo, demo, enunciado, dica ou
   solução sai numerado ("1.Rf7! fecha g8; depois de 1...Rh7, 2.e4 corre"; "Com 1.Rc4? ..."). Casa solta não.
   - Posição de **partida real** (com link para abrir no Lichess): a numeração é a do lance real da partida (tirada do PGN).
   - Posição **montada ou de estudo**: começa em 1.
   O revisor reprova a lição com lance sem número ou com número que não bate com a partida.
   **O nome da partida final é "desafio prático"**: nunca "partida contra a máquina" nas falas.
5. **Cada fala diz uma coisa, e o porquê.** O Viktor é paciente e direto: explica a razão antes do lance,
   nomeia a ideia com o nome que os livros usam, e cita o mestre quando ajuda. Dicas do `think` vão da mais
   vaga à mais clara e nenhuma dá o lance. As setas e casas mostram o que a fala diz. pt e en dizem o mesmo.
6. **Partes bem divididas.** O relatório do `build_aula.py` mostra o tempo de cada parte. O que conta é a
   divisão: uma ideia por parte, partes de 4 a 8 minutos. O total da lição não tem teto (pedido do Gabriel,
   2026-10-10: "não tem problema a minutagem, contanto que estejam bem divididas"); não se corta parte boa
   só para caber em 45 minutos. Parte com dois `think` ou com duas ideias se divide; parte com um `talk` e
   um `move` só, sem `demo`, costuma estar rasa.

## Como o revisor nota uma lição

Nota de A a E por regra e uma nota geral, com a tabela `exercício → ideia → parte que ensina` (a coluna
vazia é a falta mais grave) e o **plano de reescrita**: as partes que ficam, as que se dividem e as novas,
cada uma com a ideia, a posição (FEN) e os passos; e as fontes a procurar (partida, estudo). Quem reescreve
segue o plano; o que discorda do plano vai no dossiê.

| Nota | Significa |
|---|---|
| A | todas as ideias cobradas têm parte; ritmo e partidas no lugar; só retoques de texto |
| B | uma ideia sem parte ou uma parte densa demais; o resto no lugar |
| C | duas ou mais ideias sem parte, ou nenhuma partida real, ou falas de demo vazias |
| D | a lição é uma sequência de `talk` com variantes empilhadas; os exercícios cobram o que ela não ensina |
| E | errada no xadrez ou fora do tema |

## Como reescrever uma lição, passo a passo (para qualquer modelo)

O método é mecânico de propósito: o Opus e o Sonnet fazem a maior parte; o Fable fica para o que a triagem
marcou (tema com composição, zugzwang recíproco, casas correspondentes, ou partida difícil de achar).

1. **Despeje a aula**: `tools/.cache/venv/bin/python tools/lessons/dump_lesson.py <id> --links`. Sai tudo
   o que precisa ser lido: cada exercício com a linha em SAN, enunciado, dica e solução; cada parte com os
   passos e a fala de cada lance de `demo` (marca as vazias); o tempo por parte; o esqueleto da tabela de
   cobertura; os avisos (fala que cita motor/tabela/Lichess, chave só num idioma, partida sem url, passo
   sem `ref`); e, com `--links`, se a url da partida reproduz o FEN de cada passo que a aponta.
2. **Entenda cada exercício antes de tocar na lição.** Para cada um, escreva numa linha **a ideia que ele
   cobra** (o que o aluno precisa saber para achar o lance: "fixar o peão antes de romper", "não tomar,
   passar", "rei na frente do passado adversário antes de romper"). Use a solução e a linha em SAN; se a
   solução cita uma decisão ("c5 primeiro empata"), a ideia é essa decisão. Dois exercícios podem ter a
   mesma ideia em profundidade diferente; o 3★ costuma juntar duas.
3. **Preencha a tabela de cobertura** `exercício → ideia → parte que ensina` com a lição atual. Toda
   linha com a última coluna vazia é uma parte nova (ou um `demo` + `move` novos numa parte existente, se
   a ideia for pequena e a parte tiver espaço). Linha com "só uma fala" conta como vazia: uma frase dentro
   de um `talk` não ensina.
4. **Desenhe as partes** (o plano do revisor já traz; confira contra a sua tabela): uma ideia por parte, na
   ordem do simples ao complexo, cada uma com `think` (1/3/5 min; a posição-chave da ideia, com 1 a 3 dicas
   da mais vaga à mais clara, nenhuma com o lance) → `talk` (o porquê, com setas e casas) → `demo` (a técnica
   lance a lance; uma fala por lance dizendo o que ele ameaça ou impede; corte em 5 a 7 lances) → `move` ou
   `play` (o aluno repete, com `hint` e `done`). Variante que importa ("se toma com o outro peão") vira um
   `demo` ou `move` próprio, não uma frase. Demo de um erro: começa **depois** do lance errado (o script
   reprova lance do aluno que joga fora o objetivo) e mostra só a punição.
5. **Ache a partida.** Procure uma partida real em que o tema decidiu, só em fonte aberta que você abriu
   (Wikipedia: `?action=raw`; estudos públicos do Lichess: busca em `https://lichess.org/study/search?q=…`
   e PGN em `https://lichess.org/api/study/<id>.pgn`). Reproduza o PGN com python-chess até o ply da
   posição e monte a url (`pesquisa.md`, Links). Uma referência `game` por partida; o passo aponta
   `ref: "<id>"` ou `ref: "<id>#<ply>"` quando parou noutro lance. Não achou em fonte aberta: diga no
   dossiê, use a posição dos manuais e siga.
6. **Conte a partida, não só a posição.** Quando uma posição vem de partida, a lição dedica a ela um
   `think` ("é a sua vez de jogar como o Capablanca") ou um `talk` e as falas dizem: quem jogava, onde e
   quando; como chegaram ali (uma frase); o que o mestre viu, ou o que o perdedor deixou passar; e o que
   aconteceu depois (o resultado). Mais um `demo` com os lances da partida a partir dali, quando couber. A
   história ("Sobre este final") repete a partida com a fonte. Nada de frase genérica como "o mestre
   ganhou"; a fala tem o lance e o motivo. A mesma partida pode voltar numa parte seguinte, noutro ply.
7. **Escreva as falas** pt e en de todos os passos novos e dos que mudaram (voz do Viktor; uma coisa por
   fala, com o porquê; notação pt R/D/T/B/C e en K/Q/R/B/N; nunca "mate em N"; nada de motor, tabela,
   Lichess ou Wikipedia dentro de `step.*` e `part.*`, que isso fica no `ref` e em `history`/`key.*`). Tire
   as chaves dos passos que saíram. `part.<id>.title` e `.summary` para cada parte.
8. **Gere e confira**: o `.py` (se houver), `build_aula.py <id>` (0 problemas, sem trocar regra de `accept`
   para passar), `check_variety.py <id>`, `dump_lesson.py <id> --links` (sem aviso; todo link "bate"),
   `flutter test test/data/repositories/endgames/endgame_lessons_content_test.dart`. Leia o despejo como
   aluno: partes de 4 a 8 min (o total da lição não tem teto); a fala do lance N explica o lance N.
9. **Registre no dossiê** (`docs/aulas/<id>.md`, seção "Lição refeita (T61, <data>)"): a tabela de
   cobertura final, as partes (id, ideia, FEN, de onde veio), as partidas com link e como as abriu, onde
   saiu do plano e por quê, o que julgou o Stockfish (posições com mais de 7 peças, só em `think`/`talk`),
   e o que ficou pendente.

## Erros que a T61 viu (conferência de quem reescreve)

- Exercício cobrando ideia que nenhuma parte ensina (5 das 8 em Ruptura; 5 das 6 em Lucena).
- `talk` que empilha três variantes; `demo` com fala só do lance ("a7."); dica 2 do `think` entregando o lance.
- Posição-base ou resumo afirmando o contrário do que os exercícios provam ("peão de torre não ganha").
- Fala que descreve lances ilegais na posição (rei sem casa). O despejo e o `build_aula.py` não pegam fala
  de `talk`: jogue a posição com python-chess antes de afirmar.
- Partida citada na fala sem `ref` e referência `game` sem `url`; ou o `#ply` da url que não é a posição do passo.
- Lição de 18 min (rasa) ou de 55 min (cansa): corte demos em 5 lances, divida partes com duas ideias.
- Scratchpad compartilhado entre agentes: scripts próprios numa subpasta com o id da aula, no scratchpad da sessão (o orquestrador passa o caminho), nunca numa pasta `scratchpad/` dentro do repositório.

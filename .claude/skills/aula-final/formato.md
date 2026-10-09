# Formato de uma aula de final

## Fonte: `tools/lessons/endgames/<id>.json`

```json
{
  "id": "mates.bishopKnight.w",
  "module": "mates",
  "skills": ["mate.bishopKnight"],
  "parts": [
    {"id": "corner", "steps": [
      {"type": "think", "id": "t_corner", "fen": "…", "hints": 2,
       "arrows": ["b1e4"], "marks": ["a1"]},
      {"type": "talk", "id": "corner", "fen": "…", "arrows": ["b1e4"], "marks": ["a1"]},
      {"type": "demo", "id": "d_w", "fen": "…", "goal": "win",
       "line": [{"uci": "e5f7", "arrows": ["f7d6"]}, {"uci": "h8g8"}, {"uci": "d3f5", "marks": ["h7"]}]},
      {"type": "move", "id": "w1", "fen": "…", "goal": "win",
       "turns": [
         {"teach": "e5f7", "accept": "best", "reply": "auto"},
         {"teach": "d3f5", "accept": "best"}
       ]}
    ]},
    {"id": "finish", "steps": [
      {"type": "talk", "id": "recap", "fen": "…"},
      {"type": "play", "id": "finish", "fen": "…", "goal": "win"}
    ]}
  ],
  "exercises": [
    {"id": "e01", "stars": 1, "fen": "…", "goal": "win", "origin": "own",
     "turns": [{"teach": "…", "accept": "best", "reply": "auto"}, {"teach": "…", "accept": "only"}]}
  ],
  "passScore": 13,
  "keyPositions": [{"id": "wStart", "fen": "…", "ref": "delaVilla"}],
  "practice": {"fen": "…", "goal": "win", "positionId": null},
  "references": [
    {"id": "delaVilla", "kind": "book", "author": "…", "title": "…", "publisher": "…", "year": 2008, "where": "…"},
    {"id": "study1", "kind": "study", "author": "…", "title": "…", "url": "https://lichess.org/study/…"},
    {"id": "game1", "kind": "game", "white": "…", "black": "…", "event": "…", "year": 1983},
    {"id": "tablebase", "kind": "tablebase", "title": "Lichess tablebase (Syzygy)", "url": "https://tablebase.lichess.ovh"}
  ]
}
```

`skills` (obrigatório, T52): os ids dos nós do mapa de habilidades
(`tools/placement/skills.json`) que a aula ensina. O `build_aula.py` reprova a
aula sem `skills` ou com um id que não está no mapa; ao fazer uma aula do
catálogo, troque também, no mapa, o tipo dela de `catalog` para `endgame` (o
`tools/placement/check_skills.py` confere os dois lados).

- `parts`: a lição em partes curtas (T51). Cada parte é `{"id", "steps": [...]}` e aparece no app com
  número, título, resumo e tempo estimado. A aula ainda no formato antigo tem `steps` no lugar de `parts`:
  o script e o app a leem como uma parte só (`main`), e o JSON gerado continua com `steps`. Aula nova ou
  reescrita usa sempre `parts`.
- Os passos: `talk`, `move` e `play` de `lib/domain/models/lesson.dart`, mais `think` e `demo` (só no
  formato em partes). O aluno é o lado que joga no FEN. Num passo `talk`, `"side": "white"` (ou `"black"`) fixa de que lado o tabuleiro é visto: use quando a posição ilustrada tem o outro lado jogando (o zugzwang das pretas numa aula em que o aluno joga de brancas), para o tabuleiro não virar entre um passo e outro.
- `think`: o aluno estuda a posição sozinho antes de qualquer explicação.
  `{"type": "think", "id": "t_philidor", "fen": "…", "hints": 2, "side": "white"?, "arrows": […]?, "marks": […]?}`.
  `hints` é quantas dicas a fala tem (de 1 a 3). Não há limite de tempo (T60): um cronômetro conta para
  cima e o aluno pede as dicas (com as setas e casas do passo) e "Ver explicação" quando quiser. Enquanto
  pensa, ele pode mexer as peças à vontade, sem validação. No JSON gerado o passo sai igual.
- `demo`: o Viktor joga e explica. `{"type": "demo", "id": "d_fork", "fen": "…", "goal": "win", "side": "white"?, "line": [{"uci": "a5e5", "arrows": […]?, "marks": […]?}, {"uci": "b8a7"}, …]}`.
  O app faz todos os lances da linha, dos dois lados, animados e um de cada vez, cada um com a sua fala e as
  suas setas e casas. Todo lance é legal, e o script confere, como nos passos `move`, que nenhum lance do
  lado do aluno (`side`, ou quem joga no FEN) joga fora o `goal` (`win` ou `draw`, como em `move`). No
  JSON gerado o passo sai igual.
- `goal`: `win` ou `draw` (defender também se ensina: Philidor, Vancura, o canto certo).
- `turns`: cada vez do aluno. `teach` é o lance que a aula ensina (UCI); `reply` é a resposta do outro lado (UCI, ou `auto` para a melhor defesa da tabela). Toda vez que não é a última precisa de `reply`.
- `accept`, a regra dos lances aceitos:

  | Regra | Aceita | Quando usar |
  |---|---|---|
  | `only` | só o lance ensinado | lance único; o script confere que ele mantém o objetivo |
  | `best` | os mates mais curtos, com folga de um lance | técnica de mate, em que quase tudo "ganha" mas só um caminho ensina |
  | `win` | todo lance que mantém a vitória | posições críticas, em que errar empata |
  | `hold` | todo lance que não perde | defesas |
  | lista | exatamente esses lances | quando nenhuma regra serve; o script acusa lance da lista que joga fora o objetivo |

  Em finais como bispo e cavalo, `win` aceita quase todos os lances legais e o exercício não ensina nada: use `best` ou lista. `best` precisa da distância do mate, que a tabela só dá até 5 peças.
- No JSON gerado, cada vez vira `{"teach": …, "accept": […], "reply": …}`: o app põe o lance ensinado em primeiro entre os aceitos (é ele que a dica mostra e a quem a resposta combinada serve; outro lance aceito que deixe a resposta ilegal encerra a linha como cumprida).
- `exercises`: um por ideia distinta, sem cota (mínimo 3). `stars` de 1 a 3. `origin` é `own` (posição própria) ou o id de uma referência. Dois exercícios que diferem só pela casa dos reis, pelo espelho ou pelas cores são o mesmo exercício: o script reprova (`tools/lessons/check_variety.py` tem a conta).
- `passScore`: o mínimo de estrelas para liberar o passo final. Padrão: 60% do total, arredondado para cima. O script exige entre a metade e o total.
- `keyPositions`: as posições-base que o botão de informações mostra. `ref` (opcional) aponta a referência do crédito.
- `practice`: a posição do treino final. `positionId` é o id em `assets/positions/positions.json`, quando o catálogo tem o final (é ele que liga a aula ao speedrun de final); sem ele, o treino abre o `fen` como posição personalizada.
- `references`: `kind` é `book` (author, title, publisher, year), `study` (author, title, url do Lichess), `game` (white, black, event, year), `tablebase` ou `web` (title, url). `where` é opcional e só entra se foi visto. Ao menos um livro ou estudo.

## Uma parte boa

Uma parte ensina uma ideia: pensar sozinho, ver o professor, jogar com ajuda. O script confere (erro, não aviso):

- de 4 a 6 passos;
- termina num `move` ou `play`: a prática, em que o aluno joga e o Viktor comenta;
- no máximo um `think`, e, se houver, é o primeiro passo;
- `hints` de 1 a 3, com todas as chaves de dica nas falas (sem `minutes`: não há limite de tempo);
- lances de `demo` legais e sem jogar fora o objetivo;
- ids de parte únicos; ids de passo únicos na aula inteira (não só na parte).

O relatório do script mostra a divisão em partes e o tempo estimado de cada uma: os minutos do `think`,
~30 s por `talk`, ~10 s por lance de `demo` e ~1 min por `move` ou `play`. Depois das partes vem o teste
final: os exercícios com estrelas e a nota mínima.

## Estrelas

A régua é alta de propósito: o aluno aprende quando gasta tempo na posição. Exercício que se resolve de
olhar, porque é a posição da lição com outro rei, não ensina.

| Estrelas | O exercício pede | Tempo esperado |
|---|---|---|
| 1 | aplicar a técnica numa posição que a lição **não** mostrou (outra estrutura, outro material, outra ala com algo a mais); um ou dois lances, mas é preciso reconhecer o tema | 1 a 2 minutos |
| 2 | uma decisão: dois planos em que só um funciona, uma exceção à regra, uma conta (o quadrado, a oposição distante), uma defesa com um só lance que segura | uns 3 minutos |
| 3 | composição no estilo de estudo: solução única, lance que surpreende, várias jogadas de profundidade, a defesa mais teimosa; de preferência um estudo publicado, com crédito | uns 5 minutos |

Uma aula boa tem os três níveis. A dificuldade vem da **ideia**, não do tamanho do tabuleiro: 3 estrelas é
uma ideia a mais, não a mesma posição com o rei mais longe.

## Falas: `assets/lessons/<pt|en>/endgames/<id>.json`

Mapa de chave para texto, como em `assets/lessons/pt/lessons.json`. As mesmas chaves nos dois idiomas:

| Chave | Texto |
|---|---|
| `title`, `summary` | nome da aula e uma linha sobre ela |
| `part.<id>.title`, `part.<id>.summary` | título curto da parte e uma linha sobre ela (só no formato em partes) |
| `step.<id>` | a fala do Viktor no passo |
| `step.<id>.hint`, `step.<id>.done` | dica no erro e fala no acerto (só passos `move`) |
| `step.<id>` (think) | a pergunta do Viktor sobre a posição, sem a resposta. Sem o tempo ("você tem 5 minutos"): a frase do tempo vem das traduções do app, com o número como parâmetro |
| `step.<id>.hint1` … `step.<id>.hint<hints>` (think) | as dicas, da mais vaga à mais clara; nenhuma dá o lance |
| `step.<id>` (demo) | a introdução, dita antes do primeiro lance |
| `step.<id>.m1` … `step.<id>.m<N>` (demo) | uma fala por lance da linha (N = número de lances), o porquê daquele lance |
| `ex.<id>` | enunciado do exercício ("Brancas jogam e ganham. Onde o cavalo precisa chegar?") |
| `ex.<id>.hint` | dica: aponta a ideia, não o lance |
| `ex.<id>.solution` | a explicação que aparece depois de resolver |
| `key.<id>` | legenda da posição-base, com o crédito |
| `history` | a história do final, para o botão de informações |
| `practice` | o convite do Viktor para o treino final |

## O que o script confere

FEN válido; lances e respostas legais; as regras de uma parte boa (acima); lances de `demo` legais e sem
jogar fora o objetivo; lance ensinado entre os aceitos; nenhum lance aceito que jogue fora o objetivo; posição de cada exercício, passo `play` e treino com o veredito da tabela igual ao objetivo; estrelas de 1 a 3; ao menos 3 exercícios, sem dois iguais a menos da casa dos reis, do espelho ou das cores (as outras repetições saem como aviso no relatório); `passScore` no intervalo; referências com os campos do tipo; origem de cada exercício; todas as chaves de fala em pt e en, sem sobra e sem "mate em N".

Vitória que só existe sem a regra dos 50 lances (a tabela responde `cursed-win`) não passa como `win`. Em dois cavalos contra peão isso é parte da aula: escolha posições que ganham dentro da regra e conte o resto na fala.

## A trilha e o índice

`tools/lessons/endgames/trail.json` tem os módulos e as aulas na ordem do catálogo (todas as 55, feitas ou não). A cada aula gerada, o script reescreve `assets/lessons/endgames/index.json` só com as aulas que já têm JSON: é o índice que o app lê para montar a trilha. Aula nova no catálogo entra no `trail.json`.

## Como o app lê (T32)

- Trilha das aulas de finais (`/endgames`), separada da escola do iniciante, com os módulos do índice.
- Tela da aula: a lição (os passos, na mesma tela das aulas da escola), os exercícios com as estrelas, a nota e o passo final.
- Pontos: acerto de primeira vale todas as estrelas do exercício; cada erro ou dica tira uma (mínimo zero). "Refazer exercícios" zera a nota.
- Passo final (liberado com a nota ≥ `passScore`): escolher o ritmo e desafiar no speedrun do final (quando `practice.positionId` é a posição de um speedrun `ending`), ou abrir o treino na posição (`/setup`).
- Botão de informações: referências, posições-base com crédito e história.
- O teste `test/data/repositories/endgames/endgame_lessons_content_test.dart` confere no CI cada aula gerada: FEN, lances, falas nos dois idiomas.

O formato acima é o contrato: para mudar um campo, muda aqui, no script e no app juntos.

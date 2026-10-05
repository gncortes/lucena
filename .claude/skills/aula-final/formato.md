# Formato de uma aula de final

## Fonte: `tools/lessons/endgames/<id>.json`

```json
{
  "id": "mates.bishopKnight.w",
  "module": "mates",
  "steps": [
    {"type": "talk", "id": "corner", "fen": "…", "arrows": ["b1e4"], "marks": ["a1"]},
    {"type": "move", "id": "w1", "fen": "…", "goal": "win",
     "turns": [
       {"teach": "e5f7", "accept": "best", "reply": "auto"},
       {"teach": "d3f5", "accept": "best"}
     ]},
    {"type": "play", "id": "finish", "fen": "…", "goal": "win"}
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

- `steps`: os tipos `talk`, `move` e `play` de `lib/domain/models/lesson.dart`. O aluno é o lado que joga no FEN.
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
- `exercises`: de 8 a 12. `stars` de 1 a 3. `origin` é `own` (posição própria) ou o id de uma referência.
- `passScore`: o mínimo de estrelas para liberar o passo final. Padrão: 60% do total, arredondado para cima. O script exige entre a metade e o total.
- `keyPositions`: as posições-base que o botão de informações mostra. `ref` (opcional) aponta a referência do crédito.
- `practice`: a posição do treino final. `positionId` é o id em `assets/positions/positions.json`, quando o catálogo tem o final (é ele que liga a aula ao speedrun de final); sem ele, o treino abre o `fen` como posição personalizada.
- `references`: `kind` é `book` (author, title, publisher, year), `study` (author, title, url do Lichess), `game` (white, black, event, year), `tablebase` ou `web` (title, url). `where` é opcional e só entra se foi visto. Ao menos um livro ou estudo.

## Estrelas

| Estrelas | O exercício pede |
|---|---|
| 1 | reconhecer a posição-chave e achar o lance da técnica, um ou dois lances |
| 2 | chegar à posição-chave de perto, ou escapar de uma armadilha (afogamento, canto errado) |
| 3 | o caminho de longe, a defesa mais teimosa, ou escolher entre dois planos em que só um funciona |

Uma aula boa tem os três níveis, com mais exercícios de 1 e 2 do que de 3.

## Falas: `assets/lessons/<pt|en>/endgames/<id>.json`

Mapa de chave para texto, como em `assets/lessons/pt/lessons.json`. As mesmas chaves nos dois idiomas:

| Chave | Texto |
|---|---|
| `title`, `summary` | nome da aula e uma linha sobre ela |
| `step.<id>` | a fala do Viktor no passo |
| `step.<id>.hint`, `step.<id>.done` | dica no erro e fala no acerto (só passos `move`) |
| `ex.<id>` | enunciado do exercício ("Brancas jogam e ganham. Onde o cavalo precisa chegar?") |
| `ex.<id>.hint` | dica: aponta a ideia, não o lance |
| `ex.<id>.solution` | a explicação que aparece depois de resolver |
| `key.<id>` | legenda da posição-base, com o crédito |
| `history` | a história do final, para o botão de informações |
| `practice` | o convite do Viktor para o treino final |

## O que o script confere

FEN válido; lances e respostas legais; lance ensinado entre os aceitos; nenhum lance aceito que jogue fora o objetivo; posição de cada exercício, passo `play` e treino com o veredito da tabela igual ao objetivo; estrelas de 1 a 3; de 8 a 12 exercícios; `passScore` no intervalo; referências com os campos do tipo; origem de cada exercício; todas as chaves de fala em pt e en, sem sobra e sem "mate em N".

Vitória que só existe sem a regra dos 50 lances (a tabela responde `cursed-win`) não passa como `win`. Em dois cavalos contra peão isso é parte da aula: escolha posições que ganham dentro da regra e conte o resto na fala.

## O que falta no app

O app ainda não lê estas aulas. Falta uma tarefa do plano para o motor, com o que o Gabriel pediu em 2026-10-05:

- trilha das aulas de finais, separada da escola do iniciante;
- lista de exercícios da aula, cada um com as estrelas, e a tela de resolver;
- nota no fim (estrelas ganhas, mínimo da aula) com as saídas "refazer exercícios" e "ir para o final";
- passo final: escolher o ritmo e desafiar no speedrun do final, ou abrir o treino personalizado;
- botão de informações com referências, posições-base e história;
- `assets/lessons/endgames/` e as falas declarados no `pubspec.yaml`, e a checagem das aulas no CI.

Regra de pontos sugerida, a confirmar na tarefa: acerto de primeira vale todas as estrelas do exercício; cada erro ou dica tira uma.

Até a tarefa sair, o formato acima é o contrato: se ela precisar mudar um campo, muda aqui e no script juntos.

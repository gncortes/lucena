# Arquitetura da gamificação (T20)

Data: 2026-10-04. Base: `docs/VISAO-GAMIFICACAO.md` e o código da T19 (`v1.0.0-rc.1`). Vale para a T21 em diante.

As decisões marcadas **(Gabriel)** precisam do seu ok antes da T21. As outras são técnicas; se você não comentar, valem como estão.

## Resumo das decisões

| Assunto | Decisão |
| --- | --- |
| Speedrun: derrota **(Gabriel)** | a etapa se repete com o cronômetro correndo; a tentativa não zera |
| Speedrun: o que o cronômetro conta **(Gabriel)** | só o tempo gasto no **seu** relógio nas partidas da tentativa |
| Speedrun: pausa **(Gabriel)** | pausa livre entre etapas; no meio de uma partida, o relógio da partida segue as regras de sempre |
| Rating **(Gabriel)** | Glicko-2 local, só partidas contra Maia ou Stockfish, com o adversário "ajustado" à posição |
| Faixa do Maia | 1000 a 2600 de 200 em 200, coberta pelo modelo da T15 (medido na T19) |
| Avaliação para os personagens | Stockfish do app em segundo plano, profundidade 10, um cálculo por lance |
| Falas | geradas por IA durante o desenvolvimento e guardadas como dados; nada de IA no aparelho |
| Tradução das falas | arquivos JSON por idioma, fora dos `.arb`; inglês é a base e o português vem primeiro |
| Arte **(Gabriel, decidido)** | você manda os PNGs dos personagens; sem animações por enquanto |
| Conteúdo | tudo em JSON em `assets/`: degraus, desafios, speedruns, personagens, falas e conquistas |

## 1. O que já existe (seção 35 da visão, perguntas 1 a 8)

| Pergunta | Onde está hoje |
| --- | --- |
| 1. Partidas | `lib/ui/free_board/` (`FreeBoardCubit`: lances, fim de partida, relógio, máquina). Regras em `GameRules` (`dartchess`), relógio em `ClockEngine` (instantes, não contagem), fim em `GameEnd` (mate, afogamento, material, repetição, 50 lances, tempo, desistência) |
| 2. Maia integrado | `MaiaService` (isolate com o modelo) → `MaiaOpponentRepository` (sorteia o lance) → `DeviceOpponentRepository` (escolhe Maia ou Stockfish). Tela de diagnóstico em `lib/ui/maia_debug/` |
| 3. Força do Maia | `MaiaLevels` (1000–2600) e `GameSetup.maiaLevel`; a força vai como `selfElo` e `oppoElo` do modelo; temperatura 0,5 fixa (T19) |
| 4. Comportamento humano | `PickHumanMove` (sorteio com temperatura) e `ThinkTimePolicy.human` (tempo de pensar pela certeza do lance) |
| 5. Ritmos | `TimeControl` (minutos + incremento, um para cada lado) em `GameSetup`; não há nome nem categoria (bullet, blitz). `ClockSettings` é só aparência do relógio |
| 6. Finais | `assets/positions/positions.json` (50 posições, 8 famílias, verificadas na tablebase), lido por `AssetPositionsRepository` |
| 7. Partidas persistidas | a em andamento: `OngoingGameRepository` (`GameSnapshot` nas preferências, lances em UCI). As terminadas: tabela `Attempts` do drift (posição, data, resultado, objetivo cumprido, adversário e nível), **sem os lances, o ritmo nem a duração** |
| 8. Histórico | só `Attempts` por posição; a T21 cria a tabela completa (seção 4) |

## 2. Princípios

- **Conceitos separados** (visão, seção 34): rating, progressão, domínio, speedrun e recorde são modelos e tabelas diferentes. Uma partida terminada é o fato único; cada sistema lê o que precisa dela.
- **Conteúdo em dados, regras em código.** O que muda com conteúdo (degraus, desafios, speedruns, personagens, falas, conquistas) é JSON em `assets/`, validado por um script no CI. O que é regra (como o rating sobe, quando um degrau libera, como o cronômetro conta) é Dart puro em `domain/use_cases`, com teste unitário.
- **Novo personagem, final ou speedrun = arquivo novo**, sem mexer em código espalhado. Ids são texto estável (`queen-vs-rook`, `praieiro`); nunca índice de lista.
- **Tudo derivado do histórico quando possível.** Domínio, recordes e conquistas podem ser recalculados das partidas gravadas; assim uma regra corrigida vale para o passado e não há contador que desande.
- A arquitetura de sempre: `domain/models` (freezed), `domain/use_cases` (Dart puro), `data/repositories` (interface + implementação), `data/services`, `ui/<feature>`.

## 3. Modelos novos e onde moram (perguntas 9 a 15)

### Conteúdo (JSON em `assets/`, lido uma vez por repositório de asset)

| Arquivo | Conteúdo | Modelo (`domain/models`) | Tarefa |
| --- | --- | --- | --- |
| `assets/progression/ladder.json` | degraus 1000 → … → 2600 → Stockfish; cada degrau com a lista de desafios | `Rung`, `Challenge` | T21 |
| (dentro do degrau) | desafio = posição do catálogo + adversário (`maia:1200` ou `stockfish`) + objetivo + ritmo opcional | `Challenge`, `OpponentRef` | T21 |
| `assets/progression/time_controls.json` | ritmos nomeados (`1+0`, `3+2`…) com categoria (bullet, blitz, rápido) e parâmetros do Maia por ritmo | `NamedTimeControl` | T22 |
| `assets/speedruns/<id>.json` | modalidade (`rung`, `ending`, `exercises`, `full`) e as etapas geradas ou listadas | `SpeedrunDefinition`, `SpeedrunStage` | T23, T24 |
| `assets/achievements.json` | conquista = id + condição de uma lista fechada de tipos (`firstFulfilled`, `rungCompleted`, `beatLevel`, `recordImproved`, `underTime`…) + parâmetros | `Achievement`, `AchievementRule` | T24 |
| `assets/characters/<id>.json` | nome, nível do Maia, traços, imagens por emoção, pesos de emoção | `Character` | T25, T26 |
| `assets/lines/<idioma>/<personagem>.json` | falas por categoria de evento, com intensidade e emoção | `CharacterLine` | T25 |

Para o speedrun de final não precisa listar etapa por etapa: a definição diz "posição X contra cada degrau" e o código monta as 10 etapas.

### Fatos do jogador (drift, `lib/data/services/database/`)

| Tabela | O que guarda | Tarefa |
| --- | --- | --- |
| `Games` | partida terminada: posição inicial (FEN e id do catálogo, se houver), lances (UCI), adversário e nível, ritmo de cada lado, início e fim (instantes), tempo gasto por lado, resultado, motivo do fim, objetivo cumprido, id do desafio e da tentativa de speedrun (se houver) | T21 |
| `RatingHistory` | rating, desvio e volatilidade depois de cada partida que conta, com o id da partida | T22 |
| `SpeedrunAttempts` | definição, início, fim ou abandono, estado (em andamento, concluída, abandonada) | T23 |
| `SpeedrunStageResults` | tentativa, etapa, tempo gasto, vitórias e derrotas até concluir | T23 |
| `UnlockedAchievements` | id e instante (o que já foi mostrado ao jogador) | T24 |

- `Attempts` é migrada para `Games` na T21 sem perder nada (as partidas antigas entram sem lances e sem ritmo).
- **Domínio** (desafio concluído, degrau liberado) é calculado de `Games`: um desafio está concluído quando existe uma partida dele com o objetivo cumprido. Não há tabela própria.
- **Recordes** são calculados de `SpeedrunAttempts` e `SpeedrunStageResults` (melhor tempo geral e por etapa, histórico por mês). Sem tabela própria.
- **Progressão** (onde estou) = o primeiro degrau com desafio não concluído, ou o escolhido no tour (T27, nas preferências).

### Personagens em tempo de partida (T25)

```text
lance jogado ──► Avaliação (Stockfish, em segundo plano) ──► estado discreto
                                                             │
lances + posição ──► Detector de eventos ────────────────────┤
                                                             ▼
                                           Emoção (média móvel dos últimos lances)
                                                             │
                     personagem + evento + intensidade + emoção ──► fala + imagem
```

- `PositionAssessment` (Dart puro): da avaliação em centipeões, do lado do personagem, sai um estado (`better`, `worse`, `equal`, `bigAdvantage`, `bigDisadvantage`) e a variação desde o lance anterior (`swing`, `blunder`, `strongMove`).
- `GameEventDetector`: eventos de tabuleiro sem avaliação (captura importante, promoção, entrou em final, xeque-mate próximo) mais os da avaliação (virada, erro grave). A lista de categorias é um enum com valor desconhecido tolerado, para falas novas não quebrarem versões antigas.
- `EmotionState`: valores de confiança e tensão que andam com uma média dos últimos 6 lances. A emoção sai de faixas desses valores, com pesos por personagem. Assim "estava ganhando e foi perdendo" é diferente de "sempre esteve mal".
- `LinePicker`: filtra por evento, intensidade e emoção, nunca repete uma fala na mesma partida, e fala no máximo uma vez a cada N lances (para não virar ruído).

## 4. Regras do speedrun (Gabriel)

O que proponho, pensando em "não ser punitivo e incentivar repetição" (visão, seção 34):

1. **Derrota ou objetivo não cumprido:** a mesma etapa recomeça na hora, com o cronômetro da tentativa correndo. A tentativa não zera. A derrota fica registrada (o resumo mostra "3 derrotas na etapa 2000"). Desistir de uma partida conta como derrota.
2. **O que o cronômetro conta:** a soma do tempo que **o seu relógio** gastou em todas as partidas da tentativa, inclusive as perdidas. Por quê:
   - o tempo que a máquina pensa depende do celular (o Maia leva de 0,1 a 0,5 s de conta conforme o aparelho) e do ritmo humano que simulamos; contar isso misturaria o seu tempo com o dela;
   - tempo em menu, entre etapas, não conta.
   Alternativa (se preferir): tempo total do relógio de parede da primeira partida à última. É mais simples de explicar, mas pune quem para para tomar água.
3. **Ritmo:** cada etapa tem um ritmo definido no speedrun (por exemplo 3+2), igual para todos, para os tempos serem comparáveis. Sem relógio não há speedrun.
4. **Pausa e retomada:** pausa livre entre etapas, por quanto tempo quiser (o speedrun completo pode levar dias). Durante uma partida, vale o relógio da partida: se você sair do app, seu tempo corre, como numa partida normal (T14).
5. **Abandonar** encerra a tentativa sem recorde; ela fica no histórico como abandonada.
6. **Recorde** só de tentativa concluída. Recorde por adversário (ex.: Dama contra Torre, 1800) é o melhor tempo daquela etapa em qualquer tentativa concluída.

## 5. Rating do jogador (Gabriel)

- **Algoritmo:** Glicko-2, calculado no aparelho, partida a partida (cada partida é um "período"). Começa no rating da faixa do perfil (`RatingLevel`), com desvio alto (350), então as primeiras partidas mexem bastante e depois estabiliza. O Glicko-2 é o que o Lichess usa e lida bem com quem joga pouco por um tempo.
- **O que conta:** só partidas contra o Maia ou o Stockfish terminadas (inclusive desistência). Tabuleiro livre e "dois jogadores" não contam.
- **O problema dos finais:** uma partida de treino começa numa posição desequilibrada (dama contra rei é vitória). Contar uma vitória dessas contra o Maia 2600 como "venceu um 2600" inflaria o rating.
- **A solução:** o próprio Maia diz quanto aquela posição vale entre duas pessoas: a cabeça de resultado prevê a chance de vitória de quem tem o seu rating contra o nível escolhido, naquela posição. Essa chance vira um "adversário equivalente": se a posição dá 90% de chance para você, a partida conta como se fosse contra alguém bem mais fraco que o nível escolhido. O resultado é o objetivo cumprido (1) ou não (0); no objetivo de empatar, empatar vale 1. Uma conta do Maia por partida, no início dela.
- **Stockfish:** fixo em 3000 para o rating. Como o Maia não prevê acima de 2600, a chance usada é a do Maia 2600 com mais 400 pontos. Na prática, contra o Stockfish o rating mexe pouco, a não ser que você cumpra o objetivo.
- **Limite medido na T19:** nos finais técnicos (peão, torre), o Maia dos níveis altos joga abaixo do próprio rating. O rating ganho ali é um rating de **finais contra o Maia**, não um rating comparável ao do Lichess; a tela deve dizer isso.

## 6. Faixa do Maia

- Piso 1000 e teto 2600 (visão, seção 12), de 200 em 200. O modelo de 5M da T15 recebe qualquer rating; a calibração da T19 mediu os 9 níveis.
- Jogador abaixo de 1000 começa contra o Maia 1000: não criamos motor artificialmente fraco (visão, seção 34).
- O nível muda pouco a defesa nos mates básicos (T19). A escada da T21 deve pôr nos degraus altos finais em que o nível pesa (dama contra torre, torre e peão contra torre), não só mates básicos.

## 7. Avaliação da posição para os personagens

- **Motor:** o mesmo Stockfish do app (`multistockfish`, versão light, 1 thread). Uma análise por lance, em segundo plano, profundidade 10. A avaliação nunca aparece na tela.
- **Custo medido neste computador** (1 thread, as 50 posições do catálogo e duas de abertura):

  | Profundidade | Mediana | 90% das posições abaixo de |
  | ---: | ---: | ---: |
  | 8 | 0,7 ms | 1,5 ms |
  | 10 | 1,0 ms | 2,1 ms |
  | 12 | 2,3 ms | 8,5 ms |

  Num celular médio, contando 10 vezes mais lento, a profundidade 10 fica em torno de 10 a 20 ms por lance: bateria e CPU desprezíveis perto da conta do Maia (cerca de 100 ms). Medir no celular é parte da T25, com o diagnóstico.
- **Fila:** o Stockfish já é usado como adversário. Contra o Maia ele fica livre; contra o Stockfish os personagens não entram (o Stockfish não é personagem).
- Finais de até 5 peças podem usar resultado exato no futuro (tablebase), mas 380 MB não cabem no app; fica de fora.

## 8. Falas e IA

- **Geração:** um script em `tools/lines/` chama um modelo de IA durante o desenvolvimento, com a ficha do personagem e as categorias, e grava o JSON. As falas passam por revisão (sua ou minha) e entram versionadas. Um script de checagem no CI confere: pelo menos 100 falas e 10 categorias por personagem, nenhuma fala repetida, todas as categorias conhecidas.
- **IA no aparelho: descartada.** Os menores modelos de linguagem que escrevem frases aceitáveis têm de 0,5 a 1 bilhão de parâmetros: de 400 MB a 1 GB de arquivo, outro tanto de memória, e alguns segundos para escrever uma frase num celular médio (ordem de grandeza publicada para modelos como Qwen 0,5B e Gemma 1B; não medi). O app inteiro tem 45 MB e o Maia 10 MB. Além disso, o texto não passaria por revisão nem tradução.
- **Tradução** (900 falas para 9 personagens, vezes 20 idiomas):
  - um arquivo por idioma e personagem, `assets/lines/<idioma>/<personagem>.json`, fora dos `.arb` (não são textos de tela e cresceriam demais);
  - inglês é a base; português sai junto na T25; os outros 18 idiomas são traduzidos por script de IA com a mesma marca `"@@x-review": "pending"` dos `.arb`;
  - falta de tradução cai no inglês, e a checagem do CI avisa;
  - a fala guarda o id da categoria, não o texto, para a tradução não quebrar a seleção.

## 9. Arte dos personagens (decidido)

Você manda os PNGs de cada personagem. **Sem animações por enquanto**, para nada ficar complexo: a reação aparece pela fala e, quando houver mais de uma imagem, pela troca da imagem da emoção. Os dados da T25 já guardam um id de reação para uma tarefa futura de animação. A T26 foi ajustada para isso.

Uma divergência para você: a T25 fala em "os 10 personagens da visão", mas a visão lista 9 (de 1000 a 2600; o Stockfish fica fora). Fico com 9.

## 10. O que muda nas próximas tarefas

- **T21:** cria `Games` (migra `Attempts`), `ladder.json` e o domínio derivado. Desafio = posição + adversário + objetivo.
- **T22:** `time_controls.json` com os parâmetros do Maia por ritmo; rating da seção 5; no bullet, o Maia concentra nos lances naturais (temperatura menor) e pensa menos, sem baixar o nível.
- **T23 e T24:** speedrun com as regras da seção 4; recordes e conquistas derivados das tabelas.
- **T25:** avaliação da seção 7, emoção, falas e tradução da seção 8.
- **T26:** PNGs, sem animação.
- **Cronologia de dependências** igual ao plano: T21 → (T22 e T23) → T24 → T25 → T26 → T27.

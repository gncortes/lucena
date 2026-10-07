# Spike · Jornada introdutória: os modos novos dentro do caminho do iniciante

Pedido do Gabriel (2026-10-07), junto com a T42: agora que existem partida às cegas (T40), Ultra Bullet e
Maratona (T41), o jogador novo deve experimentar esses modos dentro da Jornada, em finais simples e na hora
certa para o nível dele. O iniciante também precisa de um caminho completo: peças, notação, mates básicos e
os primeiros finais teóricos. E o app deve ganhar mais animações, principalmente nesse fluxo.

Este documento é estudo e proposta. Nada aqui foi implementado.

## O que já existe

| Peça | Onde | O que tem |
|---|---|---|
| Aulas do Viktor | `assets/lessons/course.json` | 6 módulos: peças (8 aulas), primeiros mates (2), técnica (oposição, zugzwang, corte da torre, mate de torre), peões (4), peças menores (6) e formatura (dois bispos) |
| Desafios das estrelas | `/school/challenges` | Mover cada peça contra o relógio, 3 níveis |
| Jornada | `assets/progression/ladder.json` | 10 degraus (Maia 1000 a 2600 e Stockfish), 3 a 9 desafios cada. O 1000 e o 1200 só têm mates básicos (dama, torre, duas torres) |
| Aulas de finais | `assets/lessons/endgames/` | Lucena, Philidor, lado curto, última fileira, dama contra torre, oposição distante, casas-chave, bispo e cavalo |
| Às cegas | T40 | Qualquer final, voz, digitação ou toque, tabuleiro com peças, só casas ou nenhum |
| Speedrun | T41 | Clássico ou Maratona, ritmos do Ultra Bullet ao 15+10, ritmo inicial pelo nível |

O que falta é ligar uma coisa à outra: hoje o iniciante termina as aulas e cai na Jornada sem nunca ter visto
o modo às cegas, o speedrun ou a Maratona.

## Proposta

### 1. Um módulo de notação nas aulas, antes de tudo que usa notação

O jogo às cegas, a lista de lances e o ⓘ de "como dizer os lances" pressupõem notação. Proposta: módulo
**Notação** entre "Peças" e "Primeiros mates", com três aulas curtas no formato que já existe:

1. **Coordenadas**: o Viktor diz uma casa ("e4") e o aluno toca nela. Começa com o tabuleiro com
   coordenadas e termina sem elas. Reaproveita o toque em casas do modo às cegas (`_EmptyBoard`).
2. **O nome do lance**: a letra da peça mais a casa ("Df7"), a captura ("Txe5") e o xeque ("+"). O aluno
   lê e joga o lance mostrado.
3. **Dizer o lance**: o aluno joga um lance falando ou digitando, com o tabuleiro à vista. É a ponte para o
   modo às cegas, e o parser da T40 já entende português, inglês, espanhol e as variações faladas.

Os desafios das estrelas ganham um nível "às cegas": a estrela aparece pelo nome da casa, sem desenho.

### 2. Desafios de modalidade na Jornada

Hoje um desafio é posição + adversário + relógio. Proposta: um campo novo, `ChallengeMode`, com os valores
`normal`, `blind`, `speedrun` e `marathon`. Cada degrau ganha um ou dois desafios especiais, marcados
com um selo na trilha ("Às cegas", "Contra o relógio"), que destravam o modo no app quando vencidos.

| Degrau | Desafio especial | Por quê |
|---|---|---|
| 1000 | **Às cegas, com as casas à vista:** mate de duas torres | O mate mais mecânico; as casas ajudam a não se perder |
| 1000 | **Speedrun curto, 15+10:** mate de dama e mate de duas torres, 2 etapas | Primeiro contato com o relógio, sem pressão |
| 1200 | **Às cegas, sem tabuleiro:** mate de duas torres | Mesmo mate, agora de memória |
| 1200 | **Maratona de 3 etapas, 10+0:** rei e torre contra rei, contra o 1000, o 1200 e o 1400 | O pedido do Gabriel: o mate de torre como primeiro desafio de banco de tempo |
| 1400 | **Às cegas, com as casas à vista:** rei e peão contra rei (oposição) | Liga a aula de oposição ao modo novo |
| 1600 | **Speedrun 3+2:** os dois bispos, depois da formatura | O mate da formatura, agora contra o relógio |
| 1800 | **Bullet 1+0:** dama contra peão | Introdução ao jogo rápido |
| 2000+ | **Ultra Bullet 30 s:** mate de dama; **às cegas:** Lucena | Desafios para quem já é forte |

Regras propostas:

- **Ordem dentro do degrau:** o especial nunca é o primeiro. Ele aparece depois que o jogador venceu o mesmo
  final no modo normal ("Você já sabe esse mate. Agora sem olhar.").
- **Conclusão do degrau:** o especial não bloqueia o degrau. Ele vale estrela extra e conquista, e quem
  não tem voz no idioma joga às cegas digitando ou tocando.
- **Destravar:** vencer o primeiro desafio às cegas mostra o cartão "Novo modo: Às cegas", com o botão
  para jogar livre. O mesmo vale para o speedrun e a Maratona.

### 3. Pelo nível do jogador

A T42 já sabe o nível (`RatingLevel`) e os caminhos que o jogador escolheu. O mesmo vale aqui:

- **Iniciante:** segue a tabela inteira, um especial por vez, com o Viktor apresentando cada modo.
- **Casual ou intermediário:** os especiais do 1000 e do 1200 ficam disponíveis desde o início (não
  precisa refazer os mates em modo normal), como uma lista curta "Experimente".
- **Avançado em diante:** em vez da escada introdutória, um cartão "Desafios" na tela inicial com os modos
  difíceis: Ultra Bullet, Maratona completa e às cegas sem tabuleiro em Lucena e Philidor.
- **Escolhas da T42:** um caminho escondido pelo jogador não gera convite; o cartão "Continuar" só sugere
  modos dos caminhos visíveis.

### 4. O caminho completo do iniciante

```
Tour (nível + caminhos)
  → Aulas: Peças → Notação (novo) → Primeiros mates → Técnica → Peões → Peças menores → Formatura
  → Jornada 1000: mates básicos → às cegas com casas → speedrun curto
  → Jornada 1200: mates básicos → às cegas sem tabuleiro → Maratona do mate de torre
  → Jornada 1400: peões → às cegas na oposição
  → Aulas de finais: Lucena, Philidor... (o convite aparece ao chegar no 1600)
```

Cada etapa termina com o Viktor dizendo o que vem a seguir. O cartão "Continuar" da tela inicial segue essa
ordem.

## Animações

O pedido é deixar o fluxo do iniciante mais fluido e agradável. Proposta, da mais simples para a mais cara:

1. **Já entrou na T42:** os cartões da tela inicial, do passo do tour e de "Todos os modos" entram em
   sequência (`StaggeredEntrance`), e o cartão do caminho acende com transição de cor e borda ao ser marcado.
2. **Barato (só Flutter):**
   - transição compartilhada (`Hero`) do cartão do degrau para a tela do desafio, como já existe no retrato
     do adversário;
   - barra de progresso do degrau que enche animada ao voltar de uma vitória;
   - peças que "pousam" no tabuleiro ao abrir uma posição;
   - contador do rating que sobe ou desce número a número.
3. **Médio:**
   - **cartão "Novo modo desbloqueado"**, que entra com escala e brilho, com o ícone do modo;
   - **comemoração ao concluir um degrau** (confete curto, o retrato do adversário reagindo);
   - Viktor com emoções animadas nas falas importantes (já tem retratos por emoção).
4. **Caro (Rive):** o Viktor animado (piscar, gesticular ao falar, sincronizado com a voz da T39) e
   transições entre módulos das aulas. O MCP do Rive está disponível para prototipar; recomendo começar por
   um único estado ("Viktor falando") e medir o peso no APK.

Todas respeitam o "reduzir movimento" do sistema (`MediaQuery.disableAnimations`), como o resto do app.

## Mudanças de dados e código (estimativa)

| Item | Onde | Tamanho |
|---|---|---|
| Campo `ChallengeMode` em `Challenge` e no `ladder.json` | domínio + asset | P |
| A partida do desafio abre no modo (às cegas: rota `blindAt`; speedrun e Maratona: tentativa curta) | `Routes.challengeGame`, router | M |
| Speedrun e Maratona "curtos" com etapas definidas no asset | `speedruns.json` (`kind: marathon` com `stages`) | M |
| Destravar modos e o cartão "Novo modo" | repositório novo `UnlockRepository` + tela inicial | M |
| Módulo de notação (3 aulas) | `course.json` + textos pt/en + um tipo de passo "toque na casa" | G |
| Nível "às cegas" dos desafios das estrelas | star challenge | P |
| Animações do item 2 | widgets existentes | P |
| Animações do item 3 | widgets novos | M |

P = até meio dia, M = um dia, G = dois a três dias.

## Riscos

- **Voz:** nem todo aparelho tem reconhecimento de voz no idioma. O desafio às cegas precisa funcionar
  digitando ou tocando, e o texto do convite não pode prometer voz.
- **Jornada mais longa:** desafios especiais obrigatórios cansariam quem só quer jogar. Por isso eles não
  bloqueiam o degrau.
- **Histórico:** os ids dos desafios são estáveis e gravados no histórico. Os especiais precisam de ids
  novos (`1000/blind.twoRooks`) para não confundir o domínio do degrau.

## Perguntas para o Gabriel

1. Os desafios especiais devem contar para concluir o degrau, ou só valer estrela extra e conquista
   (a proposta)?
2. O módulo de notação entra antes dos primeiros mates (a proposta) ou como módulo opcional?
3. Animação do Viktor com Rive: vale o custo agora, ou primeiro as animações baratas?

## Tarefas sugeridas

- **T45 · Notação nas aulas:** módulo novo com 3 aulas, passo "toque na casa", nível às cegas nas estrelas.
- **T46 · Desafios de modalidade na Jornada:** `ChallengeMode`, especiais do 1000 ao 1400, destravar
  modos, cartão "Novo modo".
- **T47 · Animações do fluxo do iniciante:** itens 2 e 3 da lista acima.
- **T48 · Desafios para fortes:** os especiais do 1600 em diante e o cartão "Desafios" pelo nível.

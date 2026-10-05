# MVP — App de treino de finais (Flutter)

App offline para treinar finais contra o Maia (níveis humanos) e o Stockfish (força máxima). Open source (AGPL-3.0), multilíngue desde o primeiro commit, sem pagamento no MVP.

## Como o trabalho é dividido

O app é construído em **entregas pequenas**. Cada entrega é uma fatia que funciona de ponta a ponta e segue o mesmo ciclo:

1. A IA implementa a entrega (código + testes unitários e de BLoC).
2. O **cenário Patrol** da entrega é escrito e passa no seu celular ou emulador.
3. **Todos os cenários Patrol anteriores** continuam passando (a suíte só cresce).
4. CI verde → tag de versão → APK publicado como Release no GitHub.
5. Você instala o APK e valida usando.

Uma entrega só começa quando as entregas de que ela depende já estão na `main`. Entregas de frentes diferentes podem andar ao mesmo tempo (seção 6, "Frentes paralelas").

Requisitos que valem para **todas** as entregas, desde a primeira:

- Nenhum texto fixo no código: tudo via arquivos de tradução (ARB).
- Toda preferência e todo dado do usuário persistem e sobrevivem a fechar e reabrir o app.
- Toda tela funciona em tema claro e escuro e em idiomas da direita para a esquerda.
- Toda tela com estado em andamento sobrevive a ir para segundo plano e voltar.

---

## 0. Antes da T00: preparar o repositório

1. **Nome.** Repositório `lucena` (provisório; o GitHub permite renomear). O que **não** dá para mudar depois de publicar é o ID do app Android: defina agora, por exemplo `br.com.<suaempresa>.lucena`.
2. **Criar o repositório público** no GitHub com licença AGPL-3.0 e proteger a `main` (merge só com CI verde).
3. **Copiar o kit** para a raiz: `CLAUDE.md`, `.claude/` (settings e skills), `.mcp.json` e `docs/` (este plano e uma tarefa por arquivo em `docs/tasks/`).
4. **Ferramentas locais:** Flutter estável, Android SDK, `jq` (usado pelo hook de formatação), Python 3 (scripts de `tools/`) e Patrol CLI (`dart pub global activate patrol_cli`).
5. **Claude Code:**
   - Plugin oficial de Flutter e Dart (skills oficiais + MCP do Dart): `claude plugin marketplace add flutter/agent-plugins` e `claude plugin install dart-flutter@dart-flutter`. Com o plugin instalado, a entrada `dart` do `.mcp.json` fica redundante: mantenha só uma das duas.
   - Context7 (documentação atualizada dos pacotes) já vem no `.mcp.json`; aprove na primeira execução.
   - Rode `/permissions` uma vez para conferir se as regras do `.claude/settings.json` foram aceitas pela sua versão.
6. **Padrão Patrol do outro projeto:** se for usar o seu, substitua o conteúdo de `.claude/skills/patrol-e2e/SKILL.md` antes da T00.
7. Começar com `/tarefa T00`.

### Por que o kit economiza tokens

- `CLAUDE.md` curto: ele entra em toda sessão, então só tem regras e comandos.
- Skills carregam sob demanda: o detalhe de Patrol, traduções ou BLoC só entra quando a tarefa precisa.
- Uma tarefa por arquivo: a sessão lê `docs/tasks/T05.md`, não o plano inteiro.
- Pastas pesadas bloqueadas para leitura (`build/`, `.dart_tool/`, modelos).
- Formatação automática por hook depois de cada edição, sem gastar resposta do modelo com isso.
- Instrução de consultar Context7/MCP antes de usar APIs de pacotes, evitando idas e voltas com código que não compila.

---

## 1. Arquitetura

Segue o **guia oficial de arquitetura do Flutter** (docs.flutter.dev/app-architecture): camada de UI (views + view models), camada de dados (repositórios + serviços) e camada de domínio opcional, com dados fluindo em uma direção só e modelos imutáveis.

A única adaptação: o papel de **view model** é feito por **Cubit/Bloc** (`flutter_bloc`) em vez de `ChangeNotifier`. O próprio guia trata as orientações como recomendações, não regras, e o Cubit cumpre a mesma função (transformar dados dos repositórios em estado de tela e receber as ações do usuário). A injeção usa `RepositoryProvider`/`BlocProvider`, no lugar do `provider` do estudo de caso.

### Pastas (mesma divisão do app de exemplo oficial, o Compass)

```
lib/
  config/            # composição: quais implementações entram (normal ou E2E)
  routing/           # go_router: rotas e nomes
  data/
    services/        # wrappers sem estado: shared_preferences, banco (drift), stockfish, maia, vibração
    repositories/    # fonte da verdade de cada dado; interface + implementação(ões)
      settings/  profile/  positions/  progress/  ongoing_game/  opponent/
  domain/
    models/          # modelos imutáveis (freezed): AppSettings, UserProfile, EndgamePosition,
                     # Attempt, GameSnapshot, OpponentConfig, ClockState...
    use_cases/       # regras puras reutilizáveis: GameRules (dartchess), ClockEngine,
                     # ThinkTimePolicy, PickHumanMove (Maia + temperatura)
  ui/
    core/            # tema, widgets compartilhados, keys, extensões de l10n
    <feature>/
      view_models/   # Cubit/Bloc da tela
      widgets/       # view (página) e widgets da feature
  utils/             # Result, extensões
  l10n/              # ARB de cada idioma
testing/             # fakes e dados de teste compartilhados por unit e Patrol (como no Compass)
test/                # espelha lib/
integration_test/    # Patrol: cenários + robôs
tools/               # scripts Python
```

Features em `ui/`: `home`, `settings`, `board_settings`, `profile`, `free_board`, `catalog`, `game_setup`, `play`, `custom_position`, `result`, `about`, `debug`.

### Regras de dependência

- View só conhece o seu view model. View model conhece repositórios e use cases, **nunca serviços**.
- Repositórios usam serviços e devolvem modelos de domínio. São a única fonte da verdade de cada dado.
- Serviços não têm estado nem regra de negócio: só embrulham pacote ou plataforma.
- `domain/` é Dart puro: não importa Flutter nem `data/`.
- Erros atravessam camadas como `Result` (sucesso/falha), não como exceção solta.

### Contratos principais

```dart
// data/repositories/opponent/opponent_repository.dart
abstract class OpponentRepository {
  /// Escolhe o lance da máquina. O atraso de "pensar" é aplicado
  /// pelo view model da partida, usando ThinkTimePolicy.
  Future<Result<EngineMove>> pickMove(Position position, OpponentConfig config);
}
// implementações: StockfishOpponentRepository, MaiaOpponentRepository; FakeOpponentRepository em testing/

abstract class SettingsRepository    { Future<AppSettings> load(); Future<void> save(AppSettings s); }
abstract class ProfileRepository     { Future<UserProfile> load(); Future<void> save(UserProfile p); }
abstract class PositionsRepository   { Future<List<EndgamePosition>> bySubcategory(String id); }
abstract class ProgressRepository    { Future<void> addAttempt(Attempt a); Future<List<Attempt>> attemptsFor(String positionId); }
abstract class OngoingGameRepository { Future<void> save(GameSnapshot s); Future<GameSnapshot?> load(); Future<void> clear(); }

// data/services/maia_service.dart
abstract class MaiaService {
  /// Probabilidades sobre os lances legais (uci -> prob).
  Future<Map<String, double>> policy(String fen, {required int selfElo, required int oppoElo});
}

// domain/use_cases/now.dart
abstract interface class Now { DateTime call(); }   // relógio do sistema; falso nos testes
```

O relógio guarda **instantes** (quando a vez começou, quanto restava), não conta ticks: ao voltar do segundo plano o desconto é exato, e a partida pode ser restaurada se o sistema matar o app.

### Pacotes

`flutter_bloc`, `bloc_test`, `go_router`, `freezed` + `json_serializable`, `chessground` + `dartchess` (GPL-3.0), `flutter_localizations` + `intl`, `shared_preferences`, `drift`, pacote do Stockfish (o mais mantido no pub.dev), `patrol`, `flutter_lints`.

Licença: **AGPL-3.0** + `THIRD-PARTY-NOTICES.md`.

---

## 2. Idiomas

### Estratégia

- **Inglês é a base** (`app_en.arb`); todos os outros idiomas derivam dele.
- **Primeira tradução por IA**, revisão pela comunidade numa plataforma gratuita para projetos open source (Weblate ou Crowdin). Os arquivos traduzidos voltam por PR.
- **CI reprova** se algum idioma não tiver todas as chaves do inglês ou se houver texto fixo em widget (regra de lint).
- **Notação figurina** (♘f3) por padrão: os ícones das peças valem em qualquer idioma, ao contrário das letras (C/N/S/К...). Opção nas configurações para letras do idioma.
- **Direita para a esquerda** (árabe, persa, hebraico, urdu): a interface espelha, o tabuleiro não.
- **Pseudo-idioma de teste** que alonga os textos ~40%, para pegar layout quebrando com alemão, russo etc.
- Idiomas que o Flutter não traduz nos componentes nativos recebem um fallback para não quebrar.

### Idiomas (priorizados pelo tamanho das comunidades de xadrez)

**Grupo 1 (no MVP):** inglês, português (Brasil), português (Portugal), espanhol, francês, alemão, italiano, russo, ucraniano, polonês, turco, holandês, hindi, árabe, persa, chinês simplificado, japonês, coreano, vietnamita, indonésio.

**Grupo 2 (logo depois):** armênio, georgiano, azerbaijano, uzbeque, cazaque, mongol, húngaro, tcheco, romeno, grego, sérvio, croata, búlgaro, sueco, norueguês, dinamarquês, finlandês, catalão, hebraico, bengali, tâmil, telugo, marati, urdu, filipino, tailandês, malaio.

---

## 3. Nome do app

Concorrência direta encontrada: "Chess Endgame Training / Finales de Ajedrez" (jlomo) e "Fifty Moves: Chess Endgames". O nome precisa ser diferente e fácil de achar.

Recomendação: **marca curta + subtítulo traduzido por idioma** (o título da Play Store tem até 30 caracteres e cada idioma tem a sua ficha):

| Marca | Título em inglês | Em português | Por quê |
|---|---|---|---|
| **Lucena** | Lucena: Endgame Trainer | Lucena: Treino de Finais | A posição de final mais famosa; quem estuda finais reconhece; nome curto e de domínio público |
| Endgame Gym | Endgame Gym: Chess Trainer | Endgame Gym: Finais de Xadrez | Descritivo, ideia de treino diário |
| Zugzwang | Zugzwang: Chess Endgames | Zugzwang: Finais de Xadrez | Termo universal de finais, marcante, mas difícil de soletrar |

Antes de decidir: buscar na Play Store e na App Store, verificar domínio e consultar marcas no INPI (e, se for publicar fora, nos EUA e na Europa).

---

## 4. Conteúdo

As posições vêm do projeto open source **Chess Endgame Training / Finales de Ajedrez** (supertorpe/chessendgametraining, GPL-3.0), arquivo `code/src/static/endgamedatabase.json`:

- 3.571 posições em 8 categorias e 132 subcategorias (Básicos, Peões, Bispo, Cavalo, Cavalo-Bispo, Torre-Peões, Torre-Peças, Dama).
- Cada posição tem `fen`, `target` (`checkmate` = ganhar: 2.739; `draw` = segurar o empate: 832) e, em parte delas, `mateIn`.
- 2.904 posições têm até 7 peças (verificáveis pela tablebase); 667 têm mais.

Licença e crédito:

- O repositório é GPL-3.0 e a base de mates que ele usa (calebjcourtney/chess-endgame-training) também; ambos compatíveis com o app AGPL-3.0.
- A base de finais original veio do blog "ECO Chess Opening Codes", sem licença explícita. Dar crédito às três fontes no app e no `THIRD-PARTY-NOTICES.md`, e mandar um e-mail ao autor do projeto (endereço na política de privacidade do repositório) confirmando o uso.

Importação (script em `tools/import_positions.py`, roda uma vez e o resultado vai versionado):

1. Ler o JSON original e converter para o formato do app (abaixo), com `id` estável, categoria e subcategoria como chaves de tradução.
2. Verificar as posições de até 7 peças na API de tablebase do Lichess (com intervalo entre chamadas e cache local) e conferir com `target`; divergências vão para um relatório e saem do catálogo.
3. As de mais de 7 peças entram com `verified: false`, para validar depois com Stockfish.

Formato no app (`assets/positions/positions.json`):

```json
{
  "id": "rook-pawn.rook-vs-pawn.0007",
  "category": "rookPawn",
  "subcategory": "rookVsPawn",
  "fen": "<FEN>",
  "goal": "win",
  "mateIn": 24,
  "verified": true,
  "source": "supertorpe/chessendgametraining"
}
```

`goal`: `win` (só vitória conta) ou `draw` (empate ou vitória contam). O lado do usuário é o lado que joga no FEN.

---

## 5. Regras para a IA

- Uma entrega por sessão, contexto novo. Ler só `CLAUDE.md`, este plano e os arquivos citados.
- Cada entrega termina com: `dart format`, `flutter analyze`, testes unitários, cenário Patrol novo + suíte Patrol completa, PR com resumo curto.
- Estourou o escopo: parar e relatar.
- Modelo por entrega: o da linha "Modelo sugerido" de cada tarefa. O mais forte fica só para as entregas do Maia.

O `CLAUDE.md` e as skills completos estão no kit do repositório (seção 0).

### Convenções de teste (Patrol e widgets)

- **Keys centralizadas:** uma classe `AppKeys` por feature (`SettingsKeys.themeDark`, `PlayKeys.clockUser`...). Widget testado sem key não entra.
- **Robôs (page objects):** cada tela tem um robô em `integration_test/robots/` com ações e verificações (`settingsRobot.selectTheme(dark)`, `playRobot.expectClockUser('0:05')`). Os cenários só falam com robôs, nunca com finders soltos.
- **Modo de teste:** `--dart-define=E2E=true` injeta adversário falso, `Now` controlável e tempos curtos, para os cenários serem rápidos e determinísticos.
- **Banco limpo por cenário:** cada cenário começa com dados zerados, exceto quando testa persistência.
- **Captura de tela em falha** salva no relatório do CI.
- **Matriz mínima:** todo cenário roda em tema claro; a suíte de fumaça (seção 6, "Em toda tarefa") roda também em escuro e em árabe.

Se você já tem esse padrão (keys, robôs, helpers) em outro projeto, ele substitui o desta seção na T00, para os dois projetos ficarem iguais.

---

## 6. Tarefas

Cada tarefa é um entregável. Só começa quando as tarefas de "Depende de" já estão na `main`; dentro de uma frente, uma por vez.

### Frentes paralelas

O "Depende de" de cada tarefa lista só o que ela usa de verdade. Tarefas de frentes diferentes podem rodar ao mesmo tempo, cada uma na sua cópia de trabalho, com o seu emulador e o seu modelo.

| Frente | Tarefas, em ordem | O que a frente constrói |
| --- | --- | --- |
| A · Configurações | T01 → T02 → T03 | idiomas, tema, perfil e banco local |
| B · Tabuleiro | T04 → T05 → T06 → T07 → T08 | tabuleiro, relógio e restauração |
| C · Conteúdo | T09 → T10 | catálogo e posição customizada |
| D · Maia | T15 → T16 | referência, runtime e serviço do Maia |
| Convergência | T11 → T12 → T13 → T14 → T17 → T18 → T19 | junta as frentes: partida, Stockfish, progresso, Maia como adversário |

**Entregas (uma PR para várias tarefas).** Cada PR custa uns 15 minutos de verificação automática mais a sua validação no celular, então as tarefas saem agrupadas por marco: uma branch, uma candidata de QA, uma PR e uma validação sua.

| Entrega | Tarefas | O que você recebe | Tag | Modelo |
| --- | --- | --- | --- | --- |
| A | T02 + T03 + T04 | tema, perfil e tabuleiro livre | `v0.1.0` | Opus 5.5 |
| B | T05 + T06 + T07 + T08 | tabuleiro completo, relógio e restauração | `v0.1.4` | Opus 5.5 |
| C | T09 + T10 + T11 | catálogo, posição customizada e configuração da partida | `v0.1.7` | Opus 5.5 |
| D | T12 + T13 + T14 | Stockfish, resultado e progresso | `v0.2.2` | Opus 5.5 |
| T15 | sozinha | decisão do runtime do Maia (precisa da sua leitura) | `v0.3.0-alpha` | Fable 5.1 |
| E | T16 + T17 + T18 | Maia dentro do app, como adversário | `v0.3.2` | Fable 5.1 |
| T19 | sozinha | calibração no seu celular | `v1.0.0-mvp` | Fable 5.1 |

Ordem: A → B → C → D → E → T19. A T15 não depende de tela nenhuma e pode rodar a qualquer momento, em paralelo. As T09 e T10 só dependem da A: se a B atrasar, elas podem ser adiantadas em outra cópia de trabalho, e a T11 entra quando a B chegar na `main`.

Regras da entrega:

- branch `tarefa/TXX-TYY-nome-curto` (primeira e última tarefa), um commit por tarefa (`TXX: ...`) e PR com título `TXX + ... + TYY: ...`;
- a candidata usa a tag da última tarefa da entrega (a Entrega A sai como `v0.1.0-rc.N`); a tag final também é só essa;
- a PR traz os passos de teste e a demonstração de cada tarefa, e o checklist de cada uma é marcado no seu arquivo;
- antes de abrir a PR, o vídeo da entrega rodando no emulador vai para o Gabriel na conversa; a candidata de QA só sai depois do ok dele;
- o modelo é o da tarefa mais difícil da entrega;
- se uma tarefa emperrar, a entrega se desfaz: o que está pronto segue sozinho.

**Dificuldade e modelo.** Baixa e média: telas e persistência que seguem um padrão já existente (Sonnet 5.5). Alta: tarefa que cria padrão novo ou mexe com tempo, estado em segundo plano ou código nativo (Opus 5.5). Muito alta: porte e calibração do Maia (Fable 5.1). É estimativa: se uma tarefa precisar de várias rodadas de correção no modelo sugerido, sobe um degrau.

**Arquivos disputados.** Quase toda tarefa toca `pubspec.yaml`, os `.arb`, `router.dart`, `dependencies.dart` com `e2e_dependencies.dart`, a tela inicial e a fumaça. Para os conflitos ficarem pequenos:

- chaves de tradução agrupadas por tela e em ordem alfabética, não sempre no fim do arquivo;
- um arquivo de fumaça por tela (`integration_test/smoke/<tela>_smoke_test.dart`);
- quem entra na `main` depois da T01 traduz as chaves novas para todos os idiomas do Grupo 1;
- depois de cada merge, as outras frentes trazem a `main` para a sua branch antes de continuar.

**Antes de paralelizar** (ainda não feito):

- [ ] `versionCode` global e crescente (hoje é o número de commits da branch: duas frentes geram números fora de ordem e o celular recusa a candidata "mais antiga")
- [ ] Liberar o merge da `main` para dentro da branch de tarefa (hoje `git merge` é bloqueado nas permissões do Claude)
- [ ] Cópia de trabalho por frente com `.env` (emulador próprio) e `.claude/settings.json` copiados, já que não são versionados
- [ ] Cota do Test Lab: um aparelho por candidata, ou Test Lab só na candidata final de cada entrega
- [x] Dividir a fumaça em um arquivo por tela

**Pronto quando:** testes unitários e de BLoC passando · todos os cenários Patrol da tarefa passando · suíte Patrol anterior passando · CI verde · tag criada · APK na Release do GitHub · você validou no celular.

**Em toda tarefa (fumaça):** além dos cenários próprios, a tela nova é aberta em tema escuro e em árabe, e o app vai para segundo plano e volta sem perder estado.

### T00 · Esqueleto do projeto

Depende de: — · Tag: `v0.0.1`

Frente: Base · Dificuldade: média · Modelo sugerido: Fable 5.1

- [ ] Projeto Flutter com as pastas da seção 1, `go_router` e composição normal/E2E em `config/`
- [ ] `CLAUDE.md`, LICENSE (AGPL-3.0), `THIRD-PARTY-NOTICES.md`
- [ ] Idiomas (gen-l10n) com inglês e português
- [ ] CI: analyze, testes, checagem de traduções, build do APK
- [ ] Patrol com keys, robôs, modo E2E e banco limpo por cenário
- [ ] Tela inicial

**Cenários Patrol:**

1. Abrir o app → tela inicial visível
2. Rotacionar o aparelho → continua em retrato
3. Abrir sem internet (modo avião) → app funciona normalmente

### T01 · Idioma

Depende de: T00 · Tag: `v0.0.2`

Frente: A · Configurações · Dificuldade: média · Modelo sugerido: Opus 5.5

- [ ] Idioma padrão = idioma do sistema
- [ ] Troca manual em Configurações, com persistência
- [ ] Tradução inicial dos idiomas do Grupo 1
- [ ] Direita para a esquerda

**Cenários Patrol:**

1. Sistema em português → app abre em português
2. Trocar para espanhol → reiniciar → espanhol
3. Trocar para árabe → layout espelhado e textos em árabe
4. Voltar para "idioma do sistema" → segue o sistema de novo
5. Pseudo-idioma longo → nenhum texto cortado nas telas existentes

### T02 · Tema do app

Depende de: T01 · Tag: `v0.0.3`

Frente: A · Configurações · Dificuldade: baixa · Modelo sugerido: Sonnet 5.5

Lote: Entrega A · T02 + T03 + T04 (mesma branch, mesma candidata de QA e uma PR só)

- [ ] Claro, escuro, sistema
- [ ] Persistência

**Cenários Patrol:**

1. Escolher escuro → reiniciar → escuro
2. Escolher "sistema" → mudar o tema do celular → app acompanha
3. Escuro + árabe ao mesmo tempo → telas corretas

### T03 · Perfil local

Depende de: T01 · Tag: `v0.0.4`

Frente: A · Configurações · Dificuldade: média · Modelo sugerido: Sonnet 5.5

Lote: Entrega A · T02 + T03 + T04 (mesma branch, mesma candidata de QA e uma PR só)

- [ ] Apelido e rating aproximado (por faixas) no banco local
- [ ] Validação dos campos

**Cenários Patrol:**

1. Editar apelido e rating → reiniciar → mantidos
2. Rating escolhido num painel de faixas com nome (iniciante, casual... mestre), traduzido; fechar o painel sem confirmar → nada muda
3. Apelido vazio → usa o padrão
4. Editar e sair sem salvar → nada muda

### T04 · Tabuleiro livre

Depende de: T00 · Tag: `v0.1.0`

Frente: B · Tabuleiro · Dificuldade: alta · Modelo sugerido: Opus 5.5

Lote: Entrega A · T02 + T03 + T04 (mesma branch, mesma candidata de QA e uma PR só)

- [ ] Tabuleiro na posição inicial, lances legais pelos dois lados
- [ ] Promoção, roque, en passant
- [ ] Lista de lances

**Cenários Patrol:**

1. e4 e5 Cf3 → lista com os três lances
2. Tentar lance ilegal → peça volta, nada muda
3. Roque pequeno numa posição preparada
4. En passant numa posição preparada
5. Promover a cavalo (subpromoção)
6. Mate do pastor → fim de partida

### T05 · Aparência do tabuleiro

Depende de: T04, T01 · Tag: `v0.1.1`

Frente: B · Tabuleiro · Dificuldade: baixa · Modelo sugerido: Sonnet 5.5

Lote: Entrega B · T05 + T06 + T07 + T08 (mesma branch, mesma candidata de QA e uma PR só)

- [ ] Tema de cores, conjunto de peças (licença compatível), coordenadas
- [ ] Pré-visualização ao vivo
- [ ] Persistência

**Cenários Patrol:**

1. Trocar peças → pré-visualização muda → reiniciar → mantido
2. Trocar tema do tabuleiro → reiniciar → mantido
3. Desligar coordenadas → somem do tabuleiro de jogo também
4. Restaurar padrão → volta tudo ao original

### T06 · Comportamento do tabuleiro

Depende de: T05 · Tag: `v0.1.2`

Frente: B · Tabuleiro · Dificuldade: alta · Modelo sugerido: Opus 5.5

Lote: Entrega B · T05 + T06 + T07 + T08 (mesma branch, mesma candidata de QA e uma PR só)

- [ ] Arrastar/tocar, mostrar lances legais, destacar último lance
- [ ] Animação, virar tabuleiro, pré-lances
- [ ] Notação figurina ou por letras
- [ ] Persistência

**Cenários Patrol:**

1. Só "tocar" → arrastar não move, tocar move
2. Desligar lances legais → reiniciar → continua desligado
3. Virar tabuleiro → orientação invertida e lista inalterada
4. Trocar para notação por letras em português → lista mostra C/B/T/D/R
5. Pré-lance feito na vez do adversário é executado em seguida

### T07 · Relógio

Depende de: T04, T01 · Tag: `v0.1.3`

Frente: B · Tabuleiro · Dificuldade: alta · Modelo sugerido: Opus 5.5

Lote: Entrega B · T05 + T06 + T07 + T08 (mesma branch, mesma candidata de QA e uma PR só)

- [ ] Tempo e incremento separados por lado
- [ ] Décimos abaixo de 10 s, posição do relógio, vibração
- [ ] Perda por tempo

**Cenários Patrol:**

1. Partida de 5 s → não mexer → bandeira e tela de fim
2. Incremento de 2 s → após o lance, o relógio soma 2 s
3. Tempos diferentes por lado (1+0 contra 3+2) → cada relógio mostra o seu
4. Abaixo de 10 s → aparecem os décimos
5. Relógio em cima vs. embaixo → muda de lugar
6. Bandeira com material insuficiente do adversário → empate, não derrota

### T08 · Segundo plano e restauração

Depende de: T07 · Tag: `v0.1.4`

Frente: B · Tabuleiro · Dificuldade: alta · Modelo sugerido: Opus 5.5

Lote: Entrega B · T05 + T06 + T07 + T08 (mesma branch, mesma candidata de QA e uma PR só)

- [ ] Relógio baseado em instantes
- [ ] Partida salva a cada lance
- [ ] Restauração após o sistema fechar o app

**Cenários Patrol:**

1. Relógio rodando → tela inicial do celular por 5 s → voltar → 5 s descontados
2. Bloquear a tela → desbloquear → tempo correto
3. Fechar à força → reabrir → mesma posição, lista e tempo
4. Tempo acaba com o app em segundo plano → ao voltar, tela de fim por tempo
5. Partida terminada → reabrir → não restaura partida já encerrada

### T09 · Catálogo de posições

Depende de: T04 · Tag: `v0.1.5`

Frente: C · Conteúdo · Dificuldade: média · Modelo sugerido: Opus 5.5 (o script de importação pode ser adiantado com Sonnet 5.5)

Lote: Entrega C · T09 + T10 + T11 (mesma branch, mesma candidata de QA e uma PR só)

- [ ] Script de importação e verificação (seção 4)
- [ ] Catálogo: categoria → subcategoria → lista de posições (carregamento sob demanda)
- [ ] Abrir posição no modo dois jogadores
- [ ] Filtro por objetivo (ganhar/defender)

**Cenários Patrol:**

1. Abrir uma posição conhecida → FEN e lado corretos
2. Filtrar "defender" → só posições de empate
3. Rolar uma subcategoria grande → sem travar
4. Nomes de categorias traduzidos em espanhol e árabe
5. Posição com `mateIn` → informação exibida

### T10 · Posição customizada

Depende de: T09 · Tag: `v0.1.6`

Frente: C · Conteúdo · Dificuldade: média · Modelo sugerido: Sonnet 5.5

Lote: Entrega C · T09 + T10 + T11 (mesma branch, mesma candidata de QA e uma PR só)

- [ ] Colar FEN ou montar no editor
- [ ] Validação com mensagens traduzidas
- [ ] Escolha do objetivo

**Cenários Patrol:**

1. FEN inválido → erro
2. FEN sem rei → erro específico
3. Lado que não joga em xeque → erro
4. Montar no editor e iniciar → partida começa
5. Colar FEN válido → partida começa no lado correto

### T11 · Configuração da partida

Depende de: T07, T10 · Tag: `v0.1.7`

Frente: Convergência · Dificuldade: baixa · Modelo sugerido: Sonnet 5.5

Lote: Entrega C · T09 + T10 + T11 (mesma branch, mesma candidata de QA e uma PR só)

- [ ] Lado do usuário, tempo do usuário, tempo da máquina
- [ ] Adversário (só "dois jogadores" nesta tarefa)
- [ ] Última configuração lembrada

**Cenários Patrol:**

1. 3+2 para o usuário e 1+0 para a máquina → relógios corretos
2. Reiniciar → configuração mantida
3. Tempo zero → bloqueado com erro
4. Trocar o lado → tabuleiro vira para o usuário

### T12 · Adversário Stockfish

Depende de: T11 · Tag: `v0.2.0`

Frente: Convergência · Dificuldade: alta · Modelo sugerido: Opus 5.5

Lote: Entrega D · T12 + T13 + T14 (mesma branch, mesma candidata de QA e uma PR só)

- [ ] `OpponentRepository`
- [ ] Stockfish no aparelho, força máxima
- [ ] Tempo por lance tirado do relógio da máquina

**Cenários Patrol:**

1. Jogar um lance → máquina responde lance legal e o relógio dela desconta
2. Posição com mate em 1 para a máquina → ela dá mate
3. Máquina com pouco tempo → responde rápido e não perde por tempo
4. Desistir durante a vez da máquina → fim de partida imediato

### T13 · Resultado e progresso

Depende de: T12, T03 · Tag: `v0.2.1`

Frente: Convergência · Dificuldade: média · Modelo sugerido: Sonnet 5.5

Lote: Entrega D · T12 + T13 + T14 (mesma branch, mesma candidata de QA e uma PR só)

- [ ] Objetivo cumprido ou não
- [ ] Tentativa salva e histórico por posição
- [ ] Marca de "cumprido" no catálogo

**Cenários Patrol:**

1. (adversário falso) Ganhar posição de `win` → cumprido → marca no catálogo → reiniciar → marca continua
2. Empatar posição de `win` → não cumprido
3. Empatar posição de `draw` → cumprido
4. Histórico mostra as tentativas em ordem
5. Jogar de novo a partir do resultado → mesma posição e configuração

### T14 · Segundo plano com a máquina pensando

Depende de: T12, T08 · Tag: `v0.2.2`

Frente: Convergência · Dificuldade: alta · Modelo sugerido: Opus 5.5

Lote: Entrega D · T12 + T13 + T14 (mesma branch, mesma candidata de QA e uma PR só)

- [ ] Estado e relógios consistentes durante a vez da máquina

**Cenários Patrol:**

1. Sair durante a vez da máquina → voltar → partida continua
2. Fechar à força durante a vez da máquina → reabrir → restaurada e a máquina joga
3. Bloquear a tela durante a vez da máquina → desbloquear → consistente

### T15 · Referência e decisão de runtime do Maia

Depende de: T00 · Tag: `v0.3.0-alpha`

Frente: D · Maia · Dificuldade: muito alta · Modelo sugerido: Fable 5.1

- [x] Fixtures do PyTorch oficial
- [x] Spike: ONNX ou porte para Dart
- [x] Decisão em `docs/decisao-maia-runtime.md`

**Cenários Patrol:**

1. Sem Patrol (entrega interna); testes comparam com as fixtures

### T16 · Maia dentro do app

Depende de: T15 · Tag: `v0.3.0`

Frente: D · Maia · Dificuldade: muito alta · Modelo sugerido: Fable 5.1

Lote: Entrega E · T16 + T17 + T18 (mesma branch, mesma candidata de QA e uma PR só)

- [x] `MaiaService`
- [x] Tela de depuração (só em build de desenvolvimento)

**Cenários Patrol:**

1. Posição conhecida → lance mais provável igual ao das fixtures
2. Mesma posição em 1000 e 2600 → distribuições diferentes
3. Modo avião → funciona

### T17 · Maia como adversário e níveis

Depende de: T16, T12, T03 · Tag: `v0.3.1`

Frente: Convergência · Dificuldade: alta · Modelo sugerido: Fable 5.1

Lote: Entrega E · T16 + T17 + T18 (mesma branch, mesma candidata de QA e uma PR só)

- [x] Níveis de 1000 a 2600 (degraus de 200; piso 1000 pela visão de gamificação), temperatura por nível
- [x] Maia por nível ou Stockfish máximo
- [x] Rating do perfil sugere o nível

**Cenários Patrol:**

1. Maia 1400 → responde lances legais
2. Perfil com rating 1800 → nível sugerido 1800
3. Trocar para Stockfish → reiniciar → mantido
4. Posição de `draw` contra Maia 1000 → partida termina normalmente

### T18 · Tempo de pensar humano

Depende de: T17 · Tag: `v0.3.2`

Frente: Convergência · Dificuldade: alta · Modelo sugerido: Fable 5.1

Lote: Entrega E · T16 + T17 + T18 (mesma branch, mesma candidata de QA e uma PR só)

- [x] `ThinkTimePolicy`

**Cenários Patrol:**

1. Partida 3+2 → tempos variados e a máquina nunca perde por tempo
2. Recaptura óbvia → resposta quase imediata
3. Máquina com menos de 10 s → joga mais rápido

### T19 · Calibração e fechamento do MVP

Depende de: T18 · Tag: `v1.0.0-mvp`

Frente: Convergência · Dificuldade: alta · Modelo sugerido: Fable 5.1

- [ ] Medir ms por lance no celular (botão "Medir velocidade" no Diagnóstico do Maia: dez contas e o tempo típico; falta o número do aparelho do Gabriel)
- [x] Ajustar temperatura e tempo por nível (`docs/calibracao.md`): temperatura 0,5 em todos os níveis; a regra de tempo da T18 fica como está
- [x] Empate automático por repetição (três vezes) e pela regra dos 50 lances nas partidas contra a máquina: sem isso, defender um final de torre não terminava nunca (achado na calibração)
- [x] Configuração do treino só com Maia e Stockfish, sem "dois jogadores" (pedido do Gabriel)
- [x] Versão do app no pé da tela inicial (pedido do Gabriel)
- [x] Suíte Patrol com variantes: `--dart-define=E2E_VARIANT=dark` e `=ar`

**Cenários Patrol:**

1. Suíte completa em claro, escuro e árabe
2. Medir a velocidade mostra o tempo típico por lance
3. Repetir a posição três vezes contra a máquina → empate → objetivo de empatar cumprido (a contagem sobrevive a reiniciar)
4. A variante pedida vale de verdade (tema e direção do texto)

---

## 7. Depois do MVP

Idiomas do Grupo 2, doação pelo Google Play Billing, modelo 23M opcional (2000–2600), textos explicativos por tema, posições geradas por tablebase, ficha da Play Store traduzida e publicação.

---

## 8. Depois do MVP: progressão e gamificação (T20–T27)

Visão completa em `docs/VISAO-GAMIFICACAO.md`. Cada tarefa é uma entrega inteira (uma PR, sem lote), com o detalhe em `docs/tasks/TXX.md`. A T20 fecha as decisões em `docs/arquitetura-gamificacao.md` e precisa da leitura do Gabriel antes da T21.

| Tarefa | Entrega | Depende de | Tag | Modelo |
| --- | --- | --- | --- | --- |
| T20 | Arquitetura e regras (speedrun, rating, falas, arte) | T15 | — | Fable 5.1 |
| T21 | Jornada: escada 1000 → Stockfish, finais do iniciante, domínio e histórico | T20, T17 | `v1.1.0` | Opus 5.5 |
| T22 | Maia no ritmo humano (bullet a clássico) e rating do jogador | T20, T19, T21 | `v1.2.0` | Fable 5.1 |
| T23 | Speedrun de nível e de final, com parciais, recordes e histórico | T21 | `v1.3.0` | Opus 5.5 |
| T24 | Speedrun de exercícios e completo, conquistas e feedback | T22, T23 | `v1.4.0` | Opus 5.5 |
| T25 | Personagens: avaliação, eventos, emoção e banco de falas | T20, T22 | `v1.5.0` | Fable 5.1 |
| T26 | Personagens: avatares (PNGs do Gabriel, sem animação) | T25 | `v1.6.0` | Sonnet 5.5 |
| T27 | Primeira abertura: tour e nível inicial | T24, T26 | `v1.7.0` | Sonnet 5.5 |

Ordem: T20 → T21 → (T22 e T23 em paralelo) → T24 → T25 → T26 → T27. A T23 só precisa da Jornada, então pode sair antes da T22.

Princípios (visão, seção 34): rating, progressão, domínio e speedrun são coisas separadas; o Maia não vira engine artificialmente fraca, nem no bullet; personagens têm comportamento, não só imagem; falas dependem do contexto; speedrun não pune demais; tudo dirigido por dados.

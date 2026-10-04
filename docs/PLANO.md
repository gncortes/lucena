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

Rodadas possíveis, cada uma depois do merge da anterior:

1. T01 ‖ T04 ‖ T15 (mais o script de importação da T09, que é só Python)
2. T02 ‖ T05 ‖ T16 ‖ T09
3. T03 ‖ T06 ‖ T10
4. T07 → T08, e daí a convergência

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
- [ ] Cota do Test Lab: um aparelho por candidata, ou Test Lab só na candidata final de cada tarefa
- [ ] Dividir a fumaça em um arquivo por tela

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

- [ ] Claro, escuro, sistema
- [ ] Persistência

**Cenários Patrol:**

1. Escolher escuro → reiniciar → escuro
2. Escolher "sistema" → mudar o tema do celular → app acompanha
3. Escuro + árabe ao mesmo tempo → telas corretas

### T03 · Perfil local

Depende de: T01 · Tag: `v0.0.4`

Frente: A · Configurações · Dificuldade: média · Modelo sugerido: Sonnet 5.5

- [ ] Apelido e rating aproximado no banco local
- [ ] Validação dos campos

**Cenários Patrol:**

1. Editar apelido e rating → reiniciar → mantidos
2. Rating fora da faixa (ex.: 5000) → erro traduzido, nada salvo
3. Apelido vazio → usa o padrão
4. Editar e sair sem salvar → nada muda

### T04 · Tabuleiro livre

Depende de: T00 · Tag: `v0.1.0`

Frente: B · Tabuleiro · Dificuldade: alta · Modelo sugerido: Opus 5.5

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

- [ ] Estado e relógios consistentes durante a vez da máquina

**Cenários Patrol:**

1. Sair durante a vez da máquina → voltar → partida continua
2. Fechar à força durante a vez da máquina → reabrir → restaurada e a máquina joga
3. Bloquear a tela durante a vez da máquina → desbloquear → consistente

### T15 · Referência e decisão de runtime do Maia

Depende de: T00 · Tag: `v0.3.0-alpha`

Frente: D · Maia · Dificuldade: muito alta · Modelo sugerido: Fable 5.1

- [ ] Fixtures do PyTorch oficial
- [ ] Spike: ONNX ou porte para Dart
- [ ] Decisão em `docs/decisao-maia-runtime.md`

**Cenários Patrol:**

1. Sem Patrol (entrega interna); testes comparam com as fixtures

### T16 · Maia dentro do app

Depende de: T15 · Tag: `v0.3.0`

Frente: D · Maia · Dificuldade: muito alta · Modelo sugerido: Fable 5.1

- [ ] `MaiaService`
- [ ] Tela de depuração (só em build de desenvolvimento)

**Cenários Patrol:**

1. Posição conhecida → lance mais provável igual ao das fixtures
2. Mesma posição em 600 e 2600 → distribuições diferentes
3. Modo avião → funciona

### T17 · Maia como adversário e níveis

Depende de: T16, T12, T03 · Tag: `v0.3.1`

Frente: Convergência · Dificuldade: alta · Modelo sugerido: Fable 5.1

- [ ] Níveis de 600 a 2600 (degraus de 200), temperatura por nível
- [ ] Maia por nível ou Stockfish máximo
- [ ] Rating do perfil sugere o nível

**Cenários Patrol:**

1. Maia 1400 → responde lances legais
2. Perfil com rating 1800 → nível sugerido 1800
3. Trocar para Stockfish → reiniciar → mantido
4. Posição de `draw` contra Maia 600 → partida termina normalmente

### T18 · Tempo de pensar humano

Depende de: T17 · Tag: `v0.3.2`

Frente: Convergência · Dificuldade: alta · Modelo sugerido: Fable 5.1

- [ ] `ThinkTimePolicy`

**Cenários Patrol:**

1. Partida 3+2 → tempos variados e a máquina nunca perde por tempo
2. Recaptura óbvia → resposta quase imediata
3. Máquina com menos de 10 s → joga mais rápido

### T19 · Calibração e fechamento do MVP

Depende de: T18 · Tag: `v1.0.0-mvp`

Frente: Convergência · Dificuldade: alta · Modelo sugerido: Fable 5.1

- [ ] Medir ms por lance no celular
- [ ] Ajustar temperatura e tempo por nível (`docs/calibracao.md`)

**Cenários Patrol:**

1. Suíte completa em claro, escuro e árabe

---

## 7. Depois do MVP

Idiomas do Grupo 2, doação pelo Google Play Billing, modelo 23M opcional (2000–2600), textos explicativos por tema, posições geradas por tablebase, ficha da Play Store traduzida e publicação.

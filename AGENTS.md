# AGENTS.md: como qualquer IA trabalha no Lucena (Claude, Copilot, Gemini, Codex…)

Este é o ponto de entrada comum. Instruções e estrutura Codex podem ser versionadas;
dados pessoais, permissões locais, sessões e caches permanecem ignorados. Leia nesta ordem:
1. `CLAUDE.md`: as regras do projeto (arquitetura, l10n, keys, git, segredos). **Valem para qualquer IA.**
2. `docs/tasks/T65.md`: a tarefa atual, com as prioridades **0 = economia**, **1 = UX** e **2 = aulas**.
3. A fila da frente escolhida. UI: `docs/tasks/T65-UI.md` e o checkpoint curto `docs/tasks/T65-UI-retomada.md`; consultar `T65-UI-andamento.md` somente para dúvida concreta/histórico. AULAS: `T65-AULAS.md`/`T65-AULAS-andamento.md`, em `docs/tasks/`. Depois leia **só** o item citado em `T64-pendencias.md`.

## Princípio
**Qualidade inegociável, com o mínimo de tokens.** Economize no processo, nunca no resultado:
- script antes de IA;
- uma tarefa pequena por vez;
- estado sempre em arquivo.
Prints e vídeos são lidos e conferidos sempre que servirem para julgar.

## Roteamento: tipo de tarefa → papel → nível de modelo
Cada papel é um arquivo de instrução. Ferramentas com subagentes (Claude) chamam o agente. As outras (Copilot, Gemini) **leem o arquivo do papel e o seguem** na própria sessão.

| Tarefa | Papel (arquivo de instrução) | Nível de modelo |
|---|---|---|
| Item de UX/layout (código, teste, commit) | `.github/agents/implementador-ux.agent.md` + `.github/prompts/ux.prompt.md` | médio/forte (Opus, GPT-5, Gemini Pro) |
| Prints, MP4, medir centralização | `.claude/agents/capturador-telas.md` (biblioteca `.claude/skills/rodada-ajustes/scripts/telas.py`) | barato (Sonnet, Haiku, Flash) |
| Rodada de ajustes pedidos pelo Gabriel | `.claude/skills/rodada-ajustes/SKILL.md` | orquestrador médio |
| Revisar a lição de uma aula (só relata) | `.claude/agents/revisor-licoes.md` | forte |
| Revisar exercícios / falas | `.claude/agents/revisor-aulas.md`, `.claude/agents/revisor-falas.md` | forte |
| Criar/reescrever aula | `.claude/skills/aula-final/` (`licao.md`, `formato.md`, `glossario.md`) | forte (Fable só com justificativa) |
| Cobertura de lances, links, numeração | scripts em `tools/lessons/` (sem IA); a IA só lê o resultado | — |
| Patrol (ponta a ponta) | `.github/prompts/patrol.prompt.md` | médio, só quando o Gabriel liberar |
| Entrega / QA / PR | `.claude/skills/entrega/SKILL.md`, `.claude/skills/qa-release/SKILL.md` | médio, só quando o Gabriel pedir |

## Regras de economia (resumo; versão completa na seção "Economia" de `.claude/skills/rodada-ajustes/SKILL.md`)
- **Leia só o que a tarefa cita.** Não leia `build/`, `.dart_tool/`, `assets/models/`, `tools/.cache/` nem os arquivos gerados (`*.g.dart`, `*.freezed.dart`, `assets/lessons/endgames/*.json`), salvo quando a tarefa pedir.
- **Mecânico é script.** Rodar o script e ler a saída curta, em vez de raciocinar sobre arquivos grandes.
- **Motores com cache** em `tools/.cache/analysis/`: nunca recalcular uma posição já analisada.
- **Uma sessão por frente.** Ao terminar, registre o estado no andamento exclusivo da frente e feche. A próxima sessão começa por esse arquivo; T65-andamento.md é histórico.
- **Fila sem conversa** para trabalho repetitivo: `.claude/scripts/fila.sh` (briefs em `docs/fila/`).
- **Custo** de cada item em `docs/tasks/custos.md`.

## Regras de qualidade (nunca pular)
- `flutter analyze` zerado e testes da área verdes antes de cada commit. Commit só na branch `tarefa/...`, **nunca** na develop nem na main, e sem merge.
- Todo item de tela termina em **print ou MP4 conferido**. A centralização é medida (diferença acima × abaixo ≤ 5%, na área entre a barra de status e a de navegação).
- **Emuladores com segurança de memória (PC do Gabriel):** cada emulador gasta ~4,3 GB. Antes de subir qualquer um, rode `DONO=<nome-da-sessão> bash .claude/skills/rodada-ajustes/scripts/emuladores.sh estado` e **nunca suba acima do que ele diz**. A regra deixa folga de 12 GB livres, ou 18 GB com outro emulador aberto ou o Chrome acima de 6 GB. São no máximo 6 cópias, ou 3 com outro emulador (como o da Cogna), e metade disso com a CPU acima de 70%.
  - Suba e desça só pelo script (`subir N`, `aliviar`, `descer`).
  - Nunca `emulator ... &` solto, nunca 8 emuladores (o PC travou em 2026-10-05) e nunca o `emulator-5554`.
  - Se a memória apertar no meio, rode `aliviar`, até zero se for preciso. Este projeto nunca é a prioridade do PC.
- O `emulator-5554` é do Gabriel. Segredos nunca são lidos nem impressos. O Patrol só roda com o ok dele.
- Aulas: régua de 2026-10-11 (`licao.md` e `revisor-licoes.md`). Nenhuma aula sai de `assets/lessons/endgames/review.json` sem a nota A confirmada pelo Gabriel.
- Gostos do Gabriel: referências no Lichess e no chess.com, consistência entre os estados, folha do Viktor embaixo e texto formal e didático.

## Ferramentas (MCPs)
Veja `docs/ia/SETUP-MCP.md`. Com o MCP **mobile**, sempre escolha um emulador `5560`+, nunca o `5554`.

## Erros que já cometemos (não repetir)
- **"Centralizado" pela conta, não pela tela.** Medir sempre a % na área real da tela (diferença ≤ 5%) e olhar o print.
- **Aula aprovada como A por um revisor só.** Todas eram D. Use o painel, a cobertura de lances (tablebase, Stockfish e Maia) e confira os links. Lance que ganha nunca é recusado (1.Rd3 em Casas-chave, 4.c3 na Italiana).
- **Link com rótulo errado** ("Ver no Lichess" abria a Wikipedia) e URL crua na tela.
- **Fala do Viktor cortada** em cima do tabuleiro. A folha fica embaixo, passa por baixo dos FABs e vira modal.
- **X que apaga o progresso** sem perguntar (speedrun). Toda ação destrutiva pede confirmação, e o estado sobrevive ao segundo plano.
- **Animação inventada sem pedido** (o voo do editor, que o Gabriel recusou). Implementar o que foi pedido e mostrar antes de enfeitar.
- **Orquestrador longo** (US$ 395 numa sessão). Prefira sessões curtas por frente, com o estado em arquivo.
- **Dizer que está pronto sem evidência.** Todo item termina em print ou MP4 conferido.

## Ao terminar uma sessão
Atualize o andamento exclusivo da frente (item, estado, commit, print, obs) e responda em até 5 linhas: o que mudou, onde está o print e o que falta.

## Codex: roteamento nativo

No Codex, delegue tarefas delimitadas quando houver ganho real, usando `.codex/agents/*.toml` e `~/.codex/agents/*.toml`. Leia `.codex/README.md` apenas para configurar ou diagnosticar. Não execute a fila Claude pelo Codex. Os arquivos `.claude` citados continuam como fontes comuns de regras e ferramentas, somente leitura; não crie outra régua.

- UX: `implementador_ux`; evidência: `capturador_telas`; pedagogia: `revisor_licoes`; reescrita: `editor_falas`.
- Scripts/varredura: `triagem`; código geral: `implementador`; revisão: `revisor`; problema difícil com justificativa: `especialista`.
- No máximo três filhos simultâneos, sem delegação recursiva. Brief curto, contexto novo, um dono por arquivo. Alterações pequenas ficam no principal; builds e emuladores são coordenados por ele.
- Os papéis definem modelo e esforço. Se a interface não aceitar nome de papel, leia o TOML e use modelo/esforço explícitos com `fork_turns=none`; passe as instruções no brief. Não suponha seleção automática.
- Sem commits durante configuração da orquestração. Patrol, publicação e aprovação de aulas mantêm as autorizações existentes.

## Codex: triagem e fila de xadrez

Ao receber tarefa, faça automaticamente levantamento curto antes de implementar: objetivo e aceite, arquivos e estado existentes, dependências, se envolve posição/tabuleiro ou avaliação enxadrística, scripts/caches disponíveis, recursos locais realmente executáveis e modelo necessário. Registre em arquivo e devolva só resumo. Não delegue esse levantamento trivial se poucos comandos bastarem.

Na mesma fila, respeite prioridades explícitas e dependências primeiro; entre itens independentes da mesma prioridade, execute simples → intermediários → complexos. Deixe os complexos para o fim sem adiar pré-requisitos, bugs bloqueadores ou decisões indispensáveis à correção. Registre justificativa das exceções. Não dispare Astra em paralelo só por estar disponível.

Para xadrez: confira FEN, lado a jogar, legalidade, orientação e correspondência entre texto, setas e posição real. Faça análise reproduzível por scripts antes do julgamento do modelo. Consulte `tools/.cache/analysis/` antes de recalcular; preserve metadados de motor, versão, profundidade, candidatos, resultado e fonte. Mesmo FEN com parâmetros insuficientes pode exigir complementação fundamentada, sem invalidar caches de outro trabalho.

- Stockfish local confirmado: `~/.local/bin/stockfish` (19). Use `tools/analysis_cache.py stockfish <FEN> --engine-path <binário>`, com profundidade e candidatos definidos; limite recursos e serialize alterações do mesmo cache/FEN.
- Tablebase: cache primeiro, depois Syzygy local se disponível ou API `https://tablebase.lichess.ovh/standard?fen=...`, somente posições suportadas (até sete peças). Considere lado a jogar, regra dos 50 lances, WDL e DTZ; indisponibilidade não significa empate. Não baixe coleções de tabelas sem pedido.
- Maia: `tools/maia/reference.py` e wrapper de cache, ambiente/pesos verificados antes de executar. Use 1000/1400/1800/2200, lances >=10% e top 2 para cobertura humana. Não confunda Maia com prova de melhor lance.
- “Lila” pode significar Leela/Lc0: identifique nome, caminho, pesos e backend antes de usar; não trate o servidor Lila do Lichess como motor. Leela é complementar para planos/conceitos quando disponível e útil; não invente integração nem instalação.
- O principal executa ferramentas que escrevem caches e entrega resultados curtos aos revisores em leitura. Se faltarem motores, dependências ou rede, registre o bloqueio e avance em itens independentes; não instale pacotes nem altere ambiente por suposição.
- Use `especialista_xadrez` (GPT-6 Astra/high) para finais difíceis, confronto de avaliações, planos e coerência didática complexa, com justificativa no brief. O modelo interpreta evidências; variantes e avaliações exigem motores/fontes verificadas. Sol/high continua nas revisões comuns, Luna/low nas verificações mecânicas. Não há garantia de superioridade enxadrística sem avaliação.
- Implementação só depois de resolver dúvidas que afetam lances aceitos ou resultado. Revisão independente e evidência visual continuam obrigatórias quando aplicáveis; nenhuma aula ganha aprovação A automaticamente.

Autorizado para tarefas solicitadas: consultar motores locais identificados, scripts existentes, cache local e tablebase pública; respeite limites reais de sandbox/rede e recursos do PC. Isso não amplia acesso a segredos, não libera Patrol, commits/publicação ou alterações do Claude. Regras Codex ficam em `.codex/rules/chess.rules`; permissões do Claude permanecem intactas.

## Codex: permissões rotineiras

Os comandos usuais estão autorizados em `.codex/rules/project.rules`. Para gerenciamento de emuladores use `bash .codex/scripts/emuladores.sh <dono-unico-da-sessao> estado|lista|subir|instalar|aliviar|descer [argumento]`. Reutilize o mesmo dono ao retomar e nunca assuma emuladores da outra sessão. O wrapper chama o gerenciador existente e confere estado antes de subir, preservando a proteção de memória e do 5554. Evite comandos inline com `DONO=...`, `python -c`, heredocs ou grandes `bash -lc`: regras por prefixo podem não reconhecê-los; grave roteiros delimitados e use os comandos autorizados. Não amplie permissões para contornar políticas administradas.

## Codex: aulas e decisões enxadrísticas — regra atual

Na mesma fila, faça UX/layout antes de aulas e decisões de xadrez, respeitando dependências e prioridades explícitas. Qualquer julgamento sobre lances, avaliação, dificuldade e ensino no tabuleiro é complexo: `revisor_licoes`, `editor_falas` e `especialista_xadrez` usam GPT-6 Astra/high. Captura/varredura sem julgamento enxadrístico continua econômica; implementação de UI continua Sol. Esta regra substitui as recomendações anteriores de usar Sol para revisão ou redação enxadrística substantiva.

Antes de trabalho em aulas, leia `.codex/chess-review.md`: motores provam legalidade/resultados, Maia estima candidatos por nível, Astra interpreta e ensina. Não atribua pensamentos exatos ao jogador nem dificuldade calibrada sem dados; cubra top 2 e alternativas além dos 10%, ramificações e respostas. Os scripts existentes têm limitações documentadas; não certifique cobertura completa só pelo relatório atual. Uma revisão antes e uma independente depois da reescrita, sem laços de pareceres. A régua comum e a confirmação A pelo Gabriel continuam obrigatórias.

No Codex, toda análise/revisão de aula inclui dificuldade da aula inteira, partes e exercícios, com público-alvo e evidências, além de nota didática por critério e plano de melhoria. Formato obrigatório em `.codex/chess-review.md`; sem dados, dificuldade é estimativa não calibrada.


## Codex: estratégia Pro 5x

Principal Sol 6.1/medium; filhos genéricos Luna/low. Simples fica no principal quando
delegação não compensa. Intermediária usa implementador; decisões complexas usam
especialista Astra/high com justificativa. Papel global critico Astra/xhigh só para
riscos críticos, com revisão independente e validações proporcionais. A regra
específica Astra/high para aulas permanece. Filhos têm agents.enabled=false.
Até três filhos, sem aumento automático; revisão futura exige métricas de ganho e
cota real suficiente. Para frentes grandes, use $codex-frente e registre os seis
critérios de execução; mantenha estado no andamento exclusivo da frente. Modelos e perfis atuais em
.codex/README.md. Monitoramento sem inferência: .codex/scripts/probe.py, /status e
painel oficial. As métricas ausentes não são estimadas nem convertidas em dólares.


## Codex: duas frentes T65 — decisão atual de Gabriel

UI e AULAS podem avançar em paralelo; a regra de UX antes de aulas se aplica
somente quando estiverem na mesma fila ou houver dependência concreta. Entrada e
donos em docs/tasks/T65.md. Launcher: bash docs/tasks/codex-t65.sh ui|aulas.
Cada terminal tem até um filho aberto por vez e seu próprio andamento; a configuração
global de três filhos permanece, sem ser um limite agregado entre processos.
UI não altera conteúdo/avaliações/falas de aulas; AULAS não altera app/ARBs/widgets.
Widgets, schema, APK e evidências cruzadas exigem handoff, não escrita compartilhada.
UI coordena Flutter/build/instalação/emuladores; ferramentas Flutter usam o lock
da T65. AULAS possui motores/caches e conteúdo. Não atualizar quadros compartilhados
por rotina. Claude, gitignore local e mudanças existentes são preservados.
O piloto A oposição começa na frente AULAS: preservar antes/depois, Astra/high para
revisão/reescrita, revisão final independente, comparação e retorno de Gabriel antes
de expandir. Nenhuma aula recebe aprovação A automática nem sai de review.json.

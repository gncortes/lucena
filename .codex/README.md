# Codex no Lucena — Pro 5x

Auditado na CLI **0.162.1**, em 2026-10-11. Configuração global existente
preservada; nenhum arquivo do Claude alterado. Reinicie a sessão para carregar
instruções e papéis atualizados.

## Estrutura

| Local | Responsabilidade |
|---|---|
| `~/.codex/config.toml` | Principal Sol 6.1/medium, filhos Luna/low, limite três, MCPs existentes |
| `~/.codex/AGENTS.md` | Instruções pessoais de coordenação e consumo |
| `~/.codex/agents/*.toml` | Cinco papéis genéricos reutilizáveis |
| `~/.codex/<perfil>.config.toml` | Perfis economico, equilibrado, complexo e critico |
| `~/.agents/skills/codex-frente/SKILL.md` | Procedimento reutilizável para frentes grandes |
| `AGENTS.md` | Regras e donos do projeto |
| `.codex/config.toml` | Padrões nativos de filhos, sem alterar permissões |
| `.codex/agents/*.toml` | Cinco especialistas do Lucena |
| `.codex/chess-review.md` | Protocolo específico de aulas |
| `.codex/scripts/validate.py` | Validação mecânica de papéis, catálogo, perfis e Git |
| `.codex/scripts/probe.py` | Consulta operacional pelo app-server, sem turno de modelo |
| `.codex/scripts/run_brief.py` | Brief delimitado, processo sequencial com timeout e JSONL |
| `.codex/local/` | Relatórios, snapshots, backups e resultados pessoais ignorados |

## Modelos e papéis

| Complexidade | Execução |
|---|---|
| Simples | Script ou principal direto; triagem Luna/low quando delegar compensar |
| Intermediária | Sol 6.1/medium |
| Complexa | Sol/high para código; Astra/high para decisões justificadas |
| Crítica | Astra/xhigh, revisão independente e testes dos riscos concretos |

Globais: **triagem** (Luna/low, leitura), **implementador** (Sol/medium),
**revisor** (Sol/high, leitura), **especialista** (Astra/high, leitura),
**critico** (Astra/xhigh, leitura).
Projeto: **implementador_ux** (Sol/medium), **capturador_telas** (Luna/low),
**revisor_licoes**, **editor_falas**, **especialista_xadrez** (Astra/high).
Revisores não editam o produto. Todos os filhos têm `agents.enabled=false`.

O catálogo autenticado desta instalação anunciou sete modelos: GPT-6.1 Sol,
GPT-6 Astra, GPT-6 Sol, GPT-6 Luna, GPT-5.6 Sol, GPT-5.6 Terra e GPT-5.6 Luna.
Os seis primeiros anunciaram multi-agent v2; GPT-5.6 Luna, v1. Isso comprova
catálogo/capacidade anunciada, não uma inferência de custo nem uma execução
remota de cada modelo. Reconsultar o serviço se disponibilidade mudar.

Perfis: `codex -p economico|equilibrado|complexo|critico`. São escolhas de
inicialização, não um roteador automático. O coordenador decide a complexidade.
Papéis definem explicitamente modelo e esforço para evitar herança cara.
Se a ferramenta não expuser papel, ler seu TOML e fornecer instruções/modelo/
esforço em contexto novo. Não presumir que o arquivo foi carregado.

## Delegação e economia

Até **três filhos simultâneos por sessão**, sem contar o principal. Não há limite
agregado nativo entre processos independentes; o runner de briefs usa lock por
projeto. A regra específica de T65 continua: um filho por terminal de frente.
Mais filhos só após evidência comparável de tempo, qualidade, tokens e cota;
nunca aumentar automaticamente em função do plano.

Antes de frente grande, registrar complexidade/dependências, necessidade de filhos,
modelo/esforço, paralelismo útil, risco de consumo e aceite. Um dono por arquivo,
brief curto, contexto novo, resumo até15linhas, estado persistido para retomada.
Agrupar leituras, usar scripts/caches, não repetir testes verdes sem novo motivo.
Principal coordena SDK, builds e dispositivos. Fast/priority, max e ultra não são
padrões de economia. Nenhum teto financeiro garantido ou custo em dólares inferido.

## Consumo e validação

```sh
python3 .codex/scripts/probe.py --output .codex/local/probe.json
python3 .codex/scripts/validate.py
python3 .codex/scripts/run_brief.py triagem caminho/brief.md --timeout 600
```

`probe.py` consulta config/modelos/skills/conta/limites/atividade via app-server e
imprime somente campos operacionais. Não lê `auth.json`, emails ou credenciais.
Use também `/status` e o [painel oficial](https://chatgpt.com/codex/settings/usage).
O identificador interno da conta retornou `prolite`; não deduzir multiplicador
5x ou saldo fixo desse nome. Percentuais, janelas e horários da conta ficam
somente no relatório local ignorado. São snapshots, não garantias futuras.
Tokens/cache/atividade histórica, contexto e franquia são métricas diferentes.
O JSONL de um brief registra tokens quando o evento final os fornece; não somar
notificações cumulativas repetidas. Métricas ausentes ficam indisponíveis.

## Git e preservação

`.codex` e `AGENTS.md` **não são ignorados por inteiro**. Papéis, instruções e
scripts são compartilháveis; ficam ignorados sessões, caches, credenciais,
backups, bancos locais e regras existentes com caminhos pessoais.
Configurações globais são pessoais e permanecem fora deste repositório.
Nada em `.claude`, `CLAUDE.md` ou configurações globais Claude foi modificado.
Foram reaproveitados escopos claros, scripts, revisão independente e estado curto;
nenhum YAML ou flag específica do Claude foi copiada para o Codex.

Políticas administradas, sandbox e permissões continuam prevalecendo. Não habilitar
Patrol, publicação, acesso a segredos ou aprovação A por consequência desta estrutura.
O runner usa `fcntl` e é específico de Linux/POSIX nesta instalação.

Fontes oficiais: [subagentes](https://learn.chatgpt.com/docs/agent-configuration/subagents),
[configuração](https://learn.chatgpt.com/docs/config-file/config-basic),
[app-server](https://learn.chatgpt.com/docs/app-server),
[consumo](https://learn.chatgpt.com/docs/pricing).
Aprendizados: `retrospectiva-2026-10-11.md` (consultar sob demanda).
Estado e evidências da auditoria: `.codex/local/orchestration-20261011.md`.

## Duas frentes T65

Entrada em `docs/tasks/T65.md`, filas e andamentos próprios. Launcher:
`bash docs/tasks/codex-t65.sh ui|aulas`. Cada terminal usa um filho; worktree,
donos e handoffs explícitos impedem escrita concorrente. UI coordena Flutter/APK/
emuladores; AULAS mantém conteúdo e motores. Integração de conteúdo exige hashes
e checkpoint visual. Nenhuma aula recebe aprovação A automática.

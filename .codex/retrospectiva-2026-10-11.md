# Retrospectiva de consumo — 2026-10-11

O usuário relatou consumo excessivo nesta sessão. A conta expôs um snapshot de
uso agregado; não há medição isolada que permita atribuir uma quantidade de
tokens ou dólares a esta conversa. Os problemas abaixo foram observados no trabalho.

| Erro observado | Correção para a próxima sessão |
|---|---|
| Frente de UI extensa mantida no mesmo contexto, acumulando relatos de tentativas | Checkpoint atual até60linhas; retomar um item fechado, consultar histórico apenas por dúvida |
| Andamento com295linhas/29KB e registros intermediários contraditórios | Entrada curta T65-UI-retomada.md, estado atual primeiro, evidência inválida marcada claramente |
| Saídas de git branch/diff e documentação maiores que o necessário | Limitar branch atual, paths/linhas e max_output_tokens; logs extensos locais |
| Consultas repetidas de rótulos ADB para cada toque | Preparar roteiro curto por cenário e agrupar controles já conhecidos; dump só ao mudar/errar |
| Captura Coco iniciou depois de a análise terminar | Gravar antes de tocar; testar progresso com engine controlada e conferir frames antes de nomear prova |
| Builds sucessivos revelaram estados/resize não cobertos previamente | Matriz de estado/tamanho e teste comportamental de resize antes do build, um APK para lote pronto |
| Reordenação do resumo remontou o State da história do Viktor | Preservar identidade dos widgets e testar início/fim; revisão independente capturou o risco |
| Parecer chamou limitação de URI de aceita sem decisão explícita do usuário | Distinguir limitação técnica documentada de aprovação do usuário |
| Validador exigia ignorar toda estrutura Codex apesar do pedido atual de versionar | Testar casos positivos e negativos do gitignore e manter documentação coerente |
| Integração inicial usava FEN sem contadores e não conectava o feedback na lição | Comparar implementação com cada requisito do brief; chave completa e teste negativo de cada componente, sem aproximação implícita |
| Gate começou antes de o implementador terminar dois testes adicionais | Só iniciar validação após liberação explícita de todos os arquivos; resumir entrega e congelar a escrita antes do SDK |
| Auditoria Dart repetiu conflito entre File de dart:io e dartchess | Importar somente os símbolos necessários (`show Move`) ou usar alias `io` desde o início |

Não usar estas medidas para reduzir qualidade: Flutter analyze, testes dos riscos,
revisão independente quando necessária e prints/MP4 realmente conferidos continuam.
Não repetir testes verdes sem alteração/falha/preocupação concreta; ao editar depois
de validar, verificar apenas a área afetada e completar o gate final exigido.

Não carregar este documento inteiro em cada tarefa. As regras curtas estão no
AGENTS global; consultar este relato somente para problema semelhante.
Configuração validada por parser/prompt nativo e runner offline, sem turnos de IA
extras apenas para provar que cada modelo responde. Catálogo não é execução real.

---
name: rodada-ajustes
description: Orquestra uma rodada de ajustes de tela pedidos pelo Gabriel na conversa (vários pedidos em sequência, pelo celular). Cada pedido vira um item num quadro em arquivo, que é implementado por mim ou por um agente, capturado em emuladores sem janela em paralelo e enviado como print para ele validar. Sem Patrol até ele dizer "tudo ok". Use sempre que ele pedir ajuste, mudança ou correção de tela, texto ou fluxo, ou chamar /rodada-ajustes. Depois de um /compact, retome por aqui.
---

# Rodada de ajustes (orquestrador)

O Gabriel acompanha pelo celular e manda pedidos em sequência, muitas vezes antes de o anterior terminar. Meu papel é **organizar a casa**:
- cada pedido vira um item no quadro;
- cada item anda até virar print no celular dele;
- nada se perde entre um pedido e outro nem num `/compact`.

## Regras fixas

1. **Sem Patrol na rodada.** Nem a suíte, nem cenário solto, nem as variantes. A validação são os prints.
   - O Patrol só roda quando ele disser "está tudo ok, pode rodar os testes".
   - Elogio a uma tela ("ficou legal") aprova só aquele item.
   - `flutter analyze` e `flutter test` continuam a cada integração, porque são rápidos.
2. **Todo item termina em print no celular.** Nunca dizer que um item está feito sem a evidência enviada (SendUserFile) dos cenários que ele pediu.
   - Se um estado não dá para capturar (ex.: some rápido demais), dizer isso em uma linha.
3. **O quadro é a fonte da verdade**, e eu o atualizo **antes** de responder a cada mensagem dele.
   - Fica em `<checkout principal>/docs/rodadas/<branch>.md` (modelo em `quadro.md`). `docs/` é ignorado pelo git e é comum a todos os worktrees.
   - Depois de um `/compact`, o primeiro passo é ler o quadro.
4. **Uma branch só para a rodada**: a da tarefa (`tarefa/...`, criada da `develop`). Pedidos novos entram nela, e a PR só abre no fim.
5. **Emuladores só pelo `scripts/emuladores.sh`**, com `DONO=<nome da pasta do scratchpad>`.
   - O 5554 é do Gabriel: nunca entra na conta.
   - Se houver emulador de outra sessão, não subo nenhum: implemento e commito, e os prints esperam.
   - **Este projeto nunca é a prioridade do PC.** Com outro projeto rodando em paralelo (o emulador da Cogna, Chrome pesado, build de outro app), abro menos emuladores. Se a memória apertar no meio da rodada, fecho os meus (`aliviar`), até zero se for preciso, e capturo em fila no que sobrar.
   - No fim da rodada, ou quando ele pedir, rodo `emuladores.sh descer`.
6. **Pedido ambíguo** (qual tela, qual fala, qual botão): perguntar só sobre aquele item, numa linha, e seguir com os outros.
   - Na dúvida entre duas telas, perguntar antes de mexer. Em 2026-10-09 mexi na fala errada e tive que desfazer.

## A cada mensagem dele

1. **Ler o quadro**, se não estiver fresco na conversa.
2. **Separar a mensagem em itens.** Um item é uma tela ou um comportamento.
   - Para cada item, anotar as palavras dele (curtas), as telas e os cenários onde aparece, e o estado `fila`.
   - Feedback sobre item enviado: marcar `aprovado` ou `refazer`, com o que ele disse. Decisão dele vai para "Decisões".
3. **Responder logo, em 1 a 3 linhas**: o que entrou no quadro (ids) e o que já está andando. O trabalho pesado roda em segundo plano para a conversa continuar interativa.
4. **Despachar** os itens em `fila` (ver "Quem faz").
5. **Integrar, montar o build e capturar** assim que houver item pronto (ver abaixo), sem esperar a próxima mensagem.

## Quem faz (gastar o mínimo)

| Item | Quem | Modelo |
|------|------|--------|
| Ajuste pequeno: texto, espaçamento, cor, trocar ou mover um widget, até 2 a 3 arquivos | eu, direto | — |
| Ajuste médio: widget novo, estado no cubit, l10n em todos os idiomas, testes | agente `general-purpose` | opus |
| Lógica difícil ou conteúdo de xadrez (variantes, aulas, motor) | agente `general-purpose`, ou o revisor da área | fable |
| Prints de um grupo de itens num emulador | agente `capturador-telas` | sonnet |
| Conferência mecânica (chaves, strings, varredura) | agente `Explore` ou `general-purpose` | sonnet |

**Agentes que mexem no código:**
- Rodam em segundo plano, com `isolation: "worktree"`, e cada um pega itens de áreas diferentes.
- O brief é curto: ids, palavras do Gabriel, arquivos prováveis e as regras do `CLAUDE.md` que importam (l10n em todos os `.arb` + `gen_pseudo_l10n` + `gen-l10n` + `check_l10n`, keys de `*_keys.dart`, tokens `AppMotion`/`AppShape`, `Now`).
- Pedir: commit na branch do worktree, `flutter analyze` e os testes da área verdes, e um relatório em tabela (`id | arquivos | testes | dúvida`).
- Não pedem print, porque os prints são do orquestrador.

**Integração** (eu):
- `git cherry-pick` dos commits do agente na branch da rodada.
- Conflito em `.arb`: manter as duas chaves e regenerar o l10n.
- Depois, `flutter analyze` + `flutter test`, e um commit por item ou grupo (mensagem em português, dizendo a tela e o que mudou).
- Os itens passam para `no build` quando o APK com eles estiver instalado.

## Build e emuladores

1. **APK de release:**
   - Rodar `flutter build apk --release` no worktree da rodada, em segundo plano, e conferir `✓ Built` na saída. O build pode falhar em silêncio e deixar o APK velho.
   - Um build só por vez; os itens prontos enquanto ele roda vão no próximo.
2. **Emuladores** (`scripts/emuladores.sh`, rodando `DONO=<id> emuladores.sh ...`):
   - `estado` mostra quantos cabem. A conta deixa sempre folga para o PC não travar:
     - 12 GB livres, ou 18 GB com outro emulador ou com o Chrome passando de 6 GB;
     - no máximo 6 cópias, ou 3 com outro emulador aberto;
     - metade disso com a CPU acima de 70%.
   - Rodar `estado` antes de cada `subir`, nunca subir acima do que ele diz e rodar `aliviar` antes de cada lote de prints.
   - `subir N` liga N emuladores, com N = itens esperando print, até o que cabe.
   - `instalar <apk>` usa `install -r`, que mantém os dados.
   - Os emuladores ficam ligados durante a rodada, porque subir de novo custa minutos.
3. **Capturar:**
   - Distribuir os itens em grupos, um grupo por emulador, juntando os que usam o mesmo caminho no app (ex.: tudo que acontece depois de uma partida).
   - Grupo pequeno (1 item, roteiro que já existe): eu rodo o roteiro em segundo plano. Grupo maior: um `capturador-telas` por emulador, em paralelo.
   - Os roteiros e os prints ficam no scratchpad (`<scratchpad>/rodada/<id>.py`, prints em `<scratchpad>/rodada/prints/`).
   - Fluxo novo que se repete (ex.: jogar até a conclusão, abrir uma aula numa etapa) vira função em `scripts/telas.py`, para a próxima rodada.
4. **Conferir e enviar:**
   - Abrir o composto de cada item (uma leitura de imagem) e confirmar que mostra o pedido.
   - Enviar **um SendUserFile por item, assim que ficar pronto**, sem esperar os outros. A legenda leva o id, o que mudou e o cenário de cada tela.
   - **Item com transição** (animação, layout que troca, folha que sobe): mandar também o GIF (`gravar`/`parar` do `telas.py`). Pedido do Gabriel em 2026-10-09: GIF é o que ele prefere para validar movimento.
   - Marcar `enviado` no quadro.

## Depois de um /compact

1. Ler o quadro.
2. Rodar `DONO=<id> emuladores.sh estado`, `git -C <worktree> log --oneline -10` e `git status`.
3. Agentes listados como em andamento: esperar a notificação deles. Não abrir de novo o mesmo trabalho.
4. Retomar do primeiro item que não está `enviado` nem `aprovado`.

## Fim da rodada

Só quando ele disser que está tudo ok, ou mandar subir:
1. `emuladores.sh descer`.
2. Skill `entrega`: a suíte Patrol em paralelo (`tools/patrol_parallel.sh`, até 6 emuladores, nas variantes clara, escura e árabe), depois a `qa-release` (tag rc, link) e a PR para a `develop`.
3. Anotar no quadro: PR, tag, e a lista do que ficou para depois.

## Tropeços já vistos

- **"Jogar" na tela do desafio** abre a escolha do ritmo, e é preciso tocar em "Confirmar". `play_from_setup` já faz isso.
- **Partida curta:** a análise rápida roda sozinha e acaba antes do print. O estado "rodando" só aparece numa partida longa.
- **Rótulo fora da tela não aparece no uiautomator.** Rolar antes (`scroll_to`) em vez de concluir que sumiu.
- **Seta de dica no tabuleiro** confunde `locate_board`: localizar o tabuleiro antes de pedir a dica.
- **Edição de `.arb` por regex** já apagou chaves de outras traduções. Editar chave por chave e conferir com `check_l10n.py`.
- **Pedido sobre "a fala que some":** confirmar de quem é a fala e em que tela antes de mexer.

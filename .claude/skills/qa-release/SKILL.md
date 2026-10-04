---
name: qa-release
description: Gera a versão de QA de uma tarefa (build de release + Patrol no Firebase Test Lab + Firebase App Distribution + tag rc) e abre ou atualiza o PR com resumo e link do app. Use ao terminar uma tarefa, depois da skill `entrega`, e a cada correção pedida no PR.
---

# QA release: do branch ao link no celular

Objetivo: quando o PR chega, o Gabriel abre no app do GitHub, lê um resumo curto, toca no link, instala o app e valida como QA. Só ele aprova e faz o merge.

Duas ferramentas do Firebase, cada uma com um papel:

- **Test Lab:** roda a suíte Patrol em aparelhos reais/virtuais do Google. É a última barreira automática.
- **App Distribution:** entrega o APK de release ao Gabriel por um link que abre no celular (app "Firebase App Tester").

As duas rodam no GitHub Actions (`.github/workflows/qa.yml`), disparadas pela tag de candidata. As credenciais do Google Cloud e a keystore ficam só no GitHub (ambiente `release`): nada disso passa pela máquina local nem pelo Claude.

## Regras

- Nunca fazer merge, nunca dar push na `main`, nunca criar tag final (`vX.Y.Z`). Só tags de candidata (`vX.Y.Z-rc.N`) e só no branch da tarefa.
- Se qualquer etapa falhar, **não** abrir nem atualizar o PR com link. Corrigir, ou parar e relatar.
- Nunca imprimir, ler ou commitar segredos (keystore, senhas, chave de conta de serviço) nem mexer nos segredos do GitHub (`gh secret`).
- Todo PR e todo comentário de correção leva um **GIF da feature rodando no emulador** (seção "Demonstração"). Sem GIF, o PR não está pronto.
- Rodar pelo script (`scripts/qa_release.sh`), não comando por comando: economiza tokens e evita erro de digitação.
- O workflow já repete o Test Lab **uma vez** sozinho em caso de instabilidade do aparelho. Se reprovou mesmo assim, é falha de teste de verdade: corrigir o código, não rodar de novo.

## Pré-requisitos (conferir antes de rodar)

1. Branch atual é `tarefa/TXX-...` e não há mudanças sem commit.
2. Skill `entrega` concluída: `flutter analyze`, `flutter test` e a suíte Patrol local passando.
3. Ambiente `release` configurado no GitHub, com o segredo `QA_CONFIG_ENV` (cópia do `config.env`, que não é versionado) e os de assinatura (`SETUP.md`). O workflow confere e para cedo se faltar algo.
4. `gh` instalado e com login (o script confere).

## Versão e tag

- Versão base vem da tarefa: a tag listada em `docs/tasks/TXX.md` (ex.: `v0.1.3`).
- Cada envio para QA é uma candidata: `v0.1.3-rc.1`, `v0.1.3-rc.2`...
- O script calcula o próximo `rc.N` olhando as tags existentes. Candidata reprovada gasta o número: a próxima é `rc.N+1`.
- `versionName` no app = `0.1.3-rc.N`; `versionCode` = número de commits do repositório (sempre cresce, então o celular aceita a atualização).
- A tag final `v0.1.3` é criada pelo Gabriel depois do merge.

## Passo a passo

1. Ler `docs/tasks/TXX.md` para pegar a tag base e os cenários Patrol.
2. Rodar:
   ```bash
   bash .claude/skills/qa-release/scripts/qa_release.sh TXX v0.1.3
   ```
   Rodar em segundo plano: leva de 15 a 30 minutos. O script, em ordem:
   1. confere pré-requisitos;
   2. calcula `rc.N`;
   3. envia o branch e cria e envia a tag `vX.Y.Z-rc.N`, que dispara o workflow `QA`;
   4. espera o workflow, que:
      1. gera o build do Patrol e roda a suíte no Test Lab (aparelhos do `QA_CONFIG_ENV`);
      2. gera o APK de release assinado (sem `E2E`);
      3. envia o APK para o App Distribution, com notas de versão, para o grupo de testadores;
   5. baixa e imprime o `result.json` (links, versão, aparelhos, status).
3. Usar **só** o `result.json` que o script imprime no fim da saída (a leitura de `build/` é bloqueada). Se `status` não for `ok`, o script imprime também as últimas 50 linhas dos passos que falharam no workflow: corrigir ou relatar.
4. Gravar o GIF da feature no emulador local:
   ```bash
   bash .claude/skills/qa-release/scripts/qa_gif.sh TXX v0.1.3-rc.1 -- <comando>
   ```
   O script grava a tela enquanto `<comando>` roda, salva o GIF em `docs/qa/TXX/<rótulo>.gif` e imprime a linha de Markdown para o PR. Depois: commit do GIF (`TXX: GIF da <rótulo>`), push e trocar `<sha>` na linha pelo commit do GIF. O `<comando>` deve mostrar o que a tarefa mudou, do jeito que o Gabriel vai ver:
   - telas e fluxos: o cenário Patrol da tarefa (`patrol test -t integration_test/<feature>_test.dart -d <aparelho> --dart-define=E2E=true`);
   - abertura, animação, tema ou navegação em ritmo de gente: um roteiro curto com `adb` no build de release instalado. Para tocar nos elementos, `python3 .claude/skills/qa-release/scripts/ui_tap.py "<rótulo>"` acha o elemento pelo texto, dica ou descrição (`--list` mostra os rótulos da tela); voltar é `adb shell input keyevent KEYCODE_BACK`. Deixar 1 a 2 s entre as ações.
   - o Gabriel acompanha pelo celular, onde GIF não anima na conversa: para mostrar uma prévia antes do PR, mandar o vídeo MP4 (`ffmpeg -i x.gif -pix_fmt yuv420p x.mp4`) e uma imagem com os quadros principais.
   Manter o GIF curto (até uns 20 s; o script recusa acima de 4 MB, porque ele entra no histórico do repositório) e conferir alguns quadros antes de colocar no PR.
5. PR:
   - **Não existe PR para o branch:** criar com `gh pr create` usando o modelo abaixo.
   - **PR já existe (correção):** adicionar um comentário com `gh pr comment` usando o modelo de correção. Não editar o resumo original.
6. Responder ao Gabriel com o link do PR e o link do app, em duas linhas.

## Modelo do PR (novo)

Título: `TXX: <título da tarefa>`

```markdown
## Resumo
<até 3 linhas: o que mudou para o usuário, sem jargão de código>

## Demonstração
<linha de Markdown impressa pelo qa_gif.sh: GIF da feature no emulador>

## Testar no celular
📲 **[Instalar v0.1.3-rc.1](<testerLink>)**

1. <passo curto que exercita a mudança>
2. <passo>
3. <o que deve acontecer>

## Verificações automáticas
- ✅ Testes unitários e de BLoC
- ✅ Patrol local
- ✅ Patrol no Firebase Test Lab: <aparelhos> ([resultado](<testLabLink>))

<details>
<summary>Detalhes técnicos</summary>

- Cenários Patrol cobertos: <lista>
- Arquivos principais: <lista curta>
- Pendências: <ou "nenhuma">
</details>

---
Aprovar = fazer o merge. Achou problema? Comente aqui que eu corrijo e mando uma nova versão.
```

Regras do resumo: português, no máximo 3 linhas, foco no que o Gabriel vai ver no app. Passos de teste: no máximo 5, cada um com uma ação.

## Modelo de comentário (correção)

```markdown
## Correção: v0.1.3-rc.2
<1–2 linhas: o que foi corrigido, citando o comentário que pediu>

<GIF novo, mostrando a correção>

📲 **[Instalar v0.1.3-rc.2](<testerLink>)**

Para conferir: <1–3 passos>

✅ Testes, Patrol local e Test Lab passando ([resultado](<testLabLink>))
```

## Quando o Gabriel comenta um problema no PR

1. Ler os comentários novos do PR (`gh pr view --comments`), só os posteriores ao último envio.
2. Corrigir no mesmo branch, com teste que reproduza o problema (quando possível, também um cenário Patrol).
3. Rodar a skill `entrega` e depois esta skill de novo: sai `rc.N+1` e um comentário novo no PR.

## Erros comuns

- **Falta segredo ou configuração no GitHub:** parar e pedir ao Gabriel (`SETUP.md`); nunca criar segredo.
- **Falha de infraestrutura (permissão no Google Cloud, cota):** depois de corrigida, repetir a mesma candidata com `gh run rerun <id> --failed` em vez de gastar outro `rc`.
- **Cota do Test Lab esgotada:** relatar; não abrir PR sem o Test Lab (a menos que o Gabriel autorize explicitamente no chat).
- **`versionCode` repetido:** o workflow usa a contagem de commits; se reclamar, fazer um commit e rodar de novo.
- **GIF com barras pretas, cortado ou pesado demais:** o `qa_gif.sh` grava em 720 px na proporção da tela e recusa GIF acima de 4 MB; encurtar o roteiro em vez de baixar a qualidade.
- **Link não aparece no resultado:** o formato da saída do `gcloud` ou do Firebase CLI pode ter mudado; conferir o log do workflow e ajustar os `grep` do `qa.yml`.

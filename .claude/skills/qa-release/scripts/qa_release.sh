#!/usr/bin/env bash
# Uso: qa_release.sh TXX vX.Y.Z
# Cria a tag de candidata (vX.Y.Z-rc.N), que dispara o workflow QA no GitHub
# (Patrol no Test Lab + APK assinado no App Distribution), espera o fim e imprime o resultado.
# Nenhuma credencial do Firebase ou da keystore passa por esta máquina: ficam no GitHub.
set -euo pipefail

TASK="${1:?informe a tarefa, ex.: T05}"
BASE_TAG="${2:?informe a tag base, ex.: v0.1.3}"
WORKFLOW="qa.yml"
OUT_DIR="build/qa-release"
RESULT="$OUT_DIR/result.json"
mkdir -p "$OUT_DIR"
rm -f "$RESULT"

# O resultado vai também para a saída: a leitura de build/ é bloqueada para o Claude.
fail() {
  printf '{"status":"erro","etapa":"%s","mensagem":"%s"}\n' "$2" "$1" | tee "$RESULT"
  exit 1
}
log() { echo "[$(date +%H:%M:%S)] $*"; }

# 1. Pré-requisitos
log "Conferindo pré-requisitos"
BRANCH="$(git rev-parse --abbrev-ref HEAD)"
[[ "$BRANCH" == tarefa/* ]] || fail "branch atual ($BRANCH) não é tarefa/*" "pre"
[[ -z "$(git status --porcelain)" ]] || fail "há mudanças sem commit" "pre"
[[ "$BASE_TAG" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]] || fail "tag base inválida ($BASE_TAG), esperado vX.Y.Z" "pre"
command -v gh >/dev/null || fail "comando gh não encontrado" "pre"
gh auth status >/dev/null 2>&1 || fail "gh sem login (rodar: gh auth login)" "pre"

# 2. Versão
git fetch --tags --quiet origin || fail "git fetch das tags falhou" "versao"
BASE="${BASE_TAG#v}"
LAST_RC="$(git tag --list "v${BASE}-rc.*" | sed -E 's/.*-rc\.([0-9]+)$/\1/' | sort -n | tail -1)"
RC=$(( ${LAST_RC:-0} + 1 ))
RC_TAG="v${BASE}-rc.${RC}"
SHA="$(git rev-parse HEAD)"

# 3. Branch e tag rc (a tag dispara o workflow)
log "Enviando o branch e a tag $RC_TAG"
git push --quiet -u origin "$BRANCH" || fail "push do branch falhou" "tag"
git tag -a "$RC_TAG" -m "$TASK QA ${RC_TAG#v}"
git push --quiet origin "$RC_TAG" || fail "push da tag falhou" "tag"

# 4. Workflow QA
log "Esperando o workflow QA começar"
RUN_ID=""
for _ in $(seq 1 24); do
  RUN_ID="$(gh run list --workflow "$WORKFLOW" --commit "$SHA" --json databaseId,headBranch \
    --jq "map(select(.headBranch == \"$RC_TAG\"))[0].databaseId // empty")"
  [[ -n "$RUN_ID" ]] && break
  sleep 5
done
[[ -n "$RUN_ID" ]] || fail "o workflow QA não começou para a tag $RC_TAG" "workflow"
RUN_URL="$(gh run view "$RUN_ID" --json url --jq .url)"

log "Acompanhando $RUN_URL"
if ! gh run watch "$RUN_ID" --exit-status --interval 30 >/dev/null 2>&1; then
  echo "--- últimas 50 linhas dos passos que falharam"
  gh run view "$RUN_ID" --log-failed | tail -n 50 || true
  fail "workflow QA reprovou a $RC_TAG: $RUN_URL" "workflow"
fi

# 5. Resultado
gh run download "$RUN_ID" --name qa-result --dir "$OUT_DIR" || fail "resultado do workflow não encontrado: $RUN_URL" "resultado"
log "Pronto: $RESULT"
cat "$RESULT"

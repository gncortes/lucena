# Configuração única (feita pelo Gabriel, uma vez)

A skill só funciona depois disto. O Claude Code não deve fazer estes passos sozinho.

Onde fica cada coisa:

| O quê | Onde | Segredo? |
| --- | --- | --- |
| IDs do Firebase, aparelhos, provedor e conta de serviço | `config.env` local (não versionado; modelo em `config.env.example`), gravado no segredo `QA_CONFIG_ENV` do ambiente `release` | não versionado |
| Keystore e senhas de assinatura | segredos do ambiente `release` no GitHub | sim |
| Acesso ao Google Cloud | Workload Identity Federation (sem chave) | não existe chave |

Na máquina local ficam o `config.env` e o backup da keystore. Nenhum JSON de conta de serviço é criado.

## 1. Firebase
Antes: `cp .claude/skills/qa-release/config.env.example .claude/skills/qa-release/config.env` (o `config.env` está no `.gitignore`).

1. Criar o projeto no console do Firebase (ex.: `lucena`). Copiar o **ID do projeto** para `FIREBASE_PROJECT_ID` no `config.env`.
2. Adicionar o app Android com o ID `com.gncortes.lucena`. Copiar o **App ID** (`1:...:android:...`) para `FIREBASE_ANDROID_APP_ID`.
3. **App Distribution:** ativar e criar dois grupos: `qa` (versões de candidata, da `develop`; adicionar o seu e-mail) e `release` (versões finais, da `main`; todo mundo).
4. No celular: aceitar o convite que chega por e-mail e instalar o app **Firebase App Tester** quando pedido. A partir daí, cada link do PR abre direto nele.
5. **Test Lab:** ativar no projeto (roda só na tag final, no `release.yml`). O plano gratuito tem cota diária limitada de execuções; confira no console se basta para o seu ritmo ou se vale o plano pago (cobrança por uso).

## 2. Acesso do GitHub ao Google Cloud (sem chave)
Os workflows `qa.yml` e `release.yml` entram no Google Cloud com um token de curta duração emitido pelo próprio GitHub. O acesso é liberado só para este repositório.

```bash
source .claude/skills/qa-release/config.env
PROJECT_ID="$FIREBASE_PROJECT_ID"
REPO="gncortes/lucena"
PROJECT_NUMBER="$(gcloud projects describe "$PROJECT_ID" --format='value(projectNumber)')"
SA="qa-release@$PROJECT_ID.iam.gserviceaccount.com"

gcloud services enable testing.googleapis.com toolresults.googleapis.com \
  firebaseappdistribution.googleapis.com iamcredentials.googleapis.com --project "$PROJECT_ID"

# Conta de serviço com o mínimo: Test Lab e App Distribution
gcloud iam service-accounts create qa-release --project "$PROJECT_ID"
for role in roles/cloudtestservice.testAdmin roles/firebase.analyticsViewer roles/firebaseappdistro.admin; do
  gcloud projects add-iam-policy-binding "$PROJECT_ID" --member "serviceAccount:$SA" --role "$role"
done

# Só tokens do GitHub Actions deste repositório são aceitos
gcloud iam workload-identity-pools create github --project "$PROJECT_ID" --location global
gcloud iam workload-identity-pools providers create-oidc lucena \
  --project "$PROJECT_ID" --location global --workload-identity-pool github \
  --issuer-uri "https://token.actions.githubusercontent.com" \
  --attribute-mapping "google.subject=assertion.sub,attribute.repository=assertion.repository" \
  --attribute-condition "assertion.repository == '$REPO'"
gcloud iam service-accounts add-iam-policy-binding "$SA" --project "$PROJECT_ID" \
  --role roles/iam.workloadIdentityUser \
  --member "principalSet://iam.googleapis.com/projects/$PROJECT_NUMBER/locations/global/workloadIdentityPools/github/attribute.repository/$REPO"

# Valores para o config.env
echo "GCP_WORKLOAD_IDENTITY_PROVIDER=\"projects/$PROJECT_NUMBER/locations/global/workloadIdentityPools/github/providers/lucena\""
echo "GCP_SERVICE_ACCOUNT=\"$SA\""
```

O bucket padrão de resultados do Test Lab é gerenciado pelo Google: não dá para liberar só ele, e usá-lo exigiria o papel Editor no projeto inteiro. Por isso o workflow grava num bucket próprio, o único que a conta de serviço enxerga:

```bash
BUCKET="$PROJECT_ID-test-lab"
gcloud storage buckets create "gs://$BUCKET" --project "$PROJECT_ID" --location us-central1 --uniform-bucket-level-access
for role in roles/storage.objectAdmin roles/storage.legacyBucketReader; do
  gcloud storage buckets add-iam-policy-binding "gs://$BUCKET" --member "serviceAccount:$SA" --role "$role"
done
echo "TEST_LAB_RESULTS_BUCKET=\"$BUCKET\""   # valor para o config.env
```

Criar bucket exige faturamento ativo no projeto (plano Blaze). Sem isso, a alternativa é deixar `TEST_LAB_RESULTS_BUCKET` vazio e dar `roles/editor` à conta de serviço, que é bem mais amplo.

## 3. Assinatura do APK de release
1. Criar a keystore uma vez, fora do repositório:
   `keytool -genkey -v -keystore ~/.secrets/lucena-upload.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload`
2. **Guarde backup da keystore e das senhas.** Se forem perdidas, o app publicado não poderá mais ser atualizado com a mesma assinatura.
3. O `android/app/build.gradle.kts` assina o release com as variáveis `ANDROID_KEYSTORE_PATH`, `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS` e `ANDROID_KEY_PASSWORD`, que só o CI define. Sem elas (build local e CI de PR), assina com a chave de debug.

## 4. Ambiente `release` no GitHub
Os segredos ficam num ambiente, não no repositório inteiro: só os workflows `qa.yml` e `release.yml`, rodando em tags `v*`, conseguem lê-los. PRs (inclusive de forks) nunca recebem segredos.

1. Em *Settings → Environments*, criar o ambiente `release`.
2. Em *Deployment branches and tags*, escolher *Selected branches and tags* e adicionar a regra de **tag** `v*`.
3. Gravar os segredos (o `gh` pede o valor sem mostrar na tela):
   ```bash
   base64 -w0 ~/.secrets/lucena-upload.jks | gh secret set ANDROID_KEYSTORE_BASE64 --env release
   gh secret set ANDROID_KEYSTORE_PASSWORD --env release
   gh secret set ANDROID_KEY_ALIAS --env release
   gh secret set ANDROID_KEY_PASSWORD --env release
   gh secret set QA_CONFIG_ENV --env release < .claude/skills/qa-release/config.env
   ```
   O `qa.yml` lê a configuração só do `QA_CONFIG_ENV`: a cada mudança no `config.env`, gravar o segredo de novo.
4. Em *Settings → Rules → Rulesets*: proteger a `main` e a `develop` (exigir PR e o CI verde) e, se quiser, restringir a criação de tags `v*` a você e ao Claude.

## 5. Ferramentas locais
- GitHub CLI com login (`gh auth login`): é a única que a skill usa.
- Google Cloud CLI (`gcloud`): só para o passo 2.

## 6. Primeiro teste
Rodar a skill numa tarefa simples e conferir no resultado se os links do Test Lab e do App Distribution foram capturados. Se o formato da saída das CLIs tiver mudado, ajustar as linhas `grep` do `qa.yml`.

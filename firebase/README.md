# Firebase do Lucena (E1.02)

Projeto `lucena-2f4de` (número 456466277039). O app Android é `com.gncortes.lucena`.

## O que está ligado

| Serviço | Estado |
|---|---|
| Auth | Google e e-mail/senha. A proteção contra enumeração de e-mail está ligada. |
| Firestore | `(default)` em `nam5` (EUA multirregião), regras em `firestore.rules`. |
| Storage | A foto de perfil enviada (`users/{uid}/avatar.jpg`) e os lançamentos do conteúdo (`content/releases/{release}/`), regras em `storage.rules`. O bucket padrão precisa ser criado no console (pede o plano Blaze). |
| Cloud Functions | `functions/` (TypeScript, Node 22, v2, `southamerica-east1`). Testes: `npm --prefix functions test`. |
| Cloud Messaging | Tópico `all` (todo aparelho entra ao abrir o app). Aviso com `link` nos dados abre o desafio. |
| Hosting | https://lucena-2f4de.web.app: a landing, `/.well-known/assetlinks.json` e `/p/**` (link de desafio sem o app → landing). |

## Coleções

| Caminho | Quem lê | Quem grava |
|---|---|---|
| `users/{uid}` | o dono | o dono, só `name`, `language`, `legal`, `createdAt` (hora do servidor) e `updatedAt` |
| `users/{uid}/progress/summary` | o dono | o dono; só o id `summary`, chaves e tetos do `ProgressSummary`, apelido até 20 |
| `users/{uid}/games/{id}` | o dono | o dono cria (id `<micros>-<posição>`, chaves do `gameJson`, soma 1 em `cotas`) e apaga; não muda |
| `users/{uid}/push/device` | o dono e o admin | o dono, só `token`, `updatedAt`, `permissao` (`permitida`, `negada`, `nunca`), `conferidoEm` e `ultimaAbertura` (o último aparelho; sai no logout) |
| `cotas/{uid}` | o dono e o admin | o dono só avança: `feedbackEm`/`feedbackId` (1 feedback por minuto) e `partidas` (+1, teto 20000); ninguém apaga |
| `feedback/{id}` | admin e o autor | só com conta: `uid` do autor, chaves do `FeedbackEntry`, texto até 500, `createdAt` = hora do servidor, junto com `cotas` |
| `bloqueios/{uid}` | o dono e o admin | admin (`motivo`, `regra`, `desde`, `ate`, `adminUid`), pelo painel via `bloquearConta`/`desbloquearConta`; bloqueio vigente barra toda escrita da conta, menos apagar |
| `inscritos/{topico}` | admin | ninguém pelo app (só Cloud Function) |
| `acessos/{uid}` | o dono e o admin | a Function (`cursos.{id}`); o dono só `vistos.{id}` (timestamp, até 200) |
| `acessos/{uid}/registro/{id}` | admin | ninguém pelo app (só Cloud Function) |
| `resumosDia/{aaaa-mm-dd}`, `resumosMes/{aaaa-mm}`, `painel/{doc}`, `pushes/{id}`, `relatorios/{dia}`, `pedidosCorrecao/{id}`, `revisoes/{id}`, `entregas/{id}`, `decisoes/{id}`, `promocoes/{id}` | admin | ninguém pelo app (Cloud Function ou agente pelo Admin SDK) |
| `challenges/{code}` | ninguém | ninguém (o app não usa; o desafio vai no link) |
| `candidates/{id}` | admin | admin |
| `featured/{id}` | todos | admin |
| `admins/{uid}` | o próprio | ninguém pelo app (criar no console) |
| Storage `users/{uid}/avatar.jpg` | o dono | o dono, JPEG, PNG ou WebP até 1 MB |
| `conteudo/teste`, `conteudo/alunos` (índices de pacotes) | quem tem conta | ninguém pelo app (`publicarVersao`, `reverterVersao`) |
| Storage `content/releases/{release}/**` | quem tem conta | ninguém pelo app (PC e Functions pelo Admin SDK) |

Testes das regras no emulador: `npm --prefix firebase/test ci` e `npm --prefix firebase/test test`
(pede Java 21; o `rodar.sh` usa o do Android Studio se o do PATH for antigo).

Direito pago (premium) nunca é gravado pelo app: vem do servidor (Admin SDK).

## Comandos

```sh
firebase deploy --only firestore
firebase deploy --only storage
LANDING_SITE=https://lucena-2f4de.web.app LANDING_BASE=/ npm --prefix landing run build
firebase deploy --only hosting
```

## App Links

`landing/assets/.well-known/assetlinks.json` tem o SHA-256 da chave de QA/release.
Quando a Play assinar o app, acrescente o SHA-256 da chave de assinatura da Play
(Play Console → Integridade do app) no `assetlinks.json` e no Firebase
(`firebase apps:android:sha:create`).

## Build

O `android/app/google-services.json` não é versionado. Sem ele, o app abre sem Firebase:
sem conta, sem push e sem perfil na nuvem. Isso vale para o CI das PRs, forks e F-Droid.
Os builds de QA e de release recebem o arquivo pelo segredo `GOOGLE_SERVICES_JSON`.

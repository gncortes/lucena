# Firebase do Lucena (E1.02)

Projeto `lucena-2f4de` (número 456466277039). O app Android é `com.gncortes.lucena`.

## O que está ligado

| Serviço | Estado |
|---|---|
| Auth | Google e e-mail/senha. A proteção contra enumeração de e-mail está ligada. |
| Firestore | `(default)` em `nam5` (EUA multirregião), regras em `firestore.rules`. |
| Storage | Só a foto de perfil enviada (`users/{uid}/avatar.jpg`), regras em `storage.rules`. O bucket padrão precisa ser criado no console (pede o plano Blaze). |
| Cloud Messaging | Tópico `all` (todo aparelho entra ao abrir o app). Aviso com `link` nos dados abre o desafio. |
| Hosting | https://lucena-2f4de.web.app: a landing, `/.well-known/assetlinks.json` e `/p/**` (link de desafio sem o app → landing). |

## Coleções

| Caminho | Quem lê | Quem grava |
|---|---|---|
| `users/{uid}` | o dono | o dono, só `name`, `language`, `createdAt` e `updatedAt` |
| `users/{uid}/progress/{doc}` | o dono | o dono |
| `users/{uid}/games/{id}` | o dono | o dono cria e apaga; não muda |
| `feedback/{id}` | admin | qualquer um cria (texto até 4000, `createdAt` = hora do servidor) |
| `challenges/{code}` | quem tem o código (`get`) | o dono cria; o `result` entra uma vez |
| `candidates/{id}` | admin | admin |
| `featured/{id}` | todos | admin (o `pct` e o `total` vêm da função) |
| `daily/{day}` | todos (`get`) | só a função agendada (Admin SDK): `finalId`, `pct`, `total` |
| `admins/{uid}` | o próprio | ninguém pelo app (criar no console) |
| Storage `users/{uid}/avatar.jpg` | o dono | o dono, imagem até 1 MB |

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

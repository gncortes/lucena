---
name: l10n
description: Como adicionar ou alterar textos e idiomas. Use sempre que uma tela precisar de texto novo.
---

# Textos e idiomas

1. Adicione a chave em `lib/l10n/app_en.arb` (com `@chave` e `description`).
2. Adicione a mesma chave em `app_pt.arb` e em todos os outros `app_*.arb` do Grupo 1. Tradução inicial por IA: o arquivo fica com `"@@x-review": "pending"` até alguém revisar.
3. Rode `python3 tools/gen_pseudo_l10n.py` (regera o pseudo-idioma `app_en_XA.arb`), `flutter gen-l10n` e `python3 tools/check_l10n.py` (falha se faltar chave em algum idioma ou se o pseudo-idioma estiver desatualizado).
4. No widget: `context.l10n.chave`. Nunca string literal visível ao usuário.

Regras:
- Plurais e números com ICU (`{count, plural, ...}`), nunca concatenação.
- Notação de lances: figurina por padrão; letras do idioma só pela configuração.
- Layout conferido em árabe (direita para a esquerda) e no pseudo-idioma longo.
- Idioma novo: arquivo `app_<código>.arb` e uma entrada em `AppLanguage` (`lib/domain/models/app_language.dart`), com o nome escrito no próprio idioma.
- Posição na tela sempre com as variantes direcionais (`AlignmentDirectional`, `EdgeInsetsDirectional`), para espelhar sozinha.

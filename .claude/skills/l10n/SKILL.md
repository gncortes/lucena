---
name: l10n
description: Como adicionar ou alterar textos e idiomas. Use sempre que uma tela precisar de texto novo.
---

# Textos e idiomas

1. Adicione a chave em `lib/l10n/app_en.arb` (com `@chave` e `description`).
2. Adicione a mesma chave em `app_pt.arb` e nos demais idiomas do Grupo 1 (tradução inicial por IA, marcada para revisão).
3. Rode `flutter gen-l10n` e `python3 tools/check_l10n.py` (falha se faltar chave em algum idioma).
4. No widget: `context.l10n.chave`. Nunca string literal visível ao usuário.

Regras:
- Plurais e números com ICU (`{count, plural, ...}`), nunca concatenação.
- Notação de lances: figurina por padrão; letras do idioma só pela configuração.
- Layout conferido em árabe (direita para a esquerda) e no pseudo-idioma longo.

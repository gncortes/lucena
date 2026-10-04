---
name: arquitetura
description: Arquitetura (guia oficial do Flutter com Cubit/Bloc como view model) e padrões de teste unitário. Use ao criar modelos, use cases, serviços, repositórios ou view models.
---

# Arquitetura (docs.flutter.dev/app-architecture)

## Camadas
- `lib/ui/<feature>/widgets/`: view e widgets. Só conhece o seu view model.
- `lib/ui/<feature>/view_models/`: Cubit/Bloc. Recebe ações do usuário, chama repositórios e use cases, expõe estado imutável.
- `lib/data/repositories/<area>/`: interface + implementação. Fonte da verdade do dado; usa serviços; devolve modelos de domínio em `Result`.
- `lib/data/services/`: embrulha pacote ou plataforma (shared_preferences, drift, stockfish, maia). Sem estado, sem regra de negócio.
- `lib/domain/models/`: modelos imutáveis com `freezed`.
- `lib/domain/use_cases/`: regras puras reutilizáveis (GameRules, ClockEngine, ThinkTimePolicy, PickHumanMove). Sem Flutter, sem `data/`.
- `lib/config/`: composição (normal e E2E). `lib/routing/`: go_router.

## Dependências permitidas
widgets → view_models → (repositories, use_cases) → services. Nunca o contrário, nunca pular camada.

## Testes
- Use cases e modelos: `package:test`, tempo via `FakeNow`, aleatoriedade via `Random(seed)`.
- Repositórios: com serviços falsos; drift com `NativeDatabase.memory()`; shared_preferences com `setMockInitialValues`.
- View models: `bloc_test` com repositórios falsos de `testing/`.
- Widgets: `pumpWidget` com `TestApp` (tema, l10n, view models falsos); procurar por key.
- Nome do teste em português, descrevendo comportamento: `'incremento soma 2 s após o lance'`.

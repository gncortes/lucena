# Protocolo dos agentes de aula

Cada agente cria **uma** aula do catálogo (`.claude/skills/aula-final/catalogo.md`) seguindo a skill `aula-final` do começo ao fim. Regras comuns:

1. Só toque nos arquivos da sua aula: `docs/aulas/<id>.md`, `tools/lessons/endgames/<id>.json`, `assets/lessons/pt/endgames/<id>.json`, `assets/lessons/en/endgames/<id>.json` e o gerado `assets/lessons/endgames/<id>.json`. Nada de branch, commit, script ou catálogo.
2. Pesquisa honesta (`pesquisa.md`): só cita o que abriu (Wikipedia, estudos públicos do Lichess pela API `https://lichess.org/api/study/<id>.pgn`, páginas de editora, tabela `https://tablebase.lichess.ovh/standard?fen=…`). Sem página inventada, sem texto copiado.
3. A tabela manda: toda posição e todo lance passam pelo script `build_aula.py`. Nunca trocar a regra de aceitos por uma lista só para o script passar.
4. Lição completa (talk/move/play): posição-chave e o porquê; a técnica lance a lance com o aluno jogando; como chegar nela de longe; as defesas e armadilhas; resumo em 2-3 regras.
5. De 8 a 12 exercícios, estrelas 1 a 3 (mais de 1 e 2 que de 3), do fácil ao difícil, maioria `origin: "own"`. `passScore` ≈ 60% do total, arredondado para cima.
6. Falas em pt e en na voz do Viktor (tom de `assets/lessons/pt/lessons.json`), nunca "mate em N lances", texto original.
7. `practice.positionId`: o id do catálogo (`assets/positions/positions.json`) quando o final existe lá; senão `null` e um FEN próprio. O speedrun do final é ligado por esse id.
8. Se a tabela do Lichess responder 429 e o script parar, espere 60 s e rode de novo (o cache local evita repetir consultas).
9. No fim, relate: arquivos, exercícios com estrelas (total e mínimo), fontes consultadas, divergências e o que ficou sem resolver.

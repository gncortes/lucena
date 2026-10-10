# Revisão de uma aula por agentes

Toda aula nova (ou lote de aulas) passa por revisão **antes** da PR, por agentes separados de quem escreveu.
Quem escreve não enxerga a própria repetição nem a dica que entrega o lance; o revisor enxerga. Este arquivo
vem da T58 (2026-10-09), em que 34 aulas foram refeitas e revisadas com agentes, e lista o que deu errado para
não repetir.

## Quem faz o quê (modelo por tarefa)

| Tarefa | Modelo | Por quê |
|---|---|---|
| Pesquisa e exercícios de um tema com composição (ruptura, triangulação, casas conjugadas, dois cavalos) | Fable | precisa achar e julgar estudos; o 3★ depende disso |
| Pesquisa e exercícios dos outros temas | Opus | na T58 todas as 32 aulas no Opus passaram nos scripts; os erros que ficaram eram de julgamento (ver lista) |
| Revisor da lição, 1.ª passada (`revisor-licoes`, uma aula por vez) | Opus; Fable só nas aulas marcadas "Fable" na triagem | julga cobertura das ideias, ritmo e fontes (`licao.md`) e escreve o plano de reescrita; o `dump_lesson.py` entrega o mecânico |
| Reescrita da lição de uma aula (T61) | Opus; Fable só nas marcadas | segue o plano e os nove passos de `licao.md`; brief em `docs/tasks/T61-brief-licao.md` |
| Revisor da lição, 2.ª passada | Sonnet (com `dump_lesson.py --links`, `build_aula.py --dry-run` e python-chess); Opus se a 1.ª achou erro de xadrez | confere cobertura, fala N ↔ lance N, links que batem, pt = en; devolve correções mecânicas com o texto exato |
| Revisor de xadrez e régua (um para o lote) | Fable | compara afirmações das falas com a tabela e julga a régua; é onde os erros caros aparecem |
| Revisor de lições (`revisor-licoes`, uma aula por vez, depois do revisor de xadrez) | Fable | aprofunda as falas: variantes em lances, qualidade dos lances (!, ?, ??), soluções completas e alternativas aceitas; é o que deixa a aula rica |
| Revisor de textos pt/en (um para o lote) | Sonnet, com conferência por script | notação, chaves, tom, pt ≠ en, dica que entrega o lance. **Ainda não medido**: na T58 o revisor único foi Fable. Ao usar Sonnet aqui, anote no dossiê quantos erros ele achou e quantos o revisor de xadrez achou depois dele; se escapar erro de xadrez, não é tarefa dele |
| Cortes mecânicos, regerar `.json`, rodar scripts | Sonnet ou o próprio orquestrador | nada de julgamento |

Ordem da revisão: 1) `revisor-aulas` (exercícios, régua, xadrez); 2) `revisor-licoes` (profundidade das falas da
lição e das soluções); 3) revisor de textos pt/en.

Regras para o lote:

- Um agente por aula, **nunca dois na mesma aula**; cada um só toca nos arquivos da própria aula e no dossiê
  dela. Nada de git nos agentes: quem integra confere e commita.
- Até 8 a 10 agentes ao mesmo tempo (a tabela do Lichess responde 429 acima disso; há cache em
  `tools/.cache/tablebase`).
- O pedido ao agente aponta um **brief em arquivo** (`docs/tasks/TXX-brief-agente.md`) e diz só o id da aula.
  Relatório de volta curto e em tabela; o detalhe vai no dossiê, que o revisor lê em vez da conversa.
- Quem integra confere cada aula com `python3 tools/lessons/check_variety.py <id>` (coluna Lição 0, sem aviso)
  e `build_aula.py <id> --dry-run` (0 problemas) e dá `git add` **só dos arquivos da aula que existem**
  (`[ -f "$f" ] && git add "$f"`). Nunca `git add -A` com agentes escrevendo.

## O que o revisor de xadrez e régua confere

1. **Afirmações fortes das falas contra a tabela**: "único", "perde", "afoga", "só X ganha". Amostragem
   dirigida: todos os 3★ e tudo que o dossiê marcou como dúvida. Tabela em
   `https://tablebase.lichess.ovh/standard?fen=<FEN com + no lugar de espaço>` ou `Oracle` do `build_aula.py`.
2. **Régua** (`formato.md`, Estrelas): 1★ que ainda é posição da lição; 2★ sem decisão; 3★ que não é estudo
   nem linha de lances únicos. Linha com mais de 8 vezes do aluno: o lance-chave já apareceu antes do fim?
3. **Repetição de ideia entre aulas** (não só de posição; o script só pega posição): aulas vizinhas do catálogo
   (as de torre e peão contra torre, as de dama contra torre, as de bispo e cavalo, as de rei e peão).
4. **Botão de informações**: `keyPositions` e `history` não podem entregar a solução de um exercício. Se uma
   posição-base é o fim de um exercício, ou sai a legenda ou sai o exercício; o crédito fica em `references`.
5. **Posições próprias (`own`) nos 3★**: valem como estudo? Só quando têm lance único e surpreendente e o
   dossiê diz que não achou estudo publicado.
6. **Lances aceitos que não são o ensinado**: com `accept: best` ou `win`, um lance alternativo aceito
   encerra a linha como cumprida e o aluno nunca vê o golpe. Se o golpe é a razão do exercício, comece o
   exercício um lance depois ou troque a posição.

7. **Posição citada é posição explicada** (pedido do Gabriel, 2026-10-09): a fala agora rola numa folha sobre o
   tabuleiro, então não há motivo para poupar texto. Se uma fala cita uma posição (partida histórica, erro famoso,
   exceção à regra), ela destrincha: o lance que perde e por quê, a linha que segue, o que empatava ou ganhava e
   por quê. Ex.: "Kramnik jogou Ta1 e perdeu" pede a linha da derrota e a do empate. Quando der, o passo seguinte
   mostra a posição (demonstração ou passo de jogar) em vez de pular direto para o próximo assunto.
8. **Alternativas citadas valem como certas**: se a fala diz que outro lance também funciona, ele entra na lista
   `accept` do passo de jogar da mesma posição. Passo de pensar sem passo de jogar na mesma posição só aceita o
   lance da seta: avalie criar o passo de jogar quando a explicação admite mais de uma resposta.

9. **Citação é link** (pedido do Gabriel, 2026-10-09): livro, partida, estudo ou autor citado numa fala, na história
   ou numa legenda vira link sublinhado que abre a fonte no navegador. Toda citação precisa de uma entrada em
   `references` com `url`. A marcação no texto e o suporte no app ainda estão por fazer (ver a memória
   `pr28-rodada-ux-exercicios`, item 6); até lá, o revisor só confere que cada citação tem a referência com `url`.

## O que o revisor de textos confere

- Notação pt R/D/T/B/C, en K/Q/R/B/N; sem "mate em N"; pt e en dizem a mesma coisa.
- Enunciado diz quem joga e o objetivo, sem o lance; a dica dá a ideia, não o lance; a solução cita os lances
  aceitos do gerado (lê `assets/lessons/endgames/<id>.json`).
- Crédito ao compositor ou à partida quando `origin` não é `own`; nada traduzido de livro ou estudo.
- Chaves: todo `ex.<id>`, `.hint` e `.solution` nos dois idiomas, nenhuma chave de exercício cortado.

## Erros que a T58 encontrou (lista de conferência de quem escreve)

- Exercício que é a posição da lição com os reis em outra casa, espelhada ou com as cores trocadas; 58 de 357
  eram assim. `check_variety.py` pega.
- Cota de 10 exercícios por aula, preenchida com variações. Um por ideia, sem cota.
- 2★ que é só "aplique a técnica"; 3★ sem lance surpreendente.
- Legenda de `keyPositions` que entrega a solução de um exercício (6 aulas).
- Fonte `.py` sem `'skills': [...]` (o `build_aula.py` reprova; o id vem de `tools/placement/skills.json`).
- Id de exercício cortado reaproveitado (o progresso do aluno é por id; nunca reaproveitar).
- Linha de 9 a 11 vezes do aluno em que o lance-chave aparece no 3º lance.
- Alternativa aceita que encerra a linha antes do golpe (ver item 6 acima).
- Posição com mais de 7 peças julgada só pelo Stockfish sem registro no dossiê.
- Exercício fora do tema da aula (defesa com `goal: win`, ou o tema da aula vizinha).
- Texto que afirma "único" quando a tabela aceita 2 ou 3 lances.

## Relatório

`docs/aulas/AUDITORIA-<data>.md`: no topo as dez correções mais importantes e o que o revisor já corrigiu nos
arquivos (só texto e dados mecânicos, regerando com `build_aula.py <id>`); depois, por aula, uma tabela
`| exercício | problema | gravidade (xadrez / régua / texto) | sugestão |`. Cortar ou trocar exercício e mudar
estrelas é decisão do Gabriel: vai no relatório com uma recomendação de uma linha, não no arquivo.

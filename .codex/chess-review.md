# Revisão enxadrística e pedagógica no Codex

Este protocolo acrescenta verificações operacionais à régua comum de CLAUDE.md e dos documentos aula-final. Não altera o Claude nem substitui a régua, os exercícios aprovados ou a aprovação do Gabriel.

## Ordem e papéis

Na mesma fila, UX/layout primeiro; depois conteúdo de aulas, avaliações e decisões enxadrísticas. Prioridades explícitas e pré-requisitos prevalecem. Visualizar/capturar um tabuleiro sem julgar xadrez pode ficar com Luna; qualquer decisão sobre legalidade, avaliação, lances aceitos, dificuldade ou ensino é complexa. Use Astra/high nos papéis revisor_licoes, editor_falas e especialista_xadrez. Sol cuida de código/UX; scripts fazem verificações mecânicas. Não lance revisores redundantes: uma revisão antes e uma independente depois de reescrever; divergências concretas exigem resolução com evidências, não votação de modelos.

## Preparação reproduzível

1. Uma aula por brief. Identifique os objetivos, o público, os arquivos fonte/gerados, a versão atual e os critérios de aceite. Leia o andamento e só a régua pertinente.
2. Localize o ambiente Maia já instalado, pesos e engine wrappers antes de alegar indisponibilidade; o projeto tem integração em tools/maia/reference.py e no app. Não confunda presença no app com Python de análise pronto. Não baixe modelos nem instale dependências implicitamente. Anote caminho, versão, hash/revisão dos pesos e parâmetros. O reference.py atual fixa Maia3-5M e oferece load_model(as_in_app=True), para comparar pesos arredondados do app quando houver divergência.
3. Dump e scripts primeiro; consulte cache. Faça lista das FENs e decisões efetivamente alcançáveis: início, respostas do adversário e alternativas aceitas, incluindo ramificações. Não aceite cobertura só da linha principal. Cada FEN precisa lado a jogar, roque/en passant, contadores e legalidade conferidos. Verifique correspondência do board com texto/setas no app.
4. Stockfish/tablebase determinam resultado e variantes; Maia estima escolhas humanas; Astra interpreta conceitos e ensina. Leela/Lc0 é complementar se disponível e configurado. Não substitua análise por confiança no LLM, nem suponha que Astra supera outros modelos em xadrez sem avaliação.

## O que jogadores de diferentes níveis tenderiam a fazer

Para cada decisão do aluno, registre distribuição Maia nos níveis 1000/1400/1800/2200, com ratings de ambos os lados e histórico de lances quando suportado. Não descarte histórico disponível nem invente dados faltantes. Una lances >=10% em qualquer nível, top 2 de cada nível mesmo abaixo de 10%, alternativas já aceitas e alternativas objetivamente equivalentes identificadas pelos motores.

Maia prevê probabilidades de lances condicionadas à posição/rating; não revela pensamentos de uma pessoa nem garante o que todo jogador daquela faixa fará. Para cada candidato, Astra pode propor o erro conceitual provável, claramente marcado como hipótese pedagógica, e apoiá-lo na consequência verificada. Exemplo de tabela:

`passo/FEN | lance | % por nível | resultado/variante e fonte | aceito? | conceito ou erro provável (hipótese) | onde ensina/explica | pendência`

Para lances que preservam o objetivo da posição, não recuse uma solução equivalente só por divergir do roteiro. Confira o objetivo explícito e a régua comum para casos de vitória mais lenta. Erros precisam explicar o porquê com variante curta numerada e conferida. Quando possível, a variante deve ser navegável no tabuleiro. O aluno não recebe uma mensagem genérica sem entender a consequência.

## Dificuldade e sequência didática

Não atribua dificuldade por profundidade do Stockfish, distância até mate, uma probabilidade isolada ou palpite do LLM. Por faixa, examine massa de probabilidade dos lances que atingem o objetivo, alternativas tentadoras que falham, número de decisões críticas, ideias prévias necessárias, exceções e necessidade de cálculo. Isso produz uma estimativa, com incerteza, não rating calibrado ou probabilidade exata de resolver a aula inteira. Não multiplique probabilidades ao longo da linha como se fossem eventos independentes.

Cruze a estimativa com a régua de estrelas já existente. Cada exercício cobra ideia ensinada e permite transferência para posição diferente, sem mera repetição do demo. Uma ideia por parte; pensar → explicar/ver → praticar; apresentação do simples ao complexo. Dica progride sem entregar o lance, solução explica objetivo, plano, tentação e refutação. Termo novo é explicado; texto formal pt/en equivalente e lances numerados corretamente. Sem cortar explicação só para poupar tokens.

Antes de revisão em lote, calibre uma amostra pequena com Gabriel. Só dados de usuários ou avaliação humana sustentam ajuste empírico de dificuldade; sem esses dados, registre como estimativa. Não invente resultados de alunos artificiais.

## Gates para concluir

- Tabela exercício → ideia → parte que ensina completa; uma fala incidental não substitui ensino.
- Todos os candidatos naturais e ramificações relevantes cobertos; ausência de evidência mantém pendência, não vira OK.
- Resultado, variantes, notação, FEN e créditos conferidos; URLs abertas e PGN reproduzido na posição/lance certos quando aplicável.
- Falas explicam porquês, casos que ganham/empatam/perdem e exceções, com as fontes e motores registrados fora do texto destinado ao aluno.
- Testes de conteúdo e scripts adequados verdes; alterações de UI seguem analyze/testes e print/MP4 conferido.
- Revisor independente recebe arquivos finais e evidência mecânica; compara critérios concretos. A aprovação A segue o painel calibrado e confirmação do Gabriel. Nunca retire aula de review.json por conta própria.
- Relatório em arquivo: nota por critério, evidência, achados e lacunas; conversa em até 15 linhas. Nenhum relatório pode afirmar cobertura completa sem verificá-la.

## Limitações mecânicas já identificadas

O tools/lesson_coverage.py inspecionado seleciona candidatos Maia apenas >=10% (não inclui top 2 abaixo disso), visita think e exercícios por linha teach/reply e não comprova todas as ramificações. O wrapper analysis_cache.py chama Maia com histórico vazio. Portanto, esses relatórios são insumos parciais, não certificação de cobertura completa. Antes de aprovar uma aula, complemente as verificações ou encaminhe uma correção delimitada dos scripts; não edite ferramentas compartilhadas nesta configuração. Scores de sucessores de tablebase devem ser interpretados com o lado a jogar correto, não copiados cegamente.

Fonte primária Maia: https://github.com/CSSLab/maia3 (consultada em 2026-10-11). As probabilidades representam previsão de movimentos humanos por rating; hipóteses sobre raciocínio e dificuldade ficam explicitamente separadas.

## Avaliação obrigatória: dificuldade da aula e didática

O relatório do analisador/revisor deve conter duas seções separadas, mesmo quando não houver defeitos. Não basta avaliar exercícios isoladamente ou dar só uma nota geral. Use a mesma escala de notas da régua comum; não invente uma nova pontuação para substituí-la.

### Dificuldade

Declare público-alvo e pré-requisitos, faixa de dificuldade pretendida e estimada, justificativa e confiança. Sem dados, escreva “estimativa não calibrada”; não invente Elo exato ou taxa de acerto. Avalie a aula inteira, cada parte e os exercícios: progressão, saltos de dificuldade, carga de conceitos novos, decisões críticas, extensão do cálculo necessário e alternativas naturais tentadoras. Use distribuições Maia por nível e resultados verificados dos motores como evidência, junto da régua comum de estrelas. A probabilidade de um lance não é a dificuldade integral da aula.

Tabela mínima: `parte/exercício | dificuldade pretendida | estimada | pré-requisitos/decisões críticas | evidência Maia/motores ou lacuna | ajuste`.

Verifique se o aluno aprende antes de ser cobrado, se há transição entre exemplos guiados e aplicação independente, se o primeiro exercício é acessível ao público e se os mais difíceis aparecem após a preparação. Diferencie exercício difícil por profundidade legítima de exercício confuso por enunciado ruim, dica inadequada ou tema não ensinado. Recomende reordenar, acrescentar preparação ou dividir uma parte quando necessário; mudar estrelas não resolve uma falha de ensino.

### Didática

Dê nota por critério e uma nota didática geral com justificativa concreta, preservando a régua comum:
- objetivo de aprendizagem claro e verificável;
- conceitos e vocabulário apresentados antes do uso;
- uma ideia por parte, exemplos concretos e explicação de porquês;
- ritmo pensar → ver/explicar → jogar, com participação efetiva do aluno;
- exemplos, contraexemplos e limites da regra, sem generalizações falsas;
- dicas graduais sem entregar a resposta e explicações úteis dos erros naturais;
- transferência: exercício cobra a ideia ensinada em posição diferente, sem só decorar demo;
- correspondência entre fala, posição, setas, variante e resultado; pt/en equivalentes;
- progressão e carga cognitiva adequadas, resumo recuperando as ideias efetivamente ensinadas.

Tabela mínima: `critério | nota da régua comum | parte/passo e evidência | impacto no aluno | ação recomendada`.

Conclusão obrigatória: nota geral da régua, adequação da dificuldade ao público, nota didática geral, três problemas prioritários (ou ausência comprovada), plano de correção e lacunas. Fato enxadrístico errado, objetivo cobrado sem ensino ou evidência crítica ausente impede declarar a aula pronta. Uma boa nota de linguagem não compensa falha de xadrez ou de cobertura. Após reescrever, o revisor independente reavalia dificuldade e didática nos arquivos finais. Gabriel continua confirmando a aprovação A.

## Checklist da nota A (Gabriel, 2026-10-11 noite) — fonte única
Antes de reescrever ou revisar qualquer aula: leia o "CHECKLIST DA NOTA A" no fim de
`.claude/skills/aula-final/licao.md` (13 itens com teto de nota), as seções "Voz de treinador" e "Falas em blocos" do
mesmo arquivo, `docs/tasks/T66-blocos-explicacao.md` (explicação em blocos por ação do aluno) e o agente
`aluno_simulado`. Notas atuais: piloto `pawns.distantOpposition` = E; demais = F.

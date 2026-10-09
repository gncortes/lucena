---
name: aula-final
description: Cria uma aula avançada de final com o Viktor (pesquisa com referências, roteiro até as posições-chave, exercícios de 1 a 3 estrelas com nota mínima e treino final). Use quando o usuário pedir "/aula-final <id>", "/aula-final próxima" ou mandar criar/revisar uma aula de final (mate de bispo e cavalo, dama contra torre, Lucena...).
---

# Aula de final com o Viktor

A Escola do Viktor (T28–T31) ensina o iniciante. Estas aulas são o passo seguinte: cerca de 55 finais que todo jogador precisa dominar, ensinados a fundo, do começo até as posições-chave, no modelo dos livros do Yusupov: lição, exercícios com estrelas, nota mínima para seguir.

Uma aula por sessão. `$ARGUMENTS` é o id da aula em `catalogo.md`; `próxima` é a primeira do catálogo que ainda não tem `docs/aulas/<id>.md`.

## O que uma aula tem

1. **Lição em partes curtas**: cada parte (4 a 6 passos) segue a progressão pensar sozinho (`think`) → ver o Viktor jogar e explicar (`demo`, `talk`) → jogar com ajuda (`move` ou `play`, a prática que fecha a parte). Começa do zero do tema e chega às posições-chave: o que é a posição, por que ela ganha (ou empata), como chegar nela de longe, e as melhores defesas do outro lado.
2. **Exercícios (teste final, depois das partes)**: um por ideia distinta do tema, sem cota (mínimo 3; em geral de 5 a 8), cada um com 1, 2 ou 3 estrelas de dificuldade, do mais fácil para o mais difícil. Cada um tem enunciado, dica e a explicação da solução. Exercício que repete uma posição da lição, ou outro exercício com os reis em outra casa, espelhado ou com as cores trocadas, não é exercício.
3. **Nota**: a soma das estrelas ganhas. Abaixo do mínimo da aula (`passScore`), o Viktor manda refazer os exercícios; a partir dele, libera o passo final.
4. **Passo final**: leva ao final de verdade. O aluno escolhe o ritmo e desafia no speedrun, ou abre o treino personalizado.
5. **Botão de informações**: referências (livros, estudos do Lichess, tabela de finais, partidas), as posições-base com o crédito de quem as achou e a história do final.

## Arquivos de uma aula

| Arquivo | O que é |
|---|---|
| `docs/aulas/<id>.md` | Dossiê da pesquisa (modelo em `pesquisa.md`) |
| `tools/lessons/endgames/<id>.json` | Fonte da aula, escrita à mão (`formato.md`) |
| `assets/lessons/pt/endgames/<id>.json` e `en/…` | Falas do Viktor, nos dois idiomas |
| `assets/lessons/endgames/<id>.json` | Gerado pelo script. Não editar à mão |

## Passo a passo

1. **Branch** `tarefa/aula-<nome-curto>` a partir da `main` atualizada (ou da branch da PR aberta, se houver). Confira antes `git status -sb`: outra sessão pode estar no mesmo diretório; nesse caso use um `git worktree`.
2. **Spike de pesquisa**: siga `pesquisa.md` e escreva o dossiê. As três frentes (livros, estudos do Lichess, história) são independentes e podem ir em subagentes em paralelo. Se o tema não couber numa aula ou as fontes divergirem da tabela de finais, pare e relate.
3. **Roteiro em partes**: a partir do dossiê, escreva a lição na fonte em `parts` (regras em `formato.md`, "Uma parte boa"). Cada posição-chave abre uma parte:
   - `think` primeiro: o aluno estuda a posição sozinho (5 minutos na posição-chave; 1 ou 3 numa posição de passagem), com 1 a 3 dicas para depois do tempo, da mais vaga à mais clara;
   - a explicação: `talk` com setas e casas para o porquê, e `demo` para a técnica, em que o Viktor joga os dois lados e explica cada lance. Passo `move` que só mostraria a técnica vira `demo`;
   - a prática que fecha a parte: um `move` (ou `play`) em que o aluno repete a técnica com a máquina respondendo.

   Ordem das partes que funciona: a posição-chave pronta e o porquê dela; a técnica; como chegar à posição-chave de mais longe; as defesas e armadilhas do outro lado (afogamento, canto errado, regra dos 50 lances); por fim, uma parte de resumo com duas ou três regras para a partida, fechando num `play`. Depois das partes vem o teste final (os exercícios do passo 4). Registre no dossiê a divisão escolhida e o motivo.
4. **Exercícios**: antes de escrever, liste no dossiê as **ideias** que o tema tem (a tabela "ideia → posição → por que é diferente" de `pesquisa.md`) e escolha **uma posição por ideia**. Sem cota: se o tema tem cinco ideias, a aula tem cinco exercícios. Mudar só a casa dos reis, espelhar ou trocar as cores **não** é posição nova, e posição que a lição já mostrou não vira exercício. Régua das estrelas em `formato.md`: 1★ aplica a técnica numa posição que a lição não mostrou; 2★ pede uma decisão (dois planos, uma exceção, uma conta); 3★ é composição no estilo de estudo, com solução única e lances que surpreendem, para gastar uns 5 minutos pensando. Posições ricas vêm de estudos (Lichess, compositores clássicos), diagramas da Wikipedia e dos manuais, sempre com o crédito em `origin`; posição própria só quando traz uma ideia que as fontes não cobrem. Depois de gerar, rode `python3 tools/lessons/check_variety.py <id>`: duplicata exata o `build_aula.py` reprova; "mesma família" e "repete a lição" só passam com a justificativa no dossiê.
5. **Falas** em pt e en, na voz do Viktor: paciente, direto, cita os mestres e a história do final quando ajuda. Leia duas ou três aulas de `assets/lessons/pt/lessons.json` para pegar o tom. Nunca "mate em N lances". Todo texto é escrito do zero: nada copiado ou traduzido de livro, vídeo ou estudo.
6. **Conferir e gerar**:
   ```
   python3 -m venv tools/.cache/venv && tools/.cache/venv/bin/pip install chess   # uma vez
   tools/.cache/venv/bin/python .claude/skills/aula-final/scripts/build_aula.py <id>
   ```
   O script confere as partes, FEN, lances (inclusive os de `demo`), objetivo de cada posição, estrelas, nota mínima, referências e falas, e calcula os lances aceitos pela tabela de finais do Lichess (Stockfish acima de 7 peças). Corrija a aula até sair sem problemas. Nunca contorne um problema trocando a regra de aceitos por uma lista só para o script passar: se a tabela discorda da aula, a aula está errada.
7. **Releia como aluno**: confira no relatório do script a divisão em partes e o tempo de cada uma (uma parte muito mais longa que as outras pede para ser dividida), se cada explicação de solução bate com os lances aceitos e se a dica não entrega a resposta.
8. **Fechar**: commit `Aula <id>: <nome do final>` e PR. Na descrição: o final, a lista de exercícios com as estrelas, as fontes usadas e o que foi julgado pelo Stockfish em vez da tabela. Enquanto o app não lê estas aulas (ver "O que falta no app" em `formato.md`), a PR é só de conteúdo: sem vídeo e sem versão de QA.

## Regras que não mudam

- **Xadrez não se escreve de memória.** Toda posição, avaliação e lance passa pelo script. Lembrar que "esta posição é ganha" não vale: a tabela decide.
- **Honestidade com as fontes.** Só entra em `references` o que foi realmente aberto nesta pesquisa; nada de página, capítulo ou link citado de memória. Detalhes em `pesquisa.md`.
- **Posição é fato, texto é obra.** Posições e lances podem ser usados com crédito; explicações, títulos de capítulo e a seleção de exercícios de um autor não se copiam.
- Não mexer em `assets/positions/positions.json` à mão: se o treino final pede uma posição que o catálogo não tem, anote no dossiê e relate.

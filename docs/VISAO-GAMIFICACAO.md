# Lucena — Visão de Produto e Roadmap de Gamificação

Documento de visão do Gabriel (2026-10-04). As tarefas T20–T37 do `docs/PLANO.md` (seção 8) saem dele.

## 1. Objetivo

Evoluir o Lucena de um aplicativo de treinamento de xadrez para uma experiência completa de **aprendizado, progressão, competição contra adversários virtuais e gamificação**.

O aplicativo deve permitir que o usuário:

* aprenda através de finais e exercícios;
* enfrente adversários virtuais com diferentes forças e personalidades;
* evolua progressivamente;
* acompanhe seu rating;
* participe de desafios estruturados;
* faça Speedruns;
* registre e supere seus próprios recordes;
* acompanhe seu histórico de evolução.

A experiência deve funcionar como uma jornada:

> **Aprender → praticar → jogar → evoluir → desbloquear → completar → registrar → melhorar o recorde.**

---

# 2. Conceitos principais

O sistema deve separar claramente conceitos que possuem objetivos diferentes.

### Rating

Representa o desempenho do jogador em partidas.

### Força do adversário

Representa o nível de jogo do adversário virtual.

O Maia será utilizado dentro da faixa aproximada de **1000 a 2600**.

### Progressão

Representa o avanço do jogador dentro da estrutura de conteúdo do Lucena.

### Domínio

Representa quais finais, exercícios e desafios o jogador já conseguiu completar.

### Speedrun

Mede quanto tempo o jogador leva para completar uma sequência determinada de desafios.

### Recorde

Representa o melhor desempenho histórico do jogador em determinado desafio ou campanha.

Esses conceitos não devem ser tratados como a mesma coisa.

---

# 3. Adversários virtuais

O Lucena deve possuir adversários virtuais com:

* avatar próprio;
* personalidade;
* estilo de fala;
* reações;
* comportamento;
* força configurável;
* estado emocional;
* animações específicas.

O objetivo é que o usuário sinta que está jogando contra um personagem, e não simplesmente contra uma engine.

---

# 4. Personagens por faixa de força

A ideia inicial é criar personagens representando diferentes faixas.

Exemplos:

### 1000 — Praieiro

Jogador casual, surfista, descontraído e brincalhão.

Possíveis características:

* roupas de praia;
* elementos de surf;
* linguagem descontraída;
* provocações leves;
* comportamento relaxado.

### 1200 — Malandro

Jogador esperto, provocador e cheio de truques.

Possíveis características:

* óculos Juliette;
* personalidade malandra;
* gosta de surpreender;
* utiliza linguagem informal.

### 1400 — Arrogante

Acredita que sabe tudo sobre xadrez.

Características:

* confiante em excesso;
* gosta de provocar;
* sempre acha que está certo;
* comenta sobre conceitos e finais;
* minimiza os erros do próprio jogo.

Exemplos de comportamento:

> "Você está dando sorte."

> "Eu conheço esse final."

### 1600 — Mágico

Jogador que parece sempre tirar uma ideia inesperada da cartola.

Possíveis animações:

* tirar um pombo da cartola;
* realizar um truque após uma combinação;
* ficar surpreso quando perde uma peça;
* comemorar uma jogada inesperada.

### 1800 — Senhor bem-humorado

Jogador experiente, tranquilo e divertido.

Características:

* senhor de idade;
* conhece bastante xadrez;
* humor leve;
* comportamento tranquilo;
* transmite experiência.

### 2000 — Criança prodígio

Uma menina de aproximadamente 8 anos.

O contraste entre a aparência infantil e a força elevada de jogo faz parte da personalidade.

### 2200 — Jovem prodígio

Uma menina mais velha, aproximadamente 11 anos.

Características:

* extremamente forte;
* extrovertida;
* confiante;
* personalidade mais energética.

### 2400 — Veterano

Senhor de idade com enorme experiência no xadrez.

Características:

* conhecimento profundo;
* personalidade mais madura;
* comportamento calmo;
* experiência transmitida através das falas.

### 2600 — Jovem mestre

Jogador jovem de altíssimo nível.

Características:

* confiança;
* conhecimento técnico;
* comportamento compatível com jogador de elite;
* personalidade própria.

Esses personagens são exemplos iniciais e devem poder ser substituídos ou expandidos posteriormente.

---

# 5. Avatares

Os personagens devem possuir identidade visual própria em **estilo cartoon**.

Cada avatar deve considerar:

* rosto;
* roupas;
* acessórios;
* postura;
* expressões;
* elementos relacionados à personalidade;
* possíveis animações;
* efeitos especiais.

Os personagens precisam ser visualmente reconhecíveis sem depender do nome ou rating.

---

# 6. Banco de falas

Cada personagem deve possuir inicialmente:

* pelo menos **100 falas**;
* pelo menos **10 categorias de reação**;
* falas específicas para diferentes situações da partida.

As falas devem respeitar:

* personalidade;
* faixa de força;
* contexto;
* estado emocional;
* situação do tabuleiro;
* resultado das jogadas;
* ritmo da partida.

Não deve existir apenas uma lista aleatória de frases.

---

# 7. Categorias de reação

O sistema deve conseguir identificar situações como:

* fez uma boa jogada;
* fez uma jogada ruim;
* sofreu uma boa jogada;
* cometeu um erro grave;
* encontrou uma tática;
* está ganhando;
* está perdendo;
* está empatado;
* virou a partida;
* entrou em apuros;
* está dominando;
* fez uma captura importante;
* entrou em um final;
* promoveu um peão;
* encontrou uma combinação;
* sofreu uma combinação;
* encontrou uma jogada inesperada.

A arquitetura deve permitir adicionar novas categorias posteriormente.

---

# 8. Estado emocional

Os personagens devem possuir um estado emocional interno.

Exemplos:

* confiança;
* animação;
* tranquilidade;
* preocupação;
* tensão;
* frustração;
* euforia;
* surpresa;
* desespero.

O estado emocional não deve depender apenas do último lance.

O sistema deve considerar a evolução recente da partida.

Exemplo:

> O personagem estava ganhando → sofreu uma sequência de boas jogadas → perdeu a vantagem → entrou em posição pior.

A reação deve considerar essa sequência, e não apenas o último lance isoladamente.

---

# 9. Avaliação da posição

Precisamos utilizar algum mecanismo capaz de informar o estado da posição para o sistema de comportamento.

A informação necessária pode ser simplificada para estados como:

* melhor;
* pior;
* equilibrado;
* grande vantagem;
* grande desvantagem;
* mudança significativa de avaliação;
* jogada muito forte;
* erro grave.

A avaliação não precisa ser mostrada ao usuário.

Ela servirá como entrada para o sistema de comportamento do personagem.

---

# 10. Reações dinâmicas

A lógica geral deverá ser semelhante a:

> **Personagem + situação + estado da partida + intensidade + estado emocional → fala + reação + animação**

Exemplo:

O mágico encontra uma combinação inesperada:

> **Grande vantagem + jogada tática + personagem mágico**

Resultado:

* fala especial;
* animação;
* truque com a cartola;
* mudança de estado emocional.

---

# 11. IA local

Investigar a possibilidade de utilizar uma **IA local** para auxiliar o sistema de personagens.

Possíveis utilizações:

* geração inicial das falas;
* expansão do banco de falas;
* revisão;
* variações de linguagem;
* classificação das falas;
* seleção contextual;
* geração de novas falas durante o desenvolvimento.

A prioridade deve ser evitar dependência obrigatória de APIs externas.

Não é necessário que uma IA generativa pesada esteja executando continuamente durante cada partida.

Uma abordagem preferencial é utilizar IA durante o desenvolvimento para gerar e organizar conteúdo e manter o aplicativo com dados previamente processados.

Caso seja viável utilizar IA local durante a execução, isso deve ser avaliado considerando:

* desempenho;
* memória;
* bateria;
* tamanho do aplicativo;
* latência;
* compatibilidade com as plataformas.

---

# 12. Maia

O Maia será responsável por representar adversários dentro de uma faixa aproximada de:

> **1000 → 2600**

A força do Maia deve permanecer separada do rating do jogador.

Não devemos criar engines artificiais como:

> 400 → engine 400
> 600 → engine 600
> 800 → engine 800

A força mínima do Maia deve respeitar a configuração definida para o sistema.

---

# 13. Maia + comportamento humano

O Maia não deve apenas escolher um lance correspondente à força configurada.

Ele também deve utilizar o sistema de simulação de comportamento humano.

A ideia é representar:

> **Como um jogador daquela força tomaria uma decisão naquela posição?**

Esse comportamento deve considerar também o ritmo de jogo.

---

# 14. Adaptação ao ritmo

O mesmo Maia deve conseguir se comportar de maneira diferente em diferentes ritmos.

Exemplos:

* 1+0;
* 3+0;
* 3+2;
* 5+3;
* 10+0.

O ritmo não deve simplesmente reduzir artificialmente a qualidade dos lances.

A intenção é alterar o **processo de tomada de decisão simulado**.

---

# 15. Bullet

No bullet, um jogador humano tende a:

* reconhecer padrões rapidamente;
* confiar em conhecimento prévio;
* jogar por instinto;
* escolher continuações naturais;
* evitar cálculos muito longos;
* tomar decisões práticas;
* priorizar velocidade.

O Maia deve conseguir reproduzir esse comportamento.

Portanto:

> **Menos tempo disponível ≠ simplesmente jogar pior.**

A ideia é:

> **mesma força configurada + comportamento humano adaptado ao ritmo.**

---

# 16. Modelo de decisão

A arquitetura deve separar:

### Força

Exemplo:

> Maia 1400

### Ritmo

Exemplo:

> 1+0

### Posição

Estado atual do tabuleiro.

### Modelo humano

Como alguém daquela força tende a tomar decisões naquele contexto.

O resultado será aproximadamente:

> **Força + posição + ritmo + modelo humano → decisão do Maia**

---

# 17. Progressão do jogador

O Lucena deve possuir uma progressão estruturada.

A sequência principal proposta é:

> **1000 → 1200 → 1400 → 1600 → 1800 → 2000 → 2200 → 2400 → 2600 → Stockfish**

Esses valores representam degraus de dificuldade e progressão de conteúdo.

O Stockfish deve ser tratado como uma etapa separada e final, não como simplesmente mais um personagem do Maia.

---

# 18. Experiência inicial

Ao abrir o aplicativo pela primeira vez, o usuário deve passar por um **tour guiado**.

O tour deve apresentar:

* objetivo do aplicativo;
* rating;
* progressão;
* finais;
* adversários;
* Speedrun;
* recordes;
* histórico.

O usuário também poderá indicar seu nível inicial.

Exemplo:

> "Qual é o seu nível atual?"

O usuário poderá começar no nível recomendado ou selecionar uma faixa compatível com sua experiência.

---

# 19. Modo de iniciante

A primeira grande etapa será:

> **1000 → 1200**

O objetivo é completar os desafios e finais definidos para o nível iniciante.

A progressão deve ser construída em torno de conteúdos fundamentais.

Exemplos:

* finais básicos de dama;
* finais básicos de torre;
* finais de peões;
* oposição;
* regra do quadrado;
* promoção;
* finais simples de peças menores.

A lista final de conteúdos deve ser definida posteriormente.

---

# 20. Speedrun

O Speedrun será um dos principais sistemas de gamificação.

O jogador poderá tentar completar determinada sequência no menor tempo possível.

O cronômetro deve considerar o tempo gasto nas partidas/desafios pertencentes à tentativa.

---

# 21. Speedrun de nível

Exemplo:

> **Speedrun Iniciante — 1000 → 1200**

O jogador precisa completar todos os desafios definidos para aquela faixa.

O sistema registra:

* tempo total;
* tempo de cada desafio;
* vitórias;
* derrotas;
* tentativas;
* erros;
* melhor tempo.

Exemplo:

| Desafio | Tempo |
| ------- | ----: |
| Final 1 |  2:31 |
| Final 2 |  1:48 |
| Final 3 |  3:12 |
| Final 4 |  2:05 |
| Final 5 |  4:17 |

**Tempo total: 13:53**

---

# 22. Speedrun por final

Também deve existir Speedrun específico de um determinado final.

Exemplo:

> **Dama vs. Torre**

O jogador enfrenta progressivamente:

> 1000 → 1200 → 1400 → 1600 → 1800 → 2000 → 2200 → 2400 → 2600 → Stockfish

Cada etapa possui seu próprio tempo.

No final:

> **Dama vs. Torre**
> Melhor tempo: **27:48**

O jogador poderá repetir o desafio para tentar superar seu recorde.

---

# 23. Recordes

Cada Speedrun deve possuir histórico.

Exemplo:

> Dama vs. Torre
> Recorde atual: **27:48**

Histórico:

* 27:48
* 29:03
* 31:12
* 34:51

O objetivo principal é permitir que o usuário compita contra **seu próprio desempenho**.

---

# 24. Recordes por nível

Também devem existir recordes individuais por adversário.

Exemplo:

> Dama vs. Torre — 1800
> Melhor tempo: 2:04

> Dama vs. Torre — 2000
> Melhor tempo: 2:31

> Dama vs. Torre — 2200
> Melhor tempo: 3:18

Isso permite identificar onde o jogador está perdendo mais tempo.

---

# 25. Speedrun entre níveis

A mesma lógica deve ser aplicada às faixas:

* 1000 → 1200;
* 1200 → 1400;
* 1400 → 1600;
* 1600 → 1800;
* 1800 → 2000;
* 2000 → 2200;
* 2200 → 2400;
* 2400 → 2600;
* 2600 → Stockfish.

Cada faixa terá:

* conteúdo;
* desafios;
* finais;
* adversários;
* objetivos;
* recordes.

---

# 26. Speedrun completo

No futuro, deve existir uma campanha:

> **1000 → Stockfish**

O jogador tentará completar toda a progressão do Lucena no menor tempo possível.

Isso poderá funcionar como o grande Speedrun do aplicativo.

---

# 27. Modalidades de Speedrun

A arquitetura deve permitir diferentes modalidades:

### Speedrun de nível

Completar todos os desafios de uma faixa.

### Speedrun de final

Completar um final contra todos os níveis.

### Speedrun de exercícios

Resolver uma sequência específica de posições.

### Speedrun completo

Completar toda a progressão.

### Speedrun pessoal

Tentar superar o próprio recorde.

---

# 28. Relação entre rating e Speedrun

O rating e o Speedrun devem ser sistemas independentes.

### Rating

Mede desempenho em partidas.

### Speedrun

Mede velocidade de conclusão de um desafio.

### Progressão

Mede avanço dentro da campanha.

### Domínio

Mede quais conteúdos foram concluídos.

Não devemos obrigatoriamente fazer uma derrota apagar todo o progresso do jogador.

A regra exata de derrota, reinício e continuidade de uma tentativa deve ser definida antes da implementação.

---

# 29. Histórico

O aplicativo deve armazenar o histórico das tentativas.

Exemplo:

### Dama vs. Torre

**Outubro**

> 34:51

**Novembro**

> 29:03

**Dezembro**

> 27:48

Isso permite que o jogador veja sua evolução ao longo do tempo.

---

# 30. Conquistas

O sistema poderá futuramente oferecer conquistas como:

* completar um final pela primeira vez;
* completar todos os finais de uma faixa;
* vencer todos os níveis de um final;
* vencer um adversário 2600;
* vencer o Stockfish;
* completar uma campanha sem derrotas;
* melhorar um recorde;
* completar um desafio abaixo de determinado tempo.

---

# 31. Gamificação

O sistema deve gerar feedback constante.

Exemplos:

> **Novo recorde pessoal!**

> **Você melhorou seu tempo em 18 segundos.**

> **Você venceu 2600 pela primeira vez.**

> **Novo recorde contra 2200.**

> **Todos os finais do nível concluídos.**

O objetivo é manter uma sensação constante de evolução.

---

# 32. Arquitetura extensível

A arquitetura deve permitir adicionar novos:

* personagens;
* ratings;
* finais;
* exercícios;
* campanhas;
* Speedruns;
* categorias de reação;
* falas;
* animações;
* conquistas;
* níveis;
* modalidades.

Adicionar um novo personagem ou final não deve exigir alterações espalhadas pela aplicação.

Sempre que possível, o sistema deve ser **data-driven**.

---

# 33. Relação entre os módulos

```text
                         LUCENA
                           │
          ┌────────────────┼────────────────┐
          │                │                │
       Rating          Progressão        Speedrun
          │                │                │
          │                │                ├── Nível
          │                │                ├── Final
          │                │                ├── Exercício
          │                │                └── Completo
          │                │
          │                ├── 1000
          │                ├── 1200
          │                ├── 1400
          │                ├── 1600
          │                ├── 1800
          │                ├── 2000
          │                ├── 2200
          │                ├── 2400
          │                └── 2600
          │
          └───────────────┐
                          │
                    Adversários
                          │
                 ┌────────┴────────┐
                 │                 │
               Maia            Stockfish
                 │
       ┌─────────┼─────────┐
       │         │         │
     Força     Ritmo    Modelo humano
       │
       └──────────────┐
                      │
                 Personagem
                      │
          ┌───────────┼───────────┐
          │           │           │
        Avatar       Falas     Emoções
                      │
                   Reações
                      │
                 Animações
```

---

# 34. Princípios importantes

### Não transformar tudo em rating

Rating, progressão, domínio e Speedrun possuem objetivos diferentes.

### Não transformar o Maia em uma engine artificialmente fraca

O Maia deve representar sua faixa configurada de força.

### Não reduzir simplesmente a força no bullet

O comportamento deve simular a tomada de decisão humana sob pressão de tempo.

### Não criar personagens apenas como imagens

Eles precisam possuir personalidade e comportamento.

### Não criar falas aleatórias

As falas devem depender do contexto.

### Não tornar o Speedrun excessivamente punitivo

As regras precisam incentivar repetição e melhoria.

### Não prender a arquitetura a poucos personagens

O sistema precisa ser expansível.

---

# 35. Primeira fase de implementação

Antes de começar a implementar tudo, o projeto deve ser dividido em tarefas menores.

A primeira etapa deve ser de **investigação e arquitetura**, analisando o projeto atual do Lucena e identificando:

1. onde o sistema de partidas está implementado;
2. onde o Maia está integrado;
3. como a força do Maia é configurada;
4. como o modelo de comportamento humano está implementado;
5. como os ritmos são representados;
6. onde os finais estão armazenados;
7. como as partidas são persistidas;
8. como o histórico pode ser armazenado;
9. como criar o modelo de progressão;
10. como criar o modelo de Speedrun;
11. como criar o modelo de personagens;
12. como armazenar falas e reações;
13. como integrar avaliação de posição ao comportamento;
14. como criar o sistema de recordes;
15. como preparar a arquitetura para expansão.

Somente depois dessa análise devem ser criadas as tarefas de implementação.

---

# 36. Roadmap conceitual

### Fase 1 — Fundação

* modelos de progressão;
* níveis;
* persistência;
* histórico;
* configuração de desafios.

### Fase 2 — Partidas e Maia

* integração com níveis;
* força dos adversários;
* ritmos;
* comportamento humano;
* adaptação ao tempo.

### Fase 3 — Finais

* catálogo de finais;
* classificação por dificuldade;
* desafios;
* progressão.

### Fase 4 — Speedrun

* cronômetro;
* tentativas;
* conclusão;
* recordes;
* histórico.

### Fase 5 — Personagens

* modelo de personagem;
* avatares;
* falas;
* reações;
* estado emocional;
* animações.

### Fase 6 — Gamificação

* conquistas;
* desbloqueios;
* metas;
* feedback;
* evolução visual.

### Fase 7 — Experiência inicial

* onboarding;
* tour guiado;
* escolha de nível;
* apresentação da progressão;
* introdução ao Speedrun.

### Fase 8 — Expansão

* novos finais;
* novos personagens;
* novas campanhas;
* novos Speedruns;
* ranking;
* novos desafios.

---

# 37. Resultado esperado

O objetivo final é que o Lucena deixe de ser apenas uma ferramenta para jogar ou praticar posições e passe a funcionar como uma **plataforma de progressão de xadrez**.

O jogador deve conseguir entrar no aplicativo e entender:

> **Onde estou?**

> **Contra quem posso jogar?**

> **O que preciso aprender?**

> **Qual é meu próximo nível?**

> **Quanto tempo levei?**

> **Qual é meu recorde?**

> **Consigo fazer melhor?**

E, principalmente:

> **O que eu posso fazer agora para ficar melhor no xadrez?**

A experiência completa deve combinar:

**Rating + Progressão + Finais + Maia + Personagens + Speedrun + Recordes + Histórico + Gamificação.**

A implementação deve ser feita incrementalmente, transformando cada grande componente acima em tarefas independentes e pequenas o suficiente para serem desenvolvidas, testadas e validadas individualmente.

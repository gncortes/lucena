# Calibração do Maia (T19)

Data: 2026-10-04. Modelo: Maia-3 de 5M com os pesos do app (float16), o mesmo das fixtures.

## Decisões

| O quê | Antes | Agora | Por quê |
| --- | --- | --- | --- |
| Temperatura (quanto o Maia varia os lances) | de 1,0 no nível 1000 a 0,5 no 2600 | **0,5 em todos os níveis** | com 1,0 o Maia joga pior do que o próprio modelo prevê para pessoas do nível; com 0 ele repete a partida |
| Tempo de pensar | regra da T18 | **igual, sem diferença por nível** | a "certeza" que alimenta a regra é a mesma em todos os níveis; a cabeça de tempo do modelo não serve de relógio |
| Empate por repetição e por 50 lances | não existia | **automático nas partidas contra a máquina** | sem isso, defender um final de torre não terminava nunca |
| Tempo da conta no celular | não medido | **pendente** | falta o número do aparelho do Gabriel (ver "O que falta") |

## Como foi medido

`tools/maia/calibrate.py` jogou 22.500 partidas a partir das 50 posições do catálogo, nos 9 níveis e em 5 temperaturas (0, 0,25, 0,5, 0,75 e 1), sorteando o lance como o app sorteia:

- **Maia contra Maia** (14.850 partidas): os dois lados no mesmo nível. Mostra se ele cumpre o objetivo da posição.
- **Jogador perfeito contra Maia** (7.650 partidas): o Stockfish faz o papel de quem não erra e o Maia é o adversário, como no app.

O juiz de cada lance é a tablebase Syzygy (resultado exato com até 5 peças). Empate por três repetições e por 50 lances vale na medição, como passou a valer no app.

A referência de "como uma pessoa desse rating joga" é o próprio modelo: além dos lances, ele prevê o resultado da partida entre duas pessoas do nível. Não há aqui outra fonte de partidas humanas.

## Temperatura

Posições de ganhar (44 das 50), Maia contra Maia: em quantas partidas o lado que deveria ganhar ganhou.

| Nível | T = 0 | T = 0,25 | T = 0,5 | T = 0,75 | T = 1 | O modelo prevê para pessoas |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| 1000 | 30% | 42% | 42% | 41% | 40% | 52% |
| 1200 | 45% | 49% | 55% | 54% | 55% | 62% |
| 1400 | 59% | 61% | 65% | 63% | 61% | 69% |
| 1600 | 64% | 69% | 70% | 70% | 64% | 73% |
| 1800 | 70% | 70% | 74% | 69% | 65% | 77% |
| 2000 | 68% | 74% | 74% | 70% | 66% | 80% |
| 2200 | 70% | 75% | 76% | 71% | 66% | 81% |
| 2400 | 70% | 75% | 73% | 73% | 68% | 82% |
| 2600 | 68% | 69% | 72% | 73% | 64% | 82% |

Cada célula com sorteio tem 352 partidas (margem de uns 2,5 pontos para mais ou para menos); a coluna T = 0 tem 44.

O que os números dizem:

- **Em toda temperatura o Maia ganha menos do que o modelo prevê para pessoas.** Parte da diferença é da medição: os dois lados são o Maia, e a previsão vem de partidas reais, com relógio.
- **T = 1 é a pior escolha do nível 1600 para cima** (de 5 a 10 pontos abaixo de T = 0,5) e não ajuda nos níveis baixos.
- **T = 0 também perde**, e ainda faz toda partida sair igual, o que é ruim para treinar.
- Entre 0,25 e 0,75 a diferença fica dentro da margem. Escolhi **0,5**: está entre os melhores em todos os níveis e mantém variedade de uma partida para a outra.
- Não há sinal de que nível baixo precise de temperatura alta. A força de cada nível já vem das probabilidades do modelo.

Lances que jogam fora uma posição ganha (vitória vira empate ou derrota), Maia contra Maia:

| Nível | T = 0 | T = 0,25 | T = 0,5 | T = 0,75 | T = 1 |
| --- | ---: | ---: | ---: | ---: | ---: |
| 1000 | 6,4% | 6,0% | 6,4% | 6,6% | 6,3% |
| 1400 | 3,0% | 3,9% | 4,6% | 5,6% | 5,1% |
| 1800 | 2,7% | 3,2% | 4,3% | 4,1% | 4,9% |
| 2200 | 2,8% | 2,9% | 3,1% | 3,9% | 4,8% |
| 2600 | 2,6% | 3,5% | 3,3% | 4,3% | 5,9% |

O nível muda o erro (6,4% no 1000, 3,3% no 2600 com T = 0,5) e a temperatura alta desfaz parte dessa diferença: no 2600, T = 1 quase dobra os erros.

## O que o nível muda para quem treina

Jogador perfeito contra o Maia, com T = 0,5. "Resistência" é quantos lances o jogador levou para dar mate, em relação ao mínimo possível (mediana; 1,00 seria a defesa perfeita).

| Nível | Resistência com o Maia só de rei | Resistência com o Maia com peças |
| --- | ---: | ---: |
| 1000 | 0,91 | 0,55 |
| 1400 | 0,91 | 0,54 |
| 1800 | 0,89 | 0,65 |
| 2200 | 0,96 | 0,58 |
| 2600 | 0,89 | 0,66 |

- Contra quem não erra, o Maia perdeu todas as posições de ganhar e não venceu nenhuma de empatar, em todos os níveis. Ele não "rouba" o resultado de quem joga certo.
- **Com o Maia só de rei, o nível quase não muda a defesa** (por volta de 0,9 em todos). É o caso de 24 das 50 posições: nesses mates básicos, a dificuldade está em o jogador saber o mate, não no nível escolhido.
- Com peças para se defender, os níveis altos resistem um pouco mais (0,55 no 1000, 0,66 no 2600).

Por família de final, Maia contra Maia com T = 0,5 (entre parênteses, o que o modelo prevê para pessoas):

| Final | Objetivo | 1000 | 1400 | 1800 | 2200 | 2600 |
| --- | --- | ---: | ---: | ---: | ---: | ---: |
| Mate de dama | ganhar | 54% (61%) | 81% (85%) | 100% (94%) | 92% (97%) | 85% (98%) |
| Mate de torre | ganhar | 52% (56%) | 92% (79%) | 96% (90%) | 96% (94%) | 96% (94%) |
| Mate de duas torres | ganhar | 88% (84%) | 100% (93%) | 100% (97%) | 100% (99%) | 100% (99%) |
| Dama contra torre | ganhar | 56% (48%) | 77% (64%) | 81% (70%) | 75% (75%) | 83% (77%) |
| Dama contra peão | ganhar | 18% (48%) | 57% (67%) | 72% (79%) | 52% (86%) | 57% (86%) |
| Peão contra rei | ganhar | 17% (39%) | 31% (57%) | 40% (65%) | 73% (66%) | 48% (70%) |
| Torre e peão contra torre | ganhar | 18% (44%) | 30% (47%) | 42% (52%) | 57% (59%) | 52% (56%) |
| Torre contra peão | ganhar | 22% (28%) | 34% (44%) | 44% (59%) | 41% (69%) | 41% (71%) |
| Peão contra rei | empatar | 83% (76%) | 79% (66%) | 83% (68%) | 92% (75%) | 75% (84%) |
| Torre e peão contra torre | empatar | 58% (63%) | 33% (54%) | 46% (53%) | 38% (63%) | 8% (74%) |

Cada célula tem de 24 a 48 partidas: serve para ver o desenho, não a casa decimal.

- Nos **mates básicos e em dama contra torre**, o Maia fica perto do previsto para pessoas, ou acima.
- Nos **finais de peão, dama contra peão e torre**, ele converte bem menos do que o previsto, e mais nos níveis altos. São finais que pedem técnica exata, e o modelo de 5M não a tem.

## Tempo de pensar

A regra da T18 usa a chance do lance escolhido ("certeza"): 85% ou mais sai quase na hora; quanto menor, mais perto do tempo disponível.

| Nível | Lances óbvios (85% ou mais) | Certeza do lance (mediana) | Fatia do tempo usada (média) |
| --- | ---: | ---: | ---: |
| 1000 | 25% | 67% | 44% |
| 1400 | 29% | 70% | 42% |
| 1800 | 28% | 70% | 42% |
| 2200 | 28% | 69% | 43% |
| 2600 | 24% | 64% | 46% |

- O ritmo sai igual em todos os níveis: um lance em quatro quase na hora e, no resto, perto de metade do tempo disponível. Com o teto de 2 s por lance, dá cerca de 1 s por lance. Não há o que ajustar por nível.
- **A cabeça de tempo do modelo não foi usada.** No código oficial o alvo dela é o tempo gasto no lance dividido por 100. As saídas ficam perto de 0,5 em qualquer posição (50 s por lance num mate básico não faz sentido) e não acompanham a dúvida do lance (correlação de -0,05 a 0,17). O modelo de 5M não recebe o relógio da partida, então não tem como saber o ritmo.
- O ritmo por tipo de partida (bullet a clássico) é da T22.

## Empates automáticos

A calibração mostrou um buraco fora do Maia: o app só empatava por rei afogado ou falta de material. Num final de torre e peão contra torre, quem defendia certo nunca via o fim da partida, e com relógio acabava perdendo por tempo.

Agora, nas partidas contra a máquina, a terceira repetição da posição e a regra dos 50 lances empatam sozinhas, e o objetivo de empatar fica cumprido. No tabuleiro livre (o jogador move os dois lados) nada muda.

## Ritmo da partida (T22)

O Maia decide de outro jeito conforme o ritmo, sem trocar o nível (a força continua vindo do rating passado ao modelo). Os parâmetros ficam em `assets/progression/time_controls.json`, por categoria (pela regra do Lichess: tempo inicial + 40 × incremento; abaixo de 3 min é bullet, de 8 min blitz, de 25 min rápido):

| Categoria | Temperatura | Tempo de pensar |
| --- | ---: | ---: |
| Bullet | 0,3 | 45% |
| Blitz | 0,4 | 75% |
| Rápido e clássico | 0,5 | 100% |

- **Temperatura menor = mais instinto:** o Maia fica nos lances que as pessoas daquele rating mais jogam (os naturais da posição) e sorteia menos os que pedem cálculo. Isso não enfraquece: o lance mais provável do modelo é, quase sempre, o melhor que aquele rating acha.
- **Tempo de pensar** multiplica o tempo humano da T18 e nunca passa do teto do relógio; no bullet a máquina continua sem perder por tempo.

Medido neste computador, nas 50 posições do catálogo, com o Maia 1000, 1600 e 2200 (5 sorteios por posição):

| Ritmo | Lance mais provável | Tempo médio por lance |
| --- | ---: | ---: |
| 1+0 (bullet) | 81% | 0,6 s |
| 3+0 e 3+2 (blitz) | 73% | 1,0 s |
| 5+3 (blitz) | 72% | 1,0 s |
| 10+0 (rápido) | 70% | 1,4 s |

**Falta no celular:** jogar algumas partidas de 1+0 e 10+0 e ver se a diferença se sente. Se o bullet parecer lento ou "esperto" demais, os números estão no JSON (não precisa mexer em código).

## O que falta

- **Tempo da conta no celular do Gabriel.** O Diagnóstico do Maia ganhou o botão "Medir velocidade": dez contas seguidas e o tempo típico por lance. No emulador dá perto de 100 ms. A decisão da T15 pede revisão se passar de 400 ms no aparelho.
- **Níveis altos nos finais técnicos.** O Maia 2200 a 2600 joga abaixo do rating em finais de peão e de torre. Quem quer um adversário que não erra tem o Stockfish. O modelo maior (23M, 92 MB) continua na lista do pós-MVP.
- **Sem partidas humanas de fora.** A régua foi a previsão do próprio modelo. Uma amostra de partidas reais por rating deixaria a escolha da temperatura mais firme.
- **Sensação de jogo.** Temperatura e ritmo foram escolhidos por medição; se ao jogar o Maia parecer rápido ou lento demais, os números ficam em `MaiaLevels.temperature` e `ThinkTimePolicy`.

## Como refazer

```
venv/bin/python tools/maia/calibrate.py --syzygy <pasta das tablebases> --stockfish <binário>
```

Leva uns 30 minutos e grava `docs/calibracao-dados.json`. O ambiente é o de `tools/maia/requirements.txt`; as tablebases de 3 a 5 peças (só os arquivos `.rtbw`, 380 MB) vêm de `https://tablebase.lichess.ovh/tables/standard/3-4-5-wdl/`. O sorteio tem semente fixa: a parte do Maia contra Maia sai igual a cada execução; a do jogador perfeito varia um pouco, porque o Stockfish joga por tempo.

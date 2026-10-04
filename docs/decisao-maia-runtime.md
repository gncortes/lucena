# Decisão: como o Maia roda dentro do app (T15)

**Decisão:** o Maia-3 roda em **Dart puro**, sem biblioteca nativa. O modelo é o **Maia-3 de 5M** e os pesos vão no app em **float16** (10,5 MB).

Data: 2026-10-04. Vale para a T16 em diante.

## Por quê

| | Dart puro (escolhido) | ONNX Runtime |
| --- | --- | --- |
| Igual ao PyTorch oficial | sim: 67 de 67 posições, diferença máxima de 0,000002 na probabilidade | sim: diferença máxima de 0,00003 nas saídas brutas |
| Tempo por lance no emulador (x86_64, build de release) | 105 ms | 11 ms (1 thread) |
| Tempo por lance neste computador | 73 ms | 6 ms |
| Peso no APK universal (hoje 74 MB) | +10 MB (só os pesos) | +77 MB (58 MB de biblioteca nativa nas 3 arquiteturas + 19 MB de modelo) |
| Dependências novas | nenhuma | plugin `flutter_onnxruntime` (um mantenedor) + ONNX Runtime 1.23 |
| Teste contra a referência | no `flutter test`, em todo PR | só com aparelho ou emulador (a biblioteca nativa não roda no `flutter test`) |
| Cópia do modelo no aparelho | uma | duas (o plugin copia o modelo para o cache) |
| Exportar o modelo | um script, sem mexer no modelo | os dois exportadores do PyTorch falham no modelo oficial; precisou trocar uma camada à mão |

O ONNX é 10 vezes mais rápido, mas a velocidade não é o gargalo: o Maia faz **uma** conta por lance e a máquina já espera de 50 ms a 2 s para parecer humana. Em troca dessa velocidade o app dobraria de tamanho e os testes de fidelidade sairiam do CI. Por isso, Dart.

## O que não foi medido

- **Celular de verdade (ARM).** Só havia o emulador (x86_64). Estimativa, não medição: de 150 a 500 ms por lance, conforme o aparelho. A tela de depuração da T16 mostra o tempo real no aparelho.
- Memória, bateria e aquecimento.

**Ponto de revisão:** se na T16 a mediana no celular do Gabriel passar de 400 ms, reabrir esta decisão. Opções, da mais barata para a mais cara: otimizar as multiplicações de matriz em Dart (hoje o laço é o simples), calcular o lance enquanto o jogador pensa, ou trocar para o ONNX. A troca é contida: só `MaiaNetwork` muda, e as fixtures dizem se o resultado continua igual.

## Referência oficial

- Código: [CSSLab/maia3](https://github.com/CSSLab/maia3) no commit `1e13597` (AGPL-3.0, a mesma licença do Lucena).
- Pesos: `UofTCSSLab/Maia3-5M` no Hugging Face, revisão `b6559de`, SHA-256 `ba14208b…524f` (conferido pelos scripts).
- Fixtures: `test/fixtures/maia/reference.json`, geradas por `tools/maia/make_fixtures.py` com o código oficial. São 67 casos: posição inicial, aberturas, meio-jogo, roque dos dois lados, en passant, promoções (com captura, brancas e pretas) e os finais do catálogo, nos níveis 1000, 1400, 1800, 2200 e 2600, com ratings iguais e diferentes.
- Teste: `test/data/services/maia/maia_model_test.dart` compara cada lance legal, a previsão de resultado e a cabeça de tempo, com tolerância de 0,0001.

Para refazer tudo (pesos, fixtures e o ONNX do spike), ver `tools/maia/requirements.txt`.

## Escolhas dentro da decisão

- **Modelo de 5M, não os maiores.** Os de 23M e 79M pesam 92 MB e 316 MB: não cabem num app. O de 5M tem 5,2 milhões de pesos (o checkpoint oficial repete uma matriz nas 8 camadas; aqui ela é gravada uma vez).
- **Pesos em float16.** Metade do tamanho (21 MB → 10,5 MB). Nos 67 casos o lance mais provável não mudou em nenhum e a maior mudança de probabilidade foi 0,0007. O script de fixtures recusa gerar se isso passar de 0,002. As fixtures usam esses mesmos pesos arredondados, então o teste do porte continua apertado.
- **Pesos dentro do repositório** (`assets/models/maia3-5m.bin`, antes ignorado pelo git). Assim o CI testa e monta o app sem baixar nada e sem instalar PyTorch. Custo: 10,5 MB no repositório a cada troca de modelo, o que deve ser raro.
- **Histórico de verdade.** A rede recebe a posição atual e as 7 anteriores. O app passa as posições reais da partida (como o `--use-uci-history` oficial); no começo de um final, a primeira posição é repetida, como o código oficial faz.
- **Roque.** O `dartchess` escreve o roque como rei-toma-torre (`e1h1`); o modelo e as fixtures usam `e1g1`. `MaiaModel` converte.

## O que a T16 recebe pronto

- `lib/data/services/maia/maia_weights.dart`: lê o arquivo de pesos.
- `lib/data/services/maia/maia_network.dart`: a rede (transformer de 8 blocos com GAB, cabeças de lance, resultado e tempo).
- `lib/data/services/maia/maia_model.dart`: `MaiaModel.evaluate(histórico, selfElo, oppoElo)` devolve a probabilidade de cada lance legal, a chance de vitória, empate e derrota e a saída da cabeça de tempo.
- Falta na T16: registrar o arquivo em `pubspec.yaml`, o `MaiaService` (carregar o asset e rodar num isolate, para não travar a tela: medido, o tempo no isolate é o mesmo) e a tela de depuração.

Duas observações para as próximas tarefas:

- **T17 (níveis):** o rating muda de fato a jogada. No final de torre, o lance mais provável a 1000 tem 19% e a 2200 tem 40%; a chance de vitória prevista no mate de dama vai de 58% (1000) a 98% (2600).
- **T18 (tempo de pensar):** o modelo tem uma cabeça de tempo de reflexão, que o motor UCI oficial ignora. Ela sobe com o rating e com a dificuldade da posição (0,38 na posição inicial a 2600; 0,93 no final de torre a 2600). A unidade não está documentada; vale investigar antes de inventar uma regra própria.

## Como o ONNX foi testado

- Exportação: `tools/maia/export_onnx.py`. O exportador novo do PyTorch 2.14 falha na camada de atenção e o clássico não conhece o `RMSNorm`; o script troca o `RMSNorm` por uma conta equivalente antes de exportar.
- App de teste descartável (não versionado) com `flutter_onnxruntime` 1.8.5, build de release no emulador: 11 ms com 1 thread, 4 ms com 4, 115 ms para carregar a sessão. Precisa de uma regra de ProGuard (`-keep class ai.onnxruntime.** { *; }`), sem a qual o build de release cai no primeiro lance.
- Tamanho: `libonnxruntime.so` tem 19 MB em arm64 e 23 MB em x86_64, sem compressão dentro do APK.
- Os outros plugins (`onnxruntime`, `onnxruntime_plus`) não trazem a biblioteca para x86_64 e não rodam no emulador.

---
name: xadrez-libs
description: Referência rápida de dartchess, chessground e engines. Use ao mexer com regras de xadrez, tabuleiro, Stockfish ou Maia.
---

# Bibliotecas de xadrez

- Regras, FEN, SAN/UCI, fim de partida: `dartchess`. Toda regra de xadrez vem dele; não reimplementar.
- Tabuleiro e editor de posição: `chessground`. Ele não tem lógica de xadrez.
- Antes de usar uma API desses pacotes, confirmar a assinatura atual via Context7 ou MCP do Dart (mudam entre versões).
- Engines: `StockfishService`/`MaiaService` (serviços) usados só por `OpponentRepository`. View model nunca chama engine direto.
- Posições: `assets/positions/positions.json`, gerado por `tools/import_positions.py`. Não editar à mão.
- Não ler `assets/models/` nem repositórios de terceiros; a tarefa diz quais arquivos usar.

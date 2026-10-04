# Lucena

**Chess endgame trainer for mobile.** Practice thousands of endgame positions against human-like opponents powered by [Maia-3](https://github.com/CSSLab/maia3) (600–2600) or against Stockfish at full strength.

> 🚧 **Status:** early development. The first MVP is being built. Nothing is published on app stores yet.

---

## Why Lucena?

Knowing an endgame in theory is not the same as converting it with the clock running. Lucena lets you play endgame positions as real games:

- **Win or defend.** Every position has a goal: convert the win, or hold the draw.
- **Human-like opponents.** Maia-3 imitates how real players of a given rating move, mistakes included, so a 1400 opponent defends like a 1400 player.
- **Real clock.** Choose your time and the opponent's time separately, from bullet to rapid. The AI takes human-like time to think.
- **Full strength when you're ready.** Switch to Stockfish to test your technique against perfect defense.

The name comes from the **Lucena position**, one of the most famous endgames in chess.

## Features (MVP roadmap)

- [ ] Endgame catalog by category (pawn, rook, minor pieces, queen endgames and more)
- [ ] Custom positions (FEN or board editor)
- [ ] Separate clocks for player and opponent
- [ ] Maia-3 opponent with rating levels from 600 to 2600
- [ ] Stockfish opponent at full strength
- [ ] Local progress tracking
- [ ] Board, piece set and theme customization (light/dark)
- [ ] 20+ languages, including right-to-left support

See [`docs/PLANO.md`](docs/PLANO.md) for the full plan (in Portuguese) and [`docs/tasks/`](docs/tasks/) for individual tasks.

## Tech stack

- **Flutter / Dart**, following the [official Flutter app architecture guide](https://docs.flutter.dev/app-architecture) (Cubit/Bloc as view models)
- [`chessground`](https://pub.dev/packages/chessground) and [`dartchess`](https://pub.dev/packages/dartchess) by Lichess for the board and chess rules
- **Maia-3** for human-like move prediction
- **Stockfish** for full-strength play
- [`drift`](https://pub.dev/packages/drift) for local storage
- [Patrol](https://patrol.leancode.co/) for end-to-end tests

## Getting started

Requirements: Flutter (stable), Android SDK, Python 3 (for scripts in `tools/`), Patrol CLI.

```bash
git clone https://github.com/gncortes/lucena.git
cd lucena
cp .env.example .env   # local machine settings, never committed
flutter pub get
flutter run
```

Run the tests:

```bash
flutter analyze
flutter test
patrol test --dart-define=E2E=true
```

## Contributing

Contributions are welcome, especially:

- **Translations:** a translation platform will be set up soon. Until then, open an issue.
- **Endgame positions and explanations:** suggestions for classic positions and teaching notes.
- **Bug reports and testing** on different devices.

Please open an issue before starting larger changes.

## Credits

- **[Maia-3](https://github.com/CSSLab/maia3)** by the CSSLab at the University of Toronto (AGPL-3.0)
- **[Stockfish](https://stockfishchess.org/)** (GPL-3.0)
- **[chessground](https://github.com/lichess-org/flutter-chessground)** and **[dartchess](https://github.com/lichess-org/dartchess)** by [Lichess](https://lichess.org/) (GPL-3.0)
- Endgame positions from **[Chess Endgame Training](https://github.com/supertorpe/chessendgametraining)** by jlomo/supertorpe (GPL-3.0), which in turn uses the endgame database from ECO Chess Opening Codes and the checkmate patterns from **[calebjcourtney/chess-endgame-training](https://github.com/calebjcourtney/chess-endgame-training)** (GPL-3.0)

Full third-party license details are in [`THIRD-PARTY-NOTICES.md`](THIRD-PARTY-NOTICES.md).

## License

Lucena is free software, licensed under the **[GNU Affero General Public License v3.0](LICENSE)**.

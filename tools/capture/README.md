# Capturas da landing page

Prints e vídeos do app para `landing/assets/media/<idioma>/`, refeitos do
mesmo jeito sempre que o app mudar.

O app roda em **release**, instalado no emulador e conduzido por `adb` (sem
Patrol: o binding de teste escreve o nome do cenário na tela). Os toques vão
pelo texto da tela, tirado dos arquivos de tradução, então o mesmo roteiro
serve para qualquer idioma. No tabuleiro, as casas são achadas no print; os
lances do jogador vêm do Stockfish do computador e o do adversário é lido da
tela.

## Preparar

- Um emulador só para isso, sem outros rodando (concorrência = quadros
  perdidos). Usado: Pixel 9 Pro XL (1344x2992), Android 36.
- `stockfish` no PATH e `pip install chess pillow numpy`.
- `flutter build apk --release` e
  `adb -s <aparelho> install -r build/app/outputs/flutter-apk/app-release.apk`.

## Capturar

```bash
cd tools/capture
python3 scenes.py -d emulator-5584 -l pt            # todos os cenários
python3 scenes.py -d emulator-5584 -l en inicio     # só um
```

Idiomas: `pt`, `en`, `es` (a landing usa `en` para os outros). Os arquivos crus
(PNG do aparelho e MP4 em 1080x2404, o maior que o gravador do emulador aceita
nesse formato) ficam em `build/capture/<idioma>/`. Barra de status em modo demo
(12:00, bateria cheia, Wi-Fi) e app limpo a cada cenário.

## Gerar as versões da web

```bash
tools/capture/encode.sh   # build/capture -> landing/assets/media
```

Para cada vídeo: WebM (VP9) e MP4 (H.264) em 720x1604 a 30 fps, e o poster
(WebP). Para cada print: o PNG original e um WebP de 720 de largura.

## Telas capturadas

| Arquivo | Tela |
|---|---|
| `inicio` | Tela inicial com os caminhos de treino |
| `iniciante-aulas` (`iniciante-trilha`) | Escola do Viktor: trilha e a primeira aula (a torre) |
| `intermediario-jornada` | Jornada: desafios por nível de rating |
| `aula-dama-vs-torre` | Aula de finais: dama contra torre (posição de Philidor) |
| `aula-bispo-e-cavalo` | Aula de finais: mate de bispo e cavalo (manobra em W) |
| `aula-lucena` | Aula de finais: a posição de Lucena (a ponte) |
| `maia-nivel-e-ritmo` | Nova partida: nível do Maia e ritmo, e a partida |
| `destaque` | Partida contra o Maia 2000 (dama contra torre, com relógio) |
| `partida-stockfish` | Partida contra o Stockfish |
| `analise-partida` | Revisão da partida com o Stockfish |
| `speedrun` | Speedrun: as etapas e a primeira partida |
| `personalizacao` (`personalizacao-tema`) | Tema, cor do app, tabuleiro e peças (no tour) |

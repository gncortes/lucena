# Landing page do Lucena

Site estático em [Astro](https://astro.build), publicado no GitHub Pages
(`https://gncortes.github.io/lucena/`) pelo workflow `.github/workflows/landing.yml`.

```bash
cd landing
npm ci
npm run dev      # http://localhost:4321/lucena/
npm run build    # gera dist/
npx astro check  # tipos
```

- Textos: `src/i18n/pt-br.ts` (raiz do site) e `src/i18n/en.ts` (`/en/`). Para um
  idioma novo: dicionário em `src/i18n/`, entrada em `src/i18n/index.ts`, no
  `astro.config.mjs` e uma página em `src/pages/<idioma>/index.astro`.
- Capturas do app (vídeos, posters e prints) ficam em `assets/` com os nomes de
  `src/media.ts`.
- `node scripts/brand.mjs`: ícones, mascote e peças a partir de `../assets/branding`.
- `scripts/og.sh`: imagem de prévia (Open Graph) a partir de `scripts/og.html`.

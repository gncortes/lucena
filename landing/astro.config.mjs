import { defineConfig } from 'astro/config';
import sitemap from '@astrojs/sitemap';

// pt-BR na raiz e os outros idiomas com prefixo (/en/, /es/). Para um idioma novo:
// adicionar aqui, em src/i18n/ e criar src/pages/<idioma>/index.astro.
export default defineConfig({
  site: 'https://gncortes.github.io',
  base: '/lucena/',
  trailingSlash: 'always',
  // As capturas do app ficam em landing/assets/ e são servidas como estão.
  publicDir: './assets',
  // CSS pequeno: embutido no HTML, sem requisição bloqueando a pintura.
  build: { inlineStylesheets: 'always' },
  i18n: {
    defaultLocale: 'pt-br',
    locales: ['pt-br', 'en', 'es'],
    routing: { prefixDefaultLocale: false },
  },
  integrations: [
    sitemap({
      i18n: {
        defaultLocale: 'pt-br',
        locales: { 'pt-br': 'pt-BR', en: 'en', es: 'es' },
      },
    }),
  ],
});

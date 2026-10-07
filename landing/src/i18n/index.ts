import type { Dictionary } from './types';
import ptBr from './pt-br';
import en from './en';
import es from './es';

// Ordem dos idiomas no seletor. `path` é o prefixo da página (o padrão fica
// na raiz) e `hreflang` o código usado nas tags alternate e no Open Graph.
export const locales = {
  'pt-br': { path: '', hreflang: 'pt-BR', og: 'pt_BR', label: 'Português', dict: ptBr },
  en: { path: 'en/', hreflang: 'en', og: 'en_US', label: 'English', dict: en },
  es: { path: 'es/', hreflang: 'es', og: 'es_ES', label: 'Español', dict: es },
} as const satisfies Record<
  string,
  { path: string; hreflang: string; og: string; label: string; dict: Dictionary }
>;

export type Locale = keyof typeof locales;
export const defaultLocale: Locale = 'pt-br';

/** Para quem fala outro idioma (hreflang x-default). */
export const fallbackLocale: Locale = 'en';

export const links = {
  tester: 'https://appdistribution.firebase.dev/i/8f905d22a0d826e5',
  email: 'novaiscortesgabriel729@gmail.com',
  firebase: 'https://firebase.google.com/docs/app-distribution',
  stockfish: 'https://stockfishchess.org',
  maia: 'https://www.maiachess.com',
  lichess: 'https://lichess.org',
  philidor:
    'https://commons.wikimedia.org/wiki/File:Francois-Andre_Danican_Philidor.jpg',
};

/** Caminho absoluto (com o `base` do site) para [path] dentro de landing/assets. */
export const asset = (path: string) => `${import.meta.env.BASE_URL}${path}`;

export const pageUrl = (locale: Locale) =>
  `${import.meta.env.BASE_URL}${locales[locale].path}`;

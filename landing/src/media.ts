// Vídeos e quadros do app, por idioma capturado:
// landing/assets/media/<idioma>/<nome>.{webm,mp4} e <nome>-poster.webp; os
// quadros parados são <nome>.webp. Os idiomas sem captura própria usam os de
// português até haver as de inglês.
export const clips = {
  hero: 'maia-partida',
  school: 'escola-torre',
  journey: 'jornada',
  queenRook: 'aula-dama-vs-torre',
  speedrun: 'speedrun',
} as const;

export const stills = {
  theme: 'tema',
  journeyChallenge: 'desafio-jornada',
  exercise: 'exercicio',
  queenRookLesson: 'aula-dama-vs-torre-2',
  shortSide: 'aula-lado-curto',
  stars: 'desafio-estrelas',
} as const;

export type Clip = keyof typeof clips;
export type Still = keyof typeof stills;

/** Os idiomas com captura própria; o resto usa [fallback]. */
const captured: Record<string, string> = { 'pt-br': 'pt' };
const fallback = 'pt';

/** Pasta das capturas do idioma [locale], relativa a landing/assets. */
export const mediaDir = (locale: string) => `media/${captured[locale] ?? fallback}`;

/** O tamanho da tela do Pixel 9 Pro XL, em que foram gravados. */
export const clipSize = { width: 1344, height: 2992 };

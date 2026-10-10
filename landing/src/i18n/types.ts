type Feature = { title: string; body: string; bullets: string[] };
type Block = { title: string; body: string };

export type Dictionary = {
  meta: { title: string; description: string; ogAlt: string };
  nav: {
    features: string;
    roadmap: string;
    support: string;
    tester: string;
    skip: string;
    theme: string;
    language: string;
    menu: string;
  };
  hero: {
    eyebrow: string;
    title: string;
    titleAccent: string;
    lead: string;
    cta: string;
    secondary: string;
    note: string;
    chips: string[];
  };
  stats: { value: string; label: string }[];
  marquee: string[];
  message: {
    kicker: string;
    title: string;
    quote: string;
    quoteAuthor: string;
    body: string[];
    boardCaption: string;
  };
  story: {
    kicker: string;
    title: string;
    paragraphs: string[];
    philidor: { text: string; caption: string; alt: string };
    signature: string;
  };
  features: {
    kicker: string;
    title: string;
    lead: string;
    items: Record<
      | 'progression'
      | 'placement'
      | 'school'
      | 'lessons'
      | 'journey'
      | 'speedrun'
      | 'marathon'
      | 'blind'
      | 'voice'
      | 'stars'
      | 'analysis'
      | 'progress'
      | 'custom',
      Feature
    >;
    /** O roteiro de cada capítulo das aulas de finais. */
    route: { label: string; steps: Block[] };
  };
  levels: { kicker: string; title: string; beginner: Block; advanced: Block };
  roadmap: {
    kicker: string;
    title: string;
    items: { status: string; title: string; body: string }[];
  };
  support: {
    kicker: string;
    title: string;
    body: string[];
    cardTitle: string;
    cardBody: string;
    cta: string;
    subject: string;
    note: string;
  };
  tester: {
    kicker: string;
    title: string;
    body: string;
    teachers: string;
    safety: string;
    safetyLink: string;
    wait: string;
    cta: string;
    thanks: string;
  };
  vision: { kicker: string; title: string; body: string; cta: string };
  refs: { kicker: string; title: string; items: { name: string; body: string }[] };
  footer: { tagline: string; dev: string; contact: string };
  media: Record<
    | 'hero'
    | 'school'
    | 'journey'
    | 'queenRook'
    | 'speedrun'
    | 'theme'
    | 'journeyChallenge'
    | 'exercise'
    | 'queenRookLesson'
    | 'shortSide'
    | 'stars'
    | 'play'
    | 'pause',
    string
  >;
};

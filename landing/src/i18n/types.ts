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
  story: { kicker: string; title: string; paragraphs: string[]; signature: string };
  features: {
    kicker: string;
    title: string;
    items: Record<
      'progression' | 'lessons' | 'levels' | 'speedrun' | 'analysis' | 'custom',
      Feature
    >;
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
    price: string;
    priceNote: string;
    cta: string;
    placeholder: string;
  };
  tester: {
    kicker: string;
    title: string;
    body: string;
    teachers: string;
    cta: string;
    thanks: string;
  };
  vision: { kicker: string; title: string; body: string; cta: string };
  footer: {
    tagline: string;
    source: string;
    license: string;
    contact: string;
    credits: string;
  };
  media: Record<
    | 'hero'
    | 'home'
    | 'beginner'
    | 'intermediate'
    | 'queenRook'
    | 'lucena'
    | 'bishopKnight'
    | 'maia'
    | 'stockfish'
    | 'speedrun'
    | 'analysis'
    | 'custom'
    | 'play'
    | 'pause',
    string
  >;
};

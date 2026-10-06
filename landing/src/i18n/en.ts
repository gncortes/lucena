import type { Dictionary } from './types';

const en: Dictionary = {
  meta: {
    title: 'Lucena: train chess endgames against Maia and Stockfish',
    description:
      'Learn chess through the endgame. Train chess endgames against an AI that plays like a human, from your level up to full-strength Stockfish, with interactive lessons on queen vs rook, bishop and knight mate and more.',
    ogAlt: 'The Lucena app open on a phone, with a chess endgame on the board.',
  },
  nav: {
    features: 'Features',
    roadmap: 'Roadmap',
    support: 'Support',
    tester: 'Become a tester',
    skip: 'Skip to content',
    theme: 'Toggle light and dark theme',
    language: 'Language',
    menu: 'Menu',
  },
  hero: {
    eyebrow: 'Free and open source chess app',
    title: 'Train chess endgames until they become',
    titleAccent: 'technique',
    lead: 'Lucena has you play endgames against an AI that plays like a human, from your level all the way up to full-strength Stockfish.',
    cta: 'Become a tester',
    secondary: 'See how it works',
    note: 'Android, testing version. Coming soon to Google Play.',
    chips: ['Maia 1000–2600', 'Stockfish', 'Interactive lessons'],
  },
  stats: [
    { value: '9', label: 'Maia levels, from 1000 to 2600' },
    { value: '12', label: 'lessons on classic endgames' },
    { value: '25', label: 'lessons for beginners' },
    { value: '55', label: 'endgames to train as often as you like' },
  ],
  marquee: [
    'Lucena position',
    'Philidor position',
    'Queen vs rook',
    'Bishop and knight mate',
    'Key squares',
    'Distant opposition',
    'Back-rank defence',
    'Short-side defence',
  ],
  message: {
    kicker: 'Learn chess through the endgame',
    title: 'Start at the end of the board',
    quote:
      'In order to improve your game, you must study the endgame before everything else.',
    quoteAuthor: 'José Raúl Capablanca, world champion',
    body: [
      'With few pieces on the board, each one shows what it can do. It becomes easier to see how the king attacks, how the rook cuts off, how bishop and knight work together.',
      'That is where you learn to play with precision: every move counts, and you see right away what worked. That clarity carries over to the whole game.',
    ],
    boardLabel:
      'The Lucena position: white king on b8, pawn on b7 and rook on c1; black king on d8 and rook on a2.',
    boardCaption:
      'The Lucena position, the rook endgame the app is named after. Winning from here is a technique, and the app teaches it step by step.',
    boardMoves: ['1. Rd1+', '1... Ke7', '2. Rd4!', '2... Ra1', '3. Kc7', '3... Rc1+', '4. Kb6', '4... Rb1+', '5. Kc6', '5... Rc1+', '6. Kb5', '6... Rb1+', '7. Rb4'],
    boardWin: 'The bridge: the pawn will queen.',
  },
  story: {
    kicker: 'Why Lucena exists',
    title: 'Born from a real struggle',
    paragraphs: [
      'I play and teach chess. And, to be honest, endgames were always my weak spot. I knew the theory, but at the board the position slipped away.',
      'What changed it was training progressively: first against Maia, an AI that gets things right and wrong like a human at my level, then climbing up to Stockfish. Repeating the same position against stronger and stronger opponents locked in the techniques in a way no book ever did.',
      'Lucena is that training, organized for anyone who wants to walk the same path.',
    ],
    signature: 'Gabriel, creator of Lucena',
  },
  features: {
    kicker: 'Features',
    title: 'Everything you need to master endgames',
    items: {
      progression: {
        title: 'From Maia to Stockfish',
        body: 'Play against Maia, an AI trained on games by real people, with a human style at your level: from 1000 to 2600. Pick the time control, climb step by step and, when you are ready, face Stockfish at full strength.',
        bullets: [
          'Human levels from 1000 to 2600',
          'Clock with time and increment',
          'Full-strength Stockfish',
        ],
      },
      lessons: {
        title: 'Lessons that break the hard part into simple steps',
        body: 'Complex endgames become short, interactive steps. You learn each idea, practice it right away and only move on once you get it.',
        bullets: [
          'Queen vs rook',
          'Bishop and knight mate',
          'Rook and pawn endgames',
        ],
      },
      levels: {
        title: 'Training for beginners and intermediate players',
        body: 'Beginners learn the pieces with guided lessons. Players with some experience follow the Journey: challenges by rating level, against opponents with personality.',
        bullets: [
          'Guided lessons for beginners',
          'A Journey by rating level',
          'Stars and achievements to track your progress',
        ],
      },
      speedrun: {
        title: 'Speedrun: race the clock',
        body: 'Solve a sequence of endgames as fast as you can. Beat your record and watch the technique become automatic.',
        bullets: ['Splits per stage', 'Personal record', 'Several time controls'],
      },
      analysis: {
        title: 'Game analysis',
        body: 'After playing, review move by move with the engine evaluation and find where the win slipped away or where the defence held.',
        bullets: ['Evaluation bar', 'Best engine moves', 'Accuracy for each player'],
      },
      custom: {
        title: 'Your way',
        body: 'Light or dark theme, app colors, pieces and board, clock on top or at the bottom. The app adapts to you.',
        bullets: [],
      },
    },
  },
  levels: {
    kicker: 'For every level',
    title: 'Just starting or already strong? There is a challenge for you',
    beginner: {
      title: 'Just starting',
      body: 'Learn how each piece moves and delivers mate with short lessons, hints at the right moment and opponents that play at your pace.',
    },
    advanced: {
      title: 'Already strong',
      body: 'Convert theoretical endgames against Maia 2600 and Stockfish. If you win queen vs rook against Stockfish, the technique is yours.',
    },
  },
  roadmap: {
    kicker: 'Roadmap',
    title: 'Where Lucena is going',
    items: [
      {
        status: 'Now',
        title: 'Testing version on Android',
        body: 'Everyone in the testing group always gets the latest version.',
      },
      {
        status: 'In preparation',
        title: 'Google Play',
        body: 'The store release is already being prepared.',
      },
      {
        status: 'Next',
        title: 'App Store',
        body: 'Bringing Lucena to the iPhone is the next step, and that is where your support makes a difference.',
      },
    ],
  },
  support: {
    kicker: 'Support the project',
    title: 'Where the money goes',
    body: [
      'Lucena is free and open source. To publish on the App Store, Apple requires the Apple Developer Program, which costs US$ 99 per year.',
      'Donations pay for that: they bring the app to the iPhone and help validate the idea there. Any amount helps.',
    ],
    price: 'US$ 99',
    priceNote: 'per year, to publish on the App Store',
    cta: 'Make a donation',
    placeholder: 'Donation link coming soon',
  },
  tester: {
    kicker: 'Become a tester',
    title: 'Try it before everyone else',
    body: 'Join the testing group and always get the latest version of Lucena on your Android phone.',
    teachers:
      'Are you a chess teacher? Share the app with your students. Endgames are the best way in, and feedback from people who teach is worth gold.',
    cta: 'Join the testing group',
    thanks:
      'Thank you, truly. Someone taking the time to test, validate the idea and send feedback means a lot to me. Every message helps decide the next step for the app.',
  },
  vision: {
    kicker: 'Vision',
    title: 'A living project',
    body: 'The goal is to offer the best experience to learn chess, get better at endgames and challenge yourself in them. Lucena will grow with new features, guided by what the community asks for.',
    cta: 'Suggest a feature',
  },
  footer: {
    tagline: 'Train chess endgames against Maia and Stockfish.',
    source: 'Source on GitHub',
    license: 'AGPL-3.0 license',
    contact: 'Contact and suggestions',
    credits:
      'Maia: CSSLab, University of Toronto. Stockfish: the Stockfish project (GPL-3.0). Pieces: cburnett, by Colin M.L. Burnett.',
  },
  media: {
    hero: 'An endgame against Maia being played in Lucena',
    home: 'Lucena home screen with the training paths',
    beginner: 'A guided beginner lesson in Lucena',
    intermediate: 'The Journey of challenges by rating level in Lucena',
    queenRook: 'Interactive queen vs rook lesson in Lucena',
    bishopKnight: 'Interactive bishop and knight mate lesson in Lucena',
    maia: 'Choosing the Maia level and the time control in Lucena',
    stockfish: 'A game against Stockfish in Lucena',
    speedrun: 'Lucena speedrun mode with the time of each stage',
    analysis: 'Move-by-move game analysis in Lucena',
    custom: 'Theme, piece and board customization in Lucena',
    play: 'Play video',
    pause: 'Pause video',
  },
};

export default en;

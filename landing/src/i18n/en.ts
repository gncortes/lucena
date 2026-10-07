import type { Dictionary } from './types';

const en: Dictionary = {
  meta: {
    title: 'Lucena: train chess endgames against Maia and Stockfish',
    description:
      'Learn chess through the endgame. Train chess endgames against Maia, which plays like a human at your level, up to full-strength Stockfish, with interactive lessons on queen vs rook, bishop and knight mate and more.',
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
    eyebrow: 'Free app to train chess endgames',
    title: 'Train chess endgames until they become',
    titleAccent: 'technique',
    lead: 'Lucena has you play endgames against Maia, which plays like a human at your level, and then against full-strength Stockfish.',
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
    boardCaption:
      "The first lesson in Viktor's school: just the rook on the board. With few pieces, each one shows what it can do.",
  },
  story: {
    kicker: 'Why Lucena exists',
    title: 'Made by someone who loves chess',
    paragraphs: [
      'I am a programmer and I love programming. My other passion is chess. Lucena was born from a need of my own: endgames were always my weak spot, and I wanted a way to really train them.',
      'What worked was training progressively: first against Maia, which gets things right and wrong like a human at my level, then climbing up to Stockfish. Repeating the same position against stronger and stronger opponents locked in the techniques.',
      'But I love chess so much that I wanted to go further: to build something that lets anyone learn and practice easily and step into the world of this ancient game. I want to spread Lucena so that many people learn to play with it and master the endgames that are hardest to learn.',
    ],
    philidor: {
      text:
        'And I want to show how fascinating endgames are. They are rarely the part of chess that grabs attention, but they hold some of the most beautiful ideas in the game. More than 250 years ago, François-André Danican Philidor was already studying these positions, and the defence named after him is still taught today, including here in Lucena. No wonder many, like Grandmaster Rafael Leitão, consider him the greatest genius in chess history.',
      caption: 'François-André Danican Philidor (1726–1795), engraving by Augustin de Saint-Aubin, 1772.',
      alt: 'Profile portrait of Philidor, an 18th-century engraving',
    },
    signature: 'Gabriel, creator of Lucena',
  },
  features: {
    kicker: 'Features',
    title: 'Everything you need to master endgames',
    lead: 'This is what I can already deliver today, and it is enough to train and truly improve. But it is only the beginning: I have much more planned for Lucena.',
    items: {
      progression: {
        title: 'From Maia to Stockfish',
        body: 'Play against Maia, a neural network chess engine created by researchers at the University of Toronto and trained on millions of games played by people on Lichess. It gets things right and wrong like a real person, from 1000 to 2600, and every level is an opponent with a personality. Pick the time control, climb step by step and, when you are ready, face Stockfish at full strength.',
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
        body: 'Distributed through Firebase App Distribution, by Google. Everyone in the group always gets the latest version.',
      },
      {
        status: 'In preparation',
        title: 'Google Play',
        body: 'The Google Play account is being set up. The release is coming very soon.',
      },
      {
        status: 'Later',
        title: 'iPhone',
        body: 'As soon as there are resources to publish on the App Store.',
      },
    ],
  },
  support: {
    kicker: 'Support the project',
    title: 'Help Lucena grow',
    body: [
      'Lucena is free and made by one person in their spare time. If it helped you and you want to contribute, any support makes a difference so the app can grow faster.',
      'We will still build a simple way to support right from the app, with a supporters wall: whoever helps gets visibility inside the app. For now, if you want to donate, just send me an email.',
    ],
    cardTitle: 'Supporters wall',
    cardBody: 'Coming soon to the app: everyone who supports the project shows up inside it, for the whole community to see.',
    cta: 'I want to support',
    subject: 'I want to support Lucena',
    note:
      'What about iPhone? Lucena will go to the App Store as soon as I have the resources to publish there. First I want to validate the idea on Android but, if you use iOS, rest assured: I will do my best to get there as soon as possible.',
  },
  tester: {
    kicker: 'Become a tester',
    title: 'Try it before everyone else',
    body: 'Join the testing group and always get the latest version of Lucena on your Android phone.',
    teachers:
      'Are you a chess teacher? Share the app with your students. Endgames are the best way in, and feedback from people who teach is worth gold.',
    safety:
      'Testing versions are distributed through Firebase App Distribution, the Google platform for sending test builds of apps. You get the invite, install the Firebase testing app and download Lucena through it, safely.',
    safetyLink: 'How Firebase App Distribution works',
    wait: 'Rather wait? No problem: Lucena is coming to Google Play soon.',
    cta: 'Join the testing group',
    thanks:
      'Thank you, truly. Someone taking the time to test, validate the idea and send feedback means a lot to me. Every message helps decide the next step for the app.',
  },
  vision: {
    kicker: 'Vision',
    title: 'A living project',
    body: 'The goal is to offer the best experience to learn chess, get better at endgames and challenge yourself in them. Lucena will grow with new features, guided by what the community asks for.',
    cta: 'Send an idea',
  },
  refs: {
    kicker: 'Credits and references',
    title: 'Standing on the shoulders of giants',
    items: [
      { name: 'Stockfish', body: 'Open source chess engine (GPL-3.0), the strongest opponent in the app.' },
      { name: 'Maia', body: 'Open source neural network engine by researchers at the University of Toronto, trained on games played by people on Lichess.' },
      { name: 'Lichess', body: 'The board and rules libraries (chessground and dartchess) and the cburnett pieces, by Colin M.L. Burnett.' },
      { name: 'Firebase App Distribution', body: 'The Google platform that delivers the testing versions.' },
      { name: 'Philidor portrait', body: 'Engraving by Augustin de Saint-Aubin, 1772, public domain (Wikimedia Commons).' },
    ],
  },
  footer: {
    tagline: 'Train chess endgames against Maia and Stockfish.',
    dev: 'I am a programmer. If you need a landing page, an app, or want to learn more about my services, get in touch:',
    contact: 'Contact',
  },
  media: {
    hero: 'Choosing the Maia level and time control, then playing against it in Lucena',
    school: "The first lesson in Viktor's school in Lucena: the rook and the stars",
    journey: 'The Lucena Journey: the current opponent and the challenges',
    queenRook: 'Interactive queen vs rook lesson in Lucena',
    speedrun: 'Lucena speedrun: the stages and the game against the clock',
    theme: 'Choosing the dark theme and the app color in Lucena',
    journeyChallenge: 'A Journey challenge in Lucena: queen mate against Tito, level 1200',
    exercise: 'A queen vs rook exercise in a Lucena endgame lesson',
    queenRookLesson: 'Lucena endgame lesson: queen vs rook, reaching Philidor',
    shortSide: 'Lucena endgame lesson: the short-side defence',
    stars: 'Lucena star challenge with the rook, on hard',
    play: 'Play video',
    pause: 'Pause video',
  },
};

export default en;

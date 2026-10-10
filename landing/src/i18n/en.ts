import type { Dictionary } from './types';

const en: Dictionary = {
  meta: {
    title: 'Lucena: train chess endgames against Maia and Stockfish',
    description:
      'Learn chess through the endgame. Take the level test, study 38 endgame lessons with Master Viktor and play against Maia, which plays like a human at your level, up to full-strength Stockfish. With speedrun, Marathon and blindfold games.',
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
    lead: 'Lucena teaches endgames with Master Viktor, from how the pieces move to the Lucena position, and has you play them against Maia, which plays like a human at your level, and then against full-strength Stockfish.',
    cta: 'Become a tester',
    secondary: 'See how it works',
    note: 'Android, testing version. Coming soon to Google Play.',
    chips: ['Maia 1000–2600', 'Stockfish', '38 endgame lessons'],
  },
  stats: [
    { value: '9', label: 'Maia levels, from 1000 to 2600' },
    { value: '38', label: 'endgame lessons, in 7 modules' },
    { value: '39', label: 'lessons in Viktor\'s School, for beginners' },
    { value: '250', label: 'exercises in the lessons\' final tests' },
    { value: '80', label: 'master games cited in the lessons' },
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
    'Triangulation',
    'Réti manoeuvre',
    'Outside passed pawn',
    'Wrong bishop',
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
        body: 'Play against Maia, a neural network chess engine created by researchers at the University of Toronto and trained on millions of games played by people on Lichess. It gets things right and wrong like a real person, from 1000 to 2600, and every level is an opponent with a personality. Pick the time control, climb step by step and, when you are ready, face Stockfish at full strength. Everything runs on your phone, offline.',
        bullets: [
          'Human levels from 1000 to 2600',
          'Clock with time and increment',
          'Full-strength Stockfish',
          'Free board and custom position',
        ],
      },
      placement: {
        title: 'Level test: find out where to start',
        body: 'Twenty questions, no clock, about 8 minutes: where a piece can go, whether it is mate or stalemate, whether you can still castle, who wins with best play. Not sure? Tap "I don\'t know" instead of guessing. At the end, Viktor shows your rating range, what you already master and what is left to study.',
        bullets: [
          '20 questions, no clock',
          'A map of what you master and what is missing',
          'Endgames for you: the lessons you still need, in the right order',
        ],
      },
      school: {
        title: "Viktor's School: from zero to your first mate",
        body: 'For beginners. Master Viktor teaches how each piece moves by collecting stars on the board, then moves on to captures, check, castling, en passant, draws, notation, the first mates and the traps every beginner falls for, like the scholar\'s mate. Every lesson is short, with a hint at the right moment, and the last one is a final exam that earns you a diploma.',
        bullets: [
          '39 lessons in 8 modules',
          'Pieces, rules, notation and first mates',
          'Final exam and diploma',
        ],
      },
      lessons: {
        title: 'In-depth endgame lessons',
        body: 'Thirty-eight lessons in 7 modules: basic endgames, hard mates, pawn endgames, queen endgames, rook vs pawns, rook endgames and minor pieces. From the Lucena position and the Philidor defence to triangulation and the Réti manoeuvre. Each lesson is split into short chapters, one idea each, and many positions come from real master games, with a link so you can see the whole game.',
        bullets: [
          'A final test of exercises, from 1 to 3 stars, with a passing score',
          'A hint when you get stuck, at the cost of a point',
          'Once you pass, the challenge: play the real endgame against Maia or Stockfish',
          'Sources for every lesson: books, Lichess studies and master games',
        ],
      },
      journey: {
        title: 'Journey: one opponent at a time',
        body: 'The step after the lessons: win the challenges against each character to unlock the next, from Coco at 1000 up to Stockfish. Each one has a personality and comments on the game in a speech bubble. Along the way, special challenges: blindfold, a short speedrun and a short marathon.',
        bullets: [
          '10 opponents, from 1000 to Stockfish',
          'Special challenges, blindfold and against the clock',
          'Stars and achievements to track your progress',
        ],
      },
      speedrun: {
        title: 'Speedrun: race the clock',
        body: 'Win a series of stages as fast as you can: one endgame against every opponent, from the weakest up to Stockfish, all the challenges of one opponent, exercise sets or the full Journey. Only your clock counts, you can pause between stages, and a lost stage is played again with the timer running.',
        bullets: ['Splits per stage', 'Personal record and time history', 'From Ultra Bullet to Classical'],
      },
      marathon: {
        title: 'Marathon: a single clock',
        body: 'From 1000 to Stockfish on a single clock: each stage starts with the time left from the previous one, and one game runs straight into the next. Lose, draw or run out of time: the Marathon is over. You choose the endgame, the difficulty and the time control.',
        bullets: ['Beginner, intermediate and advanced endgames', 'Record: the time left at the end'],
      },
      blind: {
        title: 'Blindfold',
        body: 'Play without seeing the pieces: speak, type or tap your moves. Hear where the pieces are before you start, ask for the opponent\'s move again and choose how much you want to see. Your voice is recognised by the phone itself and is not recorded. It is still experimental.',
        bullets: ['With the board, just the squares or no board', 'Moves by voice, keyboard or tap'],
      },
      voice: {
        title: 'The teacher talks to you',
        body: 'Turn on the voice and Master Viktor and the opponents read their lines aloud. Every character comes with its own voice; you pick the teacher\'s, swap anyone else\'s and adjust speed and tone.',
        bullets: ['Teacher and opponent voices', 'Adjustable speed and tone'],
      },
      stars: {
        title: 'Star challenges',
        body: 'Collect stars with each piece against the clock: a star appears, you take the piece to it and another one lights up. How many can you get before time runs out? Three levels per piece, plus blindfold, where the star is given only by the square name.',
        bullets: ['Three levels per piece', 'Blindfold, by square name', 'A record for each challenge'],
      },
      analysis: {
        title: 'Game analysis',
        body: 'After playing, review move by move with Stockfish and find where the win slipped away or where the defence held. Choose how deep the analysis goes, see the best line with Stockfish in your place and open the game on Lichess or chess.com.',
        bullets: [
          'Evaluation bar',
          'Accuracy and quality of every move',
          'Copy the position (FEN) and the game (PGN)',
        ],
      },
      progress: {
        title: 'Your progress',
        body: 'An endgame rating that moves with every game against Maia or Stockfish, taking into account how much the position helped, with its history over time. Achievements to unlock, your numbers on the home screen and every game saved to review.',
        bullets: ['Endgame rating with history', '50 achievements', 'Games, wins and day streak'],
      },
      custom: {
        title: 'Your way',
        body: 'Light or dark theme, six app colors, pieces and board colors, clock above, below or one on each side. Choose what shows on the home screen and in which order. The app is available in 19 languages.',
        bullets: [],
      },
      realGames: {
        title: 'Real games, told as stories',
        body: 'Many lesson positions come from master games. Before the move, Master Viktor tells you who played, where and when, what was at stake and what to look at on the board. One tap opens the whole game on Lichess, without leaving the app.',
        bullets: ['80 master games cited in the lessons', 'A link to see the whole game on Lichess'],
      },
      exercises: {
        title: "Exercises with Viktor's explanation",
        body: 'In the final test of each lesson, the moves are yours alone: the teacher stays quiet while you play. Solved it? Then Viktor explains the move and the alternatives, with the squares highlighted in the comment.',
        bullets: ['From 1 to 3 stars, by difficulty', 'The explanation comes after you solve it'],
      },
    },
    route: {
      label: 'Every chapter follows the same path',
      steps: [
        { title: 'Think', body: 'Before any explanation, you look at the position and look for the plan on your own.' },
        { title: 'Watch', body: 'Master Viktor explains the idea, with arrows and marked squares, and shows the line move by move.' },
        { title: 'Play', body: 'Now the moves are yours: the chapter only goes on when you get it right.' },
        { title: 'Test it in practice', body: 'You play the position to the end against the engine.' },
      ],
    },
  },
  levels: {
    kicker: 'For every level',
    title: 'Just starting or already strong? There is a challenge for you',
    beginner: {
      title: 'Just starting',
      body: "Take the level test or go straight to Viktor's School: how each piece moves, check, mate and the first endgames, with short lessons, hints at the right moment and opponents that play at your pace.",
    },
    advanced: {
      title: 'Already strong',
      body: 'Head to the endgame lessons and convert theoretical positions against Maia 2600 and Stockfish. If you win queen vs rook against Stockfish, the technique is yours.',
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
    privacy: 'Privacy policy',
  },
  media: {
    hero: 'Choosing the Maia level and time control, then playing against it in Lucena',
    school: "The first lesson in Viktor's school in Lucena: the rook and the stars",
    placement: 'The Lucena level test: one question at a time, with an "I don\'t know" option',
    lesson: 'A chapter of a Lucena endgame lesson, the Lucena position: think, watch and play',
    journey: 'The Lucena Journey: the current opponent and the challenges',
    speedrun: 'Lucena speedrun: the stages and the game against the clock',
    marathon: 'Lucena Marathon: one game after another on a single clock',
    theme: 'Choosing the theme and the app color in Lucena',
    home: 'The Lucena home screen in the dark theme',
    journeyChallenge: 'A Journey challenge in Lucena: queen mate against Tito, level 1200',
    placementResult: 'Level test result: your rating range and a map of what you already master',
    lessonChapters: 'A Lucena endgame lesson split into chapters: Breakthrough, in pawn endgames',
    realGame: 'A chapter with a real game, Andersson vs Åkesson in 1999, and its Lichess link',
    solvedExercise: "A solved exercise in an endgame lesson, with Viktor's comment",
    stars: 'Lucena star challenge with the rook',
    profile: 'Endgame rating in Lucena, with the chart and the game history',
    achievements: 'Lucena achievements: the ones unlocked and the ones left',
    record: 'End of a Marathon in Lucena: the total time and a new personal best',
    gameEnd: "End of a game in Lucena: a win against Tito, the rating and Stockfish's best line",
    play: 'Play video',
    pause: 'Pause video',
  },
  privacy: {
    slug: 'privacy',
    title: 'Privacy policy',
    description: 'How Lucena handles your data: the app works offline, has no account or ads, and does not collect, send or sell personal data.',
    updated: 'Version of October 10, 2026',
    back: 'Back to home',
    sections: [
      {
        title: 'In short',
        body: [
          'Lucena is a free Android app for training chess endgames. It works offline and <strong>does not collect, send or sell personal data</strong>. It has no account, no login, no ads and no tracking tools.',
        ],
      },
      {
        title: 'What stays on your device',
        body: [
          'Your progress (lessons, games, rating, achievements and records) and your preferences (theme, language, voice, board) are stored only in the app’s storage on your phone. None of it goes to a server: Lucena has no server.',
          'To erase everything, clear Lucena’s data in the Android settings or uninstall the app.',
        ],
      },
      {
        title: 'Internet',
        body: [
          'The app asks for internet permission only to open, inside the app, the external pages you tap: Wikipedia articles and games on Lichess. Those pages belong to other sites and follow their own privacy policies (<a href="https://foundation.wikimedia.org/wiki/Policy:Privacy_policy" rel="noopener">Wikipedia</a> and <a href="https://lichess.org/privacy" rel="noopener">Lichess</a>).',
          'The chess engines, the lessons and the voices run on the device itself. When you tap share on a game, the text goes only to the app you choose.',
        ],
      },
      {
        title: 'Microphone',
        body: [
          'In blindfold mode you can speak your moves. Only then does the app ask for microphone access. Lucena does not record or keep the audio. Recognition is done by the Android speech service: on the device whenever possible; if the offline speech pack for your language is not installed, Android may use Google’s online service. Without the permission, you play with the keyboard or by tapping.',
        ],
      },
      {
        title: 'Google Play',
        body: [
          'Lucena is distributed through Google Play. Google handles your account and install data under its <a href="https://policies.google.com/privacy" rel="noopener">own privacy policy</a>. I only receive the anonymous, aggregated statistics Google Play shows every developer, such as the number of installs.',
        ],
      },
      {
        title: 'Children',
        body: [
          'Since the app collects no personal data from anyone, it collects none from children either. It can be used by people of any age.',
        ],
      },
      {
        title: 'Changes to this policy',
        body: [
          'If anything changes, this page is updated and the version date at the top changes with it.',
        ],
      },
      {
        title: 'Contact',
        body: [
          'Questions about privacy? Write to <a href="mailto:gncortes.apps@gmail.com">gncortes.apps@gmail.com</a>.',
        ],
      },
    ],
  },
};

export default en;

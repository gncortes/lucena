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
        body: 'Train your visualization: play with your eyes closed against Maia or Stockfish, saying your moves out loud. Before you start, hear where the pieces are; during the game, ask to repeat the opponent\'s move. In New game, pick Blindfold mode and, at the top of the game, how much you want to see. Still experimental.',
        bullets: ['Against Maia or Stockfish', 'Moves by voice, keyboard or tap', 'With the board, squares only or no board'],
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
    blindShots: ['Choose the mode', 'Board', 'Squares only', 'No board'],
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
    terms: 'Terms of use',
    deletion: 'Delete account',
  },
  media: {
    blindMode: 'New game in Lucena: choosing between normal and blindfold mode',
    blindBoard: 'A blindfold game with the board visible',
    blindSquares: 'A blindfold game with squares only: the grid and coordinates, no pieces',
    blindNone: 'A blindfold game with no board, only the moves',
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
    description: 'How Lucena handles your data: without an account, everything stays on your phone; with the optional account, your progress is stored in Firebase so you can get it back on another device. Nothing is sold.',
    updated: 'Version of October 22, 2026',
    back: 'Back to home',
    sections: [
      {
        title: 'In short',
        body: [
          'Lucena is a free Android app for training chess endgames. It works offline and <strong>without an account</strong>. The account is optional: it saves your progress so you can get it back on another device.',
          '<strong>I do not sell or rent personal data</strong>, and I do not use your data for anything beyond what is written here.',
        ],
      },
      {
        title: 'Who is responsible',
        body: [
          'Lucena is made by Gabriel Novais Cortes, an independent developer in Brazil, who is the data controller under Brazil’s General Data Protection Law (LGPD) and the EU GDPR. Contact: <a href="mailto:gncortes.apps@gmail.com">gncortes.apps@gmail.com</a>.',
        ],
      },
      {
        title: 'Without an account: everything stays on the device',
        body: [
          'Your progress (lessons, games, rating, achievements and records), your profile (nickname, avatar color, goal and level) and your preferences (theme, language, voice, board) are stored in the app’s storage on your phone.',
          'To erase everything, clear Lucena’s data in the Android settings or uninstall the app.',
        ],
      },
      {
        title: 'With an account: what is stored',
        body: [
          'You can sign in with your Google account or with an email address. Sign-in is handled by Google’s Firebase Authentication, which stores your email, the name and photo of your Google account (when you use it) and an account ID.',
          'With an account, the app copies to Google’s Cloud Firestore:',
          '<ul><li>your profile: name, nickname, country (read from the phone’s region, which you can change), state and city (if you enter them), language, goal, level and your Lichess and Chess.com usernames, if you entered them;</li><li>your progress: lessons, rating, achievements, records, completed challenges and positions;</li><li>your games in the app: the moves, the result, the dates and the opponent (always one of the app’s own engines).</li></ul>',
          'If you choose a profile photo (from the camera, the gallery or your Google account), it goes to Google’s Firebase Storage at a reduced size. The app only uses the camera and gallery when you tap to change the photo.', 'This data is stored on Google servers, which may be outside your country. The transfer follows Google Cloud’s contractual safeguards (<a href="https://firebase.google.com/support/privacy" rel="noopener">Firebase privacy</a>). Only you, signed in to your account, can read and change this data.',
        ],
      },
      {
        title: 'Lichess and Chess.com',
        body: [
          'If you connect Lichess, you sign in on the Lichess website itself. The app receives an access token that stays <strong>only in your phone’s secure storage</strong>, never in the Lucena account, and is used to read your rating. Your Lichess username goes to your profile.',
          'If you enter your Chess.com username, the app reads your public rating from the Chess.com API. There is no password or sign-in.',
          'These sites follow their own policies (<a href="https://lichess.org/privacy" rel="noopener">Lichess</a> and <a href="https://www.chess.com/legal/privacy" rel="noopener">Chess.com</a>).',
        ],
      },
      {
        title: 'Notifications',
        body: [
          'If you allow it, the app receives notifications through Firebase Cloud Messaging (the daily endgame, for example). For that, the phone creates a delivery token, and the app subscribes to the topics of the notifications you turned on. You turn each one off in the app, and all of them in the Android settings.',
        ],
      },
      {
        title: 'Usage statistics, crashes and ads',
        body: [
          '<strong>Usage statistics.</strong> The app uses Google Analytics for Firebase to learn which screens and lessons are used, where people give up and where they came from (for example, a challenge link). It records app events (such as opening a lesson or finishing a game), the device model, the Android version, the country and state (never the city), whether you have an account and the campaign or link you came from, with an app instance ID. Your name, your email, what you type and the positions you set up are never sent.',
          '<strong>Crashes.</strong> When the app crashes, Firebase Crashlytics sends the error report, with the device model and the system and app versions, so I can fix it.',
          '<strong>Ads.</strong> The app shows full-screen Google AdMob ads only when you tap to open or continue a lesson, and never in the first lessons or in the middle of an exercise, a game or a challenge. Before the first ad, the app shows Google’s consent screen, where you choose whether ads may be personalized. AdMob uses the device’s advertising ID, which you can reset or delete in the Android settings (<a href="https://policies.google.com/technologies/ads" rel="noopener">how Google uses data in ads</a>). You can change this choice on the app’s Privacy and ads screen.',
          '<strong>Remove ads.</strong> The purchase is made through Google Play, which handles the payment. The app only learns whether the purchase was made, so it stops showing ads.',
          '<strong>Your feedback.</strong> When you answer an in-app survey or send feedback, the answer goes to Cloud Firestore <strong>without identifying you</strong>: no account, email, name or advertising ID. Only the app version, the phone model, your level and how you found the app go with it.',
        ],
      },
      {
        title: 'Internet and external pages',
        body: [
          'The chess engines, the lessons and the voices run on the device itself. The app uses the internet for the account, notifications, statistics, ads, purchases, feedback, Lichess and Chess.com, and to open, inside the app, the external pages you tap, such as Wikipedia articles. Those pages follow their own sites’ policies.',
          'When you share a game or a challenge, the text, image and link go only to the app you choose.',
        ],
      },
      {
        title: 'Microphone',
        body: [
          'In blind mode, you can speak your moves. Only then does the app ask for microphone access. Lucena does not record or store the audio. Recognition is done by the Android speech service: on the device whenever possible; if the offline voice pack for the language is not installed, Android may use Google’s online service. Without the permission, you play with the keyboard or by tapping.',
        ],
      },
      {
        title: 'Why the data is used, and on what basis',
        body: [
          '<ul><li><strong>Account, profile, progress and games:</strong> to store and return your progress, as you asked when creating the account (performance of a contract).</li><li><strong>Notifications and personalized ads:</strong> only with your consent, which you can withdraw at any time.</li><li><strong>Usage statistics, crash reports and feedback:</strong> to fix errors and improve the lessons (legitimate interest).</li></ul>',
        ],
      },
      {
        title: 'How long',
        body: [
          'Account data is kept while the account exists. When you delete the account, it is deleted right away (see below). Usage statistics are kept for up to 14 months, and crash reports for up to 90 days.',
        ],
      },
      {
        id: 'delete-account',
        title: 'How to delete the account',
        body: [
          'In the app, open your <strong>Profile</strong> and tap <strong>Delete the account</strong>. The account and the profile, photo, progress and games stored in it are deleted right away. On this phone, the app keeps working without an account.',
          'Without the app, follow the steps on the <a href="/en/delete-account/">Delete account</a> page.',
        ],
      },
      {
        title: 'Your rights',
        body: [
          'You can ask for confirmation that I process your data, access to it, correction, portability, deletion and information about who it is shared with, and you can withdraw a consent. Write to <a href="mailto:gncortes.apps@gmail.com">gncortes.apps@gmail.com</a>: you will get an answer within 15 days. You may also complain to Brazil’s data protection authority (ANPD) or to the authority in your country.',
        ],
      },
      {
        title: 'Minimum age',
        body: [
          'Lucena is for people aged 13 and over. Users under 18 should use the account with the permission of a parent or guardian. If you learn that a child under 13 has created an account, write to me and I will delete their data.',
        ],
      },
      {
        title: 'Security',
        body: [
          'Data travels encrypted (HTTPS) and is stored with Google Cloud’s protections. The database rules let each person read and change only their own account.',
        ],
      },
      {
        title: 'Changes to this policy',
        body: [
          'If something changes, this page is updated and the version date at the top changes with it.',
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
  terms: {
    slug: 'terms',
    title: 'Terms of use',
    description: 'The rules for using Lucena, the free app for training chess endgames: the account, permitted use, open source and the limits of liability.',
    updated: 'Version of October 22, 2026',
    back: 'Back to home',
    sections: [
      {
        title: 'Acceptance',
        body: [
          'These terms apply between you and Gabriel Novais Cortes, the developer of Lucena. By using the app or creating an account, you agree to them and to the <a href="/en/privacy/">Privacy policy</a>. If you do not agree, do not use the app.',
        ],
      },
      {
        title: 'What Lucena is',
        body: [
          'Lucena is a free app for training chess endgames: lessons, exercises and games against engines that run on the device. It works without an account and without internet. Features may change, improve or be removed in new versions.',
        ],
      },
      {
        title: 'Age',
        body: [
          'The app is for people aged 13 and over. Users under 18 need the permission of a parent or guardian to create an account.',
        ],
      },
      {
        title: 'Your account',
        body: [
          'The account is optional. You are responsible for what is done with it and must keep access to your email or Google account safe. Use a name, nickname and photo that do not offend anyone or impersonate someone else.',
          'You can delete the account whenever you want, in the app’s Profile or on the <a href="/en/delete-account/">Delete account</a> page. I may suspend or delete an account used to cheat the app, attack the service or break these terms.',
        ],
      },
      {
        title: 'Permitted use',
        body: [
          'Use Lucena for your own study and enjoyment. Do not try to access other people’s data, overload or attack the servers, or use the app for illegal purposes.',
        ],
      },
      {
        title: 'Open source',
        body: [
          'Lucena’s code is free software under the <a href="https://www.gnu.org/licenses/agpl-3.0.html" rel="noopener">GNU AGPL 3.0</a> license, which defines what you can do with it. The Lucena name, the logo, the illustrations and the lesson texts are not granted by that license without permission.',
          'The app uses third-party software under their own licenses, among them the Stockfish engine (GPL 3.0) and the Maia models. The full list is in Settings → About Lucena → Open source licenses.',
        ],
      },
      {
        title: 'Third-party services',
        body: [
          'Sign-in, account storage, notifications, statistics and ads are provided by Google (Firebase and AdMob), and purchases by Google Play. Rating data comes from Lichess and Chess.com, if you connect them. These services have their own terms, and I am not responsible for their availability.',
        ],
      },
      {
        title: 'Ads',
        body: [
          'Lucena is free and supported by ads, which only appear when you open or continue a lesson. The “Remove ads” purchase is a one-time purchase through Google Play, tied to your Google account, and removes ads on the devices where you use that account. Refund requests follow Google Play’s rules.',
        ],
      },
      {
        title: 'No warranty',
        body: [
          'Lucena is offered free of charge, “as is”. I work to keep the lessons and analyses correct and the app running well, but I do not guarantee that it is free of errors or always available. The app’s rating is an estimate for your training, not an official rating.',
        ],
      },
      {
        title: 'Limitation of liability',
        body: [
          'To the extent permitted by law, I am not liable for indirect losses from using the app, such as the loss of progress stored only on the device. Nothing here limits the rights that consumer protection law gives you.',
        ],
      },
      {
        title: 'Changes to these terms',
        body: [
          'If these terms change, this page is updated and the version date changes with it. Continuing to use the app after that means you accept the new version.',
        ],
      },
      {
        title: 'Governing law',
        body: [
          'These terms are governed by the laws of Brazil, without prejudice to the mandatory consumer protection rules of the country where you live. Disputes may be brought in the courts of your place of residence.',
        ],
      },
      {
        title: 'Contact',
        body: [
          'Questions about these terms? Write to <a href="mailto:gncortes.apps@gmail.com">gncortes.apps@gmail.com</a>.',
        ],
      },
    ],
  },
  deletion: {
    slug: 'delete-account',
    title: 'Delete account',
    description: 'How to delete your Lucena account and the data stored in it, in the app or by email.',
    updated: 'Version of October 22, 2026',
    back: 'Back to home',
    sections: [
      {
        title: 'In the app',
        body: [
          '<ol><li>Open Lucena and sign in to your account.</li><li>Open your <strong>Profile</strong>.</li><li>Tap <strong>Delete account</strong> and confirm.</li></ol>',
          'You need an internet connection. For security, the app may ask you to sign in again before deleting.',
        ],
      },
      {
        title: 'Without the app',
        body: [
          'Write to <a href="mailto:gncortes.apps@gmail.com?subject=Delete%20my%20Lucena%20account">gncortes.apps@gmail.com</a> from the account’s email address, with the subject “Delete my Lucena account”. The account is deleted within 15 days, and you get a confirmation by email.',
        ],
      },
      {
        title: 'What is deleted',
        body: [
          'The account (email, name and photo) and the profile, profile photo, progress and games stored in it. None of it is kept afterwards: this cannot be undone.',
          'What is on your phone is not deleted: the app keeps working without an account. To erase that data too, clear Lucena’s data in the Android settings or uninstall the app.',
          'Usage statistics, crash reports and survey and feedback answers, which do not include your name or email and are not linked to the account, are deleted automatically within the periods in the <a href="/en/privacy/">Privacy policy</a>.',
        ],
      },
    ],
  },
};

export default en;

import type { Dictionary } from './types';

const es: Dictionary = {
  meta: {
    title: 'Lucena: entrena finales de ajedrez contra Maia y Stockfish',
    description:
      'Aprende ajedrez por los finales. Entrena finales de ajedrez contra Maia, que juega como una persona de tu nivel, hasta Stockfish a máxima fuerza, con clases interactivas de dama contra torre, mate de alfil y caballo y mucho más.',
    ogAlt: 'La app Lucena abierta en un móvil, con un final de ajedrez en el tablero.',
  },
  nav: {
    features: 'Funciones',
    roadmap: 'Hoja de ruta',
    support: 'Apoya',
    tester: 'Sé tester',
    skip: 'Saltar al contenido',
    theme: 'Cambiar entre tema claro y oscuro',
    language: 'Idioma',
    menu: 'Menú',
  },
  hero: {
    eyebrow: 'App gratuita para entrenar finales de ajedrez',
    title: 'Entrena finales de ajedrez hasta que se vuelvan',
    titleAccent: 'técnica',
    lead: 'Lucena te pone a jugar finales contra Maia, que juega como una persona de tu nivel, y luego contra Stockfish a máxima fuerza.',
    cta: 'Quiero ser tester',
    secondary: 'Ver cómo funciona',
    note: 'Android, versión de pruebas. Pronto en Google Play.',
    chips: ['Maia 1000–2600', 'Stockfish', 'Clases interactivas'],
  },
  stats: [
    { value: '9', label: 'niveles de Maia, de 1000 a 2600' },
    { value: '12', label: 'clases de finales clásicos' },
    { value: '25', label: 'clases para quien empieza' },
    { value: '55', label: 'finales para entrenar las veces que quieras' },
  ],
  marquee: [
    'Posición de Lucena',
    'Posición de Philidor',
    'Dama contra torre',
    'Mate de alfil y caballo',
    'Casillas clave',
    'Oposición a distancia',
    'Defensa desde la última fila',
    'Defensa del lado corto',
  ],
  message: {
    kicker: 'Aprender ajedrez por los finales',
    title: 'Empieza por el final del tablero',
    quote:
      'Para mejorar tu juego, debes estudiar los finales antes que cualquier otra cosa.',
    quoteAuthor: 'José Raúl Capablanca, campeón del mundo',
    body: [
      'Con pocas piezas en el tablero, cada una muestra lo que sabe hacer. Es más fácil entender cómo ataca el rey, cómo corta la torre y cómo trabajan juntos el alfil y el caballo.',
      'Ahí se aprende a jugar con precisión: cada jugada cuenta y ves al instante qué funcionó. Esa claridad sirve para toda la partida.',
    ],
    boardCaption:
      'La primera clase de la escuela de Viktor: solo la torre en el tablero. Con pocas piezas, cada una muestra lo que sabe hacer.',
  },
  story: {
    kicker: 'Por qué existe Lucena',
    title: 'Hecho por alguien que ama el ajedrez',
    paragraphs: [
      'Soy programador y me encanta programar. Mi otra pasión es el ajedrez. Lucena nació de una necesidad mía: los finales siempre fueron mi punto débil, y quería una forma de entrenarlos de verdad.',
      'Lo que funcionó fue entrenar de forma progresiva: primero contra Maia, que acierta y se equivoca como una persona de mi nivel, y luego subiendo hasta Stockfish. Repetir la misma posición contra rivales cada vez más fuertes fijó las técnicas.',
      'Pero me gusta tanto el ajedrez que quise ir más allá: crear algo para que cualquier persona pueda aprender y practicar con facilidad y entrar en el mundo de este juego milenario. Quiero difundir Lucena para que mucha gente aprenda a jugar con ella y domine los finales que más cuesta aprender.',
    ],
    philidor: {
      text:
        'Y quiero mostrar lo fascinantes que son los finales. Rara vez son la parte del ajedrez que más llama la atención, pero guardan algunas de las ideas más bonitas del juego. Hace más de 250 años, François-André Danican Philidor ya estudiaba estas posiciones, y la defensa que lleva su nombre se enseña todavía hoy, también aquí en Lucena. No es casualidad que muchos, como el Gran Maestro Rafael Leitão, lo consideren el mayor genio de la historia del ajedrez.',
      caption: 'François-André Danican Philidor (1726–1795), grabado de Augustin de Saint-Aubin, 1772.',
      alt: 'Retrato de perfil de Philidor, grabado del siglo XVIII',
    },
    signature: 'Gabriel, creador de Lucena',
  },
  features: {
    kicker: 'Funciones',
    title: 'Todo para dominar los finales',
    lead: 'Esto es lo que ya puedo ofrecer hoy, y ya sirve para entrenar y mejorar de verdad. Pero es solo el comienzo: tengo mucho más planeado para Lucena.',
    items: {
      progression: {
        title: 'De Maia a Stockfish',
        body: 'Juega contra Maia, un motor de ajedrez con red neuronal creado por investigadores de la Universidad de Toronto y entrenado con millones de partidas de personas en Lichess. Acierta y se equivoca como una persona de verdad, de 1000 a 2600, y cada nivel es un rival con personalidad. Elige el ritmo, sube escalón a escalón y, cuando estés listo, enfréntate a Stockfish a máxima fuerza.',
        bullets: [
          'Niveles humanos de 1000 a 2600',
          'Reloj con tiempo e incremento',
          'Stockfish a máxima fuerza',
        ],
      },
      lessons: {
        title: 'Clases que dividen lo difícil en pasos simples',
        body: 'Los finales complejos se convierten en pasos cortos e interactivos. Aprendes cada idea, la practicas al momento y solo sigues cuando aciertas.',
        bullets: ['Dama contra torre', 'Mate de alfil y caballo', 'Finales de torre y de peones'],
      },
      levels: {
        title: 'Entrenamiento para principiantes e intermedios',
        body: 'Quien empieza aprende las piezas con clases guiadas. Quien ya juega sigue el Recorrido: desafíos por nivel de rating, contra rivales con personalidad.',
        bullets: [
          'Clases guiadas para quien empieza',
          'Recorrido por nivel de rating',
          'Estrellas y logros para seguir tu progreso',
        ],
      },
      speedrun: {
        title: 'Speedrun: contra el reloj',
        body: 'Resuelve una serie de finales lo más rápido que puedas. Bate tu récord y mira cómo la técnica se vuelve automática.',
        bullets: ['Parciales por etapa', 'Récord personal', 'Varios ritmos'],
      },
      analysis: {
        title: 'Análisis de la partida',
        body: 'Después de jugar, revisa jugada a jugada con la evaluación del motor y descubre dónde se escapó la victoria o dónde aguantó la defensa.',
        bullets: ['Barra de evaluación', 'Mejores jugadas del motor', 'Precisión de cada jugador'],
      },
      custom: {
        title: 'A tu manera',
        body: 'Tema claro u oscuro, colores de la app, piezas y tablero, reloj arriba o abajo. La app se adapta a ti.',
        bullets: [],
      },
    },
  },
  levels: {
    kicker: 'Para todos los niveles',
    title: '¿Sabes poco o ya juegas bien? Hay un desafío para ti',
    beginner: {
      title: 'Estás empezando',
      body: 'Aprende cómo se mueve cada pieza y cómo dar mate con clases cortas, pistas en el momento justo y rivales que juegan a tu ritmo.',
    },
    advanced: {
      title: 'Ya juegas bien',
      body: 'Convierte finales teóricos contra Maia 2600 y Stockfish. Si le ganas la dama contra la torre a Stockfish, la técnica es tuya.',
    },
  },
  roadmap: {
    kicker: 'Hoja de ruta',
    title: 'Hacia dónde va Lucena',
    items: [
      {
        status: 'Ahora',
        title: 'Versión de pruebas en Android',
        body: 'Distribuida por Firebase App Distribution, de Google. Quien entra en el grupo recibe siempre la versión más reciente.',
      },
      {
        status: 'En preparación',
        title: 'Google Play',
        body: 'La cuenta de Google Play ya se está creando. La publicación llega muy pronto.',
      },
      {
        status: 'Después',
        title: 'iPhone',
        body: 'En cuanto haya recursos para publicar en la App Store.',
      },
    ],
  },
  support: {
    kicker: 'Apoya el proyecto',
    title: 'Ayuda a Lucena a crecer',
    body: [
      'Lucena es gratuita y la hace una sola persona en su tiempo libre. Si te ayudó y quieres contribuir, cualquier apoyo marca la diferencia para que la app crezca más rápido.',
      'Todavía vamos a crear una forma sencilla de apoyar desde la app, con un mural de apoyadores: quien ayude gana visibilidad dentro de ella. Por ahora, si quieres donar, solo envíame un correo.',
    ],
    cardTitle: 'Mural de apoyadores',
    cardBody: 'Muy pronto en la app: quien apoye el proyecto aparecerá dentro de ella, para que toda la comunidad lo vea.',
    cta: 'Quiero apoyar',
    subject: 'Quiero apoyar Lucena',
    note:
      '¿Y el iPhone? Lucena llegará a la App Store en cuanto tenga los recursos para publicarla allí. Primero quiero validar la idea en Android, pero si usas iOS, tranquilo: haré todo lo posible para llegar cuanto antes.',
  },
  tester: {
    kicker: 'Sé tester',
    title: 'Pruébala antes que nadie',
    body: 'Entra en el grupo de pruebas y recibe siempre la versión más reciente de Lucena en tu Android.',
    teachers:
      '¿Eres profesor de ajedrez? Pasa la app a tus alumnos. Los finales son la mejor puerta de entrada, y la opinión de quien enseña vale oro.',
    safety:
      'Las pruebas se distribuyen por Firebase App Distribution, la plataforma de Google para enviar versiones de prueba de apps. Recibes la invitación, instalas la app de pruebas de Firebase y descargas Lucena desde ella, con seguridad.',
    safetyLink: 'Cómo funciona Firebase App Distribution',
    wait: '¿Prefieres esperar? Sin problema: Lucena llega pronto a Google Play.',
    cta: 'Entrar en el grupo de pruebas',
    thanks:
      'Gracias de verdad. Que alguien dedique tiempo a probar, validar la idea y enviar comentarios es muy importante para mí. Cada mensaje ayuda a decidir el próximo paso de la app.',
  },
  vision: {
    kicker: 'Visión',
    title: 'Un proyecto vivo',
    body: 'El objetivo es ofrecer la mejor experiencia para aprender ajedrez, mejorar en los finales y desafiarte en ellos. Lucena crecerá con nuevas funciones, guiadas por lo que pida la comunidad.',
    cta: 'Enviar una idea',
  },
  refs: {
    kicker: 'Créditos y referencias',
    title: 'A hombros de gigantes',
    items: [
      { name: 'Stockfish', body: 'Motor de ajedrez de código abierto (GPL-3.0), el rival más fuerte de la app.' },
      { name: 'Maia', body: 'Motor de código abierto con red neuronal, de investigadores de la Universidad de Toronto, entrenado con partidas de personas en Lichess.' },
      { name: 'Lichess', body: 'Las bibliotecas de tablero y reglas (chessground y dartchess) y las piezas cburnett, de Colin M.L. Burnett.' },
      { name: 'Firebase App Distribution', body: 'La plataforma de Google que entrega las versiones de prueba.' },
      { name: 'Retrato de Philidor', body: 'Grabado de Augustin de Saint-Aubin, 1772, de dominio público (Wikimedia Commons).' },
    ],
  },
  footer: {
    tagline: 'Entrena finales de ajedrez contra Maia y Stockfish.',
    dev: 'Soy programador. Si necesitas una landing page, una app o quieres conocer mis servicios, escríbeme:',
    contact: 'Contacto',
  },
  media: {
    hero: 'Elección del nivel de Maia y del ritmo, y la partida contra ella en Lucena',
    school: 'Primera clase de la escuela de Viktor en Lucena: la torre y las estrellas',
    journey: 'El Recorrido de Lucena: el rival actual y los desafíos',
    queenRook: 'Clase interactiva de dama contra torre en Lucena',
    speedrun: 'Speedrun de Lucena: las etapas y la partida contra el reloj',
    theme: 'Elección del tema oscuro y del color de la app en Lucena',
    journeyChallenge: 'Desafío del Recorrido en Lucena: mate de dama contra Tito, nivel 1200',
    exercise: 'Ejercicio de dama contra torre en una clase de finales de Lucena',
    queenRookLesson: 'Clase de finales de Lucena: dama contra torre, cómo llegar a Philidor',
    shortSide: 'Clase de finales de Lucena: la defensa del lado corto',
    stars: 'Desafío de las estrellas de Lucena con la torre, en difícil',
    play: 'Reproducir vídeo',
    pause: 'Pausar vídeo',
  },
};

export default es;

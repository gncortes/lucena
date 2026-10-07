import type { Dictionary } from './types';

const es: Dictionary = {
  meta: {
    title: 'Lucena: entrena finales de ajedrez contra Maia y Stockfish',
    description:
      'Aprende ajedrez por los finales. Entrena finales de ajedrez contra una IA que juega como una persona, desde tu nivel hasta Stockfish a máxima fuerza, con clases interactivas de dama contra torre, mate de alfil y caballo y mucho más.',
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
    eyebrow: 'App de ajedrez gratuita y de código abierto',
    title: 'Entrena finales de ajedrez hasta que se vuelvan',
    titleAccent: 'técnica',
    lead: 'Lucena te pone a jugar finales contra una IA que juega como una persona, desde tu nivel hasta Stockfish a máxima fuerza.',
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
      'La posición de Lucena, el final de torre que da nombre a la app, en una clase de Viktor. Ganar desde aquí es una técnica, y la app la enseña paso a paso.',
  },
  story: {
    kicker: 'Por qué existe Lucena',
    title: 'Nació de una dificultad real',
    paragraphs: [
      'Juego y doy clases de ajedrez. Y, para ser sincero, los finales siempre fueron mi punto débil. Sabía la teoría, pero en el tablero la posición se me escapaba.',
      'Lo que cambió fue entrenar de forma progresiva: primero contra Maia, una IA que acierta y se equivoca como una persona de mi nivel, y luego subiendo hasta Stockfish. Repetir la misma posición contra rivales cada vez más fuertes fijó las técnicas como ningún libro lo había hecho.',
      'Lucena es ese entrenamiento, organizado para quien quiera recorrer el mismo camino.',
    ],
    signature: 'Gabriel, creador de Lucena',
  },
  features: {
    kicker: 'Funciones',
    title: 'Todo para dominar los finales',
    items: {
      progression: {
        title: 'De Maia a Stockfish',
        body: 'Juega contra Maia, una IA entrenada con partidas de personas reales, con estilo humano a tu nivel: de 1000 a 2600. Elige el ritmo, sube escalón a escalón y, cuando estés listo, enfréntate a Stockfish a máxima fuerza.',
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
        body: 'Quien entra en el grupo de pruebas recibe siempre la versión más reciente.',
      },
      {
        status: 'En preparación',
        title: 'Google Play',
        body: 'La publicación en la tienda ya se está preparando.',
      },
      {
        status: 'Después',
        title: 'App Store',
        body: 'Llevar Lucena al iPhone es el siguiente paso, y ahí tu apoyo marca la diferencia.',
      },
    ],
  },
  support: {
    kicker: 'Apoya el proyecto',
    title: 'Adónde va el dinero',
    body: [
      'Lucena es gratuita y de código abierto. Para publicar en la App Store, Apple exige el Apple Developer Program, que cuesta US$ 99 al año.',
      'Las donaciones pagan esa cuenta: llevan la app al iPhone y ayudan a validar la idea allí. Cualquier cantidad ayuda.',
    ],
    price: 'US$ 99',
    priceNote: 'al año, para publicar en la App Store',
    cta: 'Hacer una donación',
    placeholder: 'Enlace de donación muy pronto',
  },
  tester: {
    kicker: 'Sé tester',
    title: 'Pruébala antes que nadie',
    body: 'Entra en el grupo de pruebas y recibe siempre la versión más reciente de Lucena en tu Android.',
    teachers:
      '¿Eres profesor de ajedrez? Pasa la app a tus alumnos. Los finales son la mejor puerta de entrada, y la opinión de quien enseña vale oro.',
    cta: 'Entrar en el grupo de pruebas',
    thanks:
      'Gracias de verdad. Que alguien dedique tiempo a probar, validar la idea y enviar comentarios es muy importante para mí. Cada mensaje ayuda a decidir el próximo paso de la app.',
  },
  vision: {
    kicker: 'Visión',
    title: 'Un proyecto vivo',
    body: 'El objetivo es ofrecer la mejor experiencia para aprender ajedrez, mejorar en los finales y desafiarte en ellos. Lucena crecerá con nuevas funciones, guiadas por lo que pida la comunidad.',
    cta: 'Sugerir una función',
  },
  footer: {
    tagline: 'Entrena finales de ajedrez contra Maia y Stockfish.',
    source: 'Código en GitHub',
    license: 'Licencia AGPL-3.0',
    contact: 'Contacto y sugerencias',
    credits:
      'Maia: CSSLab, Universidad de Toronto. Stockfish: proyecto Stockfish (GPL-3.0). Piezas: cburnett, de Colin M.L. Burnett.',
  },
  media: {
    hero: 'Un final contra Maia jugado en Lucena',
    home: 'Pantalla de inicio de Lucena con los caminos de entrenamiento',
    beginner: 'Una clase guiada para principiantes en Lucena',
    intermediate: 'El Recorrido de desafíos por nivel de rating en Lucena',
    lucena: 'Clase interactiva de la posición de Lucena en la app Lucena',
    queenRook: 'Clase interactiva de dama contra torre en Lucena',
    bishopKnight: 'Clase interactiva del mate de alfil y caballo en Lucena',
    maia: 'Elección del nivel de Maia y del ritmo en Lucena',
    stockfish: 'Una partida contra Stockfish en Lucena',
    speedrun: 'Modo speedrun de Lucena con el tiempo de cada etapa',
    analysis: 'Análisis de una partida jugada a jugada en Lucena',
    custom: 'Personalización de tema, piezas y tablero en Lucena',
    play: 'Reproducir vídeo',
    pause: 'Pausar vídeo',
  },
};

export default es;

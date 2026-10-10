import type { Dictionary } from './types';

const es: Dictionary = {
  meta: {
    title: 'Lucena: entrena finales de ajedrez contra Maia y Stockfish',
    description:
      'Aprende ajedrez por los finales. Haz la prueba de nivel, estudia 38 clases de finales con el Maestro Viktor y juega contra Maia, que juega como una persona de tu nivel, hasta Stockfish a máxima fuerza. Con speedrun, Maratón y partidas a ciegas.',
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
    lead: 'Lucena enseña finales con el Maestro Viktor, desde cómo se mueven las piezas hasta la posición de Lucena, y te pone a jugarlos contra Maia, que juega como una persona de tu nivel, y luego contra Stockfish a máxima fuerza.',
    cta: 'Quiero ser tester',
    secondary: 'Ver cómo funciona',
    note: 'Android, versión de pruebas. Pronto en Google Play.',
    chips: ['Maia 1000–2600', 'Stockfish', '38 clases de finales'],
  },
  stats: [
    { value: '9', label: 'niveles de Maia, de 1000 a 2600' },
    { value: '38', label: 'clases de finales, en 7 módulos' },
    { value: '39', label: 'clases en la Escuela de Viktor, para quien empieza' },
    { value: '250', label: 'ejercicios en las pruebas finales de las clases' },
    { value: '80', label: 'partidas de maestros citadas en las clases' },
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
    'Triangulación',
    'Maniobra de Réti',
    'Peón pasado alejado',
    'Alfil del color equivocado',
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
        body: 'Juega contra Maia, un motor de ajedrez con red neuronal creado por investigadores de la Universidad de Toronto y entrenado con millones de partidas de personas en Lichess. Acierta y se equivoca como una persona de verdad, de 1000 a 2600, y cada nivel es un rival con personalidad. Elige el ritmo, sube escalón a escalón y, cuando estés listo, enfréntate a Stockfish a máxima fuerza. Todo funciona en el móvil, sin internet.',
        bullets: [
          'Niveles humanos de 1000 a 2600',
          'Reloj con tiempo e incremento',
          'Stockfish a máxima fuerza',
          'Tablero libre y posición personalizada',
        ],
      },
      placement: {
        title: 'Prueba de nivel: descubre por dónde empezar',
        body: 'Son 20 preguntas, sin reloj, en unos 8 minutos: adónde puede ir la pieza, si es mate o ahogado, si todavía se puede enrocar, quién gana con el mejor juego. ¿No lo sabes? Toca "No sé" en lugar de adivinar. Al final, Viktor te muestra tu franja de rating, lo que ya dominas y lo que te falta estudiar.',
        bullets: [
          '20 preguntas, sin reloj',
          'El mapa de lo que dominas y de lo que falta',
          'Finales para ti: las clases que faltan, en el orden correcto',
        ],
      },
      school: {
        title: 'Escuela de Viktor: de cero al primer mate',
        body: 'Para quien empieza. El Maestro Viktor enseña cómo se mueve cada pieza recogiendo estrellas en el tablero y sigue con capturas, jaque, enroque, captura al paso, tablas, notación, los primeros mates y las trampas en las que cae todo principiante, como el mate del pastor. Cada clase es corta, con pistas en el momento justo, y la última es un examen final que vale un diploma.',
        bullets: [
          '39 clases en 8 módulos',
          'Piezas, reglas, notación y primeros mates',
          'Examen final y diploma',
        ],
      },
      lessons: {
        title: 'Clases de finales en profundidad',
        body: 'Son 38 clases en 7 módulos: finales básicos, mates difíciles, finales de peones, finales de dama, torre contra peones, finales de torre y piezas menores. De la posición de Lucena y la defensa de Philidor a la triangulación y la maniobra de Réti. Cada clase se divide en capítulos cortos, con una sola idea cada uno, y muchas posiciones vienen de partidas reales de maestros, con enlace para ver la partida completa.',
        bullets: [
          'Prueba final de ejercicios, de 1 a 3 estrellas, con nota mínima para aprobar',
          'Una pista cuando te atascas, a cambio de un punto',
          'Aprobado, el desafío: jugar el final de verdad contra Maia o Stockfish',
          'Fuentes de cada clase: libros, estudios de Lichess y partidas de maestros',
        ],
      },
      journey: {
        title: 'Recorrido: un rival a la vez',
        body: 'El paso siguiente a las clases: gana los desafíos de cada personaje para desbloquear el siguiente, desde Coco, en 1000, hasta Stockfish. Cada uno tiene personalidad y comenta la partida en un globo de diálogo. Por el camino, desafíos especiales: a ciegas, un speedrun corto y un maratón corto.',
        bullets: [
          '10 rivales, de 1000 a Stockfish',
          'Desafíos especiales a ciegas y contra el reloj',
          'Estrellas y logros para seguir tu progreso',
        ],
      },
      speedrun: {
        title: 'Speedrun: contra el reloj',
        body: 'Gana una serie de etapas lo más rápido que puedas: un final contra todos los rivales, del más débil hasta Stockfish, todos los desafíos de un rival, series de ejercicios o el Recorrido completo. Solo cuenta tu reloj, puedes pausar entre etapas, y la etapa perdida se juega de nuevo con el cronómetro corriendo.',
        bullets: ['Parciales por etapa', 'Récord personal e historial de tiempos', 'Del Ultra Bullet a las Clásicas'],
      },
      marathon: {
        title: 'Maratón: un solo reloj',
        body: 'De 1000 a Stockfish con un solo reloj: cada etapa empieza con el tiempo que sobró de la anterior, y una partida enlaza con la siguiente. Si pierdes, empatas o se acaba el tiempo, se acaba el Maratón. Tú eliges el final, la dificultad y el ritmo.',
        bullets: ['Finales de principiante, intermedio y avanzado', 'Récord: el tiempo que sobra al final'],
      },
      blind: {
        title: 'A ciegas',
        body: 'Juega sin ver las piezas: di, escribe o toca tus jugadas. Escucha dónde están las piezas antes de empezar, pide que repita la jugada del rival y elige cuánto quieres ver. Tu voz la reconoce el propio móvil y no se graba. Todavía es experimental.',
        bullets: ['Con tablero, solo con las casillas o sin tablero', 'Jugadas por voz, teclado o toque'],
      },
      voice: {
        title: 'El profesor te habla',
        body: 'Activa la voz y el Maestro Viktor y los rivales leen sus frases en voz alta. Cada personaje ya trae su voz; tú eliges la del profesor, cambias la de quien quieras y ajustas la velocidad y el tono.',
        bullets: ['Voz del profesor y de los rivales', 'Velocidad y tono ajustables'],
      },
      stars: {
        title: 'Desafíos de estrellas',
        body: 'Recoge estrellas con cada pieza contra el reloj: aparece una estrella, llevas la pieza hasta ella y se enciende otra. ¿Cuántas consigues antes de que se acabe el tiempo? Tres niveles por pieza y además el modo a ciegas, en el que la estrella llega solo por el nombre de la casilla.',
        bullets: ['Tres niveles por pieza', 'A ciegas, por el nombre de la casilla', 'Récord en cada desafío'],
      },
      analysis: {
        title: 'Análisis de la partida',
        body: 'Después de jugar, revisa jugada a jugada con Stockfish y descubre dónde se escapó la victoria o dónde aguantó la defensa. Elige la profundidad del análisis, mira la mejor línea con Stockfish en tu lugar y abre la partida en Lichess o en chess.com.',
        bullets: [
          'Barra de evaluación',
          'Precisión y calidad de cada jugada',
          'Copiar la posición (FEN) y la partida (PGN)',
        ],
      },
      progress: {
        title: 'Tu progreso',
        body: 'Un Elo de finales que cambia con cada partida contra Maia o Stockfish, teniendo en cuenta cuánto ayudaba la posición, con su historial a lo largo del tiempo. Logros por desbloquear, tus números en la pantalla de inicio y cada partida guardada para revisarla.',
        bullets: ['Elo de finales con historial', '50 logros', 'Partidas, victorias y días seguidos'],
      },
      custom: {
        title: 'A tu manera',
        body: 'Tema claro u oscuro, seis colores para la app, piezas y colores del tablero, reloj arriba, abajo o uno a cada lado. Elige qué aparece en la pantalla de inicio y en qué orden. La app está en 19 idiomas.',
        bullets: [],
      },
    },
    route: {
      label: 'Cada capítulo sigue el mismo recorrido',
      steps: [
        { title: 'Piensa', body: 'Antes de cualquier explicación, miras la posición y buscas el plan por tu cuenta.' },
        { title: 'Mira', body: 'El Maestro Viktor comenta la idea, con flechas y casillas marcadas, y muestra la línea jugada a jugada.' },
        { title: 'Juega', body: 'Ahora las jugadas son tuyas: el capítulo solo sigue cuando aciertas.' },
        { title: 'Ponlo a prueba', body: 'Juegas la posición hasta el final contra el motor.' },
      ],
    },
  },
  levels: {
    kicker: 'Para todos los niveles',
    title: '¿Sabes poco o ya juegas bien? Hay un desafío para ti',
    beginner: {
      title: 'Estás empezando',
      body: 'Haz la prueba de nivel o ve directo a la Escuela de Viktor: cómo se mueve cada pieza, jaque, mate y los primeros finales, con clases cortas, pistas en el momento justo y rivales que juegan a tu ritmo.',
    },
    advanced: {
      title: 'Ya juegas bien',
      body: 'Ve a las clases de finales y convierte posiciones teóricas contra Maia 2600 y Stockfish. Si le ganas la dama contra la torre a Stockfish, la técnica es tuya.',
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

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
        body: 'Entrena la visualización: juega con los ojos cerrados contra Maia o Stockfish, diciendo las jugadas en voz alta. Antes de empezar, escucha dónde están las piezas; durante la partida, pide que se repita la jugada del rival. En Nueva partida, elige el modo A ciegas y, arriba en la partida, cuánto quieres ver. Todavía es experimental.',
        bullets: ['Contra Maia o Stockfish', 'Jugadas por voz, teclado o toque', 'Con tablero, solo casillas o sin tablero'],
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
      realGames: {
        title: 'Partidas reales, contadas como historia',
        body: 'Muchas posiciones de las clases salen de partidas de maestros. Antes de la jugada, el Maestro Viktor cuenta quién jugó, dónde y cuándo, qué estaba en juego y qué mirar en el tablero. Un toque abre la partida entera en Lichess, sin salir de la app.',
        bullets: ['80 partidas de maestros citadas en las clases', 'Enlace para ver la partida entera en Lichess'],
      },
      exercises: {
        title: 'Ejercicios con la explicación de Viktor',
        body: 'En la prueba final de cada clase, las jugadas son solo tuyas: el profesor no habla mientras juegas. ¿Lo resolviste? Entonces Viktor explica la jugada y las alternativas, con las casillas marcadas en el comentario.',
        bullets: ['De 1 a 3 estrellas, según la dificultad', 'La explicación aparece después de resolver'],
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
    blindShots: ['Elige el modo', 'Tablero', 'Solo casillas', 'Sin tablero'],
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
    privacy: 'Política de privacidad',
    terms: 'Términos de uso',
    deletion: 'Borrar la cuenta',
  },
  media: {
    blindMode: 'Nueva partida en Lucena: la elección entre el modo normal y a ciegas',
    blindBoard: 'Partida a ciegas con el tablero a la vista',
    blindSquares: 'Partida a ciegas solo con casillas: la cuadrícula y las coordenadas, sin piezas',
    blindNone: 'Partida a ciegas sin tablero, solo con las jugadas',
    hero: 'Elección del nivel de Maia y del ritmo, y la partida contra ella en Lucena',
    school: 'Primera clase de la escuela de Viktor en Lucena: la torre y las estrellas',
    placement: 'Prueba de nivel de Lucena: una pregunta a la vez, con la opción "No lo sé"',
    lesson: 'Capítulo de una clase de finales de Lucena, la posición de Lucena: piensa, mira y juega',
    journey: 'El Recorrido de Lucena: el rival actual y los desafíos',
    speedrun: 'Speedrun de Lucena: las etapas y la partida contra el reloj',
    marathon: 'Maratón de Lucena: una partida tras otra con un solo reloj',
    theme: 'Elección del tema y del color de la app en Lucena',
    home: 'Pantalla de inicio de Lucena en el tema oscuro',
    journeyChallenge: 'Desafío del Recorrido en Lucena: mate de dama contra Tito, nivel 1200',
    placementResult: 'Resultado de la prueba de nivel: tu rango de rating y el mapa de lo que ya dominas',
    lessonChapters: 'Clase de finales de Lucena dividida en capítulos: Ruptura, en finales de peones',
    realGame: 'Capítulo con una partida real, Andersson contra Åkesson en 1999, y su enlace en Lichess',
    solvedExercise: 'Ejercicio resuelto en una clase de finales, con el comentario de Viktor',
    stars: 'Desafío de las estrellas de Lucena con la torre',
    profile: 'Rating de finales en Lucena, con el gráfico y el historial de partidas',
    achievements: 'Logros de Lucena: los conseguidos y los que faltan',
    record: 'Fin del Maratón en Lucena: el tiempo total y un nuevo récord personal',
    gameEnd: 'Fin de partida en Lucena: victoria contra Tito, el rating y la mejor línea de Stockfish',
    play: 'Reproducir vídeo',
    pause: 'Pausar vídeo',
  },
  privacy: {
    slug: 'privacidad',
    title: 'Política de privacidad',
    description: 'Cómo trata Lucena tus datos: sin cuenta, todo queda en el móvil; con la cuenta opcional, el progreso se guarda en Firebase para recuperarlo en otro dispositivo. No se vende nada.',
    updated: 'Versión del 22 de octubre de 2026',
    back: 'Volver al inicio',
    sections: [
      {
        title: 'En resumen',
        body: [
          'Lucena es una app gratuita para entrenar finales de ajedrez en Android. Funciona sin internet y <strong>sin cuenta</strong>. La cuenta es opcional: sirve para guardar tu progreso y recuperarlo en otro dispositivo.',
          '<strong>No vendo ni alquilo datos personales</strong>, y no uso tus datos para nada más de lo que está escrito aquí.',
        ],
      },
      {
        title: 'Quién es el responsable',
        body: [
          'Lucena la hace Gabriel Novais Cortes, desarrollador independiente en Brasil, que es el responsable del tratamiento según la Ley General de Protección de Datos de Brasil (LGPD) y el RGPD europeo. Contacto: <a href="mailto:gncortes.apps@gmail.com">gncortes.apps@gmail.com</a>.',
        ],
      },
      {
        title: 'Sin cuenta: todo queda en el dispositivo',
        body: [
          'Tu progreso (lecciones, partidas, rating, logros y récords), tu perfil (apodo, color del avatar, objetivo y nivel) y tus preferencias (tema, idioma, voz, tablero) se guardan en el almacenamiento de la app, en tu móvil.',
          'Para borrarlo todo, borra los datos de Lucena en los ajustes de Android o desinstala la app.',
        ],
      },
      {
        title: 'Con cuenta: qué se guarda',
        body: [
          'Puedes entrar con tu cuenta de Google o con un correo electrónico. El inicio de sesión lo hace Firebase Authentication, de Google, que guarda tu correo, el nombre y la foto de tu cuenta de Google (cuando la usas) y un identificador de la cuenta.',
          'Con la cuenta, la app copia en Cloud Firestore, también de Google:',
          '<ul><li>tu perfil: nombre, apodo, país (leído de la región del móvil, que puedes cambiar), estado y ciudad (si los indicas), idioma, objetivo, nivel y tus usuarios de Lichess y Chess.com, si los indicaste;</li><li>tu progreso: lecciones, rating, logros, récords, desafíos y posiciones cumplidas;</li><li>tus partidas en la app: las jugadas, el resultado, las fechas y el rival (siempre un motor de la propia app).</li></ul>',
          'Si eliges una foto de perfil (de la cámara, de la galería o la de tu cuenta de Google), va a Firebase Storage, también de Google, en tamaño reducido. La app solo usa la cámara y la galería cuando tocas para cambiar la foto.', 'Estos datos se guardan en servidores de Google, que pueden estar fuera de tu país. La transferencia sigue las garantías contractuales de Google Cloud (<a href="https://firebase.google.com/support/privacy" rel="noopener">privacidad de Firebase</a>). Solo tú, con tu cuenta, puedes leer y cambiar estos datos.',
        ],
      },
      {
        title: 'Lichess y Chess.com',
        body: [
          'Si conectas Lichess, inicias sesión en la propia web de Lichess. La app recibe un token de acceso que queda <strong>solo en el almacenamiento seguro de tu móvil</strong>, nunca en la cuenta de Lucena, y se usa para leer tu rating. Tu usuario de Lichess va a tu perfil.',
          'Si indicas tu usuario de Chess.com, la app lee tu rating público en la API de Chess.com. No hay contraseña ni inicio de sesión.',
          'Estos sitios siguen sus propias políticas (<a href="https://lichess.org/privacy" rel="noopener">Lichess</a> y <a href="https://www.chess.com/legal/privacy" rel="noopener">Chess.com</a>).',
        ],
      },
      {
        title: 'Notificaciones',
        body: [
          'Si lo permites, la app recibe avisos por Firebase Cloud Messaging (el final del día, por ejemplo). Para ello, el móvil genera un código de envío, y la app se suscribe a los temas de los avisos que activaste. Desactivas cada aviso en la app, y todos en los ajustes de Android.',
        ],
      },
      {
        title: 'Estadísticas de uso y fallos',
        body: [
          '<strong>Estadísticas de uso.</strong> La app usa Google Analytics for Firebase para saber qué pantallas y lecciones se usan, dónde la gente abandona y de dónde vino (por ejemplo, de un enlace de desafío). Registra eventos de la app (como abrir una lección o terminar una partida), el modelo del dispositivo, la versión de Android, el país y el estado (nunca la ciudad), si tienes cuenta y la campaña o el enlace por el que llegaste, con un identificador de la app. Nunca se envían tu nombre, tu correo, lo que escribes ni las posiciones que montas.',
          '<strong>Fallos.</strong> Cuando la app se cierra por un error, Firebase Crashlytics envía el informe, con el modelo del dispositivo y las versiones del sistema y de la app, para que pueda corregirlo.',
          '<strong>Tu opinión.</strong> Cuando respondes una encuesta de la app o envías un comentario, la respuesta va a Cloud Firestore <strong>sin identificarte</strong>: sin cuenta, correo, nombre ni identificador de publicidad. Solo van la versión de la app, el modelo del móvil, tu nivel y cómo llegaste a la app.',
        ],
      },
      {
        title: 'Internet y páginas externas',
        body: [
          'Los motores de ajedrez, las lecciones y las voces funcionan en el propio dispositivo. La app usa internet para la cuenta, las notificaciones, las estadísticas, tu opinión, Lichess y Chess.com, y para abrir, dentro de ella, las páginas externas que tocas, como artículos de Wikipedia. Esas páginas siguen las políticas de sus sitios.',
          'Cuando compartes una partida o un desafío, el texto, la imagen y el enlace van solo a la app que elijas.',
        ],
      },
      {
        title: 'Micrófono',
        body: [
          'En el modo a ciegas, puedes decir las jugadas en voz alta. Solo entonces la app pide acceso al micrófono. Lucena no graba ni guarda el audio. El reconocimiento lo hace el servicio de voz de Android: siempre que es posible, solo en el dispositivo; si el paquete de voz sin conexión del idioma no está instalado, Android puede usar el servicio en línea de Google. Sin el permiso, juegas con el teclado o tocando.',
        ],
      },
      {
        title: 'Para qué se usan los datos y con qué base',
        body: [
          '<ul><li><strong>Cuenta, perfil, progreso y partidas:</strong> para guardar y devolver tu progreso, como pediste al crear la cuenta (ejecución del contrato).</li><li><strong>Notificaciones:</strong> solo con tu consentimiento, que puedes retirar en cualquier momento.</li><li><strong>Estadísticas de uso, informes de fallos y tu opinión:</strong> para corregir errores y mejorar las lecciones (interés legítimo).</li></ul>',
        ],
      },
      {
        title: 'Durante cuánto tiempo',
        body: [
          'Los datos de la cuenta se guardan mientras la cuenta exista. Al borrar la cuenta, se borran en el acto (ver abajo). Las estadísticas de uso se guardan hasta 14 meses, y los informes de fallos, hasta 90 días.',
        ],
      },
      {
        id: 'borrar-cuenta',
        title: 'Cómo borrar la cuenta',
        body: [
          'En la app, abre el <strong>Perfil</strong> y toca <strong>Borrar la cuenta</strong>. La cuenta, el perfil, la foto, el progreso y las partidas guardados en ella se borran en el acto. En este móvil, la app sigue funcionando sin cuenta.',
          'Sin la app, sigue los pasos de la página <a href="/es/borrar-cuenta/">Borrar la cuenta</a>.',
        ],
      },
      {
        title: 'Tus derechos',
        body: [
          'Puedes pedir la confirmación de que trato tus datos, el acceso a ellos, la rectificación, la portabilidad, la supresión e información sobre con quién se comparten, y retirar un consentimiento. Escribe a <a href="mailto:gncortes.apps@gmail.com">gncortes.apps@gmail.com</a>: la respuesta llega en un máximo de 15 días. También puedes reclamar ante la autoridad de protección de datos de Brasil (ANPD) o la de tu país.',
        ],
      },
      {
        title: 'Edad mínima',
        body: [
          'Lucena es para personas a partir de 13 años. Quien tenga menos de 18 años debe usar la cuenta con la autorización de sus padres o tutores. Si sabes que un niño menor de 13 años creó una cuenta, escríbeme y borraré sus datos.',
        ],
      },
      {
        title: 'Seguridad',
        body: [
          'Los datos viajan cifrados (HTTPS) y se guardan con las protecciones de Google Cloud. Las reglas de la base de datos permiten a cada persona leer y cambiar solo su propia cuenta.',
        ],
      },
      {
        title: 'Cambios en esta política',
        body: [
          'Si algo cambia, esta página se actualiza y la fecha de la versión, arriba, cambia con ella.',
        ],
      },
      {
        title: 'Contacto',
        body: [
          '¿Dudas sobre privacidad? Escribe a <a href="mailto:gncortes.apps@gmail.com">gncortes.apps@gmail.com</a>.',
        ],
      },
    ],
  },
  terms: {
    slug: 'terminos',
    title: 'Términos de uso',
    description: 'Las reglas para usar Lucena, la app gratuita para entrenar finales de ajedrez: la cuenta, el uso permitido, el código abierto y los límites de responsabilidad.',
    updated: 'Versión del 22 de octubre de 2026',
    back: 'Volver al inicio',
    sections: [
      {
        title: 'Aceptación',
        body: [
          'Estos términos rigen entre tú y Gabriel Novais Cortes, el desarrollador de Lucena. Al usar la app o crear una cuenta, aceptas estos términos y la <a href="/es/privacidad/">Política de privacidad</a>. Si no estás de acuerdo, no uses la app.',
        ],
      },
      {
        title: 'Qué es Lucena',
        body: [
          'Lucena es una app gratuita para entrenar finales de ajedrez: lecciones, ejercicios y partidas contra motores que funcionan en el dispositivo. Funciona sin cuenta y sin internet. Las funciones pueden cambiar, mejorar o desaparecer en nuevas versiones.',
        ],
      },
      {
        title: 'Edad',
        body: [
          'La app es para personas a partir de 13 años. Quien tenga menos de 18 años necesita la autorización de sus padres o tutores para crear una cuenta.',
        ],
      },
      {
        title: 'Tu cuenta',
        body: [
          'La cuenta es opcional. Respondes por lo que se hace con ella y debes mantener seguro el acceso a tu correo o a tu cuenta de Google. Usa un nombre, un apodo y una foto que no ofendan a nadie ni suplanten a otra persona.',
          'Puedes borrar la cuenta cuando quieras, en el Perfil de la app o en la página <a href="/es/borrar-cuenta/">Borrar la cuenta</a>. Puedo suspender o borrar una cuenta usada para hacer trampas en la app, atacar el servicio o incumplir estos términos.',
        ],
      },
      {
        title: 'Uso permitido',
        body: [
          'Usa Lucena para tu estudio y tu ocio. No intentes acceder a datos de otras personas, sobrecargar o atacar los servidores, ni usar la app con fines ilegales.',
        ],
      },
      {
        title: 'Código abierto',
        body: [
          'El código de Lucena es libre, bajo la licencia <a href="https://www.gnu.org/licenses/agpl-3.0.html" rel="noopener">GNU AGPL 3.0</a>, que define lo que puedes hacer con él. El nombre Lucena, el logotipo, las ilustraciones y el texto de las lecciones no se ceden por esa licencia sin autorización.',
          'La app usa programas de terceros con sus propias licencias, entre ellos el motor Stockfish (GPL 3.0) y los modelos Maia. La lista completa está en Ajustes → Acerca de Lucena → Licencias de código abierto.',
        ],
      },
      {
        title: 'Servicios de terceros',
        body: [
          'El inicio de sesión, el almacenamiento de la cuenta, las notificaciones y las estadísticas los presta Google (Firebase). Los datos de rating vienen de Lichess y Chess.com, si los conectas. Estos servicios tienen sus propios términos, y no respondo por su disponibilidad.',
        ],
      },
      {
        title: 'Sin garantía',
        body: [
          'Lucena se ofrece gratis, “tal cual”. Me esfuerzo para que las lecciones y los análisis sean correctos y la app funcione bien, pero no garantizo que esté libre de errores ni siempre disponible. El rating de la app es una estimación para tu entrenamiento, no una medida oficial.',
        ],
      },
      {
        title: 'Limitación de responsabilidad',
        body: [
          'En la medida en que la ley lo permita, no respondo por pérdidas indirectas del uso de la app, como la pérdida del progreso guardado solo en el dispositivo. Nada de esto limita los derechos que te da la ley de protección del consumidor.',
        ],
      },
      {
        title: 'Cambios en estos términos',
        body: [
          'Si estos términos cambian, esta página se actualiza y la fecha de la versión cambia con ella. Seguir usando la app después de eso significa aceptar la nueva versión.',
        ],
      },
      {
        title: 'Ley aplicable',
        body: [
          'Estos términos se rigen por las leyes de Brasil, sin perjuicio de las normas obligatorias de protección del consumidor del país donde vives. Los conflictos pueden llevarse a los tribunales de tu domicilio.',
        ],
      },
      {
        title: 'Contacto',
        body: [
          '¿Dudas sobre estos términos? Escribe a <a href="mailto:gncortes.apps@gmail.com">gncortes.apps@gmail.com</a>.',
        ],
      },
    ],
  },
  deletion: {
    slug: 'borrar-cuenta',
    title: 'Borrar la cuenta',
    description: 'Cómo borrar tu cuenta de Lucena y los datos guardados en ella, desde la app o por correo.',
    updated: 'Versión del 22 de octubre de 2026',
    back: 'Volver al inicio',
    sections: [
      {
        title: 'Desde la app',
        body: [
          '<ol><li>Abre Lucena y entra en tu cuenta.</li><li>Abre el <strong>Perfil</strong>.</li><li>Toca <strong>Borrar la cuenta</strong> y confirma.</li></ol>',
          'Necesitas conexión a internet. Por seguridad, la app puede pedirte que vuelvas a entrar en la cuenta antes de borrarla.',
        ],
      },
      {
        title: 'Sin la app',
        body: [
          'Escribe a <a href="mailto:gncortes.apps@gmail.com?subject=Borrar%20mi%20cuenta%20de%20Lucena">gncortes.apps@gmail.com</a> desde el correo de la cuenta, con el asunto “Borrar mi cuenta de Lucena”. La cuenta se borra en un máximo de 15 días, y recibes la confirmación por correo.',
        ],
      },
      {
        title: 'Qué se borra',
        body: [
          'La cuenta (correo, nombre y foto) y el perfil, la foto de perfil, el progreso y las partidas guardados en ella. Nada queda guardado después: no se puede deshacer.',
          'Lo que está en tu móvil no se borra: la app sigue funcionando sin cuenta. Para borrar también esos datos, borra los datos de Lucena en los ajustes de Android o desinstala la app.',
          'Las estadísticas de uso, los informes de fallos y las respuestas de encuestas y comentarios, que no incluyen tu nombre ni tu correo y no quedan ligados a la cuenta, se borran solos en los plazos de la <a href="/es/privacidad/">Política de privacidad</a>.',
        ],
      },
    ],
  },
};

export default es;

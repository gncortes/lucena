import type { Dictionary } from './types';

const pt: Dictionary = {
  meta: {
    title: 'Lucena: treine finais de xadrez contra o Maia e o Stockfish',
    description:
      'Aprenda xadrez pelos finais. Faça o teste de nível, estude 38 aulas de finais com o Mestre Viktor e jogue contra o Maia, que joga como gente do seu nível, até o Stockfish na força máxima. Com speedrun, Maratona e partidas às cegas.',
    ogAlt:
      'O app Lucena aberto num celular, com um final de xadrez no tabuleiro.',
  },
  nav: {
    features: 'Recursos',
    roadmap: 'Roadmap',
    support: 'Apoie',
    tester: 'Seja testador',
    skip: 'Pular para o conteúdo',
    theme: 'Alternar tema claro e escuro',
    language: 'Idioma',
    menu: 'Menu',
  },
  hero: {
    eyebrow: 'App gratuito para treinar finais de xadrez',
    title: 'Treine finais de xadrez até virar',
    titleAccent: 'técnica',
    lead: 'O Lucena ensina finais com o Mestre Viktor, do movimento das peças à posição de Lucena, e coloca você para jogá-los contra o Maia, que joga como gente do seu nível, e depois contra o Stockfish na força máxima.',
    cta: 'Quero ser testador',
    secondary: 'Ver como funciona',
    note: 'Android, versão de testes. Em breve no Google Play.',
    chips: ['Maia 1000–2600', 'Stockfish', '38 aulas de finais'],
  },
  stats: [
    { value: '9', label: 'níveis do Maia, de 1000 a 2600' },
    { value: '38', label: 'aulas de finais, em 7 módulos' },
    { value: '39', label: 'aulas na Escola do Viktor, para quem está começando' },
    { value: '250', label: 'exercícios nos testes finais das aulas' },
    { value: '80', label: 'partidas de mestres citadas nas aulas' },
    { value: '55', label: 'finais para treinar quantas vezes quiser' },
  ],
  marquee: [
    'Posição de Lucena',
    'Posição de Philidor',
    'Dama contra torre',
    'Mate de bispo e cavalo',
    'Casas-chave',
    'Oposição à distância',
    'Defesa pela última fileira',
    'Defesa pelo lado curto',
    'Triangulação',
    'Manobra de Réti',
    'Peão passado afastado',
    'Bispo errado',
  ],
  message: {
    kicker: 'Aprender xadrez pelos finais',
    title: 'Comece pelo fim do tabuleiro',
    quote:
      'Para melhorar o seu jogo, você deve estudar os finais antes de tudo.',
    quoteAuthor: 'José Raúl Capablanca, campeão mundial',
    body: [
      'Com poucas peças no tabuleiro, cada uma mostra o que sabe fazer. Fica mais fácil entender como o rei ataca, como a torre corta, como o bispo e o cavalo trabalham juntos.',
      'É aí que se aprende a jogar com precisão: cada lance conta, e você vê na hora o que funcionou. Essa clareza vale para a partida inteira.',
    ],
    boardCaption:
      'A primeira aula da escola do Viktor: só a torre no tabuleiro. Com poucas peças, cada uma mostra o que sabe fazer.',
  },
  story: {
    kicker: 'Por que o Lucena existe',
    title: 'Feito por quem ama xadrez',
    paragraphs: [
      'Sou programador e amo programar. Minha outra paixão é o xadrez. O Lucena nasceu de uma necessidade minha: os finais sempre foram o meu ponto fraco, e eu queria um jeito de treiná-los de verdade.',
      'O que funcionou foi treinar de forma progressiva: primeiro contra o Maia, que erra e acerta como gente do meu nível, depois subindo até o Stockfish. Repetir a mesma posição contra adversários cada vez mais fortes fixou as técnicas.',
      'Mas eu gosto tanto de xadrez que quis ir além: criar algo para que qualquer pessoa consiga aprender e praticar com facilidade e entrar no mundo desse jogo milenar. Quero espalhar o Lucena para que muita gente aprenda a jogar por ele e domine os finais que mais custam a entrar na cabeça.',
    ],
    philidor: {
      text:
        'E quero mostrar como os finais são fascinantes. Eles não costumam ser a parte do xadrez que mais chama atenção, mas guardam algumas das ideias mais bonitas do jogo. Há mais de 250 anos, François-André Danican Philidor já estudava essas posições, e a defesa que leva o nome dele é ensinada até hoje, inclusive aqui no Lucena. Não à toa, muitos, como o Grande Mestre Rafael Leitão, o consideram o maior gênio da história do xadrez.',
      caption: 'François-André Danican Philidor (1726–1795), gravura de Augustin de Saint-Aubin, 1772.',
      alt: 'Retrato de perfil de Philidor, gravura do século XVIII',
    },
    signature: 'Gabriel, criador do Lucena',
  },
  features: {
    kicker: 'Recursos',
    title: 'Tudo para dominar os finais',
    lead: 'Isto é o que eu já consigo entregar hoje, e já dá para treinar e evoluir de verdade. Mas é só o começo: tenho muito mais planejado para o Lucena.',
    items: {
      progression: {
        title: 'Do Maia ao Stockfish',
        body: 'Jogue contra o Maia, um motor de xadrez com rede neural criado por pesquisadores da Universidade de Toronto e treinado em milhões de partidas de pessoas no Lichess. Ele erra e acerta como gente de verdade, do 1000 ao 2600, e cada nível é um adversário com personalidade. Escolha o ritmo, suba degrau por degrau e, quando estiver pronto, enfrente o Stockfish na força máxima. Tudo roda no celular, sem internet.',
        bullets: [
          'Níveis humanos de 1000 a 2600',
          'Relógio com tempo e incremento',
          'Stockfish na força máxima',
          'Tabuleiro livre e posição personalizada',
        ],
      },
      placement: {
        title: 'Teste de nível: descubra por onde começar',
        body: 'São 20 perguntas, sem relógio, em uns 8 minutos: para onde a peça pode ir, se é mate ou afogamento, se ainda dá para rocar, quem ganha com o melhor jogo. Não sabe? Toque em "Não sei" em vez de chutar. No fim, o Viktor mostra a sua faixa de rating, o que você já domina e o que falta estudar.',
        bullets: [
          '20 perguntas, sem relógio',
          'O mapa do que você já domina e do que falta',
          'Finais para você: as aulas que faltam, na ordem certa',
        ],
      },
      school: {
        title: 'Escola do Viktor: do zero ao primeiro mate',
        body: 'Para quem está começando. O Mestre Viktor ensina como cada peça se move pegando estrelas no tabuleiro e segue com captura, xeque, roque, en passant, empates, notação, os primeiros mates e as armadilhas em que todo iniciante cai, como o mate do pastor. Cada aula é curta, com dica na hora certa, e a última é uma prova final que vale diploma.',
        bullets: [
          '39 aulas em 8 módulos',
          'Peças, regras, notação e primeiros mates',
          'Prova final e diploma',
        ],
      },
      lessons: {
        title: 'Aulas de finais aprofundadas',
        body: 'São 38 aulas em 7 módulos: finais básicos, mates difíceis, finais de peões, finais de dama, torre contra peões, finais de torre e peças menores. Da posição de Lucena e da defesa de Philidor à triangulação e à manobra de Réti. Cada aula é dividida em capítulos curtos, com uma ideia só em cada um, e muitas posições vêm de partidas reais de mestres, com link para você ver a partida inteira.',
        bullets: [
          'Teste final de exercícios, de 1 a 3 estrelas, com nota mínima para passar',
          'Dica quando travar, ao custo de um ponto',
          'Aprovado, o desafio: jogar o final de verdade contra o Maia ou o Stockfish',
          'Fontes de cada aula: livros, estudos do Lichess e partidas de mestres',
        ],
      },
      journey: {
        title: 'Jornada: um adversário de cada vez',
        body: 'O passo seguinte às aulas: vença os desafios de cada personagem para liberar o próximo, do Coco, no 1000, até o Stockfish. Cada um tem personalidade e comenta a partida num balão de fala. No caminho, desafios especiais: às cegas, um speedrun curto e uma maratona curta.',
        bullets: [
          '10 adversários, do 1000 ao Stockfish',
          'Desafios especiais às cegas e contra o relógio',
          'Estrelas e conquistas para acompanhar o progresso',
        ],
      },
      speedrun: {
        title: 'Speedrun: contra o relógio',
        body: 'Vença uma série de etapas o mais rápido que puder: um final contra todos os adversários, do mais fraco até o Stockfish, todos os desafios de um adversário, séries de exercícios ou a Jornada completa. Só o seu relógio conta, dá para pausar entre as etapas, e etapa perdida é jogada de novo com o cronômetro correndo.',
        bullets: ['Parciais por etapa', 'Recorde pessoal e histórico de tempos', 'Do Ultra Bullet ao Clássico'],
      },
      marathon: {
        title: 'Maratona: um relógio só',
        body: 'Do 1000 ao Stockfish com um relógio só: cada etapa começa com o tempo que sobrou da anterior, e uma partida emenda na outra. Perdeu, empatou ou o tempo acabou: fim da Maratona. Você escolhe o final, a dificuldade e o ritmo.',
        bullets: ['Finais de iniciante, intermediário e avançado', 'Recorde: o tempo que sobrou no fim'],
      },
      blind: {
        title: 'Às cegas',
        body: 'Treine a visualização: jogue de olhos fechados contra o Maia ou o Stockfish, falando os lances em voz alta. Antes de começar, ouça onde estão as peças; durante a partida, peça para repetir o lance do adversário. Na Nova partida, escolha o modo Às cegas e, no topo da partida, quanto quer ver. Ainda é experimental.',
        bullets: ['Contra o Maia ou o Stockfish', 'Lances por voz, teclado ou toque', 'Com tabuleiro, só com as casas ou sem tabuleiro'],
      },
      voice: {
        title: 'O professor fala com você',
        body: 'Ligue a voz e o Mestre Viktor e os adversários leem as falas em voz alta. Cada personagem já vem com a sua voz; você escolhe a do professor, troca a de quem quiser e ajusta a velocidade e o tom.',
        bullets: ['Voz do professor e dos adversários', 'Velocidade e tom ajustáveis'],
      },
      stars: {
        title: 'Desafios das estrelas',
        body: 'Pegue as estrelas com cada peça contra o relógio: uma estrela aparece, você leva a peça até ela e outra acende. Quantas você pega antes de o tempo acabar? Três níveis por peça e mais o às cegas, em que a estrela vem só pelo nome da casa.',
        bullets: ['Três níveis por peça', 'Às cegas, pelo nome da casa', 'Recorde em cada desafio'],
      },
      analysis: {
        title: 'Análise da partida',
        body: 'Depois de jogar, reveja lance a lance com o Stockfish e descubra onde a vitória escapou ou onde a defesa segurou. Escolha a profundidade da análise, veja a melhor linha com o Stockfish no seu lugar e abra a partida no Lichess ou no chess.com.',
        bullets: [
          'Barra de avaliação',
          'Precisão e qualidade de cada lance',
          'Copiar a posição (FEN) e a partida (PGN)',
        ],
      },
      progress: {
        title: 'Seu progresso',
        body: 'Um rating de finais que muda a cada partida contra o Maia ou o Stockfish, levando em conta o quanto a posição ajudava, com o histórico ao longo do tempo. Conquistas para desbloquear, os seus números na tela inicial e cada partida guardada para rever.',
        bullets: ['Rating de finais com histórico', '50 conquistas', 'Partidas, vitórias e dias seguidos'],
      },
      custom: {
        title: 'Do seu jeito',
        body: 'Tema claro ou escuro, seis cores para o app, peças e cores do tabuleiro, relógio acima, abaixo ou um de cada lado. Escolha o que aparece na tela inicial e em que ordem. O app está em 19 idiomas.',
        bullets: [],
      },
      realGames: {
        title: 'Partidas reais, contadas como história',
        body: 'Muitas posições das aulas saíram de partidas de mestres. Antes do lance, o Mestre Viktor conta quem jogou, onde e quando, o que estava em jogo e o que olhar no tabuleiro. Um toque abre a partida inteira no Lichess, sem sair do app.',
        bullets: ['80 partidas de mestres citadas nas aulas', 'Link para ver a partida inteira no Lichess'],
      },
      exercises: {
        title: 'Exercícios com a explicação do Viktor',
        body: 'No teste final de cada aula, os lances são só seus: o professor não fala enquanto você joga. Resolveu? Aí o Viktor explica o lance e as alternativas, com as casas marcadas no comentário.',
        bullets: ['De 1 a 3 estrelas, conforme a dificuldade', 'A explicação aparece depois de resolver'],
      },
    },
    route: {
      label: 'Cada capítulo segue o mesmo roteiro',
      steps: [
        { title: 'Pense', body: 'Antes de qualquer explicação, você olha a posição e procura o plano sozinho.' },
        { title: 'Veja', body: 'O Mestre Viktor comenta a ideia, com setas e casas marcadas, e mostra a linha lance a lance.' },
        { title: 'Jogue', body: 'Agora os lances são seus: o capítulo só segue quando você acerta.' },
        { title: 'Teste na prática', body: 'Você joga a posição até o fim contra o motor.' },
      ],
    },
    blindShots: ['Escolha o modo', 'Tabuleiro', 'Só as casas', 'Sem tabuleiro'],
  },
  levels: {
    kicker: 'Para todos os níveis',
    title: 'Sabe pouco ou já joga bem? Tem desafio para você',
    beginner: {
      title: 'Está começando',
      body: 'Faça o teste de nível ou vá direto à Escola do Viktor: como cada peça se move, xeque, mate e os primeiros finais, com aulas curtas, dicas na hora certa e adversários que jogam no seu ritmo.',
    },
    advanced: {
      title: 'Já joga bem',
      body: 'Vá às aulas de finais e converta posições teóricas contra o Maia 2600 e o Stockfish. Se você ganhar a dama contra a torre do Stockfish, a técnica é sua.',
    },
  },
  roadmap: {
    kicker: 'Roadmap',
    title: 'Para onde o Lucena vai',
    items: [
      {
        status: 'Agora',
        title: 'Versão de testes no Android',
        body: 'Distribuída pelo Firebase App Distribution, do Google. Quem entra no grupo recebe sempre a versão mais recente.',
      },
      {
        status: 'Em preparação',
        title: 'Google Play',
        body: 'A conta na Google Play já está sendo criada. A publicação vem logo, logo.',
      },
      {
        status: 'Depois',
        title: 'iPhone',
        body: 'Assim que houver recursos para publicar na App Store.',
      },
    ],
  },
  support: {
    kicker: 'Apoie o projeto',
    title: 'Ajude o Lucena a crescer',
    body: [
      'O Lucena é gratuito e feito por uma pessoa só, nas horas vagas. Se ele te ajudou e você quiser contribuir, qualquer apoio faz diferença para o app crescer mais rápido.',
      'Ainda vamos criar um jeito simples de apoiar direto pelo app, com um mural de apoiadores: quem ajudar ganha visibilidade lá dentro. Por enquanto, se quiser doar, é só me mandar um e-mail.',
    ],
    cardTitle: 'Mural de apoiadores',
    cardBody: 'Em breve no app: quem apoiar o projeto aparece lá dentro, para toda a comunidade ver.',
    cta: 'Quero apoiar',
    subject: 'Quero apoiar o Lucena',
    note:
      'E o iPhone? O Lucena vai para a App Store assim que eu tiver os recursos para publicar lá. Primeiro quero validar a ideia no Android, mas, se você usa iOS, pode ficar tranquilo: vou fazer o possível para chegar lá o quanto antes.',
  },
  tester: {
    kicker: 'Seja testador',
    title: 'Teste antes de todo mundo',
    body: 'Entre no grupo de testes e receba sempre a versão mais recente do Lucena no seu Android.',
    teachers:
      'É professor de xadrez? Passe o app para os seus alunos. Os finais são a melhor porta de entrada, e o feedback de quem ensina vale ouro.',
    safety:
      'Os testes são distribuídos pelo Firebase App Distribution, a plataforma do Google para enviar versões de teste de apps. Você recebe o convite, instala o app de testes do Firebase e baixa o Lucena por ele, com segurança.',
    safetyLink: 'Como funciona o Firebase App Distribution',
    wait: 'Prefere esperar? Sem problema: o Lucena chega à Google Play em breve.',
    cta: 'Entrar no grupo de testes',
    thanks:
      'Obrigado de verdade. Alguém dedicar tempo para testar, validar a ideia e mandar feedback é muito importante para mim. Cada mensagem ajuda a decidir o próximo passo do app.',
  },
  vision: {
    kicker: 'Visão',
    title: 'Um projeto vivo',
    body: 'O objetivo é oferecer a melhor experiência para aprender xadrez, melhorar nos finais e se desafiar neles. O Lucena vai crescer com novos recursos, guiados pelo que a comunidade pedir.',
    cta: 'Mandar uma ideia',
  },
  refs: {
    kicker: 'Créditos e referências',
    title: 'Feito sobre os ombros de gigantes',
    items: [
      { name: 'Stockfish', body: 'Motor de xadrez de código aberto (GPL-3.0), o adversário mais forte do app.' },
      { name: 'Maia', body: 'Motor de código aberto com rede neural, de pesquisadores da Universidade de Toronto, treinado em partidas de pessoas no Lichess.' },
      { name: 'Lichess', body: 'As bibliotecas de tabuleiro e de regras (chessground e dartchess) e as peças cburnett, de Colin M.L. Burnett.' },
      { name: 'Firebase App Distribution', body: 'A plataforma do Google que entrega as versões de teste.' },
      { name: 'Retrato de Philidor', body: 'Gravura de Augustin de Saint-Aubin, 1772, em domínio público (Wikimedia Commons).' },
    ],
  },
  footer: {
    tagline: 'Treine finais de xadrez contra o Maia e o Stockfish.',
    dev: 'Sou programador. Se você precisa de uma landing page, de um aplicativo ou quer conhecer meus serviços, fale comigo:',
    contact: 'Contato',
    privacy: 'Política de privacidade',
    terms: 'Termos de uso',
    deletion: 'Apagar a conta',
  },
  media: {
    blindMode: 'Nova partida no Lucena: a escolha entre o modo normal e o às cegas',
    blindBoard: 'Partida às cegas com o tabuleiro à vista',
    blindSquares: 'Partida às cegas só com as casas: a grade e as coordenadas, sem as peças',
    blindNone: 'Partida às cegas sem tabuleiro, só com os lances',
    hero: 'Escolha do nível do Maia e do ritmo, e a partida contra ele no Lucena',
    school: 'Primeira aula da escola do Viktor no Lucena: a torre e as estrelas',
    placement: 'Teste de nível do Lucena: uma pergunta de cada vez, com a opção "Não sei"',
    lesson: 'Capítulo de uma aula de finais do Lucena, a posição de Lucena: pense, veja e jogue',
    journey: 'A Jornada do Lucena: o adversário atual e os desafios',
    speedrun: 'Speedrun do Lucena: as etapas e a partida contra o relógio',
    marathon: 'Maratona do Lucena: uma partida emenda na outra com um relógio só',
    theme: 'Escolha do tema e da cor do app no Lucena',
    home: 'Tela inicial do Lucena no tema escuro',
    journeyChallenge: 'Desafio da Jornada no Lucena: mate de dama contra o Tito, nível 1200',
    placementResult: 'Resultado do teste de nível: a faixa de rating e o mapa do que você já domina',
    lessonChapters: 'Aula de finais do Lucena dividida em capítulos: Ruptura, nos finais de peões',
    realGame: 'Capítulo com uma partida real, Andersson contra Åkesson em 1999, e o link para ela no Lichess',
    solvedExercise: 'Exercício resolvido numa aula de finais, com o comentário do Viktor',
    stars: 'Desafio das estrelas do Lucena com a torre',
    profile: 'Rating de finais no Lucena, com o gráfico e o histórico de partidas',
    achievements: 'Conquistas do Lucena: as concluídas e as que faltam',
    record: 'Fim da Maratona no Lucena: o tempo total e um novo recorde pessoal',
    gameEnd: 'Fim de partida no Lucena: vitória contra o Tito, o rating e a melhor linha do Stockfish',
    play: 'Reproduzir vídeo',
    pause: 'Pausar vídeo',
  },
  privacy: {
    slug: 'privacidade',
    title: 'Política de privacidade',
    description: 'Como o Lucena trata os seus dados: sem conta, tudo fica no celular; com a conta opcional, o progresso é guardado no Firebase para voltar em outro aparelho. Nada é vendido.',
    updated: 'Versão de 22 de outubro de 2026',
    back: 'Voltar para o início',
    sections: [
      {
        title: 'Em resumo',
        body: [
          'O Lucena é um app gratuito para treinar finais de xadrez no Android. Ele funciona sem internet e <strong>sem conta</strong>. A conta é opcional: serve para guardar o seu progresso e recuperá-lo em outro aparelho.',
          '<strong>Eu não vendo nem alugo dados pessoais</strong>, e não uso os seus dados para nada além do que está escrito aqui.',
        ],
      },
      {
        title: 'Quem é o responsável',
        body: [
          'O Lucena é feito por Gabriel Novais Cortes, desenvolvedor independente no Brasil, que é o controlador dos dados nos termos da Lei Geral de Proteção de Dados (LGPD). Contato: <a href="mailto:gncortes.apps@gmail.com">gncortes.apps@gmail.com</a>.',
        ],
      },
      {
        title: 'Sem conta: tudo fica no aparelho',
        body: [
          'O seu progresso (aulas, partidas, rating, conquistas e recordes), o seu perfil (apelido, cor do avatar, objetivo e nível) e as suas preferências (tema, idioma, voz, tabuleiro) ficam guardados no armazenamento do app, no seu celular.',
          'Para apagar tudo, limpe os dados do Lucena nas configurações do Android ou desinstale o app.',
        ],
      },
      {
        title: 'Com conta: o que é guardado',
        body: [
          'Você pode entrar com a sua conta do Google ou com um e-mail. O login é feito pelo Firebase Authentication, do Google, que guarda o seu e-mail, o nome e a foto da conta do Google (quando você entra com ela) e um identificador da conta.',
          'Com a conta, o app copia para o Cloud Firestore, também do Google:',
          '<ul><li>o seu perfil: nome, apelido, país (lido da região do celular, que você pode trocar), estado e cidade (se você informar), idioma, objetivo, nível e os usuários do Lichess e do Chess.com, se você os informou;</li><li>o seu progresso: aulas, rating, conquistas, recordes, desafios e posições cumpridas;</li><li>as suas partidas no app: os lances, o resultado, as datas e o adversário (sempre um motor do próprio app).</li></ul>',
          'Se você escolher uma foto de perfil (da câmera, da galeria ou a da conta do Google), ela vai para o Firebase Storage, também do Google, em tamanho reduzido. O app só usa a câmera e a galeria quando você toca para trocar a foto.', 'Esses dados ficam em servidores do Google, que podem estar fora do Brasil. A transferência segue as garantias contratuais do Google Cloud (<a href="https://firebase.google.com/support/privacy" rel="noopener">privacidade do Firebase</a>). Só você, entrando na sua conta, lê e altera esses dados.',
        ],
      },
      {
        title: 'Lichess e Chess.com',
        body: [
          'Se você conectar o Lichess, o login é feito no próprio site do Lichess. O app recebe um token de acesso que fica <strong>só no armazenamento seguro do seu celular</strong>, nunca na conta do Lucena, e é usado para ler o seu rating. O nome de usuário do Lichess vai para o seu perfil.',
          'Se você informar o seu usuário do Chess.com, o app lê o seu rating público na API do Chess.com. Não há senha nem login.',
          'Esses sites seguem as políticas deles (<a href="https://lichess.org/privacy" rel="noopener">Lichess</a> e <a href="https://www.chess.com/legal/privacy" rel="noopener">Chess.com</a>).',
        ],
      },
      {
        title: 'Notificações',
        body: [
          'Se você permitir, o app recebe avisos pelo Firebase Cloud Messaging (o final do dia, por exemplo). Para isso, o celular gera um código de envio, e o app se inscreve nos tópicos dos avisos que você ligou. Você desliga cada aviso no app e todos nas configurações do Android.',
        ],
      },
      {
        title: 'Estatísticas de uso e falhas',
        body: [
          '<strong>Estatísticas de uso.</strong> O app usa o Google Analytics for Firebase para saber quais telas e aulas são usadas, onde as pessoas desistem e de onde vieram (por exemplo, de um link de desafio). Ele registra eventos do app (como abrir uma aula ou terminar uma partida), o modelo do aparelho, a versão do Android, o país e o estado (nunca a cidade), se você tem conta e a campanha ou o link pelo qual chegou, com um identificador do app. Nunca vão o seu nome, o seu e-mail, o que você digita nem as posições que você monta.',
          '<strong>Falhas.</strong> Quando o app trava, o Firebase Crashlytics envia o relatório do erro, com o modelo do aparelho, a versão do sistema e a do app, para eu poder corrigir.',
          '<strong>A sua opinião.</strong> Quando você responde uma pesquisa do app ou manda um feedback, a resposta vai para o Cloud Firestore <strong>sem identificar você</strong>: sem conta, e-mail, nome nem identificador de publicidade. Vão junto só a versão do app, o modelo do celular, o seu nível e como você chegou ao app.',
        ],
      },
      {
        title: 'Internet e páginas externas',
        body: [
          'Os motores de xadrez, as aulas e as vozes rodam no próprio aparelho. O app usa a internet para a conta, as notificações, as estatísticas, a sua opinião, o Lichess e o Chess.com, e para abrir, dentro dele, as páginas externas que você toca, como artigos da Wikipedia. Essas páginas seguem as políticas dos sites delas.',
          'Quando você compartilha uma partida ou um desafio, o texto, a imagem e o link vão só para o app que você escolher.',
        ],
      },
      {
        title: 'Microfone',
        body: [
          'No modo às cegas, você pode falar os lances. Só aí o app pede acesso ao microfone. O Lucena não grava nem guarda o áudio. O reconhecimento é feito pelo serviço de voz do Android: sempre que possível, só no aparelho; se o pacote de voz offline do idioma não estiver instalado, o Android pode usar o serviço on-line do Google. Sem a permissão, você joga com o teclado ou com toques.',
        ],
      },
      {
        title: 'Para que os dados são usados e com que base',
        body: [
          '<ul><li><strong>Conta, perfil, progresso e partidas:</strong> para guardar e devolver o seu progresso, como você pediu ao criar a conta (execução do contrato, LGPD art. 7º, V).</li><li><strong>Notificações:</strong> só com o seu consentimento, que você pode retirar a qualquer momento (art. 7º, I).</li><li><strong>Estatísticas de uso, relatórios de falha e a sua opinião:</strong> para corrigir erros e melhorar as aulas (legítimo interesse, art. 7º, IX).</li></ul>',
        ],
      },
      {
        title: 'Por quanto tempo',
        body: [
          'Os dados da conta ficam guardados enquanto a conta existir. Ao apagar a conta, eles são apagados na hora (veja abaixo). As estatísticas de uso ficam guardadas por até 14 meses, e os relatórios de falha, por até 90 dias.',
        ],
      },
      {
        id: 'apagar-conta',
        title: 'Como apagar a conta',
        body: [
          'No app, abra o <strong>Perfil</strong> e toque em <strong>Apagar a conta</strong>. A conta, o perfil, a foto, o progresso e as partidas guardados nela são apagados na hora. Neste celular, o app continua funcionando sem conta.',
          'Sem o app, siga os passos da página <a href="/apagar-conta/">Apagar a conta</a>.',
        ],
      },
      {
        title: 'Os seus direitos',
        body: [
          'Pela LGPD (e, para quem está na União Europeia, pelo GDPR), você pode pedir a confirmação de que eu trato os seus dados, o acesso a eles, a correção, a portabilidade, a exclusão e informações sobre com quem eles são compartilhados, além de retirar um consentimento. Escreva para <a href="mailto:gncortes.apps@gmail.com">gncortes.apps@gmail.com</a>: a resposta vem em até 15 dias. Você também pode reclamar à Autoridade Nacional de Proteção de Dados (ANPD).',
        ],
      },
      {
        title: 'Idade mínima',
        body: [
          'O Lucena é para pessoas a partir de 13 anos. Quem tem menos de 18 anos deve usar a conta com a autorização dos pais ou responsáveis. Se você souber que uma criança com menos de 13 anos criou uma conta, escreva para mim, e eu apago os dados dela.',
        ],
      },
      {
        title: 'Segurança',
        body: [
          'Os dados viajam criptografados (HTTPS) e ficam guardados com as proteções do Google Cloud. As regras do banco de dados deixam cada pessoa ler e alterar só a própria conta.',
        ],
      },
      {
        title: 'Mudanças nesta política',
        body: [
          'Se algo mudar, esta página é atualizada e a data da versão, lá em cima, muda junto.',
        ],
      },
      {
        title: 'Contato',
        body: [
          'Dúvidas sobre privacidade? Escreva para <a href="mailto:gncortes.apps@gmail.com">gncortes.apps@gmail.com</a>.',
        ],
      },
    ],
  },
  terms: {
    slug: 'termos',
    title: 'Termos de uso',
    description: 'As regras para usar o Lucena, o app gratuito para treinar finais de xadrez: a conta, o uso permitido, o código aberto e os limites da responsabilidade.',
    updated: 'Versão de 22 de outubro de 2026',
    back: 'Voltar para o início',
    sections: [
      {
        title: 'Aceitação',
        body: [
          'Estes termos valem entre você e Gabriel Novais Cortes, o desenvolvedor do Lucena. Ao usar o app ou criar uma conta, você concorda com eles e com a <a href="/privacidade/">Política de privacidade</a>. Se não concordar, não use o app.',
        ],
      },
      {
        title: 'O que é o Lucena',
        body: [
          'O Lucena é um app gratuito para treinar finais de xadrez: aulas, exercícios e partidas contra motores que rodam no aparelho. Ele funciona sem conta e sem internet. As funções podem mudar, ser melhoradas ou deixar de existir com novas versões.',
        ],
      },
      {
        title: 'Idade',
        body: [
          'O app é para pessoas a partir de 13 anos. Quem tem menos de 18 anos precisa da autorização dos pais ou responsáveis para criar uma conta.',
        ],
      },
      {
        title: 'A sua conta',
        body: [
          'A conta é opcional. Você responde pelo que é feito nela e deve manter o acesso ao seu e-mail ou à sua conta do Google em segurança. Use um nome, um apelido e uma foto que não ofendam ninguém nem se passem por outra pessoa.',
          'Você pode apagar a conta quando quiser, no Perfil do app ou pela página <a href="/apagar-conta/">Apagar a conta</a>. Posso suspender ou apagar uma conta usada para burlar o app, atacar o serviço ou violar estes termos.',
        ],
      },
      {
        title: 'Uso permitido',
        body: [
          'Use o Lucena para o seu estudo e o seu lazer. Não tente acessar dados de outras pessoas, sobrecarregar ou atacar os servidores, nem usar o app para fins ilegais.',
        ],
      },
      {
        title: 'Código aberto',
        body: [
          'O código do Lucena é livre, sob a licença <a href="https://www.gnu.org/licenses/agpl-3.0.html" rel="noopener">GNU AGPL 3.0</a>, que define o que você pode fazer com ele. O nome Lucena, o logotipo, as ilustrações e o texto das aulas não são cedidos por essa licença sem autorização.',
          'O app usa programas de terceiros, com as licenças deles: entre eles, o motor Stockfish (GPL 3.0) e os modelos Maia. A lista completa está em Configurações → Sobre o Lucena → Licenças de código aberto.',
        ],
      },
      {
        title: 'Serviços de terceiros',
        body: [
          'O login, o armazenamento da conta, as notificações e as estatísticas são prestados pelo Google (Firebase). Os dados de rating vêm do Lichess e do Chess.com, se você os conectar. Esses serviços têm os próprios termos, e eu não respondo pela disponibilidade deles.',
        ],
      },
      {
        title: 'Sem garantia',
        body: [
          'O Lucena é oferecido gratuitamente, “no estado em que se encontra”. Eu me esforço para que as aulas e as análises estejam certas e o app funcione bem, mas não garanto que ele esteja livre de erros nem sempre disponível. O rating do app é uma estimativa para o seu treino, não uma medida oficial.',
        ],
      },
      {
        title: 'Limitação de responsabilidade',
        body: [
          'Na medida permitida pela lei, não respondo por perdas indiretas do uso do app, como a perda de progresso guardado só no aparelho. Nada aqui limita os direitos que o Código de Defesa do Consumidor garante a você.',
        ],
      },
      {
        title: 'Mudanças nestes termos',
        body: [
          'Se estes termos mudarem, esta página é atualizada e a data da versão muda junto. Continuar usando o app depois disso vale como aceitar a nova versão.',
        ],
      },
      {
        title: 'Lei e foro',
        body: [
          'Estes termos seguem as leis do Brasil. Fica eleito o foro do seu domicílio para resolver qualquer conflito.',
        ],
      },
      {
        title: 'Contato',
        body: [
          'Dúvidas sobre estes termos? Escreva para <a href="mailto:gncortes.apps@gmail.com">gncortes.apps@gmail.com</a>.',
        ],
      },
    ],
  },
  deletion: {
    slug: 'apagar-conta',
    title: 'Apagar a conta',
    description: 'Como apagar a sua conta do Lucena e os dados guardados nela, pelo app ou por e-mail.',
    updated: 'Versão de 22 de outubro de 2026',
    back: 'Voltar para o início',
    sections: [
      {
        title: 'Pelo app',
        body: [
          '<ol><li>Abra o Lucena e entre na sua conta.</li><li>Abra o <strong>Perfil</strong>.</li><li>Toque em <strong>Apagar a conta</strong> e confirme.</li></ol>',
          'É preciso estar com internet. Por segurança, o app pode pedir que você entre de novo na conta antes de apagar.',
        ],
      },
      {
        title: 'Sem o app',
        body: [
          'Escreva para <a href="mailto:gncortes.apps@gmail.com?subject=Apagar%20a%20conta%20do%20Lucena">gncortes.apps@gmail.com</a> a partir do e-mail da conta, com o assunto “Apagar a conta do Lucena”. A conta é apagada em até 15 dias, e você recebe a confirmação por e-mail.',
        ],
      },
      {
        title: 'O que é apagado',
        body: [
          'A conta (e-mail, nome e foto), o perfil, a foto de perfil, o progresso e as partidas guardados nela. Nada disso fica guardado depois: não dá para desfazer.',
          'O que fica no seu celular não é apagado: o app continua funcionando sem conta. Para apagar também esses dados, limpe os dados do Lucena nas configurações do Android ou desinstale o app.',
          'As estatísticas de uso, os relatórios de falha e as respostas de pesquisa e feedback, que não têm o seu nome nem o seu e-mail e não ficam ligados à conta, são apagados sozinhos nos prazos da <a href="/privacidade/">Política de privacidade</a>.',
        ],
      },
    ],
  },
};

export default pt;

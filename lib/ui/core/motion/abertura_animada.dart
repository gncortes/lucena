import 'dart:math' as math;

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import '../../../l10n/app_localizations.dart';
import '../keys/motion_keys.dart';
import '../theme/mascote_colors.dart';
import 'lucena_motion.dart';
import 'movimento_reduzido.dart';

/// H-ANI-44 · a abertura do app em fases, logo depois da tela do sistema
/// (H-ANI-43), em toda partida a frio (design/branding/abertura2.html).
///
/// O [child] (o app) monta por baixo desde o começo; a abertura fica por cima
/// até a [carga] terminar e as fases acabarem:
/// - entrada (uma vez): o peão agacha, os braços nascem e os de trás somem;
/// - roscas em laço enquanto carrega (ciclo de 640 ms, esquerda e direita);
/// - final no fim do primeiro ciclo depois da carga: halteres ao alto, brilho,
///   nome, descrição e uma piscada;
/// - saída 700 ms depois do final (ou no toque, com a carga pronta): a figura
///   encolhe e some e o app aparece por baixo.
///
/// Tudo sai de um relógio só: cada valor é função do tempo, do instante em que
/// a carga terminou e do toque. Com movimento reduzido fica a pose do ícone, o
/// nome em fade e uma saída de 100 ms assim que a carga termina.
class AberturaAnimada extends StatefulWidget {
  const AberturaAnimada({
    super.key,
    required this.carga,
    required this.child,
    this.aoTerminar,
  });

  /// Termina quando a primeira tela do app está pronta.
  final Future<void> carga;

  /// Chamado uma vez, quando a abertura sai da árvore.
  final VoidCallback? aoTerminar;

  final Widget child;

  @override
  State<AberturaAnimada> createState() => _AberturaAnimadaState();
}

int _ms(Duration d) => d.inMilliseconds;

class _AberturaAnimadaState extends State<AberturaAnimada>
    with SingleTickerProviderStateMixin {
  late final Ticker _relogio;
  var _t = 0;
  int? _carregou;
  int? _toque;
  var _acabou = false;

  @override
  void initState() {
    super.initState();
    _relogio = createTicker(_passa)..start();
    widget.carga.whenComplete(() {
      if (!mounted || _carregou != null) return;
      setState(() => _carregou = _t);
    });
  }

  @override
  void dispose() {
    _relogio.dispose();
    super.dispose();
  }

  void _passa(Duration decorrido) {
    final t = decorrido.inMilliseconds;
    final saida = _saida(MovimentoReduzido.of(context));
    if (saida != null && t >= saida + _duracaoDaSaida) {
      _relogio.stop();
      setState(() {
        _t = t;
        _acabou = true;
      });
      widget.aoTerminar?.call();
      return;
    }
    setState(() => _t = t);
  }

  int get _duracaoDaSaida => _ms(
    MovimentoReduzido.of(context)
        ? LucenaMotion.saidaReduzida
        : LucenaMotion.aberturaSaida,
  );

  /// Começo do final: o fim do primeiro ciclo de roscas depois da carga.
  int? get _final {
    final carregou = _carregou;
    if (carregou == null) return null;
    final entrada = _ms(LucenaMotion.aberturaEntrada);
    final ciclo = _ms(LucenaMotion.aberturaCiclo);
    final ciclos = math.max(1, ((carregou - entrada) / ciclo).ceil());
    return entrada + ciclos * ciclo;
  }

  int? _saida(bool reduzir) {
    final carregou = _carregou;
    if (carregou == null) return null;
    final natural = reduzir
        ? math.max(_ms(LucenaMotion.nomeReduzido), carregou)
        : _final! + _ms(LucenaMotion.aberturaFinal);
    final toque = _toque;
    return toque == null ? natural : math.min(natural, toque);
  }

  void _tocou() {
    if (_carregou == null || _toque != null) return;
    setState(() => _toque = _t);
  }

  @override
  Widget build(BuildContext context) {
    // A árvore não muda de forma quando a abertura sai: o app fica no mesmo
    // lugar do Stack e não monta de novo (só a camada de cima some).
    return Stack(
      textDirection: TextDirection.ltr,
      fit: StackFit.expand,
      children: [
        widget.child,
        if (!_acabou)
          Positioned.fill(
            child: MediaQuery.maybeOf(context) == null
                ? MediaQuery.fromView(view: View.of(context), child: _camada())
                : _camada(),
          ),
      ],
    );
  }

  Widget _camada() => Builder(
    builder: (context) {
      final reduzir = MovimentoReduzido.of(context);
      final quadro = reduzir ? _quadroReduzido() : _quadro();
      return Directionality(
        textDirection: TextDirection.ltr,
        child: _Camada(quadro: quadro, aoTocar: _tocou),
      );
    },
  );

  _Quadro _quadroReduzido() {
    final luz = _entre(_t, 0, _ms(LucenaMotion.nomeReduzido));
    final saida = _saida(true);
    final some = saida == null
        ? 0.0
        : _entre(_t, saida, saida + _ms(LucenaMotion.saidaReduzida));
    return _Quadro(
      pose: PoseDoMascote.icone,
      luzDoNome: luz,
      descida: 0,
      conteudo: 1 - some,
      escala: 1,
      fundo: 1 - some,
    );
  }

  _Quadro _quadro() {
    final t = _t;
    final entrada = _ms(LucenaMotion.aberturaEntrada);
    final ciclo = _ms(LucenaMotion.aberturaCiclo);
    final rosca = _ms(LucenaMotion.aberturaRosca);
    final fim = _final;
    final saida = _saida(false);
    const std = LucenaMotion.standard;
    const baixo = LucenaMotion.anguloBaixado;

    // Entrada: agacha e volta; braços nascem; os de trás somem.
    final agacha = _ms(LucenaMotion.aberturaAgacha);
    final levanta = _ms(LucenaMotion.aberturaLevanta);
    final double amasso = t < agacha
        ? std.transform(_entre(t, 0, agacha))
        : 1 - std.transform(_entre(t, agacha, levanta));
    final nasce = std.transform(
      _entre(t, _ms(LucenaMotion.aberturaBracosDe), entrada),
    );
    final escalaDoBraco = _lerp(LucenaMotion.bracoNasce, 1, nasce);
    final atras =
        1 -
        std.transform(
          _entre(
            t,
            _ms(LucenaMotion.aberturaBracosDe),
            _ms(LucenaMotion.aberturaAtrasAte),
          ),
        );

    // Roscas: até o começo do final, em ciclos a partir do fim da entrada.
    var anguloE = baixo;
    var anguloD = baixo;
    var inclinacao = 0.0;
    final emRosca = t >= entrada && (fim == null || t < fim);
    if (emRosca) {
      final c = (t - entrada) % ciclo;
      // Sobe em 160 ms e desce em 160: esquerda em 0–320, direita em 320–640.
      double lance(int de) {
        if (c < de || c >= de + 2 * rosca) return 0;
        final p = c < de + rosca
            ? std.transform((c - de) / rosca)
            : 1 - std.transform((c - de - rosca) / rosca);
        return p;
      }

      final e = lance(0);
      final d = lance(2 * rosca);
      anguloE = baixo * (1 - e);
      anguloD = baixo * (1 - d);
      inclinacao = LucenaMotion.inclinacaoDaRosca * (d - e);
    }

    // Gota: só no primeiro ciclo.
    // Aparece em 120 ms, desce 30 px até o fim do ciclo e some descendo até
    // 46 px em 790 ms.
    final gotaT = t - entrada;
    final aparece = _ms(LucenaMotion.gotaAparece);
    final gotaSome = _ms(LucenaMotion.gotaSome);
    double gotaOpacidade = 0;
    double gotaDesce = 0;
    if (gotaT >= 0 && gotaT < gotaSome) {
      if (gotaT < aparece) {
        gotaOpacidade = gotaT / aparece;
      } else if (gotaT < ciclo) {
        gotaOpacidade = 1;
        gotaDesce =
            LucenaMotion.gotaDesce * (gotaT - aparece) / (ciclo - aparece);
      } else {
        final p = (gotaT - ciclo) / (gotaSome - ciclo);
        gotaOpacidade = 1 - p;
        gotaDesce = _lerp(LucenaMotion.gotaDesce, LucenaMotion.gotaSomeEm, p);
      }
    }

    // Final: halteres ao alto, brilho, nome e piscada.
    var brilho = 0.0;
    var olhos = 1.0;
    var luzDoNome = 0.0;
    var subida = 1.0;
    if (fim != null && t >= fim) {
      final f = t - fim;
      final alto = std.transform(
        _entre(f, 0, _ms(LucenaMotion.halteresAoAlto)),
      );
      anguloE = baixo * (1 - alto);
      anguloD = baixo * (1 - alto);
      brilho = _entre(
        f,
        _ms(LucenaMotion.brilhoDe),
        _ms(LucenaMotion.brilhoAte),
      );
      final nome = LucenaMotion.emphasized.transform(
        _entre(f, _ms(LucenaMotion.nomeDe), _ms(LucenaMotion.nomeAte)),
      );
      luzDoNome = nome;
      subida = 1 - nome;
      final fecha = _ms(LucenaMotion.piscaFecha);
      if (f >= _ms(LucenaMotion.piscaDe) && f < fecha) {
        olhos = _lerp(
          1,
          LucenaMotion.olhosFechados,
          _entre(f, _ms(LucenaMotion.piscaDe), fecha),
        );
      } else if (f >= fecha) {
        olhos = _lerp(
          LucenaMotion.olhosFechados,
          1,
          _entre(f, fecha, _ms(LucenaMotion.piscaAte)),
        );
      }
    }

    // Saída: a figura encolhe e some (ACC), o fundo some (DEC).
    var conteudo = 1.0;
    var escala = 1.0;
    var fundo = 1.0;
    if (saida != null && t >= saida) {
      final p = _entre(t, saida, saida + _ms(LucenaMotion.aberturaSaida));
      final acc = LucenaMotion.emphasizedAccelerate.transform(p);
      conteudo = 1 - acc;
      escala = _lerp(1, LucenaMotion.encolheNaSaida, acc);
      fundo = 1 - LucenaMotion.emphasizedDecelerate.transform(p);
      brilho *= 1 - _entre(t, saida, saida + _ms(LucenaMotion.brilhoSai));
    }

    return _Quadro(
      pose: PoseDoMascote(
        escalaX: _lerp(1, LucenaMotion.agachaX, amasso),
        escalaY: _lerp(1, LucenaMotion.agachaY, amasso),
        opacidadeAtras: atras,
        bracoE: BracoDaPose(
          angulo: anguloE,
          escala: escalaDoBraco,
          opacidade: nasce,
        ),
        bracoD: BracoDaPose(
          angulo: anguloD,
          escala: escalaDoBraco,
          opacidade: nasce,
        ),
        inclinacao: inclinacao,
        gotaOpacidade: gotaOpacidade,
        gotaDesce: gotaDesce,
        olhos: olhos,
        brilho: brilho,
      ),
      luzDoNome: luzDoNome,
      descida: LucenaMotion.subidaDoNome * subida,
      conteudo: conteudo,
      escala: escala,
      fundo: fundo,
    );
  }
}

/// Fração de [t] entre [de] e [ate], presa em 0–1.
double _entre(int t, int de, int ate) {
  if (ate <= de) return t >= ate ? 1 : 0;
  return ((t - de) / (ate - de)).clamp(0.0, 1.0);
}

double _lerp(double a, double b, double p) => a + (b - a) * p;

class _Quadro {
  const _Quadro({
    required this.pose,
    required this.luzDoNome,
    required this.descida,
    required this.conteudo,
    required this.escala,
    required this.fundo,
  });

  final PoseDoMascote pose;
  final double luzDoNome;
  final double descida;
  final double conteudo;
  final double escala;
  final double fundo;
}

class _Camada extends StatelessWidget {
  const _Camada({required this.quadro, required this.aoTocar});

  final _Quadro quadro;
  final VoidCallback aoTocar;

  @override
  Widget build(BuildContext context) {
    final l10n = _textos(context);
    final altura = MediaQuery.sizeOf(context).height;
    const lado = LucenaMotion.figuraDaAbertura;
    const nome = TextStyle(
      color: MascoteColors.branco,
      fontSize: 34,
      fontWeight: FontWeight.w700,
      letterSpacing: .5,
      decoration: TextDecoration.none,
    );
    const descricao = TextStyle(
      color: MascoteColors.branco,
      fontSize: 16,
      fontWeight: FontWeight.w400,
      decoration: TextDecoration.none,
    );
    return GestureDetector(
      key: MotionKeys.abertura,
      behavior: HitTestBehavior.opaque,
      onTap: aoTocar,
      child: Stack(
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: quadro.fundo,
              child: const ColoredBox(color: MascoteColors.fundo),
            ),
          ),
          Positioned.fill(
            child: Opacity(
              opacity: quadro.conteudo,
              child: Transform.scale(
                scale: quadro.escala,
                child: Stack(
                  children: [
                    Center(
                      child: CustomPaint(
                        key: MotionKeys.mascote,
                        size: const Size.square(lado),
                        painter: MascotePainter(quadro.pose),
                      ),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      top: altura * LucenaMotion.topoDoNome,
                      child: Transform.translate(
                        offset: Offset(0, quadro.descida),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Opacity(
                              opacity: quadro.luzDoNome,
                              child: Text(
                                l10n.appTitle,
                                textAlign: TextAlign.center,
                                style: nome,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Opacity(
                              opacity:
                                  quadro.luzDoNome *
                                  LucenaMotion.luzDaDescricao,
                              child: Text(
                                l10n.appTagline,
                                textAlign: TextAlign.center,
                                style: descricao,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// A abertura fica acima do `MaterialApp`: os textos saem do idioma do
  /// aparelho.
  static AppLocalizations _textos(BuildContext context) {
    final idioma = basicLocaleListResolution(
      View.of(context).platformDispatcher.locales,
      AppLocalizations.supportedLocales,
    );
    return lookupAppLocalizations(idioma);
  }
}

/// Um braço do mascote: [angulo] em graus para baixo (0 = halter ao alto).
@immutable
class BracoDaPose {
  const BracoDaPose({
    required this.angulo,
    required this.escala,
    required this.opacidade,
  });

  final double angulo;
  final double escala;
  final double opacidade;
}

/// Os valores de um quadro do mascote, lidos pelo [MascotePainter].
@immutable
class PoseDoMascote {
  const PoseDoMascote({
    required this.escalaX,
    required this.escalaY,
    required this.opacidadeAtras,
    required this.bracoE,
    required this.bracoD,
    required this.inclinacao,
    required this.gotaOpacidade,
    required this.gotaDesce,
    required this.olhos,
    required this.brilho,
  });

  /// A pose do ícone B2: braços para trás, sem halteres.
  static const icone = PoseDoMascote(
    escalaX: 1,
    escalaY: 1,
    opacidadeAtras: 1,
    bracoE: BracoDaPose(
      angulo: LucenaMotion.anguloBaixado,
      escala: LucenaMotion.bracoNasce,
      opacidade: 0,
    ),
    bracoD: BracoDaPose(
      angulo: LucenaMotion.anguloBaixado,
      escala: LucenaMotion.bracoNasce,
      opacidade: 0,
    ),
    inclinacao: 0,
    gotaOpacidade: 0,
    gotaDesce: 0,
    olhos: 1,
    brilho: 0,
  );

  final double escalaX;
  final double escalaY;
  final double opacidadeAtras;
  final BracoDaPose bracoE;
  final BracoDaPose bracoD;

  /// Graus; positivo inclina para a direita.
  final double inclinacao;
  final double gotaOpacidade;
  final double gotaDesce;

  /// Abertura dos olhos (1 = abertos).
  final double olhos;
  final double brilho;
}

/// O mascote B2 (design/branding/mascote.js) num quadro de 1024, na [pose].
class MascotePainter extends CustomPainter {
  MascotePainter(this.pose);

  final PoseDoMascote pose;

  // Medidas do B2: cabeça r 132 em y 330, corpo 170, meia largura 118.
  static const _r = 132.0, _hy = 330.0, _olho = 26.0;
  static const _gy = _hy + _r - 6, _by = _gy + 30, _fy = _by + 170;
  static const _l = 118.0, _ombY = _by + 26;
  static const _maoDx = 178.0, _maoY = _hy + 78;

  static Paint _cheio(Color c) => Paint()..color = c;

  static Paint _traco(Color c, double largura) => Paint()
    ..color = c
    ..style = PaintingStyle.stroke
    ..strokeWidth = largura
    ..strokeCap = StrokeCap.round;

  void _com(Canvas canvas, double opacidade, void Function() desenha) {
    if (opacidade <= 0) return;
    if (opacidade >= 1) {
      desenha();
      return;
    }
    canvas.saveLayer(null, Paint()..color = Color.fromRGBO(0, 0, 0, opacidade));
    desenha();
    canvas.restore();
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas
      ..save()
      ..scale(size.width / 1024, size.height / 1024)
      // tudo: agacha com a base em (512, 706).
      ..translate(512, _fy + 50)
      ..scale(pose.escalaX, pose.escalaY)
      ..translate(-512, -(_fy + 50))
      ..translate(512, 512)
      ..scale(1.04)
      ..translate(-512, -(_hy - _r + _fy + 52) / 2);

    canvas.drawOval(
      Rect.fromCenter(
        center: const Offset(512, _fy + 64),
        width: 380,
        height: 32,
      ),
      _cheio(MascoteColors.chao),
    );

    // corpoG: inclina na rosca.
    canvas
      ..save()
      ..translate(512, _fy + 50)
      ..rotate(pose.inclinacao * math.pi / 180)
      ..translate(-512, -(_fy + 50));

    _com(canvas, pose.opacidadeAtras, () {
      final atras = _traco(MascoteColors.sombra, 50);
      canvas
        ..drawPath(
          Path()
            ..moveTo(472, _ombY)
            ..quadraticBezierTo(
              512 - _l + 4,
              _ombY + 34,
              512 - _l + 22,
              _ombY + 96,
            ),
          atras,
        )
        ..drawPath(
          Path()
            ..moveTo(552, _ombY)
            ..quadraticBezierTo(
              512 + _l - 4,
              _ombY + 34,
              512 + _l - 22,
              _ombY + 96,
            ),
          atras,
        );
    });

    const c = 170.0;
    canvas
      ..drawPath(
        Path()
          ..moveTo(454, _by)
          ..cubicTo(
            450,
            _by + c * .45,
            512 - _l,
            _fy - c * .35,
            512 - _l,
            _fy + 10,
          )
          ..lineTo(512 + _l, _fy + 10)
          ..cubicTo(512 + _l, _fy - c * .35, 574, _by + c * .45, 570, _by)
          ..close(),
        _cheio(MascoteColors.branco),
      )
      ..drawPath(
        Path()
          ..moveTo(552, _by + 6)
          ..cubicTo(
            582,
            _by + c * .5,
            512 + _l - 30,
            _fy - c * .3,
            512 + _l - 26,
            _fy + 10,
          )
          ..lineTo(512 + _l, _fy + 10)
          ..cubicTo(512 + _l, _fy - c * .35, 574, _by + c * .45, 570, _by)
          ..close(),
        _cheio(MascoteColors.sombra),
      )
      ..drawRRect(
        _rr(512 - _l - 34, _fy - 8, 2 * _l + 68, 62, 31),
        _cheio(MascoteColors.branco),
      )
      ..drawRRect(
        _rr(512 - _l - 34, _fy + 32, 2 * _l + 68, 22, 11),
        _cheio(MascoteColors.sombra),
      )
      ..drawRRect(
        _rr(512 - 84, _gy, 168, 40, 20),
        _cheio(MascoteColors.branco),
      );

    _braco(canvas, -1, 512 - 46, pose.bracoE);
    _braco(canvas, 1, 512 + 46, pose.bracoD);
    _cabeca(canvas);
    _brilho(canvas);

    canvas
      ..restore()
      ..restore();
  }

  static RRect _rr(double x, double y, double w, double h, double r) =>
      RRect.fromRectAndRadius(Rect.fromLTWH(x, y, w, h), Radius.circular(r));

  void _braco(Canvas canvas, int lado, double ox, BracoDaPose braco) {
    final hx = 512 + lado * _maoDx;
    final graus = lado * braco.angulo * math.pi / 180;
    _com(canvas, braco.opacidade, () {
      canvas
        ..save()
        ..translate(ox, _ombY)
        ..rotate(graus)
        ..scale(braco.escala)
        ..translate(-ox, -_ombY)
        ..drawPath(
          Path()
            ..moveTo(ox, _ombY)
            ..quadraticBezierTo(hx + lado * 22, _ombY + 30, hx, _maoY + 20),
          _traco(MascoteColors.branco, 54),
        )
        // O halter gira ao contrário e fica de pé.
        ..translate(hx, _maoY)
        ..rotate(-graus)
        ..translate(-hx, -_maoY);
      _halter(canvas, hx, _maoY);
      canvas.restore();
    });
  }

  static void _halter(Canvas canvas, double cx, double cy) {
    final laranja = _cheio(MascoteColors.laranja);
    final claro = _cheio(MascoteColors.laranjaClaro);
    canvas
      ..drawRRect(_rr(cx - 70, cy - 9, 140, 18, 9), _cheio(MascoteColors.barra))
      ..drawRRect(_rr(cx - 82, cy - 38, 34, 76, 17), laranja)
      ..drawRRect(_rr(cx + 48, cy - 38, 34, 76, 17), laranja)
      ..drawRRect(_rr(cx - 76, cy - 30, 10, 34, 5), claro)
      ..drawRRect(_rr(cx + 54, cy - 30, 10, 34, 5), claro)
      ..drawCircle(Offset(cx, cy), 30, _cheio(MascoteColors.branco));
  }

  void _cabeca(Canvas canvas) {
    const r = _r, hy = _hy;
    final cabeca = Rect.fromCircle(center: const Offset(512, hy), radius: r);
    canvas
      ..drawCircle(const Offset(512, hy), r, _cheio(MascoteColors.branco))
      ..drawPath(
        Path()
          ..moveTo(512 + r * .55, hy - r * .83)
          ..arcToPoint(
            const Offset(512 + r * .55, hy + r * .83),
            radius: const Radius.circular(r),
          )
          ..arcToPoint(
            const Offset(512 + r * .55, hy - r * .83),
            radius: const Radius.circular(r * 1.15),
            clockwise: false,
          )
          ..close(),
        _cheio(MascoteColors.sombra),
      )
      // Faixa na testa, cortada pela cabeça, e as pontas soltas.
      ..save()
      ..clipPath(Path()..addOval(cabeca))
      ..drawRect(
        Rect.fromLTWH(512 - r, hy - r * .62, 2 * r, r * .24),
        _cheio(MascoteColors.laranja),
      )
      ..restore();
    _ponta(canvas, hy - r * .62, r * .42, -24, hy - r * .55);
    _ponta(canvas, hy - r * .5, r * .36, 18, hy - r * .45);

    final bochecha = _cheio(MascoteColors.bochecha);
    canvas
      ..drawOval(
        Rect.fromCenter(
          center: Offset(512 - r * .62, hy + r * .3),
          width: r * .34,
          height: r * .2,
        ),
        bochecha,
      )
      ..drawOval(
        Rect.fromCenter(
          center: Offset(512 + r * .62, hy + r * .3),
          width: r * .34,
          height: r * .2,
        ),
        bochecha,
      );

    // Olhos: a piscada fecha em y.
    canvas
      ..save()
      ..translate(512, hy + 4)
      ..scale(1, pose.olhos)
      ..translate(-512, -(hy + 4));
    for (final x in [512 - r * .34, 512 + r * .34]) {
      canvas
        ..drawOval(
          Rect.fromCenter(
            center: Offset(x, hy + 4),
            width: _olho * 1.64,
            height: _olho * 2,
          ),
          _cheio(MascoteColors.fundo),
        )
        ..drawCircle(
          Offset(x - _olho * .3, hy + 4 - _olho * .4),
          _olho * .32,
          _cheio(MascoteColors.brilhoDoOlho),
        );
    }
    canvas
      ..restore()
      ..drawPath(
        Path()
          ..moveTo(492, hy + r * .36)
          ..quadraticBezierTo(512, hy + r * .36 + 18, 532, hy + r * .36),
        _traco(MascoteColors.fundo, 9),
      );

    // Gota de suor.
    _com(canvas, pose.gotaOpacidade, () {
      const x = 512 + r * .78;
      // A meia largura da gota, no espaço de 1024 do desenho.
      const gota = 22.0;
      canvas
        ..save()
        ..translate(0, pose.gotaDesce)
        ..drawPath(
          Path()
            ..moveTo(x, hy - r * .72)
            ..cubicTo(
              x,
              hy - r * .72,
              x - gota,
              hy - r * .48,
              x - gota,
              hy - r * .36,
            )
            ..arcToPoint(
              const Offset(x + gota, hy - r * .36),
              radius: const Radius.circular(gota),
              clockwise: false,
            )
            ..cubicTo(x + gota, hy - r * .48, x, hy - r * .72, x, hy - r * .72)
            ..close(),
          _cheio(MascoteColors.gota),
        )
        ..restore();
    });
  }

  static void _ponta(
    Canvas canvas,
    double y,
    double largura,
    double graus,
    double pivoY,
  ) {
    const r = _r;
    const px = 512 + r * .8;
    canvas
      ..save()
      ..translate(px, pivoY)
      ..rotate(graus * math.pi / 180)
      ..translate(-px, -pivoY)
      ..drawRRect(
        _rr(512 + r * .78, y, largura, r * .14, r * .07),
        _cheio(MascoteColors.laranja),
      )
      ..restore();
  }

  void _brilho(Canvas canvas) {
    _com(canvas, pose.brilho, () {
      final traco = _traco(MascoteColors.laranja, 13);
      for (final lado in [-1, 1]) {
        canvas
          ..drawLine(
            Offset(512 + lado * (_maoDx + 70), _hy - 30),
            Offset(512 + lado * (_maoDx + 96), _hy - 58),
            traco,
          )
          ..drawLine(
            Offset(512 + lado * (_maoDx + 34), _hy - 62),
            Offset(512 + lado * (_maoDx + 44), _hy - 98),
            traco,
          );
      }
    });
  }

  @override
  bool shouldRepaint(MascotePainter oldDelegate) => oldDelegate.pose != pose;
}

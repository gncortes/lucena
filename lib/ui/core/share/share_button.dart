import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/share/share_repository.dart';
import 'share_cubit.dart';

/// A imagem do que está dentro do [RepaintBoundary] de [boundary], em PNG.
/// Com [footer], ela ganha margem na cor [background] e o texto embaixo (a
/// marca do app). Nula se ele ainda não foi desenhado.
Future<Uint8List?> capturePng(
  GlobalKey boundary, {
  List<GlobalKey> extra = const [],
  double pixelRatio = 3,
  String? footer,
  Color background = Colors.white,
  TextStyle? footerStyle,
}) async {
  final render = boundary.currentContext?.findRenderObject();
  if (render is! RenderRepaintBoundary) return null;
  return captureBoundaryPng(
    render,
    extra: [
      for (final key in extra)
        if (key.currentContext?.findRenderObject()
            case final RenderRepaintBoundary piece)
          piece,
    ],
    pixelRatio: pixelRatio,
    footer: footer,
    background: background,
    footerStyle: footerStyle,
  );
}

/// O mesmo que [capturePng], direto de um [RenderRepaintBoundary].
Future<Uint8List?> captureBoundaryPng(
  RenderRepaintBoundary render, {
  List<RenderRepaintBoundary> extra = const [],
  double pixelRatio = 3,
  String? footer,
  Color background = Colors.white,
  TextStyle? footerStyle,
}) async {
  var image = await render.toImage(pixelRatio: pixelRatio);
  // Os outros pedaços ([extra]) vão embaixo, com um respiro entre eles.
  final more = [
    for (final piece in extra) await piece.toImage(pixelRatio: pixelRatio),
  ];
  if (more.isNotEmpty) {
    final stacked = _stacked([image, ...more], gap: 16 * pixelRatio);
    for (final piece in [image, ...more]) {
      piece.dispose();
    }
    image = stacked;
  }
  if (footer != null) {
    final framed = _framed(
      image,
      footer: footer,
      background: background,
      style: (footerStyle ?? const TextStyle()).copyWith(
        fontSize: (footerStyle?.fontSize ?? 14) * pixelRatio,
      ),
      margin: 16 * pixelRatio,
    );
    image.dispose();
    image = framed;
  }
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  return data?.buffer.asUint8List();
}

// As imagens uma embaixo da outra, com [gap] entre elas.
ui.Image _stacked(List<ui.Image> images, {required double gap}) {
  final width = images.map((image) => image.width).reduce(math.max);
  final height =
      images.fold<double>(0, (sum, image) => sum + image.height) +
      gap * (images.length - 1);
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  var top = 0.0;
  for (final image in images) {
    canvas.drawImage(image, Offset(0, top), Paint());
    top += image.height + gap;
  }
  return recorder.endRecording().toImageSync(width, height.round());
}

// A imagem com margem e o rodapé.
ui.Image _framed(
  ui.Image image, {
  required String footer,
  required Color background,
  required TextStyle style,
  required double margin,
}) {
  final text = TextPainter(
    text: TextSpan(text: footer, style: style),
    textDirection: TextDirection.ltr,
    textAlign: TextAlign.center,
  )..layout(maxWidth: image.width.toDouble());
  final width = image.width + 2 * margin;
  final height = image.height + 3 * margin + text.height;
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder)
    ..drawRect(Rect.fromLTWH(0, 0, width, height), Paint()..color = background)
    ..drawImage(image, Offset(margin, margin), Paint());
  text.paint(
    canvas,
    Offset((width - text.width) / 2, image.height + 2 * margin),
  );
  return recorder.endRecording().toImageSync(width.round(), height.round());
}

/// O botão de compartilhar uma conquista: tira a imagem de [boundary] (o
/// [RepaintBoundary] com o cartão) e abre o menu do sistema com ela e o
/// texto [text].
class ShareButton extends StatelessWidget {
  const ShareButton({
    required this.boundary,
    required this.label,
    required this.fileName,
    this.text,
    super.key,
  });

  final GlobalKey boundary;
  final String label;
  final String fileName;
  final String? text;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (context) => ShareCubit(context.read<ShareRepository>()),
    child: BlocBuilder<ShareCubit, bool>(
      builder: (context, sharing) => FilledButton.tonalIcon(
        style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
        icon: const Icon(Icons.share_rounded),
        label: Text(label),
        onPressed: sharing
            ? null
            : () async {
                final cubit = context.read<ShareCubit>();
                final png = await capturePng(boundary);
                if (png == null) return;
                await cubit.share(png, name: fileName, text: text);
              },
      ),
    ),
  );
}

/// O mesmo compartilhar, como ícone (na barra do app).
class ShareIconButton extends StatelessWidget {
  const ShareIconButton({
    required this.boundary,
    this.extra = const [],
    required this.tooltip,
    required this.fileName,
    this.text,
    this.footer,
    super.key,
  });

  final GlobalKey boundary;

  /// Outros pedaços da tela que vão embaixo, na mesma imagem.
  final List<GlobalKey> extra;
  final String tooltip;
  final String fileName;
  final String? text;

  /// O rodapé da imagem (a marca do app), com margem no fundo da tela.
  final String? footer;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (context) => ShareCubit(context.read<ShareRepository>()),
    child: BlocBuilder<ShareCubit, bool>(
      builder: (context, sharing) => IconButton(
        tooltip: tooltip,
        icon: const Icon(Icons.share_rounded),
        onPressed: sharing
            ? null
            : () async {
                final cubit = context.read<ShareCubit>();
                final theme = Theme.of(context);
                final png = await capturePng(
                  boundary,
                  extra: extra,
                  footer: footer,
                  background: theme.scaffoldBackgroundColor,
                  footerStyle: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                );
                if (png == null) return;
                await cubit.share(png, name: fileName, text: text);
              },
      ),
    ),
  );
}

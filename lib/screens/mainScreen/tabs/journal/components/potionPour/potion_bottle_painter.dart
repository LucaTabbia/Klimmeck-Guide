import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:klimmeck_guide/config/potion_bottle_geometry.dart';
import 'package:klimmeck_guide/utils/pour_geometry.dart';

import 'potion_bottle_images.dart';

/// Disegna la boccetta del versamento (Phase 26 D-04, D-05): vetro, liquido
/// in multiply sotto un pelo orizzontale che ondeggia, etichetta col nome,
/// tappo che salta e getto che cade dalla bocca. Coordinate della scena.
class PotionBottlePainter extends CustomPainter {
  PotionBottlePainter({
    required this.images,
    required this.center,
    required this.boxSize,
    required this.angle,
    required this.level,
    required this.slosh,
    required this.wavePhase,
    required this.isPouring,
    required this.corkLift,
    required this.liquidColor,
    required this.name,
    required this.nameStyle,
  });

  final PotionBottleImages? images;
  final Offset center;
  final Size boxSize;
  final double angle;
  final LiquidLevel level;
  final double slosh;
  final double wavePhase;
  final bool isPouring;

  /// 0 = tappo al suo posto, 1 = tappo volato via.
  final double corkLift;
  final Color liquidColor;
  final String name;
  final TextStyle nameStyle;

  static const double _waveAmplitude = 0.012;
  static const double _waveLength = 0.22;
  static const double _streamWidth = 0.05;

  Offset get _origin => center - Offset(boxSize.width / 2, boxSize.height / 2);
  Offset get _pivot => Offset(boxSize.width / 2, boxSize.height / 2);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angle);
    canvas.translate(-_pivot.dx, -_pivot.dy);
    _drawImage(canvas, images?.glass);
    _drawLiquid(canvas);
    _drawImage(canvas, images?.label);
    _drawName(canvas);
    _drawCork(canvas);
    canvas.restore();
    if (isPouring) _drawStream(canvas, size);
  }

  void _drawImage(Canvas canvas, ui.Image? image) {
    if (image == null) return;
    canvas.drawImageRect(
      image,
      Offset.zero & Size(image.width.toDouble(), image.height.toDouble()),
      Offset.zero & boxSize,
      Paint()..filterQuality = FilterQuality.medium,
    );
  }

  Path get _interior => Path()
    ..addPolygon([
      for (final point in PotionBottleGeometry.interior)
        Offset(point.dx * boxSize.width, point.dy * boxSize.height),
    ], true);

  /// Il pelo vive nel riferimento ruotato: si disfa la rotazione dentro il
  /// ritaglio della sagoma, così resta orizzontale sullo schermo.
  void _drawLiquid(Canvas canvas) {
    if (level.liquid.isEmpty) return;
    canvas.save();
    canvas.clipPath(_interior);
    canvas.translate(_pivot.dx, _pivot.dy);
    canvas.rotate(-angle);
    canvas.translate(-_pivot.dx, -_pivot.dy);
    final surface = _surfacePath();
    canvas.drawPath(
      surface,
      Paint()
        ..color = liquidColor
        ..blendMode = BlendMode.multiply,
    );
    canvas.drawPath(
      surface,
      Paint()
        ..color = liquidColor.withValues(alpha: 0.35)
        ..blendMode = BlendMode.srcOver,
    );
    canvas.restore();
  }

  Path _surfacePath() {
    final span = boxSize.longestSide * 1.5;
    final left = _pivot.dx - span;
    final right = _pivot.dx + span;
    final amplitude = boxSize.height * _waveAmplitude;
    final waveLength = boxSize.width * _waveLength;
    final path = Path()..moveTo(left, _surfaceYAt(left, amplitude, waveLength));
    for (var x = left; x <= right; x += 6) {
      path.lineTo(x, _surfaceYAt(x, amplitude, waveLength));
    }
    return path
      ..lineTo(right, _pivot.dy + span)
      ..lineTo(left, _pivot.dy + span)
      ..close();
  }

  double _surfaceYAt(double x, double amplitude, double waveLength) =>
      level.surfaceY +
      math.tan(slosh) * (x - _pivot.dx) +
      amplitude * math.sin(x / waveLength * 2 * math.pi + wavePhase);

  void _drawName(Canvas canvas) {
    final labelWidth = PotionBottleGeometry.labelSize.width * boxSize.width;
    final labelHeight = PotionBottleGeometry.labelSize.height * boxSize.height;
    final painter = TextPainter(
      text: TextSpan(
        text: name,
        style: nameStyle.copyWith(fontSize: labelHeight * 0.22),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
      maxLines: 3,
      ellipsis: '…',
    )..layout(maxWidth: labelWidth * 0.82);
    final labelCenter = Offset(
      PotionBottleGeometry.labelCenter.dx * boxSize.width,
      PotionBottleGeometry.labelCenter.dy * boxSize.height,
    );
    painter.paint(
      canvas,
      labelCenter - Offset(painter.width / 2, painter.height / 2),
    );
  }

  void _drawCork(Canvas canvas) {
    final cork = images?.cork;
    if (cork == null || corkLift >= 1) return;
    final width = PotionBottleGeometry.corkSize.width * boxSize.width;
    final height = PotionBottleGeometry.corkSize.height * boxSize.height;
    final bottom = Offset(
      PotionBottleGeometry.corkBottom.dx * boxSize.width,
      PotionBottleGeometry.corkBottom.dy * boxSize.height,
    );
    final lift = Curves.easeOut.transform(corkLift);
    canvas.save();
    canvas.clipRect(
      Rect.fromLTRB(
        -boxSize.width,
        -boxSize.height,
        boxSize.width * 2,
        PotionBottleGeometry.corkClip * boxSize.height,
      ),
    );
    final rect = Rect.fromLTWH(
      bottom.dx - width / 2 + lift * width * 0.6,
      bottom.dy - height - lift * boxSize.height * 0.45,
      width,
      height,
    );
    canvas.translate(rect.center.dx, rect.center.dy);
    canvas.rotate(lift * 0.9);
    canvas.translate(-rect.center.dx, -rect.center.dy);
    canvas.drawImageRect(
      cork,
      Offset.zero & Size(cork.width.toDouble(), cork.height.toDouble()),
      rect,
      Paint()..color = Colors.white.withValues(alpha: 1 - corkLift),
    );
    canvas.restore();
  }

  /// Il getto parte dalla bocca, esce di lato verso cui pende la boccetta e
  /// cade dritto fino al fondo della scena.
  void _drawStream(Canvas canvas, Size size) {
    final mouth = _origin + level.mouth;
    final side = angle.sign;
    final reach = boxSize.width * 0.25 * side;
    final width = boxSize.width * _streamWidth;
    final path = Path()
      ..moveTo(mouth.dx, mouth.dy)
      ..quadraticBezierTo(
        mouth.dx + reach,
        mouth.dy,
        mouth.dx + reach * 1.2,
        size.height,
      );
    canvas.drawPath(
      path,
      Paint()
        ..color = liquidColor
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = width,
    );
  }

  @override
  bool shouldRepaint(PotionBottlePainter oldDelegate) => true;
}
